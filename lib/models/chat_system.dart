// In-app Chat System Models

import 'package:cloud_firestore/cloud_firestore.dart';

// Chat Types
enum ChatType {
  direct,        // One-on-one chat
  group,         // Group chat
  support,       // Customer support chat
  restaurant,    // Chat with restaurant
  delivery,      // Chat with delivery partner
  broadcast,     // Broadcast messages
  ai,           // AI chatbot chat
}

// Message Types
enum MessageType {
  text,          // Text message
  image,         // Image message
  file,          // File attachment
  audio,         // Audio message
  video,         // Video message
  location,      // Location share
  contact,       // Contact share
  order,         // Order details
  payment,       // Payment info
  system,        // System message
  sticker,       // Sticker/emoji
  product,       // Product/item share
  recommendation, // AI recommendation
}

// Message Status
enum MessageStatus {
  sending,       // Message being sent
  sent,          // Message sent to server
  delivered,     // Message delivered to recipient
  read,          // Message read by recipient
  failed,        // Message failed to send
  deleted,       // Message deleted
}

// Chat Room Status
enum ChatRoomStatus {
  active,        // Chat is active
  archived,      // Chat is archived
  blocked,       // Chat is blocked
  muted,         // Chat is muted
  pinned,        // Chat is pinned
}

// User Role in Chat
enum ChatUserRole {
  member,        // Regular member
  moderator,     // Chat moderator
  admin,         // Chat admin
  owner,         // Chat owner
  ai,           // AI assistant
  support,      // Support agent
}

// Chat Room
class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<String> participantIds;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final String? lastMessageId;
  final ChatRoomStatus status;
  final String? avatarUrl;
  final Map<String, ChatUserRole> userRoles;
  final Map<String, dynamic> metadata;
  final bool isEncrypted;
  final Map<String, int> unreadCounts; // userId -> unread count
  final Map<String, DateTime> userLastRead; // userId -> last read time
  final Map<String, dynamic> settings; // mute, notifications, etc.

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participantIds,
    this.createdBy,
    required this.createdAt,
    this.lastActivity,
    this.lastMessageId,
    required this.status,
    this.avatarUrl,
    required this.userRoles,
    required this.metadata,
    required this.isEncrypted,
    required this.unreadCounts,
    required this.userLastRead,
    required this.settings,
  });

  factory ChatRoom.fromJson(String id, Map<String, dynamic> json) {
    return ChatRoom(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      type: ChatType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChatType.direct,
      ),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      createdBy: json['createdBy'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      lastActivity: json['lastActivity'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActivity'])
          : null,
      lastMessageId: json['lastMessageId'],
      status: ChatRoomStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ChatRoomStatus.active,
      ),
      avatarUrl: json['avatarUrl'],
      userRoles: Map<String, ChatUserRole>.from(
        (json['userRoles'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            ChatUserRole.values.firstWhere(
              (r) => r.name == value,
              orElse: () => ChatUserRole.member,
            ),
          ),
        ) ?? {},
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isEncrypted: json['isEncrypted'] ?? false,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      userLastRead: Map<String, DateTime>.from(
        (json['userLastRead'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            DateTime.fromMillisecondsSinceEpoch(value),
          ),
        ) ?? {},
      ),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'participantIds': participantIds,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActivity': lastActivity?.millisecondsSinceEpoch,
      'lastMessageId': lastMessageId,
      'status': status.name,
      'avatarUrl': avatarUrl,
      'userRoles': userRoles.map((key, value) => MapEntry(key, value.name)),
      'metadata': metadata,
      'isEncrypted': isEncrypted,
      'unreadCounts': unreadCounts,
      'userLastRead': userLastRead.map((key, value) => MapEntry(key, value.millisecondsSinceEpoch)),
      'settings': settings,
    };
  }

  // Check if user is participant
  bool hasParticipant(String userId) {
    return participantIds.contains(userId);
  }

  // Get user's role
  ChatUserRole getUserRole(String userId) {
    return userRoles[userId] ?? ChatUserRole.member;
  }

  // Check if user can send messages
  bool canSendMessage(String userId) {
    final role = getUserRole(userId);
    return role != ChatUserRole.ai && status == ChatRoomStatus.active;
  }

  // Get unread count for user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  // Check if chat is muted for user
  bool isMutedForUser(String userId) {
    return settings['muted'] == true || 
           (settings['mutedUsers'] as List<String>?)?.contains(userId) == true;
  }

  // Get last read time for user
  DateTime? getLastReadTime(String userId) {
    return userLastRead[userId];
  }

  // Check if chat is recent (active within last 24 hours)
  bool get isRecent {
    if (lastActivity == null) return false;
    return DateTime.now().difference(lastActivity!).inHours < 24;
  }
}

