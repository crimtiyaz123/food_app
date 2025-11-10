import 'package:cloud_firestore/cloud_firestore.dart';

// Custom Time class to avoid Flutter widget dependency
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  bool isAfter(TimeOfDay other) {
    if (hour != other.hour) {
      return hour > other.hour;
    }
    return minute > other.minute;
  }

  bool isBefore(TimeOfDay other) {
    if (hour != other.hour) {
      return hour < other.hour;
    }
    return minute < other.minute;
  }
}

// Notification Types
enum NotificationType {
  orderUpdate,
  deliveryTracking,
  promotion,
  recommendation,
  loyaltyReward,
  feedback,
  reorder,
  weatherBased,
  timeBased,
  locationBased,
  systemAlert,
  custom
}

// Notification Channel
enum NotificationChannel {
  push,
  email,
  sms,
  inApp,
  all
}

// Notification Priority
enum NotificationPriority {
  low,
  normal,
  high,
  urgent
}

// Notification Status
enum NotificationStatus {
  pending,
  sent,
  delivered,
  read,
  clicked,
  dismissed,
  failed
}

// User Notification Preferences
class NotificationPreferences {
  final String userId;
  final Map<NotificationType, bool> enabledTypes;
  final Map<NotificationChannel, bool> preferredChannels;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final List<String> doNotDisturbDays;
  final Map<NotificationPriority, bool> prioritySettings;
  final bool marketingOptIn;
  final bool promotionalOptIn;
  final bool orderAlerts;
  final bool deliveryAlerts;
  final bool recommendationAlerts;
  final bool locationBasedAlerts;
  final bool weatherBasedAlerts;
  final bool reorderSuggestions;
  final bool loyaltyAlerts;
  final bool cartAbandonmentAlerts;
  final double engagementScore; // 0-1 scale
  final DateTime lastUpdated;

