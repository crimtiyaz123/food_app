class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    return NotificationModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum NotificationType {
  orderUpdate('Order Update'),
  promotion('Promotion'),
  deliveryUpdate('Delivery Update'),
  general('General'),
  restaurantUpdate('Restaurant Update');

  const NotificationType(this.displayName);
  final String displayName;
}

class NotificationPreferences {
  final String userId;
  bool orderUpdates;
  bool promotions;
  bool deliveryUpdates;
  bool generalNotifications;
  bool soundEnabled;
  bool vibrationEnabled;

  NotificationPreferences({
    required this.userId,
    this.orderUpdates = true,
    this.promotions = true,
    this.deliveryUpdates = true,
    this.generalNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  factory NotificationPreferences.fromJson(String userId, Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: userId,
      orderUpdates: json['orderUpdates'] ?? true,
      promotions: json['promotions'] ?? true,
      deliveryUpdates: json['deliveryUpdates'] ?? true,
      generalNotifications: json['generalNotifications'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'deliveryUpdates': deliveryUpdates,
      'generalNotifications': generalNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }
}