// Chat Message
class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final MessageType type;
  final String content;
  final List<String> attachments; // URLs of attached files
  final DateTime timestamp;
  final MessageStatus status;
  final DateTime? editedAt;
  final String? replyToId; // ID of message being replied to
  final List<String> reactions; // List of reaction emojis
  final Map<String, List<String>> reactionUsers; // emoji -> list of userIds
  final Map<String, dynamic> metadata;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? location; // For location messages
  final String? contactInfo; // For contact messages
  final Map<String, dynamic> orderInfo; // For order messages
  final Map<String, dynamic> paymentInfo; // For payment messages
  final Map<String, dynamic> productInfo; // For product messages
  final List<String> mentions; // Mentioned user IDs
  final String? aiContext; // Context for AI responses

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.type,
    required this.content,
    this.attachments = const [],
    required this.timestamp,
    required this.status,
    this.editedAt,
    this.replyToId,
    this.reactions = const [],
    this.reactionUsers = const {},
    this.metadata = const {},
    this.isDeleted = false,
    this.deletedAt,
    this.location,
    this.contactInfo,
    this.orderInfo = const {},
    this.paymentInfo = const {},
    this.productInfo = const {},
    this.mentions = const [],
    this.aiContext,
  });

  factory ChatMessage.fromJson(String id, Map<String, dynamic> json) {
    return ChatMessage(
      id: id,
      chatRoomId: json['chatRoomId'] ?? '',
      senderId: json['senderId'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sending,
      ),
      editedAt: json['editedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['editedAt'])
          : null,
      replyToId: json['replyToId'],
      reactions: List<String>.from(json['reactions'] ?? []),
      reactionUsers: Map<String, List<String>>.from(
        (json['reactionUsers'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ) ?? {},
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'])
          : null,
      location: json['location'],
      contactInfo: json['contactInfo'],
      orderInfo: Map<String, dynamic>.from(json['orderInfo'] ?? {}),
      paymentInfo: Map<String, dynamic>.from(json['paymentInfo'] ?? {}),
      productInfo: Map<String, dynamic>.from(json['productInfo'] ?? {}),
      mentions: List<String>.from(json['mentions'] ?? []),
      aiContext: json['aiContext'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'type': type.name,
      'content': content,
      'attachments': attachments,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'replyToId': replyToId,
      'reactions': reactions,
      'reactionUsers': reactionUsers.map((key, value) => MapEntry(key, value)),
      'metadata': metadata,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'location': location,
      'contactInfo': contactInfo,
      'orderInfo': orderInfo,
      'paymentInfo': paymentInfo,
      'productInfo': productInfo,
      'mentions': mentions,
      'aiContext': aiContext,
    };
  }

  // Check if message is from current user
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  // Check if message has been read by user
  bool isReadByUser(String userId) {
    // This would need to be checked against read receipts
    return status == MessageStatus.read;
  }

  // Add reaction
  void addReaction(String emoji, String userId) {
    if (!reactions.contains(emoji)) {
      reactions.add(emoji);
    }
    
    if (!reactionUsers.containsKey(emoji)) {
      reactionUsers[emoji] = [];
    }
    
    if (!reactionUsers[emoji]!.contains(userId)) {
      reactionUsers[emoji]!.add(userId);
    }
  }

  // Remove reaction
  void removeReaction(String emoji, String userId) {
    if (reactionUsers.containsKey(emoji)) {
      reactionUsers[emoji]!.remove(userId);
      if (reactionUsers[emoji]!.isEmpty) {
        reactions.remove(emoji);
        reactionUsers.remove(emoji);
      }
    }
  }

  // Check if user reacted with emoji
  bool hasUserReaction(String emoji, String userId) {
    return reactionUsers[emoji]?.contains(userId) == true;
  }

  // Get total reaction count
  int get totalReactions {
    return reactionUsers.values.fold(0, (sum, users) => sum + users.length);
  }

  // Check if message is ephemeral (auto-delete)
  bool get isEphemeral {
    return metadata['deleteAfter'] != null;
  }

  // Check if message should be deleted
  bool get shouldBeDeleted {
    if (!isEphemeral) return false;
    
    final deleteAfter = metadata['deleteAfter'] as int?;
    if (deleteAfter == null) return false;
    
    final expiryTime = timestamp.add(Duration(seconds: deleteAfter));
    return DateTime.now().isAfter(expiryTime);
  }
}

// Chat Participant (User Profile in Chat Context)
class ChatParticipant {
  final String userId;
  final String displayName;
  final String? profilePicture;
  final String? lastSeen;
  final bool isOnline;
  final ChatUserRole role;
  final DateTime joinedAt;
  final bool isTyping;
  final String? typingMessage; // Current typing message
  final Map<String, dynamic> presenceInfo; // online status, device info, etc.

  ChatParticipant({
    required this.userId,
    required this.displayName,
    this.profilePicture,
    this.lastSeen,
    required this.isOnline,
    required this.role,
    required this.joinedAt,
    this.isTyping = false,
    this.typingMessage,
    this.presenceInfo = const {},
  });

  factory ChatParticipant.fromJson(String id, Map<String, dynamic> json) {
    return ChatParticipant(
      userId: id,
      displayName: json['displayName'] ?? '',
      profilePicture: json['profilePicture'],
      lastSeen: json['lastSeen'],
      isOnline: json['isOnline'] ?? false,
      role: ChatUserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatUserRole.member,
      ),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] ?? 0),
      isTyping: json['isTyping'] ?? false,
      typingMessage: json['typingMessage'],
      presenceInfo: Map<String, dynamic>.from(json['presenceInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'profilePicture': profilePicture,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
      'role': role.name,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'isTyping': isTyping,
      'typingMessage': typingMessage,
      'presenceInfo': presenceInfo,
    };
  }

  // Get display status
  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    return 'Last seen $lastSeen';
  }
}

// Typing Indicator
class TypingIndicator {
  final String chatRoomId;
  final String userId;
  final String? partialMessage; // Current typing text
  final DateTime lastActivity;

  TypingIndicator({
    required this.chatRoomId,
    required this.userId,
    this.partialMessage,
    required this.lastActivity,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'userId': userId,
      'partialMessage': partialMessage,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
    };
  }

  factory TypingIndicator.fromJson(String id, Map<String, dynamic> json) {
    return TypingIndicator(
      chatRoomId: json['chatRoomId'] ?? '',
      userId: json['userId'] ?? '',
      partialMessage: json['partialMessage'],
      lastActivity: DateTime.fromMillisecondsSinceEpoch(json['lastActivity'] ?? 0),
    );
  }

  // Check if typing indicator is stale
  bool get isStale {
    return DateTime.now().difference(lastActivity).inSeconds > 10;
  }
}

// Read Receipt
class ReadReceipt {
  final String messageId;
  final String userId;
  final DateTime readAt;

  ReadReceipt({
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'readAt': readAt.millisecondsSinceEpoch,
    };
  }

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      messageId: json['messageId'] ?? '',
      userId: json['userId'] ?? '',
      readAt: DateTime.fromMillisecondsSinceEpoch(json['readAt'] ?? 0),
    );
  }
}

