import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import 'ai_recommendation_service.dart';

// Voice Command Types
enum VoiceCommandType {
  search,
  addToCart,
  order,
  trackOrder,
  askQuestion,
  navigate,
  reorder,
  customize,
  cancel,
  help,
  unknown
}

// Voice Command Response
class VoiceCommandResponse {
  final bool success;
  final String message;
  final VoiceCommandType commandType;
  final Map<String, dynamic>? data;
  final List<String>? followUpQuestions;

  VoiceCommandResponse({
    required this.success,
    required this.message,
    required this.commandType,
    this.data,
    this.followUpQuestions,
  });
}

// Voice Order Item
class VoiceOrderItem {
  final String productName;
  final int quantity;
  final List<String> customizations;
  final double estimatedPrice;

  VoiceOrderItem({
    required this.productName,
    required this.quantity,
    required this.customizations,
    required this.estimatedPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      'customizations': customizations,
      'estimatedPrice': estimatedPrice,
    };
  }
}

// Voice Session
class VoiceSession {
  final String sessionId;
  final String userId;
  final List<VoiceOrderItem> currentOrder;
  final Map<String, dynamic> context;
  final DateTime startTime;
  bool isActive;

  VoiceSession({
    required this.sessionId,
    required this.userId,
    required this.currentOrder,
    required this.context,
    required this.startTime,
    this.isActive = true,
  });
}

class VoiceOrderingService {
  final AIRecommendationService _recommendationService = AIRecommendationService();
  final Map<String, VoiceSession> _activeSessions = {};
  
  // Voice Recognition (Mock implementation for demo)
  static Future<bool> get _isRecognitionAvailable async => true;
  
  // Speech Synthesis (Mock implementation for demo)
  static Future<void> _speak(String text) async {
    debugPrint('🔊 Speaking: $text');
    // In a real implementation, this would use flutter_tts
  }

  // Start voice ordering session
  Future<String> startVoiceSession(String userId) async {
    final sessionId = 'voice_${DateTime.now().millisecondsSinceEpoch}';
    
    _activeSessions[sessionId] = VoiceSession(
      sessionId: sessionId,
      userId: userId,
      currentOrder: [],
      context: {'stage': 'greeting', 'time': DateTime.now()},
      startTime: DateTime.now(),
    );

    await _speak('Welcome to FoodFirst voice ordering. I can help you place an order, track your delivery, or answer questions. What would you like to do?');
    return sessionId;
  }

  // Process voice input
  Future<VoiceCommandResponse> processVoiceInput(String sessionId, String input) async {
    try {
      final session = _activeSessions[sessionId];
      if (session == null) {
        return VoiceCommandResponse(
          success: false,
          message: 'Session not found. Please start a new voice session.',
          commandType: VoiceCommandType.unknown,
        );
      }

      // Detect command type
      final commandType = _detectCommandType(input.toLowerCase());
      
      switch (commandType) {
        case VoiceCommandType.search:
          return await _handleSearchCommand(session, input);
        case VoiceCommandType.addToCart:
          return await _handleAddToCartCommand(session, input);
        case VoiceCommandType.order:
          return await _handleOrderCommand(session, input);
        case VoiceCommandType.trackOrder:
          return await _handleTrackOrderCommand(session, input);
        case VoiceCommandType.askQuestion:
          return await _handleQuestionCommand(session, input);
        case VoiceCommandType.navigate:
          return await _handleNavigateCommand(session, input);
        case VoiceCommandType.reorder:
          return await _handleReorderCommand(session, input);
        case VoiceCommandType.customize:
          return await _handleCustomizeCommand(session, input);
        case VoiceCommandType.cancel:
          return await _handleCancelCommand(session, input);
        case VoiceCommandType.help:
          return await _handleHelpCommand(session, input);
        default:
          return await _handleUnknownCommand(session, input);
      }
    } catch (e) {
      debugPrint('Error processing voice input: $e');
      return VoiceCommandResponse(
        success: false,
        message: 'I didn\'t understand that. Could you please repeat?',
        commandType: VoiceCommandType.unknown,
      );
    }
  }

