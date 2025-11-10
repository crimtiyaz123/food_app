class AdminUser {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final DateTime createdAt;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  factory AdminUser.fromJson(String id, Map<String, dynamic> json) {
    return AdminUser(
      id: id,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AdminRole.superAdmin,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

enum AdminRole {
  superAdmin('Super Admin'),
  admin('Admin'),
  moderator('Moderator'),
  support('Support');

  const AdminRole(this.displayName);
  final String displayName;
}

class AdminAnalytics {
  final int totalUsers;
  final int totalRestaurants;
  final int totalOrders;
  final double totalRevenue;
  final int activeOrders;
  final int pendingApprovals;
  final Map<String, int> ordersByStatus;
  final Map<String, double> revenueByDay;
  final List<TopRestaurant> topRestaurants;
  final List<TopCustomer> topCustomers;

  AdminAnalytics({
    required this.totalUsers,
    required this.totalRestaurants,
    required this.totalOrders,
    required this.totalRevenue,
    required this.activeOrders,
    required this.pendingApprovals,
    required this.ordersByStatus,
    required this.revenueByDay,
    required this.topRestaurants,
    required this.topCustomers,
  });
}

class TopRestaurant {
  final String id;
  final String name;
  final int orderCount;
  final double revenue;

  TopRestaurant({
    required this.id,
    required this.name,
    required this.orderCount,
    required this.revenue,
  });
}

class TopCustomer {
  final String id;
  final String name;
  final int orderCount;
  final double totalSpent;

  TopCustomer({
    required this.id,
    required this.name,
    required this.orderCount,
    required this.totalSpent,
  });
}

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String subject;
  final String description;
  final SupportPriority priority;
  final SupportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.assignedTo,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(String id, Map<String, dynamic> json) {
    return SupportTicket(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      priority: SupportPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => SupportPriority.medium,
      ),
      status: SupportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SupportStatus.open,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      assignedTo: json['assignedTo'],
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => SupportMessage.fromJson(msg))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'subject': subject,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}

enum SupportPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  const SupportPriority(this.displayName);
  final String displayName;
}

enum SupportStatus {
  open('Open'),
  inProgress('In Progress'),
  resolved('Resolved'),
  closed('Closed');

  const SupportStatus(this.displayName);
  final String displayName;
}

class SupportMessage {
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromAdmin;

  SupportMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromAdmin,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isFromAdmin: json['isFromAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isFromAdmin': isFromAdmin,
    };
  }
}