// AI Chatbot Models for 24/7 Customer Support

import 'package:cloud_firestore/cloud_firestore.dart';

// Chat Message Types
enum MessageType {
  text,           // Text message
  image,          // Image attachment
  voice,          // Voice message
  location,       // Location sharing
  menuItem,       // Menu item suggestion
  orderStatus,    // Order status update
  recommendation, // Product recommendation
  payment,        // Payment related
  refund,         // Refund request
  complaint,      // Customer complaint
  compliment,     // Customer compliment
  system          // System message
}

// Sender Types
enum SenderType {
  customer,       // End customer
  chatbot,        // AI chatbot
  humanAgent,     // Human support agent
  restaurant,     // Restaurant staff
  system          // System automated
}

// Chatbot Intent Types
enum IntentType {
  greeting,           // Initial greeting
  orderInquiry,       // Ask about order
  menuInquiry,        // Ask about menu
  priceInquiry,       // Ask about pricing
  deliveryInquiry,    // Ask about delivery
  paymentInquiry,     // Ask about payment
  refundInquiry,      // Ask about refund
  complaint,          // File a complaint
  compliment,         // Give compliment
  technicalSupport,   // Technical help
  accountSupport,     // Account related
  restaurantInquiry,  // Restaurant information
  allergenInquiry,    // Allergen questions
  dietaryInquiry,     // Dietary restrictions
  timeInquiry,        // Operating hours
  locationInquiry,    // Location questions
  recommendation,      // Get recommendations
  feedback,           // Provide feedback
  goodbye,           // End conversation
  fallback           // Unknown intent
}

// Chat Session
class ChatSession {
  final String id;
  final String userId;
  final String? guestId; // For non-logged users
  final SenderType customerType; // customer or guest
  final DateTime startTime;
  final DateTime? endTime;
  final String? status; // 'active', 'waiting', 'resolved', 'escalated', 'abandoned'
  final String? assignedAgent; // Human agent ID if escalated
  final Map<String, dynamic> context; // Conversation context
  final List<String> tags; // Session tags
  final int messageCount;
  final double? satisfactionRating;
  final Map<String, dynamic> metadata;

  ChatSession({
    required this.id,
    required this.userId,
    this.guestId,
    required this.customerType,
    required this.startTime,
    this.endTime,
    this.status,
    this.assignedAgent,
    required this.context,
    required this.tags,
    required this.messageCount,
    this.satisfactionRating,
    required this.metadata,
  });

