import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/location.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual API key
  final String _backendUrl = 'http://localhost:3000'; // Update with your backend URL

  // Location Tracking
  Future<void> updateLocationTracking(LocationTracking tracking) async {
    await _firestore.collection('locationTracking').doc(tracking.id).set(tracking.toJson());
  }

  Future<List<LocationTracking>> getLocationHistory(
    String entityId,
    String entityType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _firestore
        .collection('locationTracking')
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType)
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => LocationTracking.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Geofencing
  Future<void> createGeofence(Geofence geofence) async {
    await _firestore.collection('geofences').doc(geofence.id).set(geofence.toJson());
  }

  Future<List<Geofence>> getActiveGeofences() async {
    final snapshot = await _firestore
        .collection('geofences')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => Geofence.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<List<Geofence>> checkLocationInGeofences(LocationData location) async {
    final geofences = await getActiveGeofences();
    return geofences.where((geofence) => geofence.containsLocation(location)).toList();
  }

  // Route Optimization
  Future<DeliveryRoute> calculateRoute(
    String orderId,
    LocationData start,
    LocationData end, {
    List<LocationData>? waypoints,
  }) async {
    try {
      // Call Google Maps Directions API
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${start.latitude},${start.longitude}&'
          'destination=${end.latitude},${end.longitude}&'
          'key=$_googleMapsApiKey'
          '${waypoints != null ? '&waypoints=' + waypoints.map((w) => '${w.latitude},${w.longitude}').join('|') : ''}'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final route = data['routes'][0];

        final legs = route['legs'] as List;
        final distance = legs.fold<double>(0, (sum, leg) => sum + leg['distance']['value']);
        final duration = legs.fold<int>(0, (sum, leg) => sum + (leg['duration']['value'] as int));

        final instructions = legs.expand((leg) {
          final steps = leg['steps'] as List;
          return steps.map((step) => step['html_instructions'] as String);
        }).toList();

        return DeliveryRoute(
          id: 'route_${orderId}',
          orderId: orderId,
          waypoints: waypoints ?? [],
          startLocation: start,
          endLocation: end,
          distance: distance / 1000, // Convert to km
          estimatedDuration: Duration(seconds: duration),
          instructions: instructions,
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Failed to calculate route');
      }
    } catch (e) {
      // Fallback: Create simple route
      return DeliveryRoute(
        id: 'route_${orderId}',
        orderId: orderId,
        waypoints: waypoints ?? [],
        startLocation: start,
        endLocation: end,
        distance: start.distanceTo(end),
        estimatedDuration: Duration(minutes: (start.distanceTo(end) * 2).round()), // Rough estimate
        instructions: ['Head towards destination', 'Follow main roads'],
        createdAt: DateTime.now(),
      );
    }
  }

  // Address Autocomplete
  Future<List<AddressSuggestion>> getAddressSuggestions(String input, {String? location}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$input&'
          'key=$_googleMapsApiKey'
          '${location != null ? '&location=$location' : ''}'
          '&radius=50000'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;

        return predictions.map((prediction) {
          return AddressSuggestion.fromJson(prediction);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get Place Details
  Future<LocationData?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?'
          'place_id=$placeId&'
          'key=$_googleMapsApiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];

        final location = result['geometry']['location'];
        final addressComponents = result['address_components'] as List;

        String city = '', state = '', country = '', postalCode = '';

        for (var component in addressComponents) {
          final types = component['types'] as List;
          if (types.contains('locality')) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            state = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('postal_code')) {
            postalCode = component['long_name'];
          }
        }

        return LocationData(
          latitude: location['lat'],
          longitude: location['lng'],
          address: result['formatted_address'],
          city: city,
          state: state,
          country: country,
          postalCode: postalCode,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  // Reverse Geocoding
  Future<LocationData?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=$latitude,$longitude&'
          'key=$_googleMapsApiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final result = results[0];
          final addressComponents = result['address_components'] as List;

          String city = '', state = '', country = '', postalCode = '';

          for (var component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('locality')) {
              city = component['long_name'];
            } else if (types.contains('administrative_area_level_1')) {
              state = component['long_name'];
            } else if (types.contains('country')) {
              country = component['long_name'];
            } else if (types.contains('postal_code')) {
              postalCode = component['long_name'];
            }
          }

          return LocationData(
            latitude: latitude,
            longitude: longitude,
            address: result['formatted_address'],
            city: city,
            state: state,
            country: country,
            postalCode: postalCode,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  // Save user address
  Future<void> saveUserAddress(String userId, LocationData address) async {
    await _firestore
        .collection('userAddresses')
        .doc('${userId}_${DateTime.now().millisecondsSinceEpoch}')
        .set({
          'userId': userId,
          'location': address.toJson(),
          'createdAt': Timestamp.now(),
        });
  }

  // Get user saved addresses
  Future<List<LocationData>> getUserAddresses(String userId) async {
    final snapshot = await _firestore
        .collection('userAddresses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LocationData.fromJson(doc.data()['location']))
        .toList();
  }

  // Calculate delivery zones
  Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    // This would typically integrate with a mapping service to define delivery areas
    // For now, return mock data
    return [
      {
        'id': 'zone_1',
        'name': 'Downtown',
        'center': {'latitude': 40.7128, 'longitude': -74.0060},
        'radius': 5000, // 5km
        'deliveryFee': 2.99,
        'estimatedTime': 25,
      },
      {
        'id': 'zone_2',
        'name': 'Midtown',
        'center': {'latitude': 40.7589, 'longitude': -73.9851},
        'radius': 3000, // 3km
        'deliveryFee': 1.99,
        'estimatedTime': 15,
      },
    ];
  }

  // Check if location is within delivery zone
  Future<Map<String, dynamic>?> getDeliveryZoneForLocation(LocationData location) async {
    final zones = await getDeliveryZones();

    for (var zone in zones) {
      final center = zone['center'];
      final centerLocation = LocationData(
        latitude: center['latitude'],
        longitude: center['longitude'],
        address: '',
        city: '',
        state: '',
        country: '',
        postalCode: '',
        timestamp: DateTime.now(),
      );

      final distance = location.distanceTo(centerLocation) * 1000; // Convert to meters
      if (distance <= zone['radius']) {
        return zone;
      }
    }

    return null;
  }
}