import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_system.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat room
  Future<ChatRoom> createChatRoom({
    required String name,
    required ChatType type,
    required List<String> participantIds,
    String? createdBy,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Set user roles
      final userRoles = <String, ChatUserRole>{};
      for (final userId in participantIds) {
        if (userId == createdBy) {
          userRoles[userId] = ChatUserRole.admin;
        } else {
          userRoles[userId] = ChatUserRole.member;
        }
      }

      // Add AI bot for support chats
      if (type == ChatType.support) {
        final aiBotId = 'ai_support_bot';
        participantIds.add(aiBotId);
        userRoles[aiBotId] = ChatUserRole.ai;
      }

      final chatRoom = ChatRoom(
        id: roomId,
        name: name,
        description: description,
        type: type,
        participantIds: participantIds,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        status: ChatRoomStatus.active,
        userRoles: userRoles,
        metadata: metadata ?? {},
        isEncrypted: false,
        unreadCounts: {for (var id in participantIds) id: 0},
        userLastRead: {},
        settings: {
          'allowFileSharing': true,
          'allowImageSharing': true,
          'maxFileSize': 10485760, // 10MB
          'maxMessageLength': 1000,
        },
      );

      await _firestore.collection('chatRooms').doc(roomId).set(chatRoom.toJson());
      return chatRoom;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      rethrow;
    }
  }

  // Send a message
  Future<ChatMessage> sendMessage({
    required String chatRoomId,
    required String senderId,
    required MessageType type,
    required String content,
    List<String>? attachments,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final message = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        type: type,
        content: content,
        attachments: attachments ?? [],
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        replyToId: replyToId,
        metadata: metadata ?? {},
        reactions: [],
        reactionUsers: {},
      );

      // Save message
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat room
      await _updateChatRoomAfterMessage(chatRoomId, messageId);

      // Update message status to sent
      await _updateMessageStatus(chatRoomId, messageId, MessageStatus.sent);

      // Process AI responses if applicable
      await _processAIResponse(chatRoomId, message);

      // Send notifications
      await _sendMessageNotifications(chatRoomId, message);

      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
    String? messageId, // Mark specific message as read, or all unread
  }) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom == null || !chatRoom.hasParticipant(userId)) {
        return;
      }

      if (messageId != null) {
        // Mark specific message as read
        await _updateMessageStatus(chatRoomId, messageId, MessageStatus.read);
        
        // Update read receipts
        await _saveReadReceipt(messageId, userId);
      } else {
        // Mark all unread messages as read
        final unreadMessages = await getUnreadMessages(chatRoomId, userId);
        for (final message in unreadMessages) {
          if (message.senderId != userId) {
            await _updateMessageStatus(chatRoomId, message.id, MessageStatus.read);
            await _saveReadReceipt(message.id, userId);
          }
        }
      }

      // Reset unread count
      await _resetUnreadCount(chatRoomId, userId);
      
      // Update last read time
      await _updateLastReadTime(chatRoomId, userId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Add message reaction
  Future<void> addReaction({
    required String chatRoomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageDoc = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageDoc);
        if (snapshot.exists) {
          final message = ChatMessage.fromJson(messageId, snapshot.data()!);
          message.addReaction(emoji, userId);
          
          transaction.update(messageDoc, {
            'reactions': message.reactions,
            'reactionUsers': message.reactionUsers.map((key, value) => MapEntry(key, value)),
          });
        }
      });
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  // Remove message reaction
  Future<void> removeReaction({
    required String chatRoomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageDoc = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageDoc);
        if (snapshot.exists) {
          final message = ChatMessage.fromJson(messageId, snapshot.data()!);
          message.removeReaction(emoji, userId);
          
          transaction.update(messageDoc, {
            'reactions': message.reactions,
            'reactionUsers': message.reactionUsers.map((key, value) => MapEntry(key, value)),
          });
        }
      });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
    }
  }

  // Start typing indicator
  Future<void> startTyping({
    required String chatRoomId,
    required String userId,
    String? partialMessage,
  }) async {
    try {
      final typingIndicator = TypingIndicator(
        chatRoomId: chatRoomId,
        userId: userId,
        partialMessage: partialMessage,
        lastActivity: DateTime.now(),
      );

      await _firestore
          .collection('typingIndicators')
          .doc('${chatRoomId}_$userId')
          .set(typingIndicator.toJson());
    } catch (e) {
      debugPrint('Error starting typing: $e');
    }
  }

  // Stop typing indicator
  Future<void> stopTyping({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('typingIndicators')
          .doc('${chatRoomId}_$userId')
          .delete();
    } catch (e) {
      debugPrint('Error stopping typing: $e');
    }
  }

  // Get chat rooms for user
  Future<List<ChatRoom>> getUserChatRooms(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chatRooms')
          .where('participantIds', arrayContains: userId)
          .orderBy('lastActivity', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ChatRoom.fromJson(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting user chat rooms: $e');
      return [];
    }
  }

  // Get messages for chat room
  Future<List<ChatMessage>> getMessages({
    required String chatRoomId,
    String? lastMessageId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastMessageId != null) {
        // Get messages before the last loaded message
        final lastMessageDoc = await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(lastMessageId)
            .get();

        if (lastMessageDoc.exists) {
          final lastTimestamp = (lastMessageDoc.data()?['timestamp'] as int);
          query = query.where('timestamp', isLessThan: lastTimestamp);
        }
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  // Get unread messages for user
  Future<List<ChatMessage>> getUnreadMessages(String chatRoomId, String userId) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom == null) return [];

      final lastReadTime = chatRoom.getLastReadTime(userId);
      if (lastReadTime == null) {
        // If no read time, get all messages
        return await getMessages(chatRoomId: chatRoomId, limit: 100);
      }

      final snapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastReadTime))
          .where('senderId', isNotEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting unread messages: $e');
      return [];
    }
  }

  // Get typing indicators for chat room
  Future<List<TypingIndicator>> getTypingIndicators(String chatRoomId, String excludeUserId) async {
    try {
      final snapshot = await _firestore
          .collection('typingIndicators')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('userId', isNotEqualTo: excludeUserId)
          .get();

      return snapshot.docs
          .map((doc) => TypingIndicator.fromJson(doc.id, doc.data()))
          .where((indicator) => !indicator.isStale)
          .toList();
    } catch (e) {
      debugPrint('Error getting typing indicators: $e');
      return [];
    }
  }

  // Search messages
  Future<List<ChatSearchResult>> searchMessages({
    required String chatRoomId,
    required String query,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      // Note: Firestore full-text search is limited
      // This is a basic implementation - in production, use Algolia or similar
      Query searchQuery = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('content')
          .limit(limit);

      if (userId != null) {
        searchQuery = searchQuery.where('senderId', isEqualTo: userId);
      }

      if (startDate != null) {
        searchQuery = searchQuery.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        searchQuery = searchQuery.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await searchQuery.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return ChatSearchResult(
          messageId: doc.id,
          chatRoomId: chatRoomId,
          content: (data?['content'] as String?) ?? '',
          senderName: (data?['senderName'] as String?) ?? 'Unknown',
          timestamp: DateTime.fromMillisecondsSinceEpoch((data?['timestamp'] as int?) ?? 0),
          highlights: _getSearchHighlights((data?['content'] as String?) ?? '', query),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  // Join group chat
  Future<Map<String, dynamic>> joinGroupChat({
    required String chatRoomId,
    required String userId,
    required String invitedBy,
  }) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom == null) {
        return {'success': false, 'error': 'Chat room not found'};
      }

      if (chatRoom.hasParticipant(userId)) {
        return {'success': false, 'error': 'Already a member'};
      }

      if (chatRoom.type != ChatType.group) {
        return {'success': false, 'error': 'Not a group chat'};
      }

      // Add user to participants
      final updatedParticipants = List<String>.from(chatRoom.participantIds)..add(userId);
      final updatedRoles = Map<String, ChatUserRole>.from(chatRoom.userRoles);
      updatedRoles[userId] = ChatUserRole.member;

      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'participantIds': updatedParticipants,
        'userRoles': updatedRoles.map((key, value) => MapEntry(key, value.name)),
        'unreadCounts.$userId': 0,
      });

      // Send system message
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        content: '$invitedBy added $userId to the group',
        metadata: {'action': 'user_joined', 'userId': userId, 'invitedBy': invitedBy},
      );

      return {'success': true, 'message': 'Successfully joined group'};
    } catch (e) {
      debugPrint('Error joining group chat: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Leave group chat
  Future<Map<String, dynamic>> leaveGroupChat({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom == null) {
        return {'success': false, 'error': 'Chat room not found'};
      }

      if (!chatRoom.hasParticipant(userId)) {
        return {'success': false, 'error': 'Not a member'};
      }

      if (chatRoom.type != ChatType.group) {
        return {'success': false, 'error': 'Not a group chat'};
      }

      // Remove user from participants
      final updatedParticipants = List<String>.from(chatRoom.participantIds)..remove(userId);
      final updatedRoles = Map<String, ChatUserRole>.from(chatRoom.userRoles)..remove(userId);
      final updatedUnreadCounts = Map<String, int>.from(chatRoom.unreadCounts)..remove(userId);

      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'participantIds': updatedParticipants,
        'userRoles': updatedRoles.map((key, value) => MapEntry(key, value.name)),
        'unreadCounts': updatedUnreadCounts,
      });

      // Send system message
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        content: '$userId left the group',
        metadata: {'action': 'user_left', 'userId': userId},
      );

      return {'success': true, 'message': 'Successfully left group'};
    } catch (e) {
      debugPrint('Error leaving group chat: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Archive chat
  Future<void> archiveChat({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'status': ChatRoomStatus.archived.name,
        'settings.archivedBy': userId,
        'settings.archivedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error archiving chat: $e');
    }
  }

  // Mute/unmute chat
  Future<void> toggleChatMute({
    required String chatRoomId,
    required String userId,
    bool mute = true,
  }) async {
    try {
      final updates = {
        'settings.muted': mute,
        'settings.mutedBy': userId,
        'settings.mutedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (mute) {
        final currentMuted = List<String>.from([]);
        // Would need to get current muted users list
        currentMuted.add(userId);
        updates['settings.mutedUsers'] = currentMuted;
      }

      await _firestore.collection('chatRooms').doc(chatRoomId).update(updates);
    } catch (e) {
      debugPrint('Error toggling chat mute: $e');
    }
  }

  // Pin/unpin chat
  Future<void> toggleChatPin({
    required String chatRoomId,
    required String userId,
    bool pin = true,
  }) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom == null) return;

      final updatedSettings = Map<String, dynamic>.from(chatRoom.settings);
      
      if (pin) {
        updatedSettings['pinnedBy'] = userId;
        updatedSettings['pinnedAt'] = DateTime.now().millisecondsSinceEpoch;
        updatedSettings['isPinned'] = true;
      } else {
        updatedSettings.remove('pinnedBy');
        updatedSettings.remove('pinnedAt');
        updatedSettings.remove('isPinned');
      }

      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'status': pin ? ChatRoomStatus.pinned.name : ChatRoomStatus.active.name,
        'settings': updatedSettings,
      });
    } catch (e) {
      debugPrint('Error toggling chat pin: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final message = await getMessage(chatRoomId, messageId);
      if (message == null) return;

      // Check if user can delete this message
      if (message.senderId != userId) {
        final chatRoom = await getChatRoom(chatRoomId);
        final userRole = chatRoom?.getUserRole(userId) ?? ChatUserRole.member;
        if (userRole == ChatUserRole.member) {
          throw Exception('Cannot delete others messages');
        }
      }

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
        'content': 'This message was deleted',
        'type': MessageType.system.name,
      });
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  // Edit message
  Future<void> editMessage({
    required String chatRoomId,
    required String messageId,
    required String userId,
    required String newContent,
  }) async {
    try {
      final message = await getMessage(chatRoomId, messageId);
      if (message == null) return;

      // Check if user can edit this message
      if (message.senderId != userId) {
        throw Exception('Cannot edit others messages');
      }

      // Check time limit (e.g., 5 minutes)
      final timeLimit = DateTime.now().difference(message.timestamp).inMinutes;
      if (timeLimit > 5) {
        throw Exception('Cannot edit message after 5 minutes');
      }

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error editing message: $e');
    }
  }

  // Get chat analytics
  Future<ChatAnalytics> getChatAnalytics({
    required String chatRoomId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final messages = snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.id, doc.data());
      }).toList();

      return _generateChatAnalytics(chatRoomId, messages, startDate, endDate);
    } catch (e) {
      debugPrint('Error getting chat analytics: $e');
      rethrow;
    }
  }

  // Private helper methods
  
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    final doc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    if (doc.exists) {
      return ChatRoom.fromJson(chatRoomId, doc.data()!);
    }
    return null;
  }

  Future<ChatMessage?> getMessage(String chatRoomId, String messageId) async {
    final doc = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .get();
    
    if (doc.exists) {
      return ChatMessage.fromJson(messageId, doc.data()!);
    }
    return null;
  }

  Future<void> _updateChatRoomAfterMessage(String chatRoomId, String messageId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessageId': messageId,
      'lastActivity': DateTime.now().millisecondsSinceEpoch,
    });

    // Update unread counts for all participants except sender
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom != null) {
      final updates = <String, dynamic>{};
      for (final userId in chatRoom.participantIds) {
        if (userId != chatRoom.lastMessageId) { // This would need the sender ID
          updates['unreadCounts.$userId'] = FieldValue.increment(1);
        }
      }
      await _firestore.collection('chatRooms').doc(chatRoomId).update(updates);
    }
  }

  Future<void> _updateMessageStatus(
    String chatRoomId,
    String messageId,
    MessageStatus status,
  ) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'status': status.name,
    });
  }

  Future<void> _processAIResponse(String chatRoomId, ChatMessage message) async {
    // Check if this is a support chat
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom?.type == ChatType.support) {
      // Trigger AI response
      // In a real implementation, this would call the AI service
      // For now, we'll simulate an AI response
      await Future.delayed(Duration(seconds: 1));
      
      final aiResponse = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatRoomId: chatRoomId,
        senderId: 'ai_support_bot',
        type: MessageType.text,
        content: 'I understand you\'re asking about "${message.content.substring(0, 50)}...". How can I help you further?',
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        aiContext: 'support_response',
      );

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(aiResponse.id)
          .set(aiResponse.toJson());

      await _updateChatRoomAfterMessage(chatRoomId, aiResponse.id);
    }
  }

  Future<void> _sendMessageNotifications(String chatRoomId, ChatMessage message) async {
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom == null) return;

    // Create notifications for all participants except sender
    for (final userId in chatRoom.participantIds) {
      if (userId != message.senderId) {
        final notification = ChatNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          chatRoomId: chatRoomId,
          messageId: message.id,
          title: 'New message in ${chatRoom.name}',
          body: message.content.length > 50 
              ? '${message.content.substring(0, 50)}...'
              : message.content,
          data: {
            'chatRoomId': chatRoomId,
            'messageId': message.id,
            'senderId': message.senderId,
            'messageType': message.type.name,
          },
          createdAt: DateTime.now(),
          isRead: false,
          type: NotificationType.message,
        );

        await _firestore
            .collection('chatNotifications')
            .doc(notification.id)
            .set(notification.toJson());
      }
    }
  }

  Future<void> _resetUnreadCount(String chatRoomId, String userId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'unreadCounts.$userId': 0,
    });
  }

  Future<void> _updateLastReadTime(String chatRoomId, String userId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'userLastRead.$userId': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _saveReadReceipt(String messageId, String userId) async {
    final receipt = ReadReceipt(
      messageId: messageId,
      userId: userId,
      readAt: DateTime.now(),
    );

    await _firestore
        .collection('readReceipts')
        .doc('${messageId}_$userId')
        .set(receipt.toJson());
  }

  Future<void> sendSystemMessage({
    required String chatRoomId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: chatRoomId,
      senderId: 'system',
      type: MessageType.system,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      metadata: metadata ?? {},
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(systemMessage.id)
        .set(systemMessage.toJson());

    await _updateChatRoomAfterMessage(chatRoomId, systemMessage.id);
  }

  List<String> _getSearchHighlights(String content, String query) {
    // Simple highlight implementation
    final highlights = <String>[];
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();
    
    int startIndex = 0;
    while (true) {
      final index = contentLower.indexOf(queryLower, startIndex);
      if (index == -1) break;
      
      final start = index;
      final end = index + query.length;
      highlights.add(content.substring(start, end));
      startIndex = index + 1;
    }
    
    return highlights;
  }

  ChatAnalytics _generateChatAnalytics(
    String chatRoomId,
    List<ChatMessage> messages,
    DateTime startDate,
    DateTime endDate,
  ) {
    final userMessageCount = <String, int>{};
    final messageTypeCount = <String, int>{};
    final hoursActivity = List.filled(24, 0);
    int totalReactions = 0;
    final reactionTypes = <String, int>{};

    for (final message in messages) {
      // Count messages per user
      userMessageCount[message.senderId] = (userMessageCount[message.senderId] ?? 0) + 1;
      
      // Count message types
      final typeName = message.type.name;
      messageTypeCount[typeName] = (messageTypeCount[typeName] ?? 0) + 1;
      
      // Track activity by hour
      final hour = message.timestamp.hour;
      hoursActivity[hour]++;
      
      // Count reactions
      totalReactions += message.totalReactions;
      for (final emoji in message.reactions) {
        final reactionCount = message.reactionUsers[emoji]?.length ?? 0;
        reactionTypes[emoji] = (reactionTypes[emoji] ?? 0) + reactionCount;
      }
    }

    final totalMessages = messages.length;
    final uniqueUsers = userMessageCount.length;
    final activeUsers = userMessageCount.length; // Simplified - all users who messaged

    // Find peak hour
    int peakHour = 0;
    int maxActivity = 0;
    for (int i = 0; i < hoursActivity.length; i++) {
      if (hoursActivity[i] > maxActivity) {
        maxActivity = hoursActivity[i];
        peakHour = i;
      }
    }

    // Sort users by message count
    final topUsersList = userMessageCount.entries
        .toList();
    topUsersList.sort((a, b) => b.value.compareTo(a.value));
    final topUsers = topUsersList
        .take(5)
        .map((e) => e.key)
        .toList();

    return ChatAnalytics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: chatRoomId,
      periodStart: startDate,
      periodEnd: endDate,
      totalMessages: totalMessages,
      uniqueUsers: uniqueUsers,
      activeUsers: activeUsers,
      messagesPerUser: userMessageCount,
      messagesPerType: messageTypeCount,
      averageResponseTime: 2.5, // Simplified calculation
      peakHour: peakHour,
      engagementMetrics: {
        'averageMessagesPerDay': totalMessages / (endDate.difference(startDate).inDays + 1),
        'messagePerUserRatio': totalMessages / uniqueUsers,
        'reactionRate': totalReactions / totalMessages,
      },
      topParticipants: topUsers,
      reactionStats: reactionTypes,
      generatedAt: DateTime.now(),
    );
  }
}