  factory ChatSession.fromJson(String id, Map<String, dynamic> json) {
    return ChatSession(
      id: id,
      userId: json['userId'] ?? '',
      guestId: json['guestId'],
      customerType: SenderType.values.firstWhere(
        (e) => e.name == json['customerType'],
        orElse: () => SenderType.customer,
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      status: json['status'],
      assignedAgent: json['assignedAgent'],
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      messageCount: json['messageCount'] ?? 0,
      satisfactionRating: json['satisfactionRating']?.toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'guestId': guestId,
      'customerType': customerType.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'status': status,
      'assignedAgent': assignedAgent,
      'context': context,
      'tags': tags,
      'messageCount': messageCount,
      'satisfactionRating': satisfactionRating,
      'metadata': metadata,
    };
  }

  // Get session duration
  Duration? get duration => endTime != null 
      ? endTime!.difference(startTime) 
      : null;
  
  // Check if session is still active
  bool get isActive => status == 'active' || status == 'waiting';
  
  // Check if session is resolved
  bool get isResolved => status == 'resolved';
  
  // Check if escalated to human
  bool get isEscalated => status == 'escalated';
}

// Chat Message
class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final MessageType type;
  final SenderType sender;
  final DateTime timestamp;
  final String? senderId; // ID of sender (user, agent, etc.)
  final Map<String, dynamic> metadata;
  final String? replyToMessageId; // For threading
  final bool isRead;
  final List<String> attachments; // File URLs
  final IntentType? intent; // Detected intent
  final double confidence; // Intent detection confidence
  final Map<String, dynamic> entities; // Extracted entities

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.senderId,
    required this.metadata,
    this.replyToMessageId,
    required this.isRead,
    required this.attachments,
    this.intent,
    required this.confidence,
    required this.entities,
  });

  factory ChatMessage.fromJson(String id, Map<String, dynamic> json) {
    return ChatMessage(
      id: id,
      sessionId: json['sessionId'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      sender: SenderType.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => SenderType.customer,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      senderId: json['senderId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      replyToMessageId: json['replyToMessageId'],
      isRead: json['isRead'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
      intent: json['intent'] != null 
          ? IntentType.values.firstWhere(
              (e) => e.name == json['intent'],
              orElse: () => IntentType.fallback,
            )
          : null,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      entities: Map<String, dynamic>.from(json['entities'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'content': content,
      'type': type.name,
      'sender': sender.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'senderId': senderId,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'isRead': isRead,
      'attachments': attachments,
      'intent': intent?.name,
      'confidence': confidence,
      'entities': entities,
    };
  }
}

// Knowledge Base Article
class KnowledgeBaseArticle {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> categories;
  final String? language;
  final int viewCount;
  final double? rating;
  final List<String> keywords;
  final DateTime lastUpdated;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final String? createdBy;
  final List<String> relatedArticles;

  KnowledgeBaseArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.categories,
    this.language,
    required this.viewCount,
    this.rating,
    required this.keywords,
    required this.lastUpdated,
    required this.isActive,
    required this.metadata,
    this.createdBy,
    required this.relatedArticles,
  });

  factory KnowledgeBaseArticle.fromJson(String id, Map<String, dynamic> json) {
    return KnowledgeBaseArticle(
      id: id,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      language: json['language'],
      viewCount: json['viewCount'] ?? 0,
      rating: json['rating']?.toDouble(),
      keywords: List<String>.from(json['keywords'] ?? []),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      isActive: json['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdBy: json['createdBy'],
      relatedArticles: List<String>.from(json['relatedArticles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'categories': categories,
      'language': language,
      'viewCount': viewCount,
      'rating': rating,
      'keywords': keywords,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isActive': isActive,
      'metadata': metadata,
      'createdBy': createdBy,
      'relatedArticles': relatedArticles,
    };
  }
}

// Chatbot Response Template
class ResponseTemplate {
  final String id;
  final String template;
  final List<String> variables; // Placeholders like {{order_id}}
  final IntentType intent;
  final String? language;
  final double? confidence;
  final List<String> keywords;
  final String? responseType; // 'text', 'quick_replies', 'image', etc.
  final Map<String, dynamic> quickReplies;
  final Map<String, dynamic> metadata;

  ResponseTemplate({
    required this.id,
    required this.template,
    required this.variables,
    required this.intent,
    this.language,
    this.confidence,
    required this.keywords,
    this.responseType,
    required this.quickReplies,
    required this.metadata,
  });

  factory ResponseTemplate.fromJson(String id, Map<String, dynamic> json) {
    return ResponseTemplate(
      id: id,
      template: json['template'] ?? '',
      variables: List<String>.from(json['variables'] ?? []),
      intent: IntentType.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => IntentType.fallback,
      ),
      language: json['language'],
      confidence: json['confidence']?.toDouble(),
      keywords: List<String>.from(json['keywords'] ?? []),
      responseType: json['responseType'],
      quickReplies: Map<String, dynamic>.from(json['quickReplies'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'template': template,
      'variables': variables,
      'intent': intent.name,
      'language': language,
      'confidence': confidence,
      'keywords': keywords,
      'responseType': responseType,
      'quickReplies': quickReplies,
      'metadata': metadata,
    };
  }
}

// AI Chatbot Configuration
class ChatbotConfig {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final String? greetingMessage;
  final String? fallbackMessage;
  final int maxRetries;
  final int escalationTimeout; // Minutes
  final List<String> supportedLanguages;
  final Map<String, dynamic> aiSettings;
  final Map<String, dynamic> integrationSettings;
  final Map<String, dynamic> businessHours;
  final List<String> escalationRules;
  final Map<String, dynamic> metadata;

  ChatbotConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    this.greetingMessage,
    this.fallbackMessage,
    required this.maxRetries,
    required this.escalationTimeout,
    required this.supportedLanguages,
    required this.aiSettings,
    required this.integrationSettings,
    required this.businessHours,
    required this.escalationRules,
    required this.metadata,
  });

  factory ChatbotConfig.fromJson(String id, Map<String, dynamic> json) {
    return ChatbotConfig(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      greetingMessage: json['greetingMessage'],
      fallbackMessage: json['fallbackMessage'],
      maxRetries: json['maxRetries'] ?? 3,
      escalationTimeout: json['escalationTimeout'] ?? 30,
      supportedLanguages: List<String>.from(json['supportedLanguages'] ?? ['en']),
      aiSettings: Map<String, dynamic>.from(json['aiSettings'] ?? {}),
      integrationSettings: Map<String, dynamic>.from(json['integrationSettings'] ?? {}),
      businessHours: Map<String, dynamic>.from(json['businessHours'] ?? {}),
      escalationRules: List<String>.from(json['escalationRules'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'greetingMessage': greetingMessage,
      'fallbackMessage': fallbackMessage,
      'maxRetries': maxRetries,
      'escalationTimeout': escalationTimeout,
      'supportedLanguages': supportedLanguages,
      'aiSettings': aiSettings,
      'integrationSettings': integrationSettings,
      'businessHours': businessHours,
      'escalationRules': escalationRules,
      'metadata': metadata,
    };
  }
}

// Human Agent Assignment
class AgentAssignment {
  final String id;
  final String sessionId;
  final String agentId;
  final String agentName;
  final String agentType; // 'chat_agent', 'phone_agent', 'specialist'
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String status; // 'pending', 'active', 'completed', 'transferred'
  final String? transferReason;
  final Map<String, dynamic> skills;
  final double? rating;

  AgentAssignment({
    required this.id,
    required this.sessionId,
    required this.agentId,
    required this.agentName,
    required this.agentType,
    required this.assignedAt,
    this.startedAt,
    this.endedAt,
    required this.status,
    this.transferReason,
    required this.skills,
    this.rating,
  });

  factory AgentAssignment.fromJson(String id, Map<String, dynamic> json) {
    return AgentAssignment(
      id: id,
      sessionId: json['sessionId'] ?? '',
      agentId: json['agentId'] ?? '',
      agentName: json['agentName'] ?? '',
      agentType: json['agentType'] ?? '',
      assignedAt: DateTime.fromMillisecondsSinceEpoch(json['assignedAt'] ?? 0),
      startedAt: json['startedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endedAt'])
          : null,
      status: json['status'] ?? 'pending',
      transferReason: json['transferReason'],
      skills: Map<String, dynamic>.from(json['skills'] ?? {}),
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'agentId': agentId,
      'agentName': agentName,
      'agentType': agentType,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'status': status,
      'transferReason': transferReason,
      'skills': skills,
      'rating': rating,
    };
  }

  // Get assignment duration
  Duration? get duration => endedAt != null 
      ? endedAt!.difference(assignedAt) 
      : null;
  
  // Check if assignment is still active
  bool get isActive => status == 'active' || status == 'pending';
}

// Analytics and Reporting
class ChatbotAnalytics {
  final String id;
  final DateTime date;
  final String? timeRange; // 'hourly', 'daily', 'weekly', 'monthly'
  final int totalSessions;
  final int activeSessions;
  final int resolvedSessions;
  final int escalatedSessions;
  final int abandonedSessions;
  final double averageResponseTime; // Seconds
  final double averageSessionDuration; // Minutes
  final double resolutionRate; // Percentage
  final double escalationRate; // Percentage
  final double abandonmentRate; // Percentage
  final double averageSatisfactionRating;
  final Map<String, int> intentDistribution;
  final Map<String, int> languageDistribution;
  final Map<String, int> deviceDistribution;
  final Map<String, int> peakHours;
  final List<String> topQuestions;
  final Map<String, double> sentimentAnalysis;
  final Map<String, dynamic> metadata;

  ChatbotAnalytics({
    required this.id,
    required this.date,
    this.timeRange,
    required this.totalSessions,
    required this.activeSessions,
    required this.resolvedSessions,
    required this.escalatedSessions,
    required this.abandonedSessions,
    required this.averageResponseTime,
    required this.averageSessionDuration,
    required this.resolutionRate,
    required this.escalationRate,
    required this.abandonmentRate,
    required this.averageSatisfactionRating,
    required this.intentDistribution,
    required this.languageDistribution,
    required this.deviceDistribution,
    required this.peakHours,
    required this.topQuestions,
    required this.sentimentAnalysis,
    required this.metadata,
  });

  factory ChatbotAnalytics.fromJson(String id, Map<String, dynamic> json) {
    return ChatbotAnalytics(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      timeRange: json['timeRange'],
      totalSessions: json['totalSessions'] ?? 0,
      activeSessions: json['activeSessions'] ?? 0,
      resolvedSessions: json['resolvedSessions'] ?? 0,
      escalatedSessions: json['escalatedSessions'] ?? 0,
      abandonedSessions: json['abandonedSessions'] ?? 0,
      averageResponseTime: (json['averageResponseTime'] ?? 0.0).toDouble(),
      averageSessionDuration: (json['averageSessionDuration'] ?? 0.0).toDouble(),
      resolutionRate: (json['resolutionRate'] ?? 0.0).toDouble(),
      escalationRate: (json['escalationRate'] ?? 0.0).toDouble(),
      abandonmentRate: (json['abandonmentRate'] ?? 0.0).toDouble(),
      averageSatisfactionRating: (json['averageSatisfactionRating'] ?? 0.0).toDouble(),
      intentDistribution: Map<String, int>.from(json['intentDistribution'] ?? {}),
      languageDistribution: Map<String, int>.from(json['languageDistribution'] ?? {}),
      deviceDistribution: Map<String, int>.from(json['deviceDistribution'] ?? {}),
      peakHours: Map<String, int>.from(json['peakHours'] ?? {}),
      topQuestions: List<String>.from(json['topQuestions'] ?? []),
      sentimentAnalysis: Map<String, double>.from(json['sentimentAnalysis'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'timeRange': timeRange,
      'totalSessions': totalSessions,
      'activeSessions': activeSessions,
      'resolvedSessions': resolvedSessions,
      'escalatedSessions': escalatedSessions,
      'abandonedSessions': abandonedSessions,
      'averageResponseTime': averageResponseTime,
      'averageSessionDuration': averageSessionDuration,
      'resolutionRate': resolutionRate,
      'escalationRate': escalationRate,
      'abandonmentRate': abandonmentRate,
      'averageSatisfactionRating': averageSatisfactionRating,
      'intentDistribution': intentDistribution,
      'languageDistribution': languageDistribution,
      'deviceDistribution': deviceDistribution,
      'peakHours': peakHours,
      'topQuestions': topQuestions,
      'sentimentAnalysis': sentimentAnalysis,
      'metadata': metadata,
    };
  }
}