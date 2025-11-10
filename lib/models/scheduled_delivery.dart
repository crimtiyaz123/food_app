// Scheduled Deliveries & Pre-orders Models

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

// Delivery Schedule Types
enum ScheduleType {
  immediate,      // Immediate delivery
  scheduled,      // Scheduled for specific time
  recurring,      // Recurring delivery (daily, weekly, etc.)
  preorder,       // Pre-order for future date
  rush,          // Rush delivery (faster, higher cost)
}

// Delivery Status
enum DeliveryStatus {
  pending,        // Order placed, waiting for confirmation
  confirmed,      // Order confirmed by restaurant
  preparing,      // Food being prepared
  ready,          // Food ready for pickup
  pickedup,       // Order picked up by delivery partner
  intransit,     // Order in transit
  delivered,      // Order delivered
  failed,         // Delivery failed
  cancelled,     // Order cancelled
  rescheduled,   // Order rescheduled
}

// Order Priority
enum OrderPriority {
  low,           // Low priority
  normal,        // Normal priority
  high,          // High priority
  urgent,        // Urgent (Rush delivery)
  vip,          // VIP customer
}

// Recurring Pattern
enum RecurringPattern {
  daily,         // Every day
  weekdays,      // Monday to Friday
  weekends,      // Saturday and Sunday
  weekly,        // Every week
  biweekly,      // Every 2 weeks
  monthly,       // Every month
  custom,        // Custom pattern
}

