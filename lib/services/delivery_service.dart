import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/delivery_partner.dart';
import '../models/restaurant_order.dart';

class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Delivery Partner Management
  Future<void> registerDeliveryPartner(DeliveryPartner partner) async {
    await _firestore.collection('deliveryPartners').doc(partner.id).set(partner.toJson());
  }

  Future<DeliveryPartner?> getDeliveryPartner(String partnerId) async {
    final doc = await _firestore.collection('deliveryPartners').doc(partnerId).get();
    if (doc.exists) {
      return DeliveryPartner.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  Future<List<DeliveryPartner>> getAvailablePartners() async {
    final snapshot = await _firestore
        .collection('deliveryPartners')
        .where('isActive', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => DeliveryPartner.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> updatePartnerLocation(String partnerId, Location location) async {
    await _firestore.collection('deliveryPartners').doc(partnerId).update({
      'currentLocation': location.toJson(),
      'lastLocationUpdate': Timestamp.now(),
    });
  }

  Future<void> updatePartnerAvailability(String partnerId, bool isAvailable) async {
    await _firestore.collection('deliveryPartners').doc(partnerId).update({
      'isAvailable': isAvailable,
    });
  }

  // Delivery Assignment
  Future<void> assignOrderToPartner(String orderId, String partnerId, RestaurantOrder order) async {
    final assignment = DeliveryAssignment(
      id: 'assignment_${orderId}',
      orderId: orderId,
      deliveryPartnerId: partnerId,
      restaurantId: orderId.split('_')[0], // Extract from order ID
      customerId: order.customerId,
      pickupLocation: Location(latitude: 0, longitude: 0, address: 'Restaurant Address'), // TODO: Get from restaurant
      deliveryLocation: Location(latitude: 0, longitude: 0, address: order.deliveryAddress),
      assignedAt: DateTime.now(),
      earnings: order.deliveryFee * 0.7, // 70% goes to partner
    );

    await _firestore.collection('deliveryAssignments').doc(assignment.id).set(assignment.toJson());

    // Update partner availability
    await updatePartnerAvailability(partnerId, false);
  }

  Future<DeliveryAssignment?> getDeliveryAssignment(String orderId) async {
    final snapshot = await _firestore
        .collection('deliveryAssignments')
        .where('orderId', isEqualTo: orderId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return DeliveryAssignment.fromJson(doc.id, doc.data());
    }
    return null;
  }

  Future<List<DeliveryAssignment>> getPartnerAssignments(String partnerId) async {
    final snapshot = await _firestore
        .collection('deliveryAssignments')
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .orderBy('assignedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DeliveryAssignment.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateDeliveryStatus(String assignmentId, DeliveryStatus status) async {
    final updateData = {
      'status': status.name,
      'lastUpdated': Timestamp.now(),
    };

    switch (status) {
      case DeliveryStatus.pickedUp:
        updateData['pickedUpAt'] = Timestamp.now();
        break;
      case DeliveryStatus.delivered:
        updateData['deliveredAt'] = Timestamp.now();
        // Make partner available again
        final assignment = await _firestore.collection('deliveryAssignments').doc(assignmentId).get();
        if (assignment.exists) {
          final partnerId = assignment.data()!['deliveryPartnerId'];
          await updatePartnerAvailability(partnerId, true);
        }
        break;
      default:
        break;
    }

    await _firestore.collection('deliveryAssignments').doc(assignmentId).update(updateData);
  }

  // Route Optimization (Simple implementation)
  Future<List<Location>> getOptimizedRoute(Location start, Location end) async {
    // For now, return direct route. In production, integrate with Google Maps API
    return [start, end];
  }

  // Partner Statistics
  Future<Map<String, dynamic>> getPartnerStatistics(String partnerId) async {
    final assignments = await getPartnerAssignments(partnerId);

    int totalDeliveries = assignments.length;
    int completedDeliveries = assignments.where((a) => a.status == DeliveryStatus.delivered).length;
    double totalEarnings = assignments.fold(0, (sum, a) => sum + a.earnings);
    double averageRating = 4.5; // TODO: Calculate from ratings

    return {
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'totalEarnings': totalEarnings,
      'averageRating': averageRating,
      'completionRate': totalDeliveries > 0 ? completedDeliveries / totalDeliveries : 0,
    };
  }

  // Find nearest available partner
  Future<DeliveryPartner?> findNearestPartner(Location location) async {
    final partners = await getAvailablePartners();

    if (partners.isEmpty) return null;

    // Simple distance calculation (in production, use proper geolocation)
    DeliveryPartner? nearest;
    double minDistance = double.infinity;

    for (var partner in partners) {
      final distance = _calculateDistance(location, partner.currentLocation);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = partner;
      }
    }

    return nearest;
  }

  double _calculateDistance(Location loc1, Location loc2) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // km
    final lat1Rad = loc1.latitude * (math.pi / 180);
    final lat2Rad = loc2.latitude * (math.pi / 180);
    final deltaLatRad = (loc2.latitude - loc1.latitude) * (math.pi / 180);
    final deltaLngRad = (loc2.longitude - loc1.longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}