  // Detect command type from speech
  VoiceCommandType _detectCommandType(String input) {
    // Search commands
    if (input.contains('search') || input.contains('find') || input.contains('show me') || input.contains('look for')) {
      return VoiceCommandType.search;
    }
    
    // Add to cart commands
    if (input.contains('add') || input.contains('get') || input.contains('want') || input.contains('order') && !input.contains('track')) {
      return VoiceCommandType.addToCart;
    }
    
    // Order placement
    if (input.contains('place order') || input.contains('checkout') || input.contains('confirm order') || input.contains('proceed')) {
      return VoiceCommandType.order;
    }
    
    // Track order
    if (input.contains('track') || input.contains('where is my') || input.contains('status') || input.contains('delivery')) {
      return VoiceCommandType.trackOrder;
    }
    
    // Questions
    if (input.contains('what') || input.contains('how') || input.contains('when') || input.contains('where') || input.contains('why')) {
      return VoiceCommandType.askQuestion;
    }
    
    // Navigation
    if (input.contains('go to') || input.contains('show me menu') || input.contains('categories') || input.contains('back')) {
      return VoiceCommandType.navigate;
    }
    
    // Reorder
    if (input.contains('reorder') || input.contains('same as last') || input.contains('previous order')) {
      return VoiceCommandType.reorder;
    }
    
    // Customize
    if (input.contains('customize') || input.contains('modify') || input.contains('change') || input.contains('add extra')) {
      return VoiceCommandType.customize;
    }
    
    // Cancel
    if (input.contains('cancel') || input.contains('remove') || input.contains('delete')) {
      return VoiceCommandType.cancel;
    }
    
    // Help
    if (input.contains('help') || input.contains('what can you do') || input.contains('commands')) {
      return VoiceCommandType.help;
    }
    
    return VoiceCommandType.unknown;
  }

  // Handle search commands
  Future<VoiceCommandResponse> _handleSearchCommand(VoiceSession session, String input) async {
    // Extract food items or categories from speech
    final searchTerms = _extractSearchTerms(input);
    final categories = _extractCategories(input);
    final dietary = _extractDietaryRestrictions(input);
    
    try {
      List<Product> results = [];
      
      if (searchTerms.isNotEmpty) {
        // Get recommendations based on search terms
        final recommendations = await _recommendationService.getContextualRecommendations(
          userId: session.userId,
          timeOfDay: _getTimeOfDay(),
          limit: 5,
        );
        
        results = recommendations.where((product) =>
          searchTerms.any((term) => 
            product.name.toLowerCase().contains(term) ||
            product.description?.toLowerCase().contains(term) == true)
        ).toList();
      }
      
      if (results.isEmpty) {
        await _speak('I found some popular items for you. Here are some recommended dishes:');
      } else {
        await _speak('I found ${results.length} items that match your search. Here are the top results:');
      }
      
      // List the results
      for (int i = 0; i < results.length && i < 3; i++) {
        final product = results[i];
        await _speak('${i + 1}. ${product.name} for \$${product.price.toStringAsFixed(2)}. ${product.description ?? ""}');
      }
      
      session.context['lastSearch'] = searchTerms;
      session.context['searchResults'] = results.map((p) => p.id).toList();
      
      return VoiceCommandResponse(
        success: true,
        message: 'Search completed successfully',
        commandType: VoiceCommandType.search,
        data: {
          'results': results.map((p) => p.toJson()).toList(),
          'searchTerms': searchTerms,
        },
        followUpQuestions: [
          'Would you like to add any of these to your order?',
          'Do you want to hear more options?',
          'Would you like to search for something else?',
        ],
      );
    } catch (e) {
      return VoiceCommandResponse(
        success: false,
        message: 'Sorry, I encountered an error while searching. Please try again.',
        commandType: VoiceCommandType.search,
      );
    }
  }