// Time Slot
class TimeSlot {
  final String id;
  final String startTime; // Format: "HH:mm"
  final String endTime;   // Format: "HH:mm"
  final int maxOrders;    // Maximum orders for this slot
  final int currentOrders; // Current orders assigned
  final double fee;       // Delivery fee for this slot
  final bool isAvailable; // Whether this slot is available
  final Map<String, dynamic> restrictions; // Time slot restrictions

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.maxOrders,
    required this.currentOrders,
    required this.fee,
    required this.isAvailable,
    required this.restrictions,
  });

  factory TimeSlot.fromJson(String id, Map<String, dynamic> json) {
    return TimeSlot(
      id: id,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      maxOrders: json['maxOrders'] ?? 0,
      currentOrders: json['currentOrders'] ?? 0,
      fee: (json['fee'] ?? 0.0).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      restrictions: Map<String, dynamic>.from(json['restrictions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'maxOrders': maxOrders,
      'currentOrders': currentOrders,
      'fee': fee,
      'isAvailable': isAvailable,
      'restrictions': restrictions,
    };
  }

  // Get time slot duration in minutes
  int get durationMinutes {
    final start = DateTime.parse('1970-01-01 $startTime');
    final end = DateTime.parse('1970-01-01 $endTime');
    return end.difference(start).inMinutes;
  }

  // Check if slot is available for given order count
  bool isAvailableForOrder(int orderCount) {
    return isAvailable && (currentOrders + orderCount) <= maxOrders;
  }

  // Check if current time falls within this slot
  bool containsTime(DateTime time) {
    final slotStart = DateTime.parse('1970-01-01 $startTime');
    final slotEnd = DateTime.parse('1970-01-01 $endTime');
    final currentTime = DateTime.parse('1970-01-01 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00');
    
    return currentTime.isAfter(slotStart.subtract(Duration(minutes: 1))) && 
           currentTime.isBefore(slotEnd.add(Duration(minutes: 1)));
  }
}

// Scheduled Delivery Order
class ScheduledDeliveryOrder {
  final String id;
  final String userId;
  final String restaurantId;
  final String orderId;
  final ScheduleType type;
  final DateTime scheduledDateTime;
  final DateTime createdAt;
  final DeliveryStatus status;
  final OrderPriority priority;
  final List<String> items;
  final double totalAmount;
  final String? deliveryAddress;
  final String? specialInstructions;
  final String? deliveryPartnerId;
  final DateTime? confirmedAt;
  final DateTime? preparedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final String? failureReason;
  final double deliveryFee;
  final double rushFee;
  final Map<String, dynamic> metadata;
  final String? recurringPatternId;
  final RecurringPattern? recurringPattern;
  final int? recurringCount; // For recurring orders
  final int? maxRecurringCount; // Maximum recurring deliveries
  final DateTime? lastDeliveredAt;
  final bool isRecurringActive;
  final Map<String, int> estimatedPrepTime; // itemId -> prep time in minutes
  final TimeSlot? assignedTimeSlot;
  final String? confirmationCode; // For pickup verification

  ScheduledDeliveryOrder({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.orderId,
    required this.type,
    required this.scheduledDateTime,
    required this.createdAt,
    required this.status,
    required this.priority,
    required this.items,
    required this.totalAmount,
    this.deliveryAddress,
    this.specialInstructions,
    this.deliveryPartnerId,
    this.confirmedAt,
    this.preparedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.failedAt,
    this.failureReason,
    required this.deliveryFee,
    required this.rushFee,
    required this.metadata,
    this.recurringPatternId,
    this.recurringPattern,
    this.recurringCount,
    this.maxRecurringCount,
    this.lastDeliveredAt,
    required this.isRecurringActive,
    required this.estimatedPrepTime,
    this.assignedTimeSlot,
    this.confirmationCode,
  });

  factory ScheduledDeliveryOrder.fromJson(String id, Map<String, dynamic> json) {
    return ScheduledDeliveryOrder(
      id: id,
      userId: json['userId'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      orderId: json['orderId'] ?? '',
      type: ScheduleType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ScheduleType.immediate,
      ),
      scheduledDateTime: DateTime.fromMillisecondsSinceEpoch(json['scheduledDateTime'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      status: DeliveryStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      priority: OrderPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => OrderPriority.normal,
      ),
      items: List<String>.from(json['items'] ?? []),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      deliveryAddress: json['deliveryAddress'],
      specialInstructions: json['specialInstructions'],
      deliveryPartnerId: json['deliveryPartnerId'],
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['confirmedAt'])
          : null,
      preparedAt: json['preparedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['preparedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['pickedUpAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt'])
          : null,
      failedAt: json['failedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['failedAt'])
          : null,
      failureReason: json['failureReason'],
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      rushFee: (json['rushFee'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      recurringPatternId: json['recurringPatternId'],
      recurringPattern: json['recurringPattern'] != null 
          ? RecurringPattern.values.firstWhere(
              (p) => p.name == json['recurringPattern'],
              orElse: () => RecurringPattern.daily,
            )
          : null,
      recurringCount: json['recurringCount'],
      maxRecurringCount: json['maxRecurringCount'],
      lastDeliveredAt: json['lastDeliveredAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastDeliveredAt'])
          : null,
      isRecurringActive: json['isRecurringActive'] ?? false,
      estimatedPrepTime: Map<String, int>.from(json['estimatedPrepTime'] ?? {}),
      assignedTimeSlot: json['assignedTimeSlot'] != null 
          ? TimeSlot.fromJson('', json['assignedTimeSlot'])
          : null,
      confirmationCode: json['confirmationCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'orderId': orderId,
      'type': type.name,
      'scheduledDateTime': scheduledDateTime.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.name,
      'priority': priority.name,
      'items': items,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'specialInstructions': specialInstructions,
      'deliveryPartnerId': deliveryPartnerId,
      'confirmedAt': confirmedAt?.millisecondsSinceEpoch,
      'preparedAt': preparedAt?.millisecondsSinceEpoch,
      'pickedUpAt': pickedUpAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'failedAt': failedAt?.millisecondsSinceEpoch,
      'failureReason': failureReason,
      'deliveryFee': deliveryFee,
      'rushFee': rushFee,
      'metadata': metadata,
      'recurringPatternId': recurringPatternId,
      'recurringPattern': recurringPattern?.name,
      'recurringCount': recurringCount,
      'maxRecurringCount': maxRecurringCount,
      'lastDeliveredAt': lastDeliveredAt?.millisecondsSinceEpoch,
      'isRecurringActive': isRecurringActive,
      'estimatedPrepTime': estimatedPrepTime,
      'assignedTimeSlot': assignedTimeSlot?.toJson(),
      'confirmationCode': confirmationCode,
    };
  }

  // Check if order can be cancelled
  bool get canBeCancelled {
    return status == DeliveryStatus.pending || 
           status == DeliveryStatus.confirmed;
  }

  // Check if order can be rescheduled
  bool get canBeRescheduled {
    return status == DeliveryStatus.pending || 
           status == DeliveryStatus.confirmed;
  }

  // Check if order is ready for pickup
  bool get isReadyForPickup {
    return status == DeliveryStatus.ready;
  }

  // Get estimated total preparation time
  int get totalEstimatedPrepTime {
    return estimatedPrepTime.values.fold(0, (sum, time) => sum + time);
  }

  // Check if order is overdue
  bool get isOverdue {
    final now = DateTime.now();
    return scheduledDateTime.isBefore(now) && 
           status != DeliveryStatus.delivered &&
           status != DeliveryStatus.failed &&
           status != DeliveryStatus.cancelled;
  }

  // Get time until scheduled delivery
  Duration get timeUntilScheduled {
    return scheduledDateTime.difference(DateTime.now());
  }

  // Check if this is a rush order
  bool get isRushOrder {
    return type == ScheduleType.rush || priority == OrderPriority.urgent;
  }

  // Calculate total delivery cost including rush fees
  double get totalDeliveryCost {
    return deliveryFee + rushFee;
  }

  // Generate confirmation code if not exists
  String generateConfirmationCode() {
    if (confirmationCode != null) return confirmationCode!;
    
    final timestamp = scheduledDateTime.millisecondsSinceEpoch;
    final hash = (id + timestamp.toString()).hashCode.abs();
    return 'CONF${hash.toString().substring(0, 6).toUpperCase()}';
  }

  // Get remaining time for preparation
  Duration get remainingPrepTime {
    if (confirmedAt == null) return Duration.zero;
    
    final prepDeadline = confirmedAt!.add(Duration(minutes: totalEstimatedPrepTime));
    return prepDeadline.difference(DateTime.now());
  }

  // Check if preparation is on time
  bool get isPrepOnTime {
    if (preparedAt == null) return false;
    if (confirmedAt == null) return true;
    
    final expectedPrepTime = confirmedAt!.add(Duration(minutes: totalEstimatedPrepTime));
    return preparedAt!.isBefore(expectedPrepTime);
  }
}

// Recurring Delivery Pattern
class RecurringDeliveryPattern {
  final String id;
  final String userId;
  final String name;
  final String description;
  final RecurringPattern pattern;
  final List<int> customDays; // For custom pattern: days of week (1=Monday, 7=Sunday)
  final TimeOfDay deliveryTime; // Desired delivery time
  final List<String> restaurantIds; // Preferred restaurants
  final List<String> itemPreferences; // Preferred items/categories
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final Map<String, dynamic> preferences; // Dietary, spice level, etc.
  final DateTime lastExecuted;
  final int executionCount;
  final int maxExecutions;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  RecurringDeliveryPattern({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.pattern,
    required this.customDays,
    required this.deliveryTime,
    required this.restaurantIds,
    required this.itemPreferences,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.preferences,
    required this.lastExecuted,
    required this.executionCount,
    required this.maxExecutions,
    required this.createdAt,
    required this.metadata,
  });

  factory RecurringDeliveryPattern.fromJson(String id, Map<String, dynamic> json) {
    return RecurringDeliveryPattern(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pattern: RecurringPattern.values.firstWhere(
        (p) => p.name == json['pattern'],
        orElse: () => RecurringPattern.daily,
      ),
      customDays: List<int>.from(json['customDays'] ?? []),
      deliveryTime: TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(json['deliveryTime'] ?? 0)),
      restaurantIds: List<String>.from(json['restaurantIds'] ?? []),
      itemPreferences: List<String>.from(json['itemPreferences'] ?? []),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: json['endDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      isActive: json['isActive'] ?? true,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      lastExecuted: DateTime.fromMillisecondsSinceEpoch(json['lastExecuted'] ?? 0),
      executionCount: json['executionCount'] ?? 0,
      maxExecutions: json['maxExecutions'] ?? -1, // -1 for unlimited
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'pattern': pattern.name,
      'customDays': customDays,
      'deliveryTime': deliveryTime.hour * 60 + deliveryTime.minute, // Store as minutes since midnight
      'restaurantIds': restaurantIds,
      'itemPreferences': itemPreferences,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isActive': isActive,
      'preferences': preferences,
      'lastExecuted': lastExecuted.millisecondsSinceEpoch,
      'executionCount': executionCount,
      'maxExecutions': maxExecutions,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Check if pattern should execute on given date
  bool shouldExecuteOn(DateTime date) {
    if (!isActive) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    if (maxExecutions > 0 && executionCount >= maxExecutions) return false;

    switch (pattern) {
      case RecurringPattern.daily:
        return true;
      case RecurringPattern.weekdays:
        final weekday = date.weekday; // 1=Monday, 7=Sunday
        return weekday >= 1 && weekday <= 5;
      case RecurringPattern.weekends:
        final weekday = date.weekday;
        return weekday == 6 || weekday == 7;
      case RecurringPattern.weekly:
        return true; // Would need specific day logic
      case RecurringPattern.biweekly:
        return true; // Would need specific day logic
      case RecurringPattern.monthly:
        return true; // Would need specific day logic
      case RecurringPattern.custom:
        return customDays.contains(date.weekday);
    }
  }

  // Get next execution date after given date
  DateTime getNextExecutionDate(DateTime fromDate) {
    DateTime nextDate = fromDate.add(Duration(days: 1));

    // Find next date that matches the pattern
    while (!shouldExecuteOn(nextDate)) {
      nextDate = nextDate.add(Duration(days: 1));
    }

    // Set the time
    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      deliveryTime.hour,
      deliveryTime.minute,
    );
  }

  // Check if pattern has reached max executions
  bool get hasReachedMaxExecutions {
    return maxExecutions > 0 && executionCount >= maxExecutions;
  }

  // Check if pattern is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive &&
           now.isAfter(startDate) &&
           (endDate == null || now.isBefore(endDate!)) &&
           !hasReachedMaxExecutions;
  }
}

// TimeOfDay helper class for JSON serialization
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Duration get durationSinceMidnight {
    return Duration(hours: hour, minutes: minute);
  }

  @override
  String toString() => formatted;
}

// Restaurant Operating Hours
class RestaurantOperatingHours {
  final String restaurantId;
  final Map<int, List<TimeSlot>> dailySlots; // dayOfWeek -> list of time slots
  final Map<String, dynamic> specialHours; // date -> list of time slots
  final bool isClosed;
  final Map<String, dynamic> exceptions; // holiday closures, etc.

  RestaurantOperatingHours({
    required this.restaurantId,
    required this.dailySlots,
    required this.specialHours,
    required this.isClosed,
    required this.exceptions,
  });

  factory RestaurantOperatingHours.fromJson(String id, Map<String, dynamic> json) {
    final slots = <int, List<TimeSlot>>{};
    
    // Parse daily slots
    if (json['dailySlots'] != null) {
      for (final entry in json['dailySlots'].entries) {
        final dayOfWeek = int.parse(entry.key);
        slots[dayOfWeek] = (entry.value as List)
            .map((slotJson) => TimeSlot.fromJson('', slotJson))
            .toList();
      }
    }

    return RestaurantOperatingHours(
      restaurantId: id,
      dailySlots: slots,
      specialHours: Map<String, dynamic>.from(json['specialHours'] ?? {}),
      isClosed: json['isClosed'] ?? false,
      exceptions: Map<String, dynamic>.from(json['exceptions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailySlots': dailySlots.map((day, slots) => MapEntry(
        day.toString(),
        slots.map((slot) => slot.toJson()).toList(),
      )),
      'specialHours': specialHours,
      'isClosed': isClosed,
      'exceptions': exceptions,
    };
  }

  // Get available time slots for a specific date
  List<TimeSlot> getAvailableTimeSlots(DateTime date) {
    // Check for special hours first
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (specialHours.containsKey(dateKey)) {
      return List<TimeSlot>.from(specialHours[dateKey])
          .where((slot) => slot.isAvailable)
          .toList();
    }

    // Check daily slots
    final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
    final daySlots = dailySlots[dayOfWeek] ?? [];
    return daySlots.where((slot) => slot.isAvailable).toList();
  }

  // Check if restaurant is open at given time
  bool isOpenAt(DateTime dateTime) {
    if (isClosed) return false;
    
    final availableSlots = getAvailableTimeSlots(dateTime);
    return availableSlots.any((slot) => slot.containsTime(dateTime));
  }

  // Get next available time slot
  TimeSlot? getNextAvailableSlot(DateTime fromDateTime) {
    final availableSlots = getAvailableTimeSlots(fromDateTime);
    return availableSlots.isNotEmpty ? availableSlots.first : null;
  }

  // Get minimum advance time required for scheduling
  Duration get minimumAdvanceTime {
    // This could be configured per restaurant
    return Duration(hours: 2);
  }

  // Get maximum advance booking days
  int get maxAdvanceBookingDays {
    // This could be configured per restaurant
    return 30;
  }
}

// Delivery Zone
class DeliveryZone {
  final String id;
  final String name;
  final List<LatLng> boundaries; // Polygon defining delivery zone
  final double baseDeliveryFee;
  final double feePerKm;
  final Duration estimatedDeliveryTime;
  final bool isActive;
  final Map<String, dynamic> restrictions; // Min order amount, etc.
  final String? restaurantId; // Null for general delivery zones

  DeliveryZone({
    required this.id,
    required this.name,
    required this.boundaries,
    required this.baseDeliveryFee,
    required this.feePerKm,
    required this.estimatedDeliveryTime,
    required this.isActive,
    required this.restrictions,
    this.restaurantId,
  });

  factory DeliveryZone.fromJson(String id, Map<String, dynamic> json) {
    return DeliveryZone(
      id: id,
      name: json['name'] ?? '',
      boundaries: List<LatLng>.from(
        (json['boundaries'] as List).map((coord) => LatLng(
          coord['lat'],
          coord['lng'],
        ))
      ),
      baseDeliveryFee: (json['baseDeliveryFee'] ?? 0.0).toDouble(),
      feePerKm: (json['feePerKm'] ?? 0.0).toDouble(),
      estimatedDeliveryTime: Duration(minutes: json['estimatedDeliveryTime'] ?? 30),
      isActive: json['isActive'] ?? true,
      restrictions: Map<String, dynamic>.from(json['restrictions'] ?? {}),
      restaurantId: json['restaurantId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'boundaries': boundaries.map((coord) => {
        'lat': coord.latitude,
        'lng': coord.longitude,
      }).toList(),
      'baseDeliveryFee': baseDeliveryFee,
      'feePerKm': feePerKm,
      'estimatedDeliveryTime': estimatedDeliveryTime.inMinutes,
      'isActive': isActive,
      'restrictions': restrictions,
      'restaurantId': restaurantId,
    };
  }

  // Check if point is within delivery zone (simplified point-in-polygon)
  bool containsPoint(LatLng point) {
    // Simplified implementation - in production, use proper polygon point-in-polygon algorithm
    return boundaries.any((boundary) => _calculateDistance(boundary, point) < 0.1); // 100m tolerance
  }

  // Calculate delivery fee for given distance
  double calculateDeliveryFee(double distanceKm) {
    return baseDeliveryFee + (distanceKm * feePerKm);
  }

  // Check if minimum order amount is met
  bool meetsMinimumOrder(double orderAmount) {
    final minOrder = restrictions['minOrderAmount'] as double?;
    return minOrder == null || orderAmount >= minOrder;
  }
}

// Simple LatLng class
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  double _calculateDistance(LatLng other) {
    // Haversine formula for distance calculation
    const R = 6371; // Earth's radius in km
    final dLat = (other.latitude - latitude) * 3.14159 / 180;
    final dLon = (other.longitude - longitude) * 3.14159 / 180;
    final a = math.sin(dLat/2) * math.sin(dLat/2) +
              math.cos(latitude * 3.14159 / 180) * math.cos(other.latitude * 3.14159 / 180) *
              math.sin(dLon/2) * math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    return R * c;
  }
}

double _calculateDistance(LatLng point1, LatLng point2) {
  // Haversine formula for distance calculation
  const R = 6371; // Earth's radius in km
  final dLat = (point2.latitude - point1.latitude) * 3.14159 / 180;
  final dLon = (point2.longitude - point1.longitude) * 3.14159 / 180;
  final a = math.sin(dLat/2) * math.sin(dLat/2) +
            math.cos(point1.latitude * 3.14159 / 180) * math.cos(point2.latitude * 3.14159 / 180) *
            math.sin(dLon/2) * math.sin(dLon/2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
  return R * c;
}