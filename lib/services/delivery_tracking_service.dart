import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/delivery_tracking.dart';
import '../models/order.dart' as app_order;

// Mock location classes for demonstration
class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final double headingAccuracy;
  final DateTime timestamp;
  final bool isMocked;

  Position({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.speedAccuracy,
    required this.heading,
    required this.headingAccuracy,
    required this.timestamp,
    required this.isMocked,
  });
}

enum LocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
}

enum LocationAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
  bestForNavigation,
}

class Geolocator {
  static Future<bool> isLocationServiceEnabled() async {
    return true; // Mock implementation
  }

  static Future<LocationPermission> checkPermission() async {
    return LocationPermission.always; // Mock implementation
  }

  static Future<LocationPermission> requestPermission() async {
    return LocationPermission.always; // Mock implementation
  }

  static Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    bool forceAndroidLocationManager = false,
    Duration timeLimit = const Duration(seconds: 5),
  }) async {
    // Mock implementation with realistic coordinates
    return Position(
      latitude: 40.7128,
      longitude: -74.0060,
      accuracy: 10.0,
      altitude: 10.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      timestamp: DateTime.now(),
      isMocked: true,
    );
  }
}

class DeliveryTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start tracking for a new order
  Future<void> startOrderTracking({
    required String orderId,
    required String deliveryPartnerId,
    required String customerId,
    required LocationData restaurantLocation,
    required LocationData deliveryAddress,
    required String deliveryPartnerName,
    required String deliveryPartnerPhone,
  }) async {
    try {
      final tracking = DeliveryTracking(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        customerId: customerId,
        currentLocation: restaurantLocation, // Start at restaurant
        restaurantLocation: restaurantLocation,
        deliveryAddress: deliveryAddress,
        orderStatus: OrderStatus.confirmed,
        lastUpdated: DateTime.now(),
        estimatedArrival: _calculateEstimatedArrival(
          restaurantLocation,
          deliveryAddress,
        ),
        trackingHistory: [
          TrackingUpdate(
            status: 'confirmed',
            description: 'Order confirmed by restaurant',
            timestamp: DateTime.now(),
            location: restaurantLocation,
            updatedBy: 'system',
          ),
        ],
        deliveryPartnerName: deliveryPartnerName,
        deliveryPartnerPhone: deliveryPartnerPhone,
        vehicleInfo: 'Standard Delivery Vehicle',
        distanceRemaining: _calculateDistance(
          restaurantLocation,
          deliveryAddress,
        ),
        deliveryTimeSeconds: _calculateDeliveryTimeSeconds(
          restaurantLocation,
          deliveryAddress,
        ),
      );

      await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .set(tracking.toJson());

      debugPrint('Started tracking for order: $orderId');
    } catch (e) {
      debugPrint('Error starting order tracking: $e');
      rethrow;
    }
  }

  // Update delivery partner's current location
  Future<void> updateDeliveryLocation({
    required String orderId,
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
  }) async {
    try {
      final trackingDoc = await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .get();

      if (!trackingDoc.exists) {
        throw Exception('Tracking document not found for order: $orderId');
      }

      final currentTracking = DeliveryTracking.fromJson(trackingDoc.data()!);
      final newLocation = LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        placeName: placeName,
        timestamp: DateTime.now(),
      );

      // Calculate new distance and time
      final newDistance = _calculateDistance(
        newLocation,
        currentTracking.deliveryAddress,
      );
      final newTimeSeconds = _calculateDeliveryTimeSeconds(
        newLocation,
        currentTracking.deliveryAddress,
      );
      final estimatedArrival = _formatEstimatedArrival(
        DateTime.now().add(Duration(seconds: newTimeSeconds)),
      );

      // Determine order status based on distance
      final newStatus = _determineOrderStatus(newDistance);

      // Add tracking update to history
      final updatedHistory = List<TrackingUpdate>.from(currentTracking.trackingHistory);
      if (newStatus != currentTracking.orderStatus) {
        updatedHistory.add(TrackingUpdate(
          status: newStatus.toString(),
          description: newStatus.description,
          timestamp: DateTime.now(),
          location: newLocation,
          updatedBy: 'delivery_partner',
        ));
      }

      final updatedTracking = currentTracking.copyWith(
        currentLocation: newLocation,
        orderStatus: newStatus,
        lastUpdated: DateTime.now(),
        estimatedArrival: estimatedArrival,
        distanceRemaining: newDistance,
        deliveryTimeSeconds: newTimeSeconds,
        trackingHistory: updatedHistory,
      );

      await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .set(updatedTracking.toJson());

      debugPrint('Updated location for order: $orderId');
    } catch (e) {
      debugPrint('Error updating delivery location: $e');
      rethrow;
    }
  }

  // Get real-time tracking data for an order
  Stream<DeliveryTracking> getOrderTracking(String orderId) {
    return _firestore
        .collection('deliveryTracking')
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return DeliveryTracking.fromJson(doc.data()!);
          } else {
            throw Exception('Tracking document not found');
          }
        });
  }

  // Get all active tracking for a customer
  Stream<List<DeliveryTracking>> getCustomerActiveOrders(String customerId) {
    return _firestore
        .collection('deliveryTracking')
        .where('customerId', isEqualTo: customerId)
        .where('orderStatus', whereIn: [
          OrderStatus.confirmed.toString(),
          OrderStatus.preparing.toString(),
          OrderStatus.ready.toString(),
          OrderStatus.pickedUp.toString(),
          OrderStatus.outForDelivery.toString(),
          OrderStatus.arriving.toString(),
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryTracking.fromJson(doc.data()))
            .toList());
  }

  // Update order status manually (for restaurant updates)
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? description,
  }) async {
    try {
      final trackingDoc = await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .get();

      if (!trackingDoc.exists) {
        throw Exception('Tracking document not found for order: $orderId');
      }

      final currentTracking = DeliveryTracking.fromJson(trackingDoc.data()!);

      // Add status update to history
      final updatedHistory = List<TrackingUpdate>.from(currentTracking.trackingHistory);
      updatedHistory.add(TrackingUpdate(
        status: newStatus.toString(),
        description: description ?? newStatus.description,
        timestamp: DateTime.now(),
        updatedBy: 'restaurant',
      ));

      final updatedTracking = currentTracking.copyWith(
        orderStatus: newStatus,
        lastUpdated: DateTime.now(),
        trackingHistory: updatedHistory,
      );

      await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .set(updatedTracking.toJson());

      debugPrint('Updated order status for order: $orderId to $newStatus');
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  // Complete delivery
  Future<void> completeDelivery({
    required String orderId,
    LocationData? deliveryLocation,
  }) async {
    try {
      final trackingDoc = await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .get();

      if (!trackingDoc.exists) {
        throw Exception('Tracking document not found for order: $orderId');
      }

      final currentTracking = DeliveryTracking.fromJson(trackingDoc.data()!);
      final finalLocation = deliveryLocation ?? currentTracking.currentLocation;

      // Add delivery completion to history
      final updatedHistory = List<TrackingUpdate>.from(currentTracking.trackingHistory);
      updatedHistory.add(TrackingUpdate(
        status: 'delivered',
        description: 'Order delivered successfully',
        timestamp: DateTime.now(),
        location: finalLocation,
        updatedBy: 'delivery_partner',
      ));

      final updatedTracking = currentTracking.copyWith(
        orderStatus: OrderStatus.delivered,
        currentLocation: finalLocation,
        lastUpdated: DateTime.now(),
        estimatedArrival: 'Delivered',
        distanceRemaining: 0.0,
        deliveryTimeSeconds: 0,
        trackingHistory: updatedHistory,
      );

      await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .set(updatedTracking.toJson());

      debugPrint('Completed delivery for order: $orderId');
    } catch (e) {
      debugPrint('Error completing delivery: $e');
      rethrow;
    }
  }

  // Calculate distance between two locations (Haversine formula)
  double _calculateDistance(LocationData from, LocationData to) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double latDistance = _toRadians(to.latitude - from.latitude);
    double lonDistance = _toRadians(to.longitude - from.longitude);

    double a = math.sin(latDistance / 2) * math.sin(latDistance / 2) +
        math.cos(_toRadians(from.latitude)) * math.cos(_toRadians(to.latitude)) *
        math.sin(lonDistance / 2) * math.sin(lonDistance / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Calculate estimated arrival time
  String _calculateEstimatedArrival(LocationData from, LocationData to) {
    final distanceKm = _calculateDistance(from, to);
    final timeSeconds = _calculateDeliveryTimeSeconds(from, to);
    final arrivalTime = DateTime.now().add(Duration(seconds: timeSeconds));
    
    return _formatEstimatedArrival(arrivalTime);
  }

  String _formatEstimatedArrival(DateTime arrivalTime) {
    final now = DateTime.now();
    final difference = arrivalTime.difference(now);

    if (difference.inMinutes < 1) {
      return 'Less than 1 minute';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }

  // Calculate delivery time in seconds
  int _calculateDeliveryTimeSeconds(LocationData from, LocationData to) {
    final distanceKm = _calculateDistance(from, to);
    
    // Assume average delivery speed of 25 km/h in city traffic
    // Add base time for pickup and drop-off procedures
    const double averageSpeedKmh = 25.0;
    const int baseTimeSeconds = 300; // 5 minutes base time

    final travelTimeSeconds = (distanceKm / averageSpeedKmh * 3600).round();
    return travelTimeSeconds + baseTimeSeconds;
  }

  // Determine order status based on distance
  OrderStatus _determineOrderStatus(double distanceKm) {
    if (distanceKm < 0.1) {
      return OrderStatus.arriving; // Less than 100 meters
    } else if (distanceKm < 2.0) {
      return OrderStatus.outForDelivery; // Less than 2 km
    } else {
      return OrderStatus.outForDelivery;
    }
  }

  // Get current location (for delivery partners)
  Future<Position> getCurrentLocation() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Check if delivery is close to customer
  bool isDeliveryClose(LocationData deliveryLocation, LocationData customerLocation, {double thresholdKm = 0.2}) {
    final distance = _calculateDistance(deliveryLocation, customerLocation);
    return distance <= thresholdKm;
  }

  // Get tracking analytics for an order
  Future<Map<String, dynamic>> getOrderAnalytics(String orderId) async {
    try {
      final trackingDoc = await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .get();

      if (!trackingDoc.exists) {
        throw Exception('Tracking document not found');
      }

      final tracking = DeliveryTracking.fromJson(trackingDoc.data()!);
      final now = DateTime.now();
      final orderTime = tracking.trackingHistory.isNotEmpty
          ? tracking.trackingHistory.first.timestamp
          : tracking.lastUpdated;
      
      final totalTime = now.difference(orderTime).inMinutes;
      final estimatedTime = tracking.deliveryTimeSeconds ~/ 60;
      final distanceTravelled = _calculateDistance(
        tracking.restaurantLocation,
        tracking.currentLocation,
      );

      return {
        'totalTimeMinutes': totalTime,
        'estimatedTimeMinutes': estimatedTime,
        'distanceTravelledKm': distanceTravelled,
        'distanceRemainingKm': tracking.distanceRemaining,
        'progressPercentage': tracking.restaurantLocation == tracking.currentLocation
            ? 0.0
            : (distanceTravelled / (distanceTravelled + tracking.distanceRemaining) * 100),
        'averageSpeedKmh': totalTime > 0 ? (distanceTravelled / (totalTime / 60)) : 0.0,
        'statusUpdates': tracking.trackingHistory.length,
      };
    } catch (e) {
      debugPrint('Error getting order analytics: $e');
      rethrow;
    }
  }

  // Simulate delivery movement (for demo purposes)
  Future<void> simulateDeliveryMovement(String orderId) async {
    try {
      final trackingDoc = await _firestore
          .collection('deliveryTracking')
          .doc(orderId)
          .get();

      if (!trackingDoc.exists) {
        throw Exception('Tracking document not found for order: $orderId');
      }

      final currentTracking = DeliveryTracking.fromJson(trackingDoc.data()!);
      
      // Simulate movement towards delivery address
      final currentLat = currentTracking.currentLocation.latitude;
      final currentLng = currentTracking.currentLocation.longitude;
      final targetLat = currentTracking.deliveryAddress.latitude;
      final targetLng = currentTracking.deliveryAddress.longitude;

      // Move 5% closer to target
      final newLat = currentLat + (targetLat - currentLat) * 0.05;
      final newLng = currentLng + (targetLng - currentLng) * 0.05;

      await updateDeliveryLocation(
        orderId: orderId,
        latitude: newLat,
        longitude: newLng,
        address: 'Moving towards destination',
      );

      debugPrint('Simulated delivery movement for order: $orderId');
    } catch (e) {
      debugPrint('Error simulating delivery movement: $e');
      rethrow;
    }
  }
}