  // Handle add to cart commands
  Future<VoiceCommandResponse> _handleAddToCartCommand(VoiceSession session, String input) async {
    final items = _extractOrderItems(input);
    
    if (items.isEmpty) {
      await _speak('I didn\'t catch what you\'d like to add. Could you say the name of the item you want?');
      return VoiceCommandResponse(
        success: false,
        message: 'No items detected in request',
        commandType: VoiceCommandType.addToCart,
      );
    }
    
    for (final item in items) {
      session.currentOrder.add(item);
      await _speak('Added ${item.quantity} ${item.productName}${item.quantity > 1 ? 's' : ''} to your order.');
    }
    
    final totalItems = session.currentOrder.length;
    await _speak('Your order now has $totalItems items. Would you like to add more or proceed to checkout?');
    
    return VoiceCommandResponse(
      success: true,
      message: 'Items added to order successfully',
      commandType: VoiceCommandType.addToCart,
      data: {
        'items': items.map((i) => i.toJson()).toList(),
      },
      followUpQuestions: [
        'Would you like to add more items?',
        'Are you ready to place your order?',
        'Would you like to customize any of these items?',
      ],
    );
  }

  // Handle order placement
  Future<VoiceCommandResponse> _handleOrderCommand(VoiceSession session, String input) async {
    if (session.currentOrder.isEmpty) {
      await _speak('Your cart is empty. Please add some items first.');
      return VoiceCommandResponse(
        success: false,
        message: 'Cannot place order with empty cart',
        commandType: VoiceCommandType.order,
      );
    }
    
    // Calculate total
    final total = session.currentOrder.fold<double>(0.0, (sum, item) => sum + item.estimatedPrice);
    
    await _speak('You have ${session.currentOrder.length} items in your order totaling \$${total.toStringAsFixed(2)}. Here\'s your order summary:');
    
    for (int i = 0; i < session.currentOrder.length; i++) {
      final item = session.currentOrder[i];
      await _speak('${i + 1}. ${item.quantity} ${item.productName}${item.customizations.isNotEmpty ? ' with ${item.customizations.join(', ')}' : ''}');
    }
    
    await _speak('Please confirm your order by saying "yes" to place it, or "no" to make changes.');
    
    session.context['pendingOrder'] = session.currentOrder.map((i) => i.toJson()).toList();
    session.context['total'] = total;
    
    return VoiceCommandResponse(
      success: true,
      message: 'Order ready for confirmation',
      commandType: VoiceCommandType.order,
      data: {
        'orderItems': session.currentOrder.map((i) => i.toJson()).toList(),
        'total': total,
        'itemCount': session.currentOrder.length,
      },
      followUpQuestions: [
        'Is this order correct?',
        'Would you like to add any items before confirming?',
        'Any special instructions for your order?',
      ],
    );
  }

  // Handle track order commands
  Future<VoiceCommandResponse> _handleTrackOrderCommand(VoiceSession session, String input) async {
    // In a real implementation, this would integrate with the delivery tracking service
    await _speak('Let me check the status of your recent order...');
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock order status
    final statuses = [
      'Your order is being prepared at the restaurant',
      'Your order is ready for pickup',
      'Your order is out for delivery',
      'Your delivery partner is arriving soon',
      'Your order has been delivered'
    ];
    
    final randomStatus = statuses[DateTime.now().millisecond % statuses.length];
    await _speak(randomStatus);
    
    return VoiceCommandResponse(
      success: true,
      message: 'Order status retrieved',
      commandType: VoiceCommandType.trackOrder,
      data: {'status': randomStatus},
    );
  }

  // Handle question commands
  Future<VoiceCommandResponse> _handleQuestionCommand(VoiceSession session, String input) async {
    if (input.contains('delivery time') || input.contains('how long')) {
      await _speak('Delivery times typically range from 25 to 45 minutes depending on your location and restaurant preparation time.');
      return VoiceCommandResponse(
        success: true,
        message: 'Delivery time information provided',
        commandType: VoiceCommandType.askQuestion,
      );
    }
    
    if (input.contains('payment') || input.contains('pay')) {
      await _speak('We accept all major credit cards, debit cards, digital wallets, and cash on delivery.');
      return VoiceCommandResponse(
        success: true,
        message: 'Payment information provided',
        commandType: VoiceCommandType.askQuestion,
      );
    }
    
    if (input.contains('delivery fee') || input.contains('cost')) {
      await _speak('Delivery fees vary by distance and restaurant. Most orders have a small delivery fee of \$2-5.');
      return VoiceCommandResponse(
        success: true,
        message: 'Delivery fee information provided',
        commandType: VoiceCommandType.askQuestion,
      );
    }
    
    await _speak('I can help with order information, delivery status, menu items, and account questions. What specific information do you need?');
    
    return VoiceCommandResponse(
      success: true,
      message: 'General information provided',
      commandType: VoiceCommandType.askQuestion,
    );
  }

