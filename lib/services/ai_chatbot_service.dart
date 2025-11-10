import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chatbot.dart';
import '../models/order.dart' as order_model;
import '../models/product.dart';

class AIChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start a new chat session
  Future<String> startChatSession({
    required String userId,
    String? guestId,
    SenderType customerType = SenderType.customer,
    Map<String, dynamic>? initialContext,
  }) async {
    try {
      final session = ChatSession(
        id: '',
        userId: userId,
        guestId: guestId,
        customerType: customerType,
        startTime: DateTime.now(),
        context: initialContext ?? {},
        tags: [],
        messageCount: 0,
        metadata: {},
      );

      final docRef = await _firestore.collection('chatSessions').add(
        session.toJson()
      );

      // Send initial greeting message
      await _sendGreetingMessage(docRef.id, userId);

      return docRef.id;
    } catch (e) {
      debugPrint('Error starting chat session: $e');
      rethrow;
    }
  }

  // Process user message and generate AI response
  Future<ChatMessage> processMessage({
    required String sessionId,
    required String content,
    MessageType type = MessageType.text,
    String? senderId,
  }) async {
    try {
      // Get session details
      final session = await _getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Create user message
      final userMessage = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: content,
        type: type,
        sender: SenderType.customer,
        timestamp: DateTime.now(),
        senderId: senderId,
        metadata: {},
        isRead: false,
        attachments: [],
        confidence: 0.0,
        entities: {},
      );

      // Save user message
      await _firestore
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .add(userMessage.toJson());

      // Update session
      await _updateSessionMessageCount(sessionId, session.messageCount + 1);

      // Process message with AI
      final aiResponse = await _generateAIResponse(session, content);

      // Create and save AI response
      final aiMessage = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: aiResponse['content'] ?? '',
        type: MessageType.values.firstWhere(
          (e) => e.name == (aiResponse['type'] as String? ?? 'text'),
          orElse: () => MessageType.text,
        ),
        sender: SenderType.chatbot,
        timestamp: DateTime.now(),
        metadata: aiResponse['metadata'] ?? {},
        isRead: false,
        attachments: List<String>.from(aiResponse['attachments'] ?? []),
        intent: aiResponse['intent'] != null 
            ? IntentType.values.firstWhere(
                (e) => e.name == aiResponse['intent'],
                orElse: () => IntentType.fallback,
              )
            : null,
        confidence: (aiResponse['confidence'] ?? 0.0).toDouble(),
        entities: Map<String, dynamic>.from(aiResponse['entities'] ?? {}),
      );

      await _firestore
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .add(aiMessage.toJson());

      // Check for escalation conditions
      await _checkEscalationConditions(session, aiResponse, content);

      // Update session context
      await _updateSessionContext(sessionId, aiResponse['entities'] ?? {});

      return userMessage;
    } catch (e) {
      debugPrint('Error processing message: $e');
      rethrow;
    }
  }

  // Get chat history for a session
  Future<List<ChatMessage>> getChatHistory(
    String sessionId, {
    int limit = 50,
    int? offset,
  }) async {
    try {
      Query query = _firestore
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (offset != null && offset > 0) {
        // Note: Firestore Query doesn't have offset method in latest SDK
        // This would need to be implemented with startAfterDocument for proper pagination
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.id, Map<String, dynamic>.from(doc.data() as Map));
      }).toList().reversed.toList();
    } catch (e) {
      debugPrint('Error getting chat history: $e');
      return [];
    }
  }

  // Get active chat sessions for agents
  Future<List<ChatSession>> getActiveSessions({
    String? agentId,
    String? status,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('chatSessions');
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      } else {
        query = query.where('status', whereIn: ['active', 'waiting']);
      }

      if (agentId != null) {
        query = query.where('assignedAgent', isEqualTo: agentId);
      }

      final snapshot = await query
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return ChatSession.fromJson(doc.id, Map<String, dynamic>.from(doc.data() as Map));
      }).toList();
    } catch (e) {
      debugPrint('Error getting active sessions: $e');
      return [];
    }
  }

  // Escalate to human agent
  Future<bool> escalateToAgent({
    required String sessionId,
    required String agentId,
    required String reason,
    String? priority,
  }) async {
    try {
      final session = await _getSession(sessionId);
      if (session == null) return false;

      // Update session status
      await _firestore.collection('chatSessions').doc(sessionId).update({
        'status': 'escalated',
        'assignedAgent': agentId,
        'escalationReason': reason,
        'escalationTime': DateTime.now().millisecondsSinceEpoch,
      });

      // Create agent assignment record
      final assignment = AgentAssignment(
        id: '',
        sessionId: sessionId,
        agentId: agentId,
        agentName: 'Agent', // Would be retrieved from agent database
        agentType: 'chat_agent',
        assignedAt: DateTime.now(),
        status: 'pending',
        skills: {},
      );

      await _firestore.collection('agentAssignments').add(
        assignment.toJson()
      );

      // Send escalation message
      await _sendSystemMessage(
        sessionId,
        'This conversation has been escalated to a human agent. Please wait while they join the conversation.',
      );

      return true;
    } catch (e) {
      debugPrint('Error escalating to agent: $e');
      return false;
    }
  }

  // Search knowledge base
  Future<List<KnowledgeBaseArticle>> searchKnowledgeBase({
    required String query,
    String? category,
    int limit = 5,
  }) async {
    try {
      Query searchQuery = _firestore
          .collection('knowledgeBase')
          .where('isActive', isEqualTo: true);

      // Search in title and content
      searchQuery = searchQuery.where('keywords', arrayContains: query.toLowerCase());

      if (category != null) {
        searchQuery = searchQuery.where('categories', arrayContains: category);
      }

      final snapshot = await searchQuery.limit(limit).get();

      return snapshot.docs.map((doc) {
        return KnowledgeBaseArticle.fromJson(doc.id, Map<String, dynamic>.from(doc.data() as Map));
      }).toList();
    } catch (e) {
      debugPrint('Error searching knowledge base: $e');
      return [];
    }
  }

  // Get chatbot analytics
  Future<Map<String, dynamic>> getChatbotAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? timeRange, // 'hourly', 'daily', 'weekly', 'monthly'
  }) async {
    try {
      Query query = _firestore.collection('chatSessions');
      
      if (startDate != null && endDate != null) {
        query = query
            .where('startTime', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
            .where('startTime', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      }

      final snapshot = await query.get();
      final sessions = snapshot.docs.map((doc) {
        return ChatSession.fromJson(doc.id, Map<String, dynamic>.from(doc.data() as Map));
      }).toList();

      // Calculate metrics
      final metrics = _calculateChatbotMetrics(sessions);

      // Get intent distribution
      final intentSnapshot = await _firestore
          .collection('chatSessions')
          .doc('analytics') // Special analytics document
          .collection('intents')
          .get();

      final intentDistribution = <String, int>{};
      for (final doc in intentSnapshot.docs) {
        intentDistribution[doc.id] = (Map<String, dynamic>.from(doc.data() as Map)['count'] ?? 0) as int;
      }

      return {
        ...metrics,
        'intentDistribution': intentDistribution,
        'totalSessions': sessions.length,
        'dateRange': {
          'start': startDate?.millisecondsSinceEpoch,
          'end': endDate?.millisecondsSinceEpoch,
        },
      };
    } catch (e) {
      debugPrint('Error getting chatbot analytics: $e');
      return {};
    }
  }

  // End chat session
  Future<bool> endChatSession({
    required String sessionId,
    String? status,
    double? satisfactionRating,
    String? feedback,
  }) async {
    try {
      final updateData = {
        'status': status ?? 'resolved',
        'endTime': DateTime.now().millisecondsSinceEpoch,
      };

      if (satisfactionRating != null) {
        updateData['satisfactionRating'] = satisfactionRating;
      }

      if (feedback != null) {
        updateData['feedback'] = feedback;
      }

      await _firestore.collection('chatSessions').doc(sessionId).update(updateData);

      // Send goodbye message
      await _sendSystemMessage(
        sessionId,
        'Thank you for using our customer support! If you have any more questions, feel free to start a new conversation.',
      );

      return true;
    } catch (e) {
      debugPrint('Error ending chat session: $e');
      return false;
    }
  }

  // Private helper methods
  Future<ChatSession?> _getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('chatSessions').doc(sessionId).get();
      if (doc.exists) {
        return ChatSession.fromJson(sessionId, Map<String, dynamic>.from(doc.data() as Map));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting session: $e');
      return null;
    }
  }

  Future<void> _sendGreetingMessage(String sessionId, String userId) async {
    try {
      final message = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: 'Hello! I\'m your AI assistant. How can I help you today?',
        type: MessageType.text,
        sender: SenderType.chatbot,
        timestamp: DateTime.now(),
        metadata: {'isGreeting': true},
        isRead: false,
        attachments: [],
        confidence: 1.0,
        entities: {},
      );

      await _firestore
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .add(message.toJson());
    } catch (e) {
      debugPrint('Error sending greeting message: $e');
    }
  }

  Future<Map<String, dynamic>> _generateAIResponse(
    ChatSession session,
    String userMessage,
  ) async {
    try {
      // Detect intent
      final intent = await _detectIntent(userMessage, session.context);
      
      // Generate response based on intent
      switch (intent['type']) {
        case 'order_inquiry':
          return await _handleOrderInquiry(userMessage, intent['entities']);
        
        case 'menu_inquiry':
          return await _handleMenuInquiry(userMessage, intent['entities']);
        
        case 'delivery_inquiry':
          return await _handleDeliveryInquiry(userMessage, intent['entities']);
        
        case 'payment_inquiry':
          return await _handlePaymentInquiry(userMessage, intent['entities']);
        
        case 'complaint':
          return await _handleComplaint(userMessage, intent['entities']);
        
        case 'compliment':
          return await _handleCompliment(userMessage, intent['entities']);
        
        case 'technical_support':
          return await _handleTechnicalSupport(userMessage, intent['entities']);
        
        case 'recommendation':
          return await _handleRecommendation(userMessage, intent['entities']);
        
        case 'goodbye':
          return {
            'content': 'Thank you for using our service! Have a great day!',
            'type': 'text',
            'intent': 'goodbye',
            'confidence': 0.9,
            'entities': {},
            'metadata': {},
            'attachments': [],
          };
        
        default:
          return await _handleFallback(userMessage, intent);
      }
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      return {
        'content': 'I apologize, but I\'m having trouble understanding your request. Could you please rephrase that?',
        'type': 'text',
        'intent': 'fallback',
        'confidence': 0.5,
        'entities': {},
        'metadata': {},
        'attachments': [],
      };
    }
  }

  Future<Map<String, dynamic>> _detectIntent(
    String message,
    Map<String, dynamic> context,
  ) async {
    // Simple intent detection (in production, this would use ML/NLP)
    final lowercaseMessage = message.toLowerCase();
    
    if (_containsKeywords(lowercaseMessage, ['order', 'my order', 'status'])) {
      return {
        'type': 'order_inquiry',
        'confidence': 0.8,
        'entities': _extractOrderEntities(message),
      };
    }
    
    if (_containsKeywords(lowercaseMessage, ['menu', 'food', 'restaurant'])) {
      return {
        'type': 'menu_inquiry',
        'confidence': 0.7,
        'entities': _extractMenuEntities(message),
      };
    }
    
    if (_containsKeywords(lowercaseMessage, ['delivery', 'shipping', 'arrival'])) {
      return {
        'type': 'delivery_inquiry',
        'confidence': 0.8,
        'entities': _extractDeliveryEntities(message),
      };
    }
    
    if (_containsKeywords(lowercaseMessage, ['payment', 'refund', 'charge'])) {
      return {
        'type': 'payment_inquiry',
        'confidence': 0.8,
        'entities': _extractPaymentEntities(message),
      };
    }
    
    if (_containsKeywords(lowercaseMessage, ['complaint', 'problem', 'issue', 'wrong'])) {
      return {
        'type': 'complaint',
        'confidence': 0.9,
        'entities': _extractComplaintEntities(message),
      };
    }
    
    if (_containsKeywords(lowercaseMessage, ['thank', 'great', 'awesome', 'excellent'])) {
      return {
        'type': 'compliment',
        'confidence': 0.8,
        'entities': {},
      };
    }
    
    if (_containsKeywords(lowercaseMessage, ['recommend', 'suggestion', 'what should'])) {
      return {
        'type': 'recommendation',
        'confidence': 0.7,
        'entities': _extractRecommendationEntities(message),
      };
    }
    
    return {
      'type': 'fallback',
      'confidence': 0.3,
      'entities': {},
    };
  }

  bool _containsKeywords(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  Map<String, dynamic> _extractOrderEntities(String message) {
    // Extract order-related entities
    final entities = <String, dynamic>{};
    
    // Look for order numbers
    final orderNumberRegex = RegExp(r'order\s*#?(\d+)');
    final match = orderNumberRegex.firstMatch(message.toLowerCase());
    if (match != null) {
      entities['order_number'] = match.group(1);
    }
    
    return entities;
  }

  Map<String, dynamic> _extractMenuEntities(String message) {
    return {};
  }

  Map<String, dynamic> _extractDeliveryEntities(String message) {
    return {};
  }

  Map<String, dynamic> _extractPaymentEntities(String message) {
    return {};
  }

  Map<String, dynamic> _extractComplaintEntities(String message) {
    return {};
  }

  Map<String, dynamic> _extractRecommendationEntities(String message) {
    return {};
  }

  // Intent handlers
  Future<Map<String, dynamic>> _handleOrderInquiry(
    String message,
    Map<String, dynamic> entities,
  ) async {
    try {
      if (entities['order_number'] != null) {
        // Get specific order status
        final orderId = entities['order_number'] as String;
        final order = await _getOrderById(orderId);
        
        if (order != null) {
          return {
            'content': 'Your order #${order.id} is currently ${order.status}. Total: \$${order.totalPrice.toStringAsFixed(2)}. Date: ${order.date.toString().split(' ')[0]}.',
            'type': 'text',
            'intent': 'order_inquiry',
            'confidence': 0.9,
            'entities': entities,
            'metadata': {'order_id': order.id},
            'attachments': [],
          };
        } else {
          return {
            'content': 'I couldn\'t find an order with that number. Could you please check the order number or provide more details?',
            'type': 'text',
            'intent': 'order_inquiry',
            'confidence': 0.7,
            'entities': entities,
            'metadata': {},
            'attachments': [],
          };
        }
      } else {
        return {
          'content': 'I can help you with your order! Could you please provide your order number or tell me more about what you\'d like to know?',
          'type': 'text',
          'intent': 'order_inquiry',
          'confidence': 0.6,
          'entities': entities,
          'metadata': {},
          'attachments': [],
        };
      }
    } catch (e) {
      debugPrint('Error handling order inquiry: $e');
      return await _handleFallback(message, {'type': 'order_inquiry'});
    }
  }

  Future<Map<String, dynamic>> _handleMenuInquiry(
    String message,
    Map<String, dynamic> entities,
  ) async {
    // Search knowledge base for menu information
    final articles = await searchKnowledgeBase(
      query: 'menu',
      limit: 3,
    );
    
    if (articles.isNotEmpty) {
      return {
        'content': 'Here\'s some information about our menu: ${articles.first.content}',
        'type': 'text',
        'intent': 'menu_inquiry',
        'confidence': 0.8,
        'entities': entities,
        'metadata': {'knowledge_base_hit': true},
        'attachments': [],
      };
    } else {
      return {
        'content': 'We have a wide variety of delicious options! You can browse our full menu in the app. Is there a specific type of cuisine or dietary preference you\'re looking for?',
        'type': 'text',
        'intent': 'menu_inquiry',
        'confidence': 0.6,
        'entities': entities,
        'metadata': {},
        'attachments': [],
      };
    }
  }

  Future<Map<String, dynamic>> _handleDeliveryInquiry(
    String message,
    Map<String, dynamic> entities,
  ) async {
    return {
      'content': 'Our delivery times typically range from 25-45 minutes depending on your location and order complexity. You can track your order in real-time through the app. Is there a specific issue with your delivery?',
      'type': 'text',
      'intent': 'delivery_inquiry',
      'confidence': 0.7,
      'entities': entities,
      'metadata': {},
      'attachments': [],
    };
  }

  Future<Map<String, dynamic>> _handlePaymentInquiry(
    String message,
    Map<String, dynamic> entities,
  ) async {
    return {
      'content': 'We accept all major credit cards, debit cards, and digital wallets. All payments are processed securely. If you have a specific payment concern, please let me know the details.',
      'type': 'text',
      'intent': 'payment_inquiry',
      'confidence': 0.8,
      'entities': entities,
      'metadata': {},
      'attachments': [],
    };
  }

  Future<Map<String, dynamic>> _handleComplaint(
    String message,
    Map<String, dynamic> entities,
  ) async {
    // Escalate complaints to human agent
    return {
      'content': 'I\'m sorry to hear you\'re having an issue. Let me connect you with one of our human agents who can better assist you with your concern.',
      'type': 'text',
      'intent': 'complaint',
      'confidence': 0.9,
      'entities': entities,
      'metadata': {'escalation_required': true},
      'attachments': [],
    };
  }

  Future<Map<String, dynamic>> _handleCompliment(
    String message,
    Map<String, dynamic> entities,
  ) async {
    return {
      'content': 'Thank you so much for the kind words! We really appreciate your feedback. Is there anything else I can help you with today?',
      'type': 'text',
      'intent': 'compliment',
      'confidence': 0.9,
      'entities': entities,
      'metadata': {},
      'attachments': [],
    };
  }

  Future<Map<String, dynamic>> _handleTechnicalSupport(
    String message,
    Map<String, dynamic> entities,
  ) async {
    return {
      'content': 'I can help you with technical issues. Could you please describe the problem you\'re experiencing in more detail?',
      'type': 'text',
      'intent': 'technical_support',
      'confidence': 0.7,
      'entities': entities,
      'metadata': {},
      'attachments': [],
    };
  }

  Future<Map<String, dynamic>> _handleRecommendation(
    String message,
    Map<String, dynamic> entities,
  ) async {
    return {
      'content': 'I\'d be happy to recommend something for you! Based on popular items, I suggest trying our signature dishes. What type of cuisine are you in the mood for today?',
      'type': 'text',
      'intent': 'recommendation',
      'confidence': 0.7,
      'entities': entities,
      'metadata': {},
      'attachments': [],
    };
  }

  Future<Map<String, dynamic>> _handleFallback(
    String message,
    Map<String, dynamic> intent,
  ) async {
    // Search knowledge base for relevant articles
    final articles = await searchKnowledgeBase(
      query: message,
      limit: 2,
    );
    
    if (articles.isNotEmpty) {
      return {
        'content': 'I found some information that might help: ${articles.first.content}',
        'type': 'text',
        'intent': 'fallback',
        'confidence': 0.5,
        'entities': intent['entities'] ?? {},
        'metadata': {'knowledge_base_hit': true},
        'attachments': [],
      };
    }
    
    return {
      'content': 'I\'m not sure I understand that. Could you please rephrase your question or try asking about: orders, menu, delivery, or payment?',
      'type': 'text',
      'intent': 'fallback',
      'confidence': 0.3,
      'entities': intent['entities'] ?? {},
      'metadata': {},
      'attachments': [],
    };
  }

  Future<void> _checkEscalationConditions(
    ChatSession session,
    Map<String, dynamic> aiResponse,
    String userMessage,
  ) async {
    // Check if escalation is needed
    final shouldEscalate = 
        aiResponse['intent'] == 'complaint' ||
        (aiResponse['confidence'] < 0.4) ||
        session.messageCount > 10; // After 10 messages without resolution
    
    if (shouldEscalate) {
      // Find available human agent
      final availableAgent = await _findAvailableAgent();
      if (availableAgent != null) {
        await escalateToAgent(
          sessionId: session.id,
          agentId: availableAgent,
          reason: aiResponse['intent'] == 'complaint' 
              ? 'Customer complaint' 
              : 'Low confidence or extended conversation',
        );
      }
    }
  }

  Future<String?> _findAvailableAgent() async {
    try {
      // In a real implementation, this would check agent availability
      // For now, return a mock agent ID
      return 'agent_001';
    } catch (e) {
      debugPrint('Error finding available agent: $e');
      return null;
    }
  }

  Future<void> _updateSessionContext(
    String sessionId,
    Map<String, dynamic> entities,
  ) async {
    try {
      await _firestore.collection('chatSessions').doc(sessionId).update({
        'context': FieldValue.arrayUnion([entities]),
      });
    } catch (e) {
      debugPrint('Error updating session context: $e');
    }
  }

  Future<void> _updateSessionMessageCount(String sessionId, int newCount) async {
    try {
      await _firestore.collection('chatSessions').doc(sessionId).update({
        'messageCount': newCount,
      });
    } catch (e) {
      debugPrint('Error updating session message count: $e');
    }
  }

  Future<void> _sendSystemMessage(String sessionId, String content) async {
    try {
      final message = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: content,
        type: MessageType.system,
        sender: SenderType.system,
        timestamp: DateTime.now(),
        metadata: {'isSystem': true},
        isRead: false,
        attachments: [],
        confidence: 1.0,
        entities: {},
      );

      await _firestore
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .add(message.toJson());
    } catch (e) {
      debugPrint('Error sending system message: $e');
    }
  }

  Map<String, dynamic> _calculateChatbotMetrics(List<ChatSession> sessions) {
    final totalSessions = sessions.length;
    final activeSessions = sessions.where((s) => s.isActive).length;
    final resolvedSessions = sessions.where((s) => s.isResolved).length;
    final escalatedSessions = sessions.where((s) => s.isEscalated).length;
    final abandonedSessions = sessions.where((s) => s.status == 'abandoned').length;
    
    final totalDuration = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!.inMinutes)
        .fold<int>(0, (sumValue, minutes) => sumValue + minutes);
    
    final averageSessionDuration = totalSessions > 0
        ? totalDuration / totalSessions
        : 0.0;
    
    final ratedSessions = sessions.where((s) => s.satisfactionRating != null).toList();
    final averageSatisfaction = ratedSessions.isNotEmpty
        ? ratedSessions.map((s) => s.satisfactionRating!).reduce((a, b) => a + b) / ratedSessions.length
        : 0.0;
    
    return {
      'totalSessions': totalSessions,
      'activeSessions': activeSessions,
      'resolvedSessions': resolvedSessions,
      'escalatedSessions': escalatedSessions,
      'abandonedSessions': abandonedSessions,
      'averageSessionDuration': averageSessionDuration,
      'averageSatisfactionRating': averageSatisfaction,
      'resolutionRate': totalSessions > 0 ? (resolvedSessions / totalSessions) * 100 : 0.0,
      'escalationRate': totalSessions > 0 ? (escalatedSessions / totalSessions) * 100 : 0.0,
    };
  }

  Future<order_model.Order?> _getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        
        // Parse product data from the order document
        final productData = data['product'] as Map<String, dynamic>?;
        Product product;
        
        if (productData != null) {
          product = Product(
            id: productData['id'] ?? 'unknown',
            name: productData['name'] ?? 'Unknown Item',
            price: (productData['price'] ?? 0.0).toDouble(),
            categoryId: productData['categoryId'] ?? 'general',
            restaurantId: productData['restaurantId'] ?? 'default_restaurant',
            imageUrl: productData['imageUrl'],
            description: productData['description'],
            rating: (productData['rating'] ?? 0.0).toDouble(),
            reviewCount: productData['reviewCount'] ?? 0,
            isAvailable: productData['isAvailable'] ?? true,
          );
        } else {
          // Fallback if product data is missing
          product = Product(
            id: 'unknown',
            name: 'Unknown Item',
            price: 0.0,
            categoryId: 'general',
            restaurantId: data['restaurantId'] ?? 'default_restaurant',
          );
        }
        
        return order_model.Order(
          id: doc.id,
          product: product,
          quantity: data['quantity'] ?? 1,
          date: DateTime.fromMillisecondsSinceEpoch(
            (data['date'] is int) ? data['date'] : DateTime.now().millisecondsSinceEpoch
          ),
          totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
          status: data['status'] ?? 'pending',
          rating: data['rating']?.toDouble(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }
}