// Chat Notification
class ChatNotification {
  final String id;
  final String userId;
  final String chatRoomId;
  final String messageId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  ChatNotification({
    required this.id,
    required this.userId,
    required this.chatRoomId,
    required this.messageId,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory ChatNotification.fromJson(String id, Map<String, dynamic> json) {
    return ChatNotification(
      id: id,
      userId: json['userId'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      messageId: json['messageId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      isRead: json['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.message,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'chatRoomId': chatRoomId,
      'messageId': messageId,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type.name,
    };
  }
}

enum NotificationType {
  message,
  mention,
  reaction,
  newMember,
  memberLeft,
  adminAction,
  system,
}

// Chat Search Result
class ChatSearchResult {
  final String messageId;
  final String chatRoomId;
  final String content;
  final String senderName;
  final DateTime timestamp;
  final List<String> highlights; // Search term highlights

  ChatSearchResult({
    required this.messageId,
    required this.chatRoomId,
    required this.content,
    required this.senderName,
    required this.timestamp,
    required this.highlights,
  });

  factory ChatSearchResult.fromJson(Map<String, dynamic> json) {
    return ChatSearchResult(
      messageId: json['messageId'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      content: json['content'] ?? '',
      senderName: json['senderName'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      highlights: List<String>.from(json['highlights'] ?? []),
    );
  }
}

// Chat Analytics
class ChatAnalytics {
  final String id;
  final String chatRoomId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalMessages;
  final int uniqueUsers;
  final int activeUsers;
  final Map<String, int> messagesPerUser; // userId -> message count
  final Map<String, int> messagesPerType; // messageType -> count
  final double averageResponseTime; // in minutes
  final int peakHour; // Hour with most activity
  final Map<String, dynamic> engagementMetrics;
  final List<String> topParticipants;
  final Map<String, int> reactionStats;
  final DateTime generatedAt;

  ChatAnalytics({
    required this.id,
    required this.chatRoomId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalMessages,
    required this.uniqueUsers,
    required this.activeUsers,
    required this.messagesPerUser,
    required this.messagesPerType,
    required this.averageResponseTime,
    required this.peakHour,
    required this.engagementMetrics,
    required this.topParticipants,
    required this.reactionStats,
    required this.generatedAt,
  });

  factory ChatAnalytics.fromJson(String id, Map<String, dynamic> json) {
    return ChatAnalytics(
      id: id,
      chatRoomId: json['chatRoomId'] ?? '',
      periodStart: DateTime.fromMillisecondsSinceEpoch(json['periodStart'] ?? 0),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(json['periodEnd'] ?? 0),
      totalMessages: json['totalMessages'] ?? 0,
      uniqueUsers: json['uniqueUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      messagesPerUser: Map<String, int>.from(json['messagesPerUser'] ?? {}),
      messagesPerType: Map<String, int>.from(json['messagesPerType'] ?? {}),
      averageResponseTime: (json['averageResponseTime'] ?? 0.0).toDouble(),
      peakHour: json['peakHour'] ?? 0,
      engagementMetrics: Map<String, dynamic>.from(json['engagementMetrics'] ?? {}),
      topParticipants: List<String>.from(json['topParticipants'] ?? []),
      reactionStats: Map<String, int>.from(json['reactionStats'] ?? {}),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(json['generatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'periodStart': periodStart.millisecondsSinceEpoch,
      'periodEnd': periodEnd.millisecondsSinceEpoch,
      'totalMessages': totalMessages,
      'uniqueUsers': uniqueUsers,
      'activeUsers': activeUsers,
      'messagesPerUser': messagesPerUser,
      'messagesPerType': messagesPerType,
      'averageResponseTime': averageResponseTime,
      'peakHour': peakHour,
      'engagementMetrics': engagementMetrics,
      'topParticipants': topParticipants,
      'reactionStats': reactionStats,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  // Get most active user
  String get mostActiveUser {
    if (messagesPerUser.isEmpty) return 'Unknown';
    return messagesPerUser.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get most popular message type
  String get mostPopularMessageType {
    if (messagesPerType.isEmpty) return 'text';
    return messagesPerType.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}