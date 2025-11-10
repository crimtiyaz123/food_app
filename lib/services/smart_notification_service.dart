import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/notification_preferences.dart';
import '../models/user_preferences.dart';
import 'ai_recommendation_service.dart';

class SmartNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIRecommendationService _recommendationService = AIRecommendationService();

  // Send personalized notification based on AI analysis
  Future<void> sendPersonalizedNotification(String userId, NotificationType type) async {
    try {
      // Get user preferences and behavior data
      final preferences = await _getUserPreferences(userId);
      final userBehavior = await _analyzeUserBehavior(userId);
      final context = await _getContextualData(userId);
      
      // Generate AI-powered notification content
      final notification = await _generateAINotification(
        userId: userId,
        type: type,
        preferences: preferences,
        userBehavior: userBehavior,
        context: context,
      );
      
      if (notification != null && _shouldSendNotification(notification, preferences)) {
        // Schedule and send notification
        await _sendNotification(notification);
        await _updateUserEngagementScore(userId, notification);
      }
    } catch (e) {
      debugPrint('Error sending personalized notification: $e');
    }
  }

  // Send contextual recommendations
  Future<void> sendContextualRecommendations(String userId) async {
    try {
      final preferences = await _getUserPreferences(userId);
      if (!preferences.recommendationAlerts) return;
      
      final recommendations = await _recommendationService.getContextualRecommendations(
        userId: userId,
        timeOfDay: _getTimeOfDay(),
        limit: 3,
      );
      
      if (recommendations.isNotEmpty) {
        final message = _formatRecommendationMessage(recommendations);
        final notification = SmartNotification(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: NotificationType.recommendation,
          priority: NotificationPriority.normal,
          title: 'Recommended for you',
          message: message,
          data: {'recommendations': recommendations.map((p) => p.toJson()).toList()},
          actionButtons: ['Order Now', 'Save for Later'],
          scheduledTime: DateTime.now(),
          channel: NotificationChannel.push,
          status: NotificationStatus.pending,
          createdAt: DateTime.now(),
          aiMetadata: {
            'aiGenerated': true,
            'contextual': true,
            'personalized': true,
            'confidence': 0.85,
          },
        );
        
        await _sendNotification(notification);
      }
    } catch (e) {
      debugPrint('Error sending contextual recommendations: $e');
    }
  }

  // Send reorder suggestions
  Future<void> sendReorderSuggestion(String userId, String orderId) async {
    try {
      final preferences = await _getUserPreferences(userId);
      if (!preferences.reorderSuggestions) return;
      
      // Get previous order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final orderData = orderDoc.data()!;
      final productName = orderData['product']['name'] ?? 'your favorite item';
      final restaurantName = orderData['restaurantName'] ?? 'restaurant';
      final orderDate = (orderData['orderDate'] as Timestamp).toDate();
      
      // Check if it's been a reasonable time since last order
      final daysSinceLastOrder = DateTime.now().difference(orderDate).inDays;
      if (daysSinceLastOrder < 3 || daysSinceLastOrder > 30) return;
      
      final message = 'Ready for another ${productName} from ${restaurantName}? It\'s been ${daysSinceLastOrder} days since your last order.';
      
      final notification = SmartNotification(
        id: 'reorder_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: NotificationType.reorder,
        priority: NotificationPriority.normal,
        title: 'Time to reorder?',
        message: message,
        data: {
          'previousOrderId': orderId,
          'productName': productName,
          'restaurantName': restaurantName,
          'daysSinceLastOrder': daysSinceLastOrder,
        },
        actionButtons: ['Reorder Now', 'Browse Menu'],
        scheduledTime: _convertTimeOfDayToDateTime(_getOptimalSendTime(preferences)),
        channel: NotificationChannel.push,
        status: NotificationStatus.pending,
        createdAt: DateTime.now(),
        aiMetadata: {
          'reorderProbability': _calculateReorderProbability(daysSinceLastOrder, userId),
          'timeBased': true,
        },
      );
      
      await _sendNotification(notification);
    } catch (e) {
      debugPrint('Error sending reorder suggestion: $e');
    }
  }

  // Send weather-based recommendations
  Future<void> sendWeatherBasedRecommendations(String userId) async {
    try {
      final preferences = await _getUserPreferences(userId);
      if (!preferences.weatherBasedAlerts) return;
      
      // Mock weather data - in real implementation, would fetch from weather API
      final weather = _getMockWeatherData();
      final recommendations = _getWeatherBasedRecommendations(weather);
      
      if (recommendations.isNotEmpty) {
        final message = _formatWeatherMessage(weather, recommendations.first);
        
        final notification = SmartNotification(
          id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: NotificationType.weatherBased,
          priority: NotificationPriority.normal,
          title: 'Weather-perfect food',
          message: message,
          data: {
            'weather': weather,
            'recommendations': recommendations,
          },
          actionButtons: ['Order Now', 'View Recommendations'],
          scheduledTime: DateTime.now(),
          channel: NotificationChannel.push,
          status: NotificationStatus.pending,
          createdAt: DateTime.now(),
          aiMetadata: {
            'weatherBased': true,
            'weatherCondition': weather['condition'],
            'temperature': weather['temperature'],
          },
        );
        
        await _sendNotification(notification);
      }
    } catch (e) {
      debugPrint('Error sending weather-based recommendations: $e');
    }
  }

  // Send loyalty rewards
  Future<void> sendLoyaltyReward(String userId) async {
    try {
      // Get user loyalty data
      final loyaltyData = await _getUserLoyaltyData(userId);
      final preferences = await _getUserPreferences(userId);
      
      if (loyaltyData['points'] >= 100 && preferences.loyaltyAlerts) {
        final rewardMessage = 'Congratulations! You have ${loyaltyData['points']} loyalty points. Redeem them for a free meal!';
        
        final notification = SmartNotification(
          id: 'loyalty_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: NotificationType.loyaltyReward,
          priority: NotificationPriority.high,
          title: 'Loyalty Reward Available',
          message: rewardMessage,
          data: {
            'points': loyaltyData['points'],
            'rewardValue': loyaltyData['points'] * 0.1,
            'eligibleRewards': loyaltyData['eligibleRewards'],
          },
          actionButtons: ['Redeem Now', 'View Rewards'],
          scheduledTime: _convertTimeOfDayToDateTime(_getOptimalSendTime(preferences)),
          channel: NotificationChannel.push,
          status: NotificationStatus.pending,
          createdAt: DateTime.now(),
          aiMetadata: {
            'loyaltyTier': loyaltyData['tier'],
            'engagementScore': preferences.engagementScore,
            'rewardType': 'points_redemption',
          },
        );
        
        await _sendNotification(notification);
      }
    } catch (e) {
      debugPrint('Error sending loyalty reward: $e');
    }
  }

  // Send abandoned cart reminder
  Future<void> sendAbandonedCartReminder(String userId) async {
    try {
      final preferences = await _getUserPreferences(userId);
      if (!preferences.cartAbandonmentAlerts) return;
      
      // Check for abandoned carts
      final abandonedCarts = await _getAbandonedCarts(userId);
      
      for (final cart in abandonedCarts) {
        final hoursAgo = DateTime.now().difference(cart['createdAt']).inHours;
        if (hoursAgo >= 1 && hoursAgo <= 24) { // Send reminder between 1-24 hours
          
          final message = 'Don\'t forget your ${cart['itemCount']} items in your cart. Complete your order now!';
          
          final notification = SmartNotification(
            id: 'cart_${cart['id']}',
            userId: userId,
            type: NotificationType.promotion,
            priority: NotificationPriority.normal,
            title: 'Complete your order',
            message: message,
            data: {
              'cartId': cart['id'],
              'totalAmount': cart['totalAmount'],
              'itemCount': cart['itemCount'],
              'hoursAgo': hoursAgo,
            },
            actionButtons: ['Complete Order', 'View Cart'],
            scheduledTime: DateTime.now(),
            channel: NotificationChannel.push,
            status: NotificationStatus.pending,
            createdAt: DateTime.now(),
            aiMetadata: {
              'conversionProbability': _calculateCartConversionProbability(cart, userId),
              'urgency': hoursAgo > 6 ? 'medium' : 'low',
            },
          );
          
          await _sendNotification(notification);
        }
      }
    } catch (e) {
      debugPrint('Error sending abandoned cart reminder: $e');
    }
  }

  // Analyze user behavior for AI insights
  Future<Map<String, dynamic>> _analyzeUserBehavior(String userId) async {
    try {
      // Get recent orders (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('orderDate', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      final orders = ordersSnapshot.docs.map((doc) => doc.data()).toList();
      
      // Analyze patterns
      final analysis = <String, dynamic>{
        'totalOrders': orders.length,
        'averageOrderValue': orders.isNotEmpty 
            ? orders.fold<double>(0.0, (sum, order) => sum + (order['totalPrice'] ?? 0.0)) / orders.length 
            : 0.0,
        'favoriteCategories': _analyzeFavoriteCategories(orders),
        'orderTimes': _analyzeOrderTimes(orders),
        'dayPreferences': _analyzeDayPreferences(orders),
        'engagementScore': _calculateEngagementScore(orders),
        'lastOrderDate': orders.isNotEmpty 
            ? orders.map((o) => (o['orderDate'] as Timestamp).toDate()).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
        'orderFrequency': orders.length / 30.0, // orders per day
      };
      
      return analysis;
    } catch (e) {
      debugPrint('Error analyzing user behavior: $e');
      return {};
    }
  }

  // Generate AI-powered notification content
  Future<SmartNotification?> _generateAINotification({
    required String userId,
    required NotificationType type,
    required NotificationPreferences preferences,
    required Map<String, dynamic> userBehavior,
    required Map<String, dynamic> context,
  }) async {
    try {
      switch (type) {
        case NotificationType.recommendation:
          return await _generateRecommendationNotification(userId, preferences, userBehavior);
        case NotificationType.promotion:
          return await _generatePromotionNotification(userId, preferences, userBehavior, context);
        case NotificationType.loyaltyReward:
          return await _generateLoyaltyNotification(userId, preferences, userBehavior);
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error generating AI notification: $e');
      return null;
    }
  }

  // Generate recommendation notification
  Future<SmartNotification> _generateRecommendationNotification(
    String userId,
    NotificationPreferences preferences,
    Map<String, dynamic> userBehavior,
  ) async {
    final recommendations = await _recommendationService.getPersonalizedRecommendations(
      userId: userId,
      limit: 3,
    );
    
    final topRecommendation = recommendations.first;
    final message = 'Based on your preferences, you might love ${topRecommendation.name} - rated ${topRecommendation.rating?.toStringAsFixed(1) ?? "4.5"}/5!';
    
    return SmartNotification(
      id: 'ai_rec_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: NotificationType.recommendation,
      priority: NotificationPriority.normal,
      title: 'AI Recommendation',
      message: message,
      data: {
        'productId': topRecommendation.id,
        'confidence': 0.85,
        'reasoning': 'Based on your order history and preferences',
      },
      actionButtons: ['Order Now', 'See More'],
      scheduledTime: _convertTimeOfDayToDateTime(_getOptimalSendTime(preferences)),
      channel: NotificationChannel.push,
      status: NotificationStatus.pending,
      createdAt: DateTime.now(),
      aiMetadata: {
        'aiGenerated': true,
        'mlModel': 'collaborative_filtering',
        'confidence': 0.85,
        'personalization': 'high',
      },
    );
  }

  // Generate promotion notification
  Future<SmartNotification> _generatePromotionNotification(
    String userId,
    NotificationPreferences preferences,
    Map<String, dynamic> userBehavior,
    Map<String, dynamic> context,
  ) async {
    // AI determines best promotion based on user behavior
    final promotionType = _selectOptimalPromotion(userBehavior, context);
    final message = _generatePersonalizedPromotionMessage(promotionType, userBehavior);
    
    return SmartNotification(
      id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: NotificationType.promotion,
      priority: NotificationPriority.normal,
      title: 'Special offer just for you!',
      message: message,
      data: {
        'promotionType': promotionType,
        'discount': _getPromotionDiscount(promotionType, userBehavior),
        'validUntil': DateTime.now().add(const Duration(hours: 24)),
      },
      actionButtons: ['Order Now', 'View Details'],
      scheduledTime: _convertTimeOfDayToDateTime(_getOptimalSendTime(preferences)),
      channel: NotificationChannel.push,
      status: NotificationStatus.pending,
      createdAt: DateTime.now(),
      aiMetadata: {
        'aiOptimized': true,
        'targeting': 'behavior_based',
        'expectedUplift': 0.25,
      },
    );
  }

  // Generate loyalty notification
  Future<SmartNotification> _generateLoyaltyNotification(
    String userId,
    NotificationPreferences preferences,
    Map<String, dynamic> userBehavior,
  ) async {
    final loyaltyData = await _getUserLoyaltyData(userId);
    final tier = loyaltyData['tier'] ?? 'bronze';
    final points = loyaltyData['points'] ?? 0;
    
    final message = tier == 'gold' || tier == 'platinum' 
        ? 'Exclusive offer for ${tier} members! Get 20% off your next order.'
        : 'You\'re ${100 - points} points away from a free meal!';
    
    return SmartNotification(
      id: 'loyalty_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: NotificationType.loyaltyReward,
      priority: NotificationPriority.high,
      title: tier == 'gold' || tier == 'platinum' ? 'VIP Exclusive' : 'Loyalty Progress',
      message: message,
      data: {
        'tier': tier,
        'points': points,
        'nextMilestone': _getNextMilestone(points),
      },
      actionButtons: ['Claim Offer', 'View Progress'],
      scheduledTime: _convertTimeOfDayToDateTime(_getOptimalSendTime(preferences)),
      channel: NotificationChannel.push,
      status: NotificationStatus.pending,
      createdAt: DateTime.now(),
      aiMetadata: {
        'tierBased': true,
        'retention': true,
        'value': points > 50 ? 'high' : 'medium',
      },
    );
  }

  // Private helper methods
  Future<NotificationPreferences> _getUserPreferences(String userId) async {
    final doc = await _firestore.collection('notificationPreferences').doc(userId).get();
    if (doc.exists) {
      return NotificationPreferences.fromJson(doc.data()!);
    } else {
      // Return default preferences
      return NotificationPreferences(
        userId: userId,
        enabledTypes: {},
        preferredChannels: {},
        quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
        quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
        doNotDisturbDays: [],
        prioritySettings: {},
        marketingOptIn: true,
        promotionalOptIn: true,
        orderAlerts: true,
        deliveryAlerts: true,
        recommendationAlerts: true,
        locationBasedAlerts: false,
        weatherBasedAlerts: false,
        reorderSuggestions: true,
        loyaltyAlerts: true,
        cartAbandonmentAlerts: true,
        engagementScore: 0.5,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<Map<String, dynamic>> _getContextualData(String userId) async {
    // Get contextual information like location, weather, time, etc.
    return {
      'timeOfDay': _getTimeOfDay(),
      'dayOfWeek': DateTime.now().weekday,
      'weather': _getMockWeatherData(),
      'location': 'Current Location', // Would get from user preferences
      'season': _getCurrentSeason(),
    };
  }

  bool _shouldSendNotification(SmartNotification notification, NotificationPreferences preferences) {
    // Check if notification type is enabled
    if (!preferences.isTypeEnabled(notification.type)) return false;
    
    // Check if channel is preferred
    if (!preferences.isChannelPreferred(notification.channel)) return false;
    
    // Check quiet hours
    if (preferences.isQuietHours() && notification.priority == NotificationPriority.low) {
      return false;
    }
    
    // Check do not disturb days
    if (preferences.isDoNotDisturbDay(DateTime.now().weekday)) return false;
    
    // Check priority settings
    if (!preferences.isPriorityAllowed(notification.priority)) return false;
    
    return true;
  }

  Future<void> _sendNotification(SmartNotification notification) async {
    // Mark as scheduled
    final scheduledNotification = notification.copyWith(
      status: NotificationStatus.sent,
      sentAt: DateTime.now(),
    );
    
    // Save to Firestore
    await _firestore.collection('smartNotifications').doc(notification.id).set(
      scheduledNotification.toJson(),
    );
    
    // Send via appropriate channel
    switch (notification.channel) {
      case NotificationChannel.push:
        await _sendPushNotification(notification);
        break;
      case NotificationChannel.email:
        await _sendEmailNotification(notification);
        break;
      case NotificationChannel.sms:
        await _sendSMSNotification(notification);
        break;
      default:
        break;
    }
  }

  Future<void> _updateUserEngagementScore(String userId, SmartNotification notification) async {
    // Update engagement score based on notification performance
    final preferences = await _getUserPreferences(userId);
    final currentScore = preferences.engagementScore;
    
    double newScore = currentScore;
    switch (notification.status) {
      case NotificationStatus.clicked:
        newScore += 0.1;
        break;
      case NotificationStatus.read:
        newScore += 0.05;
        break;
      case NotificationStatus.dismissed:
        newScore -= 0.02;
        break;
      default:
        break;
    }
    
    newScore = newScore.clamp(0.0, 1.0);
    
    await _firestore.collection('notificationPreferences').doc(userId).update({
      'engagementScore': newScore,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Notification sending methods
  Future<void> _sendPushNotification(SmartNotification notification) async {
    // Mock implementation - in real app would use Firebase Cloud Messaging
    debugPrint('🔔 Push notification sent: ${notification.title}');
  }

  Future<void> _sendEmailNotification(SmartNotification notification) async {
    // Implementation would integrate with email service
    debugPrint('📧 Email sent: ${notification.title}');
  }

  Future<void> _sendSMSNotification(SmartNotification notification) async {
    // Implementation would integrate with SMS service
    debugPrint('📱 SMS sent: ${notification.title}');
  }

  // Analysis helpers
  List<String> _analyzeFavoriteCategories(List<Map<String, dynamic>> orders) {
    final categoryCount = <String, int>{};
    
    for (final order in orders) {
      final category = order['category'] ?? 'unknown';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    final sortedEntries = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(3)
        .map((entry) => entry.key)
        .toList();
  }

  List<int> _analyzeOrderTimes(List<Map<String, dynamic>> orders) {
    final times = <int>[];
    
    for (final order in orders) {
      final orderDate = (order['orderDate'] as Timestamp).toDate();
      times.add(orderDate.hour);
    }
    
    return times;
  }

  Map<int, int> _analyzeDayPreferences(List<Map<String, dynamic>> orders) {
    final dayCount = <int, int>{};
    
    for (final order in orders) {
      final orderDate = (order['orderDate'] as Timestamp).toDate();
      final dayOfWeek = orderDate.weekday;
      dayCount[dayOfWeek] = (dayCount[dayOfWeek] ?? 0) + 1;
    }
    
    return dayCount;
  }

  double _calculateEngagementScore(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) return 0.0;
    
    // Factors: order frequency, average order value, time since last order
    final dates = orders.map((o) => (o['orderDate'] as Timestamp).toDate()).toList();
    final daysSinceFirstOrder = DateTime.now().difference(dates.reduce((a, b) => a.isBefore(b) ? a : b)).inDays;
    
    final orderFrequency = orders.length / (daysSinceFirstOrder / 7.0); // orders per week
    final avgOrderValue = orders.fold<double>(0.0, (sum, order) => sum + (order['totalPrice'] ?? 0.0)) / orders.length;
    
    // Normalize and combine factors
    final frequencyScore = math.min(orderFrequency / 7.0, 1.0); // Max 1 order per day
    final valueScore = math.min(avgOrderValue / 50.0, 1.0); // Max $50 order value
    final recencyScore = orders.isNotEmpty 
        ? 1.0 - (DateTime.now().difference(dates.first).inDays / 30.0)
        : 0.0;
    
    return (frequencyScore * 0.4 + valueScore * 0.3 + recencyScore * 0.3);
  }

  String _formatRecommendationMessage(List<dynamic> recommendations) {
    if (recommendations.isEmpty) return 'Discover delicious new items!';
    final first = recommendations.first;
    return 'You might love ${first['name']}! Rated ${first['rating']?.toStringAsFixed(1) ?? "4.5"}/5.';
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 16) return 'lunch';
    if (hour < 21) return 'dinner';
    return 'late_night';
  }

  TimeOfDay _getOptimalSendTime(NotificationPreferences preferences) {
    return preferences.getOptimalSendTime();
  }

  DateTime _convertTimeOfDayToDateTime(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  }

  // Mock data methods (in real implementation, these would call actual APIs)
  Map<String, dynamic> _getMockWeatherData() {
    return {
      'temperature': 22,
      'condition': 'sunny',
      'humidity': 65,
    };
  }

  List<String> _getWeatherBasedRecommendations(Map<String, dynamic> weather) {
    final condition = weather['condition'];
    final temperature = weather['temperature'] ?? 20;
    
    if (condition == 'hot' || temperature > 25) {
      return ['salad', 'cold drinks', 'ice cream', 'fresh fruit'];
    } else if (condition == 'rainy' || temperature < 15) {
      return ['soup', 'hot drinks', 'comfort food', 'pasta'];
    } else {
      return ['burgers', 'pizza', 'sandwiches', 'mild dishes'];
    }
  }

  String _formatWeatherMessage(Map<String, dynamic> weather, String recommendation) {
    final condition = weather['condition'];
    final temperature = weather['temperature'];
    
    if (condition == 'hot') {
      return 'Perfect weather for $recommendation! Cool down with our fresh options.';
    } else if (condition == 'rainy') {
      return 'Rainy day comfort? Try our warm $recommendation!';
    } else {
      return 'Great day for $recommendation! Order now and enjoy.';
    }
  }

  double _calculateReorderProbability(int daysSinceLastOrder, String userId) {
    // AI model would calculate this based on historical data
    if (daysSinceLastOrder <= 7) return 0.8;
    if (daysSinceLastOrder <= 14) return 0.6;
    if (daysSinceLastOrder <= 21) return 0.4;
    return 0.2;
  }

  Future<Map<String, dynamic>> _getUserLoyaltyData(String userId) async {
    // Mock loyalty data
    return {
      'points': 75,
      'tier': 'silver',
      'eligibleRewards': [
        {'name': 'Free Appetizer', 'points': 100},
        {'name': 'Free Main Course', 'points': 200},
      ],
    };
  }

  int _getNextMilestone(int currentPoints) {
    if (currentPoints < 100) return 100;
    if (currentPoints < 250) return 250;
    if (currentPoints < 500) return 500;
    return 1000;
  }

  Future<List<Map<String, dynamic>>> _getAbandonedCarts(String userId) async {
    // Mock abandoned cart data
    return [
      {
        'id': 'cart_123',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'totalAmount': 25.99,
        'itemCount': 2,
      },
    ];
  }

  double _calculateCartConversionProbability(Map<String, dynamic> cart, String userId) {
    final hoursAgo = DateTime.now().difference(cart['createdAt']).inHours;
    final totalAmount = cart['totalAmount'] ?? 0.0;
    
    // Higher probability for smaller amounts and recent carts
    return math.max(0.1, 0.7 - (hoursAgo * 0.05) - (totalAmount / 100.0 * 0.1));
  }

  String _selectOptimalPromotion(Map<String, dynamic> userBehavior, Map<String, dynamic> context) {
    final avgOrderValue = userBehavior['averageOrderValue'] ?? 0.0;
    final frequency = userBehavior['orderFrequency'] ?? 0.0;
    
    if (avgOrderValue < 20) return 'percentage_discount';
    if (frequency < 2) return 'free_delivery';
    return 'bogo_offer';
  }

  String _generatePersonalizedPromotionMessage(String promotionType, Map<String, dynamic> userBehavior) {
    final avgOrderValue = userBehavior['averageOrderValue'] ?? 0.0;
    
    switch (promotionType) {
      case 'percentage_discount':
        return 'Get 15% off your next order! Perfect for trying something new.';
      case 'free_delivery':
        return 'Free delivery on your next order! No minimum required.';
      case 'bogo_offer':
        return 'Buy one get one free on selected items! Share with friends or enjoy twice the flavor.';
      default:
        return 'Special offer just for you! Don\'t miss out.';
    }
  }

  double _getPromotionDiscount(String promotionType, Map<String, dynamic> userBehavior) {
    switch (promotionType) {
      case 'percentage_discount':
        return 15.0;
      case 'free_delivery':
        return 5.0; // Average delivery fee
      case 'bogo_offer':
        return 50.0; // 50% effective discount
      default:
        return 10.0;
    }
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }
}