  // Handle navigation commands
  Future<VoiceCommandResponse> _handleNavigateCommand(VoiceSession session, String input) async {
    if (input.contains('menu') || input.contains('show menu')) {
      await _speak('Here are our main categories: Burgers, Pizza, Sushi, Desserts, and Drinks. Which category interests you?');
    } else if (input.contains('category')) {
      final categories = _extractCategories(input);
      if (categories.isNotEmpty) {
        await _speak('Here are popular items in ${categories.first}:');
        // Would return category-specific items
      }
    } else if (input.contains('back')) {
      await _speak('Going back to the main menu.');
    } else {
      await _speak('You can ask me to show you the menu, browse categories, or search for specific items.');
    }
    
    return VoiceCommandResponse(
      success: true,
      message: 'Navigation handled',
      commandType: VoiceCommandType.navigate,
    );
  }

  // Handle reorder commands
  Future<VoiceCommandResponse> _handleReorderCommand(VoiceSession session, String input) async {
    await _speak('I can see your previous orders. Would you like to reorder the same items from your last order?');
    
    // In real implementation, would fetch previous orders
    return VoiceCommandResponse(
      success: true,
      message: 'Reorder functionality initiated',
      commandType: VoiceCommandType.reorder,
    );
  }

  // Handle customize commands
  Future<VoiceCommandResponse> _handleCustomizeCommand(VoiceSession session, String input) async {
    final customizations = _extractCustomizations(input);
    
    if (session.currentOrder.isNotEmpty && customizations.isNotEmpty) {
      session.currentOrder.last.customizations.addAll(customizations);
      await _speak('Added ${customizations.join(', ')} to your ${session.currentOrder.last.productName}.');
    } else {
      await _speak('Please add an item first, then let me know how you\'d like to customize it.');
    }
    
    return VoiceCommandResponse(
      success: true,
      message: 'Customization handled',
      commandType: VoiceCommandType.customize,
    );
  }

  // Handle cancel commands
  Future<VoiceCommandResponse> _handleCancelCommand(VoiceSession session, String input) async {
    final itemName = _extractItemName(input);
    
    if (itemName != null) {
      session.currentOrder.removeWhere((item) => 
        item.productName.toLowerCase().contains(itemName.toLowerCase()));
      await _speak('Removed $itemName from your order.');
    } else {
      session.currentOrder.clear();
      await _speak('Cleared your entire order.');
    }
    
    return VoiceCommandResponse(
      success: true,
      message: 'Item(s) removed from order',
      commandType: VoiceCommandType.cancel,
    );
  }

  // Handle help commands
  Future<VoiceCommandResponse> _handleHelpCommand(VoiceSession session, String input) async {
    await _speak('I can help you with:');
    await _speak('• Searching for food items');
    await _speak('• Adding items to your order');
    await _speak('• Tracking your delivery');
    await _speak('• Answering questions about orders and restaurants');
    await _speak('• Navigating the menu');
    await _speak('And much more! What would you like to do?');
    
    return VoiceCommandResponse(
      success: true,
      message: 'Help information provided',
      commandType: VoiceCommandType.help,
    );
  }

  // Handle unknown commands
  Future<VoiceCommandResponse> _handleUnknownCommand(VoiceSession session, String input) async {
    await _speak('I didn\'t understand that command. You can say things like "search for pizza" or "add a burger to my order" or "track my order".');
    
    return VoiceCommandResponse(
      success: false,
      message: 'Command not recognized',
      commandType: VoiceCommandType.unknown,
    );
  }