  NotificationPreferences({
    required this.userId,
    required this.enabledTypes,
    required this.preferredChannels,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.doNotDisturbDays,
    required this.prioritySettings,
    required this.marketingOptIn,
    required this.promotionalOptIn,
    required this.orderAlerts,
    required this.deliveryAlerts,
    required this.recommendationAlerts,
    required this.locationBasedAlerts,
    required this.weatherBasedAlerts,
    required this.reorderSuggestions,
    required this.loyaltyAlerts,
    required this.cartAbandonmentAlerts,
    required this.engagementScore,
    required this.lastUpdated,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['userId'] ?? '',
      enabledTypes: (json['enabledTypes'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(NotificationType.values.firstWhere((e) => e.toString().split('.').last == key), value)) ?? {},
      preferredChannels: (json['preferredChannels'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(NotificationChannel.values.firstWhere((e) => e.toString().split('.').last == key), value)) ?? {},
      quietHoursStart: TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(json['quietHoursStart'] ?? 0)),
      quietHoursEnd: TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(json['quietHoursEnd'] ?? 0)),
      doNotDisturbDays: List<String>.from(json['doNotDisturbDays'] ?? []),
      prioritySettings: (json['prioritySettings'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(NotificationPriority.values.firstWhere((e) => e.toString().split('.').last == key), value)) ?? {},
      marketingOptIn: json['marketingOptIn'] ?? false,
      promotionalOptIn: json['promotionalOptIn'] ?? false,
      orderAlerts: json['orderAlerts'] ?? true,
      deliveryAlerts: json['deliveryAlerts'] ?? true,
      recommendationAlerts: json['recommendationAlerts'] ?? true,
      locationBasedAlerts: json['locationBasedAlerts'] ?? false,
      weatherBasedAlerts: json['weatherBasedAlerts'] ?? false,
      reorderSuggestions: json['reorderSuggestions'] ?? true,
      loyaltyAlerts: json['loyaltyAlerts'] ?? true,
      cartAbandonmentAlerts: json['cartAbandonmentAlerts'] ?? true,
      engagementScore: (json['engagementScore'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enabledTypes': enabledTypes.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'preferredChannels': preferredChannels.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'quietHoursStart': DateTime(2020, 1, 1, quietHoursStart.hour, quietHoursStart.minute).millisecondsSinceEpoch,
      'quietHoursEnd': DateTime(2020, 1, 1, quietHoursEnd.hour, quietHoursEnd.minute).millisecondsSinceEpoch,
      'doNotDisturbDays': doNotDisturbDays,
      'prioritySettings': prioritySettings.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'marketingOptIn': marketingOptIn,
      'promotionalOptIn': promotionalOptIn,
      'orderAlerts': orderAlerts,
      'deliveryAlerts': deliveryAlerts,
      'recommendationAlerts': recommendationAlerts,
      'locationBasedAlerts': locationBasedAlerts,
      'weatherBasedAlerts': weatherBasedAlerts,
      'reorderSuggestions': reorderSuggestions,
      'loyaltyAlerts': loyaltyAlerts,
      'cartAbandonmentAlerts': cartAbandonmentAlerts,
      'engagementScore': engagementScore,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  // Check if notification type is enabled
  bool isTypeEnabled(NotificationType type) {
    return enabledTypes[type] ?? true;
  }

  // Check if channel is preferred
  bool isChannelPreferred(NotificationChannel channel) {
    return preferredChannels[channel] ?? true;
  }

  // Check if currently in quiet hours
  bool isQuietHours() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    if (quietHoursStart.hour < quietHoursEnd.hour) {
      // Same day quiet hours
      return currentTime.hour >= quietHoursStart.hour && 
             currentTime.hour < quietHoursEnd.hour;
    } else {
      // Overnight quiet hours (e.g., 10 PM to 7 AM)
      return currentTime.hour >= quietHoursStart.hour || 
             currentTime.hour < quietHoursEnd.hour;
    }
  }

  // Check if day is in do not disturb list
  bool isDoNotDisturbDay(int dayOfWeek) {
    return doNotDisturbDays.contains(dayOfWeek.toString());
  }

  // Check if priority is allowed
  bool isPriorityAllowed(NotificationPriority priority) {
    return prioritySettings[priority] ?? true;
  }

  // Get maximum notifications per day
  int getMaxNotificationsPerDay() {
    if (engagementScore > 0.8) return 10;
    if (engagementScore > 0.6) return 7;
    if (engagementScore > 0.4) return 5;
    return 3;
  }

  // Get optimal sending time based on user behavior
  TimeOfDay getOptimalSendTime() {
    // This would be determined by AI analysis of user's activity patterns
    // For now, return a default optimal time
    if (engagementScore > 0.7) {
      return const TimeOfDay(hour: 12, minute: 0); // Lunch time for high engagement
    } else if (engagementScore > 0.4) {
      return const TimeOfDay(hour: 18, minute: 0); // Dinner time for medium engagement
    } else {
      return const TimeOfDay(hour: 19, minute: 30); // Early evening for low engagement
    }
  }
}

// Smart Notification
class SmartNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final List<String>? actionButtons;
  final DateTime scheduledTime;
  final DateTime? expiryTime;
  final String? imageUrl;
  final String? deepLink;
  final NotificationChannel channel;
  final NotificationStatus status;
  final String? deliveryId;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? clickedAt;
  final String? failureReason;
  final Map<String, dynamic> aiMetadata;

  SmartNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.data,
    this.actionButtons,
    required this.scheduledTime,
    this.expiryTime,
    this.imageUrl,
    this.deepLink,
    required this.channel,
    required this.status,
    this.deliveryId,
    required this.createdAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.clickedAt,
    this.failureReason,
    required this.aiMetadata,
  });

  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    return SmartNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.custom,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
      actionButtons: json['actionButtons'] != null ? List<String>.from(json['actionButtons']) : null,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(json['scheduledTime']),
      expiryTime: json['expiryTime'] != null ? DateTime.fromMillisecondsSinceEpoch(json['expiryTime']) : null,
      imageUrl: json['imageUrl'],
      deepLink: json['deepLink'],
      channel: NotificationChannel.values.firstWhere(
        (e) => e.toString().split('.').last == json['channel'],
        orElse: () => NotificationChannel.push,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => NotificationStatus.pending,
      ),
      deliveryId: json['deliveryId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      sentAt: json['sentAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['sentAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt']) : null,
      readAt: json['readAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['readAt']) : null,
      clickedAt: json['clickedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['clickedAt']) : null,
      failureReason: json['failureReason'],
      aiMetadata: Map<String, dynamic>.from(json['aiMetadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'actionButtons': actionButtons,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'expiryTime': expiryTime?.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'channel': channel.toString().split('.').last,
      'status': status.toString().split('.').last,
      'deliveryId': deliveryId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sentAt': sentAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'clickedAt': clickedAt?.millisecondsSinceEpoch,
      'failureReason': failureReason,
      'aiMetadata': aiMetadata,
    };
  }

  // Get estimated engagement score for this notification
  double getEstimatedEngagement() {
    double score = 0.5; // Base score

    // Priority boost
    switch (priority) {
      case NotificationPriority.urgent:
        score += 0.3;
        break;
      case NotificationPriority.high:
        score += 0.2;
        break;
      case NotificationPriority.normal:
        score += 0.1;
        break;
      case NotificationPriority.low:
        break;
    }

    // Type-based engagement
    switch (type) {
      case NotificationType.orderUpdate:
      case NotificationType.deliveryTracking:
        score += 0.2; // High engagement for order-related
        break;
      case NotificationType.recommendation:
      case NotificationType.reorder:
        score += 0.15; // Good engagement for recommendations
        break;
      case NotificationType.promotion:
      case NotificationType.loyaltyReward:
        score += 0.1; // Moderate engagement for promotions
        break;
      default:
        break;
    }

    // Time-based adjustment
    final now = DateTime.now();
    final timeDiff = scheduledTime.difference(now).inMinutes;
    if (timeDiff <= 5) {
      score += 0.1; // Immediate notifications get boost
    } else if (timeDiff > 120) {
      score -= 0.1; // Far future notifications get penalty
    }

    return score.clamp(0.0, 1.0);
  }

  // Check if notification is expired
  bool isExpired() {
    return expiryTime != null && DateTime.now().isAfter(expiryTime!);
  }

  // Check if notification should be sent now
  bool shouldSendNow() {
    return status == NotificationStatus.pending && 
           scheduledTime.isBefore(DateTime.now()) && 
           !isExpired();
  }

  // Mark as sent
  SmartNotification markAsSent() {
    return copyWith(
      status: NotificationStatus.sent,
      sentAt: DateTime.now(),
    );
  }

  // Mark as delivered
  SmartNotification markAsDelivered() {
    return copyWith(
      status: NotificationStatus.delivered,
      deliveredAt: DateTime.now(),
    );
  }

  // Mark as read
  SmartNotification markAsRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }

  // Mark as clicked
  SmartNotification markAsClicked() {
    return copyWith(
      status: NotificationStatus.clicked,
      clickedAt: DateTime.now(),
    );
  }

  // Mark as failed
  SmartNotification markAsFailed(String reason) {
    return copyWith(
      status: NotificationStatus.failed,
      failureReason: reason,
    );
  }

  SmartNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    List<String>? actionButtons,
    DateTime? scheduledTime,
    DateTime? expiryTime,
    String? imageUrl,
    String? deepLink,
    NotificationChannel? channel,
    NotificationStatus? status,
    String? deliveryId,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? clickedAt,
    String? failureReason,
    Map<String, dynamic>? aiMetadata,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      actionButtons: actionButtons ?? this.actionButtons,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      expiryTime: expiryTime ?? this.expiryTime,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      deliveryId: deliveryId ?? this.deliveryId,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      clickedAt: clickedAt ?? this.clickedAt,
      failureReason: failureReason ?? this.failureReason,
      aiMetadata: aiMetadata ?? this.aiMetadata,
    );
  }
}