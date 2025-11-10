import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/qr_delivery.dart';


class QRDeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generate QR code for contactless delivery
  Future<QRCodeDelivery> generateContactlessDeliveryQR({
    required String orderId,
    required String customerId,
    required String deliveryPersonId,
    required ContactlessDeliveryRequest request,
    int expirationMinutes = 60,
  }) async {
    try {
      // Generate unique verification token
      final verificationToken = _generateVerificationToken();
      
      // Create QR code data
      final qrData = {
        'type': 'contactless_delivery',
        'orderId': orderId,
        'customerId': customerId,
        'deliveryPersonId': deliveryPersonId,
        'token': verificationToken,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      
      final qrCodeData = base64Encode(utf8.encode(json.encode(qrData)));
      
      // Create delivery contact info
      final contactInfo = DeliveryContactInfo(
        customerName: request.customerId, // This would be fetched from user data
        customerPhone: 'customer_phone', // This would be fetched from user data
        deliveryInstructions: request.dropOffInstructions,
        dropOffLocation: request.dropOffLocation,
        leaveAtDoor: request.leaveAtDoor,
        specialNotes: request.specialNotes,
        safetyRequirements: request.safetyMeasures,
      );
      
      // Create QR code delivery object
      final qrDelivery = QRCodeDelivery(
        id: 'qr_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        deliveryPersonId: deliveryPersonId,
        customerId: customerId,
        codeType: QRCodeType.orderDelivery,
        qrCodeData: qrCodeData,
        status: QRCodeStatus.generated,
        contactInfo: contactInfo,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: expirationMinutes)),
        deliveryMetadata: {
          'contactless': request.contactlessDelivery,
          'verificationMethod': request.verificationMethod,
          'safetyProtocols': request.safetyMeasures,
          'dropOffType': request.leaveAtDoor ? 'doorstep' : 'direct_handoff',
        },
        scanHistory: [],
        isContactless: request.contactlessDelivery,
        verificationToken: verificationToken,
        scanCount: 0,
        maxScanCount: 3, // Allow 3 scans for verification
      );
      
      // Save to Firestore
      await _firestore.collection('qrDeliveries').doc(qrDelivery.id).set(
        qrDelivery.toJson(),
      );
      
      // Update order with QR delivery info
      await _firestore.collection('orders').doc(orderId).update({
        'qrDeliveryId': qrDelivery.id,
        'contactlessDelivery': true,
        'qrGeneratedAt': DateTime.now().millisecondsSinceEpoch,
        'deliveryInstructions': request.dropOffInstructions,
        'safetyMeasures': request.safetyMeasures,
      });
      
      return qrDelivery;
    } catch (e) {
      debugPrint('Error generating QR delivery: $e');
      rethrow;
    }
  }

  // Scan and verify QR code
  Future<QRCodeDelivery?> scanQRCode({
    required String qrCodeData,
    required String scannedBy,
    required String scannedByRole,
    String? location,
    String? deviceInfo,
  }) async {
    try {
      // Decode QR code data
      final decodedData = utf8.decode(base64Decode(qrCodeData));
      final qrData = json.decode(decodedData) as Map<String, dynamic>;
      
      // Verify QR code structure
      if (!_isValidQRCodeStructure(qrData)) {
        return null;
      }
      
      // Get QR delivery record
      final orderId = qrData['orderId'] as String;
      final deliveryDoc = await _firestore
          .collection('qrDeliveries')
          .where('orderId', isEqualTo: orderId)
          .where('status', whereIn: [QRCodeStatus.active.toString().split('.').last, QRCodeStatus.generated.toString().split('.').last])
          .limit(1)
          .get();
      
      if (deliveryDoc.docs.isEmpty) {
        debugPrint('QR code not found or invalid for order: $orderId');
        return null;
      }
      
      final qrDelivery = QRCodeDelivery.fromJson(
        deliveryDoc.docs.first.id,
        deliveryDoc.docs.first.data() as Map<String, dynamic>,
      );
      
      // Verify token
      if (qrDelivery.verificationToken != qrData['token']) {
        debugPrint('QR code verification token mismatch');
        return null;
      }
      
      // Check if QR code is still valid
      if (!qrDelivery.canBeUsed()) {
        debugPrint('QR code is no longer valid or expired');
        return null;
      }
      
      // Create scan event
      final scanEvent = QRCodeScanEvent(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        scannedBy: scannedBy,
        scannedByRole: scannedByRole,
        scannedAt: DateTime.now(),
        location: location,
        deviceInfo: deviceInfo,
        isSuccessful: true,
      );
      
      // Update QR delivery with scan event
      var updatedDelivery = qrDelivery.addScanEvent(scanEvent);
      
      // If this is the delivery person scanning, mark as active
      if (scannedByRole == 'delivery_person' && qrDelivery.status == QRCodeStatus.generated) {
        updatedDelivery = updatedDelivery.copyWith(status: QRCodeStatus.active);
      }
      
      // If customer scans and it's contactless, mark as used
      if (scannedByRole == 'customer' && qrDelivery.isContactless) {
        final finalDelivery = updatedDelivery.markAsUsed(scannedBy);
        
        // Update order status to delivered
        await _updateOrderDeliveryStatus(orderId, finalDelivery);
        
        return finalDelivery;
      }
      
      // Update in Firestore
      await _firestore.collection('qrDeliveries').doc(qrDelivery.id).set(
        updatedDelivery.toJson(),
      );
      
      return updatedDelivery;
    } catch (e) {
      debugPrint('Error scanning QR code: $e');
      return null;
    }
  }

  // Confirm delivery completion
  Future<bool> confirmDeliveryCompletion({
    required String qrDeliveryId,
    required String confirmedBy,
    required String confirmationType, // 'customer', 'auto', 'delivery_person'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final qrDoc = await _firestore.collection('qrDeliveries').doc(qrDeliveryId).get();
      
      if (!qrDoc.exists) {
        return false;
      }
      
      final qrDelivery = QRCodeDelivery.fromJson(qrDeliveryId, qrDoc.data()! as Map<String, dynamic>);
      
      if (!qrDelivery.canBeUsed()) {
        return false;
      }
      
      // Mark as used
      final completedDelivery = qrDelivery.markAsUsed(confirmedBy);
      
      // Add completion data
      final deliveryData = completedDelivery.getDeliveryCompletionData();
      if (additionalData != null) {
        deliveryData.addAll(additionalData);
      }
      
      // Update in Firestore
      await _firestore.collection('qrDeliveries').doc(qrDeliveryId).set(
        completedDelivery.toJson(),
      );
      
      // Update order status
      await _updateOrderDeliveryStatus(qrDelivery.orderId, completedDelivery);
      
      // Log delivery completion
      await _logDeliveryCompletion(qrDelivery, confirmedBy, confirmationType, deliveryData);
      
      return true;
    } catch (e) {
      debugPrint('Error confirming delivery completion: $e');
      return false;
    }
  }

  // Get QR delivery status
  Future<QRCodeDelivery?> getQRDeliveryStatus(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('qrDeliveries')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      return QRCodeDelivery.fromJson(
        snapshot.docs.first.id,
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Error getting QR delivery status: $e');
      return null;
    }
  }

  // Get delivery safety protocols
  Future<List<DeliverySafetyProtocol>> getSafetyProtocols() async {
    try {
      final snapshot = await _firestore
          .collection('deliverySafetyProtocols')
          .where('isActive', isEqualTo: true)
          .orderBy('orderPriority', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        return DeliverySafetyProtocol.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getting safety protocols: $e');
      return [];
    }
  }

  // Generate pickup QR code for restaurant
  Future<QRCodeDelivery> generatePickupQR({
    required String orderId,
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      final verificationToken = _generateVerificationToken();
      
      final qrData = {
        'type': 'pickup_verification',
        'orderId': orderId,
        'restaurantId': restaurantId,
        'customerId': customerId,
        'token': verificationToken,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final qrCodeData = base64Encode(utf8.encode(json.encode(qrData)));
      
      final contactInfo = DeliveryContactInfo(
        customerName: customerId,
        customerPhone: 'customer_phone',
        deliveryInstructions: 'Pickup verification',
        dropOffLocation: 'Restaurant pickup counter',
        leaveAtDoor: false,
        safetyRequirements: [],
      );
      
      final qrDelivery = QRCodeDelivery(
        id: 'pickup_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        deliveryPersonId: restaurantId,
        customerId: customerId,
        codeType: QRCodeType.pickupVerification,
        qrCodeData: qrCodeData,
        status: QRCodeStatus.generated,
        contactInfo: contactInfo,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        deliveryMetadata: {
          'type': 'pickup',
          'location': 'restaurant',
        },
        scanHistory: [],
        isContactless: false,
        verificationToken: verificationToken,
        scanCount: 0,
        maxScanCount: 2,
      );
      
      await _firestore.collection('qrDeliveries').doc(qrDelivery.id).set(
        qrDelivery.toJson(),
      );
      
      return qrDelivery;
    } catch (e) {
      debugPrint('Error generating pickup QR: $e');
      rethrow;
    }
  }

  // Validate QR code without updating status
  Future<bool> validateQRCode(String qrCodeData) async {
    try {
      final decodedData = utf8.decode(base64Decode(qrCodeData));
      final qrData = json.decode(decodedData) as Map<String, dynamic>;
      
      return _isValidQRCodeStructure(qrData);
    } catch (e) {
      debugPrint('Error validating QR code: $e');
      return false;
    }
  }

  // Get delivery analytics
  Future<Map<String, dynamic>> getDeliveryAnalytics({
    String? deliveryPersonId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('qrDeliveries');
      
      if (deliveryPersonId != null) {
        query = query.where('deliveryPersonId', isEqualTo: deliveryPersonId);
      }
      
      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      
      if (startDate != null && endDate != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      final deliveries = snapshot.docs.map((doc) {
        return QRCodeDelivery.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      final analytics = {
        'totalDeliveries': deliveries.length,
        'successfulDeliveries': deliveries.where((d) => d.status == QRCodeStatus.used).length,
        'failedDeliveries': deliveries.where((d) => d.status == QRCodeStatus.expired).length,
        'contactlessDeliveries': deliveries.where((d) => d.isContactless).length,
        'averageDeliveryTime': _calculateAverageDeliveryTime(deliveries),
        'scanCountDistribution': _getScanCountDistribution(deliveries),
        'popularDropOffLocations': _getPopularDropOffLocations(deliveries),
        'safetyProtocolCompliance': _getSafetyProtocolCompliance(deliveries),
      };
      
      return analytics;
    } catch (e) {
      debugPrint('Error getting delivery analytics: $e');
      return {};
    }
  }

  // Private helper methods
  String _generateVerificationToken() {
    final bytes = utf8.encode('${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000000)}');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  bool _isValidQRCodeStructure(Map<String, dynamic> qrData) {
    final requiredFields = ['type', 'orderId', 'token', 'timestamp'];
    
    for (final field in requiredFields) {
      if (!qrData.containsKey(field)) {
        return false;
      }
    }
    
    // Validate QR code type
    final validTypes = ['contactless_delivery', 'pickup_verification', 'feedback'];
    if (!validTypes.contains(qrData['type'])) {
      return false;
    }
    
    return true;
  }

  Future<void> _updateOrderDeliveryStatus(String orderId, QRCodeDelivery qrDelivery) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Delivered',
        'deliveredAt': DateTime.now().millisecondsSinceEpoch,
        'deliveryPersonId': qrDelivery.deliveryPersonId,
        'deliveryMethod': qrDelivery.isContactless ? 'contactless' : 'direct',
        'deliveryLocation': qrDelivery.contactInfo.dropOffLocation,
        'qrDeliveryId': qrDelivery.id,
      });
      
      // Send notification to customer
      await _sendDeliveryNotification(orderId, qrDelivery.customerId, 'delivered');
    } catch (e) {
      debugPrint('Error updating order delivery status: $e');
    }
  }

  Future<void> _logDeliveryCompletion(
    QRCodeDelivery qrDelivery,
    String confirmedBy,
    String confirmationType,
    Map<String, dynamic> deliveryData,
  ) async {
    try {
      final logEntry = {
        'qrDeliveryId': qrDelivery.id,
        'orderId': qrDelivery.orderId,
        'confirmedBy': confirmedBy,
        'confirmationType': confirmationType,
        'deliveryData': deliveryData,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'scanCount': qrDelivery.scanCount,
        'contactless': qrDelivery.isContactless,
      };
      
      await _firestore.collection('deliveryCompletionLogs').add(logEntry);
    } catch (e) {
      debugPrint('Error logging delivery completion: $e');
    }
  }

  Future<void> _sendDeliveryNotification(String orderId, String customerId, String status) async {
    try {
      final notification = {
        'userId': customerId,
        'type': 'delivery_update',
        'title': 'Order Delivered',
        'message': 'Your order has been successfully delivered',
        'data': {'orderId': orderId, 'status': status},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _firestore.collection('notifications').add(notification);
    } catch (e) {
      debugPrint('Error sending delivery notification: $e');
    }
  }

  double _calculateAverageDeliveryTime(List<QRCodeDelivery> deliveries) {
    final successfulDeliveries = deliveries.where((d) => d.usedAt != null).toList();
    
    if (successfulDeliveries.isEmpty) return 0.0;
    
    final totalTime = successfulDeliveries.fold<int>(0, (total, delivery) {
      final deliveryTime = delivery.usedAt!.difference(delivery.createdAt).inMinutes;
      return total + deliveryTime;
    });
    
    return totalTime / successfulDeliveries.length;
  }

  Map<String, int> _getScanCountDistribution(List<QRCodeDelivery> deliveries) {
    final distribution = <String, int>{};
    
    for (final delivery in deliveries) {
      final scanCount = delivery.scanCount;
      final countKey = scanCount == 0 ? '0' : 
                      scanCount == 1 ? '1' : 
                      scanCount == 2 ? '2' : '3+';
      
      distribution[countKey] = (distribution[countKey] ?? 0) + 1;
    }
    
    return distribution;
  }

  Map<String, int> _getPopularDropOffLocations(List<QRCodeDelivery> deliveries) {
    final locations = <String, int>{};
    
    for (final delivery in deliveries) {
      final location = delivery.contactInfo.dropOffLocation;
      locations[location] = (locations[location] ?? 0) + 1;
    }
    
    final sortedEntries = locations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(5));
  }

  Map<String, double> _getSafetyProtocolCompliance(List<QRCodeDelivery> deliveries) {
    final contactlessDeliveries = deliveries.where((d) => d.isContactless).toList();
    final totalDeliveries = deliveries.length;
    
    if (totalDeliveries == 0) return {'contactlessRate': 0.0};
    
    return {
      'contactlessRate': contactlessDeliveries.length / totalDeliveries,
      'averageScans': deliveries.fold<double>(0, (total, d) => total + d.scanCount) / totalDeliveries,
      'successRate': deliveries.where((d) => d.status == QRCodeStatus.used).length / totalDeliveries,
    };
  }

  // Cleanup expired QR codes
  Future<void> cleanupExpiredQRCodes() async {
    try {
      final now = DateTime.now();
      final expiredSnapshot = await _firestore
          .collection('qrDeliveries')
          .where('status', whereIn: [QRCodeStatus.active.toString().split('.').last, QRCodeStatus.generated.toString().split('.').last])
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in expiredSnapshot.docs) {
        batch.update(doc.reference, {
          'status': QRCodeStatus.expired.toString().split('.').last,
        });
      }
      
      await batch.commit();
      
      debugPrint('Cleaned up ${expiredSnapshot.docs.length} expired QR codes');
    } catch (e) {
      debugPrint('Error cleaning up expired QR codes: $e');
    }
  }
}