  // End voice session
  Future<void> endVoiceSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.isActive = false;
      await _speak('Thank you for using FoodFirst voice ordering. Have a great day!');
      _activeSessions.remove(sessionId);
    }
  }

  // Get current session
  VoiceSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  // Utility methods for NLP processing
  List<String> _extractSearchTerms(String input) {
    final terms = <String>[];
    
    // Common food items
    final foodKeywords = [
      'pizza', 'burger', 'pasta', 'salad', 'sandwich', 'soup', 'stir fry', 'curry',
      'sushi', 'ramen', 'taco', 'burrito', 'wrap', 'noodle', 'rice', 'chicken',
      'beef', 'pork', 'fish', 'vegetable', 'dessert', 'cake', 'ice cream'
    ];
    
    for (final keyword in foodKeywords) {
      if (input.contains(keyword)) {
        terms.add(keyword);
      }
    }
    
    return terms;
  }

  List<String> _extractCategories(String input) {
    final categories = <String>[];
    
    if (input.contains('burger') || input.contains('fast food')) categories.add('Burgers');
    if (input.contains('pizza')) categories.add('Pizza');
    if (input.contains('sushi') || input.contains('japanese')) categories.add('Sushi');
    if (input.contains('dessert') || input.contains('sweet')) categories.add('Desserts');
    if (input.contains('drink') || input.contains('beverage')) categories.add('Drinks');
    
    return categories;
  }

  List<String> _extractDietaryRestrictions(String input) {
    final restrictions = <String>[];
    
    if (input.contains('vegetarian') || input.contains('veggie')) restrictions.add('vegetarian');
    if (input.contains('vegan')) restrictions.add('vegan');
    if (input.contains('gluten free')) restrictions.add('gluten-free');
    if (input.contains('dairy free')) restrictions.add('dairy-free');
    if (input.contains('low carb')) restrictions.add('low-carb');
    
    return restrictions;
  }

  List<VoiceOrderItem> _extractOrderItems(String input) {
    final items = <VoiceOrderItem>[];
    
    // Simple parsing - in real implementation would use more sophisticated NLP
    final searchTerms = _extractSearchTerms(input);
    if (searchTerms.isNotEmpty) {
      final quantity = _extractQuantity(input);
      final customizations = _extractCustomizations(input);
      
      items.add(VoiceOrderItem(
        productName: searchTerms.first,
        quantity: quantity,
        customizations: customizations,
        estimatedPrice: quantity * 12.99, // Mock price
      ));
    }
    
    return items;
  }

  int _extractQuantity(String input) {
    // Extract numbers from speech
    final numbers = RegExp(r'\d+').allMatches(input);
    if (numbers.isNotEmpty) {
      return int.parse(numbers.first.group(0)!);
    }
    return 1;
  }

  List<String> _extractCustomizations(String input) {
    final customizations = <String>[];
    
    if (input.contains('extra cheese')) customizations.add('extra cheese');
    if (input.contains('no onions')) customizations.add('no onions');
    if (input.contains('spicy')) customizations.add('spicy');
    if (input.contains('mild')) customizations.add('mild');
    if (input.contains('extra sauce')) customizations.add('extra sauce');
    
    return customizations;
  }

  String? _extractItemName(String input) {
    final searchTerms = _extractSearchTerms(input);
    return searchTerms.isNotEmpty ? searchTerms.first : null;
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 16) return 'lunch';
    if (hour < 21) return 'dinner';
    return 'late_night';
  }

  // Mock permissions check
  Future<bool> checkPermissions() async {
    // Mock implementation - in real app would check actual permissions
    debugPrint('🔊 Checking microphone permissions...');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Voice Assistant Integration (mock implementations)
  Future<void> integrateWithGoogleAssistant(String command) async {
    debugPrint('📱 Google Assistant Integration: $command');
    // In real implementation, would use Google Assistant SDK
  }

  Future<void> integrateWithAlexa(String command) async {
    debugPrint('🔊 Alexa Integration: $command');
    // In real implementation, would use Alexa Skills Kit
  }

  Future<void> integrateWithSiri(String command) async {
    debugPrint('🎤 Siri Integration: $command');
    // In real implementation, would use Siri Shortcuts
  }
}