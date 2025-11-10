import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/scheduled_delivery.dart';

class ScheduledDeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a scheduled delivery order
  Future<Map<String, dynamic>> createScheduledOrder({
    required String userId,
    required String restaurantId,
    required List<String> items,
    required double totalAmount,
    required DateTime scheduledDateTime,
    required ScheduleType type,
    required OrderPriority priority,
    String? deliveryAddress,
    String? specialInstructions,
    String? recurringPatternId,
    String? assignedTimeSlotId,
  }) async {
    try {
      // Validate scheduling requirements
      final validation = await _validateScheduling(
        restaurantId: restaurantId,
        scheduledDateTime: scheduledDateTime,
        totalAmount: totalAmount,
        type: type,
        priority: priority,
      );
      
      if (!validation['isValid']) {
        return {
          'success': false,
          'error': validation['error'],
        };
      }

      // Get or create time slot
      TimeSlot? assignedTimeSlot;
      if (assignedTimeSlotId != null) {
        assignedTimeSlot = await _getTimeSlot(assignedTimeSlotId);
        if (assignedTimeSlot == null) {
          return {
            'success': false,
            'error': 'Selected time slot is not available',
          };
        }
      }

      // Calculate delivery fees
      final deliveryFee = _calculateDeliveryFee(deliveryAddress, type, priority);
      final rushFee = _calculateRushFee(type, priority);

      // Estimate preparation time
      final estimatedPrepTime = await _estimatePreparationTime(restaurantId, items);

      // Create the scheduled order
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final scheduledOrder = ScheduledDeliveryOrder(
        id: orderId,
        userId: userId,
        restaurantId: restaurantId,
        orderId: orderId,
        type: type,
        scheduledDateTime: scheduledDateTime,
        createdAt: DateTime.now(),
        status: DeliveryStatus.pending,
        priority: priority,
        items: items,
        totalAmount: totalAmount,
        deliveryAddress: deliveryAddress,
        specialInstructions: specialInstructions,
        deliveryFee: deliveryFee,
        rushFee: rushFee,
        metadata: {
          'source': 'scheduled_delivery',
          'rushOrder': type == ScheduleType.rush || priority == OrderPriority.urgent,
          'estimatedPrepTime': estimatedPrepTime,
        },
        recurringPatternId: recurringPatternId,
        estimatedPrepTime: estimatedPrepTime,
        assignedTimeSlot: assignedTimeSlot,
        confirmationCode: '',
        isRecurringActive: recurringPatternId != null,
      );

      // Save the order
      await _firestore
          .collection('scheduledDeliveryOrders')
          .doc(orderId)
          .set(scheduledOrder.toJson());

      // Update time slot if assigned
      if (assignedTimeSlot != null) {
        await _updateTimeSlotAvailability(assignedTimeSlotId!, 1);
      }

      // Create recurring pattern entry if needed
      if (recurringPatternId != null) {
        await _createRecurringOrderEntry(scheduledOrder);
      }

      // Send confirmation notification
      await _sendSchedulingConfirmation(scheduledOrder);

      return {
        'success': true,
        'orderId': orderId,
        'confirmationCode': scheduledOrder.generateConfirmationCode(),
        'estimatedPrepTime': estimatedPrepTime,
        'deliveryFee': deliveryFee + rushFee,
        'scheduledTime': scheduledDateTime,
      };
    } catch (e) {
      debugPrint('Error creating scheduled order: $e');
      return {
        'success': false,
        'error': 'Failed to create scheduled order: $e',
      };
    }
  }

  // Get available time slots for a restaurant and date
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String restaurantId,
    required DateTime date,
    int? orderCount,
  }) async {
    try {
      final operatingHours = await _getRestaurantOperatingHours(restaurantId);
      if (operatingHours == null) {
        return [];
      }

      final availableSlots = operatingHours.getAvailableTimeSlots(date);
      final now = DateTime.now();

      // Filter out past time slots
      final validSlots = availableSlots.where((slot) {
        if (date.day != now.day || date.month != now.month || date.year != now.year) {
          return true; // Future date, all slots are valid
        }

        final slotStart = DateTime.parse('1970-01-01 ${slot.startTime}');
        final currentTime = DateTime.parse('1970-01-01 ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00');
        
        return slotStart.isAfter(currentTime.add(operatingHours.minimumAdvanceTime));
      }).toList();

      return validSlots.where((slot) {
        final requiredCount = orderCount ?? 1;
        return slot.isAvailableForOrder(requiredCount);
      }).toList();
    } catch (e) {
      debugPrint('Error getting available time slots: $e');
      return [];
    }
  }

  // Create a recurring delivery pattern
  Future<Map<String, dynamic>> createRecurringPattern({
    required String userId,
    required String name,
    required String description,
    required RecurringPattern pattern,
    required List<int> customDays,
    required TimeOfDay deliveryTime,
    required List<String> restaurantIds,
    required List<String> itemPreferences,
    required DateTime startDate,
    DateTime? endDate,
    Map<String, dynamic>? preferences,
    int maxExecutions = -1,
  }) async {
    try {
      // Validate pattern
      if (!_isValidRecurringPattern(pattern, customDays)) {
        return {
          'success': false,
          'error': 'Invalid recurring pattern configuration',
        };
      }

      final patternId = DateTime.now().millisecondsSinceEpoch.toString();
      final recurringPattern = RecurringDeliveryPattern(
        id: patternId,
        userId: userId,
        name: name,
        description: description,
        pattern: pattern,
        customDays: customDays,
        deliveryTime: deliveryTime,
        restaurantIds: restaurantIds,
        itemPreferences: itemPreferences,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        preferences: preferences ?? {},
        lastExecuted: startDate.subtract(Duration(days: 1)),
        executionCount: 0,
        maxExecutions: maxExecutions,
        createdAt: DateTime.now(),
        metadata: {
          'createdBy': 'user',
          'autoGenerate': false,
        },
      );

      await _firestore
          .collection('recurringDeliveryPatterns')
          .doc(patternId)
          .set(recurringPattern.toJson());

      return {
        'success': true,
        'patternId': patternId,
        'nextExecution': recurringPattern.getNextExecutionDate(DateTime.now()),
        'message': 'Recurring delivery pattern created successfully',
      };
    } catch (e) {
      debugPrint('Error creating recurring pattern: $e');
      return {
        'success': false,
        'error': 'Failed to create recurring pattern: $e',
      };
    }
  }

  // Update scheduled order
  Future<Map<String, dynamic>> updateScheduledOrder({
    required String orderId,
    String? newDateTime,
    String? newAddress,
    String? newInstructions,
    OrderPriority? newPriority,
  }) async {
    try {
      final order = await getScheduledOrder(orderId);
      if (order == null) {
        return {
          'success': false,
          'error': 'Scheduled order not found',
        };
      }

      if (!order.canBeRescheduled) {
        return {
          'success': false,
          'error': 'Order cannot be updated at this stage',
        };
      }

      final updates = <String, dynamic>{};
      
      if (newDateTime != null) {
        final newDate = DateTime.parse(newDateTime);
        
        // Validate new scheduling time
        final validation = await _validateScheduling(
          restaurantId: order.restaurantId,
          scheduledDateTime: newDate,
          totalAmount: order.totalAmount,
          type: order.type,
          priority: newPriority ?? order.priority,
          excludeOrderId: orderId,
        );
        
        if (!validation['isValid']) {
          return {
            'success': false,
            'error': validation['error'],
          };
        }
        
        updates['scheduledDateTime'] = newDate.millisecondsSinceEpoch;
        updates['rescheduledAt'] = DateTime.now().millisecondsSinceEpoch;
        updates['previousDateTime'] = order.scheduledDateTime.millisecondsSinceEpoch;
      }
      
      if (newAddress != null) {
        updates['deliveryAddress'] = newAddress;
      }
      
      if (newInstructions != null) {
        updates['specialInstructions'] = newInstructions;
      }
      
      if (newPriority != null) {
        updates['priority'] = newPriority.name;
        // Recalculate rush fee if priority changes
        if (newPriority != order.priority) {
          final newRushFee = _calculateRushFee(order.type, newPriority);
          updates['rushFee'] = newRushFee;
        }
      }

      await _firestore
          .collection('scheduledDeliveryOrders')
          .doc(orderId)
          .update(updates);

      // Send update notification
      await _sendOrderUpdateNotification(order);

      return {
        'success': true,
        'message': 'Scheduled order updated successfully',
        'updatedFields': updates.keys.toList(),
      };
    } catch (e) {
      debugPrint('Error updating scheduled order: $e');
      return {
        'success': false,
        'error': 'Failed to update scheduled order: $e',
      };
    }
  }

  // Cancel scheduled order
  Future<Map<String, dynamic>> cancelScheduledOrder({
    required String orderId,
    required String userId,
    String? reason,
  }) async {
    try {
      final order = await getScheduledOrder(orderId);
      if (order == null) {
        return {
          'success': false,
          'error': 'Scheduled order not found',
        };
      }

      if (order.userId != userId) {
        return {
          'success': false,
          'error': 'Unauthorized to cancel this order',
        };
      }

      if (!order.canBeCancelled) {
        return {
          'success': false,
          'error': 'Order cannot be cancelled at this stage',
        };
      }

      await _firestore
          .collection('scheduledDeliveryOrders')
          .doc(orderId)
          .update({
        'status': DeliveryStatus.cancelled.name,
        'cancelledAt': DateTime.now().millisecondsSinceEpoch,
        'cancellationReason': reason ?? 'User cancelled',
        'cancelledBy': userId,
      });

      // Release time slot if assigned
      if (order.assignedTimeSlot != null) {
        await _updateTimeSlotAvailability(order.assignedTimeSlot!.id, -1);
      }

      // Cancel recurring series if applicable
      if (order.recurringPatternId != null) {
        await _cancelRecurringSeries(order.recurringPatternId!, orderId);
      }

      // Process refund if applicable
      final refundAmount = await _processCancellationRefund(order);

      // Send cancellation notification
      await _sendOrderCancellationNotification(order, refundAmount);

      return {
        'success': true,
        'message': 'Scheduled order cancelled successfully',
        'refundAmount': refundAmount,
        'cancelledAt': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error cancelling scheduled order: $e');
      return {
        'success': false,
        'error': 'Failed to cancel scheduled order: $e',
      };
    }
  }

  // Process recurring deliveries
  Future<void> processRecurringDeliveries() async {
    try {
      final now = DateTime.now();
      
      // Get all active recurring patterns
      final patternsSnapshot = await _firestore
          .collection('recurringDeliveryPatterns')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in patternsSnapshot.docs) {
        final pattern = RecurringDeliveryPattern.fromJson(doc.id, doc.data());
        
        // Check if pattern should execute today
        if (pattern.shouldExecuteOn(now)) {
          await _executeRecurringDelivery(pattern);
        }
      }
    } catch (e) {
      debugPrint('Error processing recurring deliveries: $e');
    }
  }

  // Get user's scheduled orders
  Future<List<ScheduledDeliveryOrder>> getUserScheduledOrders({
    required String userId,
    int days = 30,
    DeliveryStatus? status,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: 1));
      final endDate = DateTime.now().add(Duration(days: days));

      Query query = _firestore
          .collection('scheduledDeliveryOrders')
          .where('userId', isEqualTo: userId)
          .where('scheduledDateTime', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('scheduledDateTime', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .orderBy('scheduledDateTime', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ScheduledDeliveryOrder.fromJson(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user scheduled orders: $e');
      return [];
    }
  }

  // Get restaurant's scheduled orders
  Future<List<ScheduledDeliveryOrder>> getRestaurantScheduledOrders({
    required String restaurantId,
    DateTime? date,
    DeliveryStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('scheduledDeliveryOrders')
          .where('restaurantId', isEqualTo: restaurantId);

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(Duration(days: 1));
        
        query = query
            .where('scheduledDateTime', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
            .where('scheduledDateTime', isLessThan: endOfDay.millisecondsSinceEpoch);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('scheduledDateTime', descending: false);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ScheduledDeliveryOrder.fromJson(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting restaurant scheduled orders: $e');
      return [];
    }
  }

  // Update order status
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required DeliveryStatus newStatus,
    String? notes,
    String? updatedBy,
  }) async {
    try {
      final order = await getScheduledOrder(orderId);
      if (order == null) {
        return {
          'success': false,
          'error': 'Order not found',
        };
      }

      final updates = <String, dynamic>{
        'status': newStatus.name,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus.name,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'updatedBy': updatedBy ?? 'system',
            'notes': notes ?? '',
          }
        ]),
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case DeliveryStatus.confirmed:
          updates['confirmedAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case DeliveryStatus.preparing:
          updates['preparingAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case DeliveryStatus.ready:
          updates['readyAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case DeliveryStatus.pickedup:
          updates['pickedUpAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case DeliveryStatus.delivered:
          updates['deliveredAt'] = DateTime.now().millisecondsSinceEpoch;
          // Update recurring pattern execution count
          if (order.recurringPatternId != null) {
            await _updateRecurringPatternExecution(order.recurringPatternId!);
          }
          break;
        case DeliveryStatus.failed:
          updates['failedAt'] = DateTime.now().millisecondsSinceEpoch;
          updates['failureReason'] = notes ?? 'Delivery failed';
          break;
        default:
          break;
      }

      await _firestore
          .collection('scheduledDeliveryOrders')
          .doc(orderId)
          .update(updates);

      // Send status notification
      await _sendStatusUpdateNotification(order, newStatus);

      return {
        'success': true,
        'message': 'Order status updated successfully',
        'newStatus': newStatus.name,
      };
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return {
        'success': false,
        'error': 'Failed to update order status: $e',
      };
    }
  }

  // Get available delivery zones
  Future<List<DeliveryZone>> getAvailableDeliveryZones({
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('deliveryZones')
          .where('isActive', isEqualTo: true)
          .get();

      var zones = snapshot.docs.map((doc) {
        return DeliveryZone.fromJson(doc.id, doc.data());
      }).toList();

      // Filter by location if coordinates provided
      if (userLatitude != null && userLongitude != null) {
        final userLocation = LatLng(userLatitude, userLongitude);
        zones = zones.where((zone) => zone.containsPoint(userLocation)).toList();
      }

      return zones;
    } catch (e) {
      debugPrint('Error getting delivery zones: $e');
      return [];
    }
  }

  // Private helper methods
  
  Future<Map<String, dynamic>> _validateScheduling({
    required String restaurantId,
    required DateTime scheduledDateTime,
    required double totalAmount,
    required ScheduleType type,
    required OrderPriority priority,
    String? excludeOrderId,
  }) async {
    final now = DateTime.now();
    
    // Check if scheduled time is in the future
    if (scheduledDateTime.isBefore(now)) {
      return {
        'isValid': false,
        'error': 'Scheduled time must be in the future',
      };
    }

    // Check minimum advance time
    final operatingHours = await _getRestaurantOperatingHours(restaurantId);
    if (operatingHours != null) {
      final minAdvance = operatingHours.minimumAdvanceTime;
      if (scheduledDateTime.isBefore(now.add(minAdvance))) {
        return {
          'isValid': false,
          'error': 'Minimum advance time is ${minAdvance.inHours} hours',
        };
      }

      // Check maximum advance booking
      final maxAdvance = Duration(days: operatingHours.maxAdvanceBookingDays);
      if (scheduledDateTime.isAfter(now.add(maxAdvance))) {
        return {
          'isValid': false,
          'error': 'Maximum advance booking is ${operatingHours.maxAdvanceBookingDays} days',
        };
      }

      // Check if restaurant is open at scheduled time
      if (!operatingHours.isOpenAt(scheduledDateTime)) {
        return {
          'isValid': false,
          'error': 'Restaurant is not open at the selected time',
        };
      }
    }

    // Check time slot availability
    final availableSlots = await getAvailableTimeSlots(
      restaurantId: restaurantId,
      date: scheduledDateTime,
      orderCount: 1,
    );
    
    if (availableSlots.isEmpty) {
      return {
        'isValid': false,
        'error': 'No available time slots for the selected time',
      };
    }

    // Check for conflicting orders
    if (excludeOrderId != null) {
      final conflictingOrders = await _getConflictingOrders(
        restaurantId,
        scheduledDateTime,
        excludeOrderId,
      );
      
      if (conflictingOrders.isNotEmpty) {
        return {
          'isValid': false,
          'error': 'There is already an order scheduled for this time slot',
        };
      }
    }

    return {'isValid': true};
  }

  Future<TimeSlot?> _getTimeSlot(String timeSlotId) async {
    final doc = await _firestore.collection('timeSlots').doc(timeSlotId).get();
    if (doc.exists) {
      return TimeSlot.fromJson(timeSlotId, doc.data()!);
    }
    return null;
  }

  Future<RestaurantOperatingHours?> _getRestaurantOperatingHours(String restaurantId) async {
    final doc = await _firestore
        .collection('restaurantOperatingHours')
        .doc(restaurantId)
        .get();
    
    if (doc.exists) {
      return RestaurantOperatingHours.fromJson(restaurantId, doc.data()!);
    }
    return null;
  }

  double _calculateDeliveryFee(String? address, ScheduleType type, OrderPriority priority) {
    // Base delivery fee logic
    double baseFee = 3.99; // Base delivery fee
    
    // Add fees based on type
    switch (type) {
      case ScheduleType.rush:
        baseFee += 5.00; // Rush delivery surcharge
        break;
      case ScheduleType.scheduled:
        baseFee += 1.50; // Scheduled delivery fee
        break;
      case ScheduleType.preorder:
        baseFee += 2.00; // Pre-order fee
        break;
      default:
        break;
    }
    
    // Priority adjustments
    if (priority == OrderPriority.urgent || priority == OrderPriority.vip) {
      baseFee += 3.00;
    }
    
    return baseFee;
  }

  double _calculateRushFee(ScheduleType type, OrderPriority priority) {
    if (type == ScheduleType.rush || priority == OrderPriority.urgent) {
      return 7.99; // Rush fee
    }
    return 0.0;
  }

  Future<Map<String, int>> _estimatePreparationTime(String restaurantId, List<String> items) async {
    // Simplified preparation time estimation
    // In a real app, this would consider restaurant prep times, item complexity, etc.
    final prepTime = <String, int>{};
    final basePrepTime = 15; // Base 15 minutes
    
    for (final item in items) {
      // Each item adds 5-10 minutes based on complexity
      final itemPrepTime = basePrepTime + (item.length % 5) * 2;
      prepTime[item] = itemPrepTime;
    }
    
    return prepTime;
  }

  Future<void> _updateTimeSlotAvailability(String timeSlotId, int delta) async {
    await _firestore.collection('timeSlots').doc(timeSlotId).update({
      'currentOrders': FieldValue.increment(delta),
    });
  }

  Future<void> _createRecurringOrderEntry(ScheduledDeliveryOrder order) async {
    if (order.recurringPatternId == null) return;
    
    final recurringEntry = {
      'patternId': order.recurringPatternId,
      'orderId': order.id,
      'scheduledDateTime': order.scheduledDateTime.millisecondsSinceEpoch,
      'executionNumber': order.recurringCount ?? 1,
      'status': order.status.name,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _firestore
        .collection('recurringOrderEntries')
        .doc(order.id)
        .set(recurringEntry);
  }

  Future<void> _sendSchedulingConfirmation(ScheduledDeliveryOrder order) async {
    // Implementation would send push notification/email
    debugPrint('Sending scheduling confirmation for order ${order.id}');
  }

  Future<void> _sendOrderUpdateNotification(ScheduledDeliveryOrder order) async {
    debugPrint('Sending order update notification for order ${order.id}');
  }

  Future<void> _sendOrderCancellationNotification(ScheduledDeliveryOrder order, double refundAmount) async {
    debugPrint('Sending cancellation notification for order ${order.id} with refund $refundAmount');
  }

  Future<void> _sendStatusUpdateNotification(ScheduledDeliveryOrder order, DeliveryStatus status) async {
    debugPrint('Sending status update notification: ${order.id} -> $status');
  }

  bool _isValidRecurringPattern(RecurringPattern pattern, List<int> customDays) {
    if (pattern == RecurringPattern.custom && customDays.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _executeRecurringDelivery(RecurringDeliveryPattern pattern) async {
    // Implementation would create a new order based on the pattern
    debugPrint('Executing recurring delivery for pattern ${pattern.id}');
  }

  Future<List<ScheduledDeliveryOrder>> _getConflictingOrders(
    String restaurantId,
    DateTime scheduledDateTime,
    String excludeOrderId,
  ) async {
    final startTime = scheduledDateTime.subtract(Duration(minutes: 30));
    final endTime = scheduledDateTime.add(Duration(minutes: 30));
    
    final snapshot = await _firestore
        .collection('scheduledDeliveryOrders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('scheduledDateTime', isGreaterThanOrEqualTo: startTime.millisecondsSinceEpoch)
        .where('scheduledDateTime', isLessThanOrEqualTo: endTime.millisecondsSinceEpoch)
        .where('status', whereIn: [DeliveryStatus.pending.name, DeliveryStatus.confirmed.name])
        .get();
    
    return snapshot.docs
        .where((doc) => doc.id != excludeOrderId)
        .map((doc) => ScheduledDeliveryOrder.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> _cancelRecurringSeries(String patternId, String orderId) async {
    await _firestore.collection('recurringDeliveryPatterns').doc(patternId).update({
      'isActive': false,
    });
  }

  Future<double> _processCancellationRefund(ScheduledDeliveryOrder order) async {
    // Calculate refund based on cancellation policy
    final now = DateTime.now();
    final timeUntilDelivery = order.scheduledDateTime.difference(now).inHours;
    
    double refundPercentage = 1.0; // Full refund
    
    if (timeUntilDelivery < 2) {
      refundPercentage = 0.5; // 50% refund if less than 2 hours
    } else if (timeUntilDelivery < 4) {
      refundPercentage = 0.75; // 75% refund if less than 4 hours
    }
    
    return (order.totalAmount + order.deliveryFee + order.rushFee) * refundPercentage;
  }

  Future<void> _updateRecurringPatternExecution(String patternId) async {
    await _firestore.collection('recurringDeliveryPatterns').doc(patternId).update({
      'executionCount': FieldValue.increment(1),
      'lastExecuted': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<ScheduledDeliveryOrder?> getScheduledOrder(String orderId) async {
    final doc = await _firestore
        .collection('scheduledDeliveryOrders')
        .doc(orderId)
        .get();
    
    if (doc.exists) {
      return ScheduledDeliveryOrder.fromJson(orderId, doc.data()!);
    }
    return null;
  }
}