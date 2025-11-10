import 'dart:math' as math;

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postalCode'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Calculate distance between two locations (in kilometers)
  double distanceTo(LocationData other) {
    const double earthRadius = 6371; // km
    final lat1Rad = latitude * (math.pi / 180);
    final lat2Rad = other.latitude * (math.pi / 180);
    final deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    final deltaLngRad = (other.longitude - longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

class DeliveryRoute {
  final String id;
  final String orderId;
  final List<LocationData> waypoints;
  final LocationData startLocation;
  final LocationData endLocation;
  final double distance; // in kilometers
  final Duration estimatedDuration;
  final List<String> instructions;
  final DateTime createdAt;

  DeliveryRoute({
    required this.id,
    required this.orderId,
    required this.waypoints,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.estimatedDuration,
    required this.instructions,
    required this.createdAt,
  });

  factory DeliveryRoute.fromJson(String id, Map<String, dynamic> json) {
    return DeliveryRoute(
      id: id,
      orderId: json['orderId'] ?? '',
      waypoints: (json['waypoints'] as List<dynamic>?)
          ?.map((point) => LocationData.fromJson(point))
          .toList() ?? [],
      startLocation: LocationData.fromJson(json['startLocation'] ?? {}),
      endLocation: LocationData.fromJson(json['endLocation'] ?? {}),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedDuration: Duration(seconds: json['estimatedDurationSeconds'] ?? 0),
      instructions: List<String>.from(json['instructions'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'waypoints': waypoints.map((point) => point.toJson()).toList(),
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'distance': distance,
      'estimatedDurationSeconds': estimatedDuration.inSeconds,
      'instructions': instructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LocationTracking {
  final String id;
  final String entityId; // Could be delivery partner, order, etc.
  final String entityType; // 'delivery_partner', 'order', etc.
  final LocationData location;
  final double speed; // km/h
  final double heading; // degrees
  final String status; // 'moving', 'stopped', 'idle'
  final DateTime timestamp;

  LocationTracking({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.location,
    required this.speed,
    required this.heading,
    required this.status,
    required this.timestamp,
  });

  factory LocationTracking.fromJson(String id, Map<String, dynamic> json) {
    return LocationTracking(
      id: id,
      entityId: json['entityId'] ?? '',
      entityType: json['entityType'] ?? '',
      location: LocationData.fromJson(json['location'] ?? {}),
      speed: (json['speed'] ?? 0.0).toDouble(),
      heading: (json['heading'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'stopped',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'location': location.toJson(),
      'speed': speed,
      'heading': heading,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Geofence {
  final String id;
  final String name;
  final LocationData center;
  final double radius; // in meters
  final String type; // 'restaurant', 'delivery_zone', 'restricted_area'
  final bool isActive;
  final Map<String, dynamic> metadata;

  Geofence({
    required this.id,
    required this.name,
    required this.center,
    required this.radius,
    required this.type,
    this.isActive = true,
    this.metadata = const {},
  });

  factory Geofence.fromJson(String id, Map<String, dynamic> json) {
    return Geofence(
      id: id,
      name: json['name'] ?? '',
      center: LocationData.fromJson(json['center'] ?? {}),
      radius: (json['radius'] ?? 0.0).toDouble(),
      type: json['type'] ?? '',
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'center': center.toJson(),
      'radius': radius,
      'type': type,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // Check if a location is inside this geofence
  bool containsLocation(LocationData location) {
    final distance = center.distanceTo(location) * 1000; // Convert to meters
    return distance <= radius;
  }
}

class AddressSuggestion {
  final String placeId;
  final String description;
  final LocationData? location;
  final String mainText;
  final String secondaryText;

  AddressSuggestion({
    required this.placeId,
    required this.description,
    this.location,
    required this.mainText,
    required this.secondaryText,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] != null ? LocationData.fromJson(json['location']) : null,
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}