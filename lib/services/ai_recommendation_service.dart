import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/product.dart';
import '../models/user_preferences.dart';
import '../models/order.dart' as app_order;
import '../models/review.dart';

class AIRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get personalized recommendations for a user
  Future<List<Product>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
    String? context,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Get user preferences and order history
      final userPreferences = await _getUserPreferences(userId);
      final orderHistory = await _getUserOrderHistory(userId);
      final userReviews = await _getUserReviews(userId);
      final similarUsers = await _findSimilarUsers(userPreferences, limit: 50);
      
      // Get all available products
      final allProducts = await _getAllProducts();
      
      // Generate recommendations using multiple ML algorithms
      final recommendations = await _generateAdvancedRecommendations(
        allProducts: allProducts,
        userPreferences: userPreferences,
        orderHistory: orderHistory,
        userReviews: userReviews,
        similarUsers: similarUsers,
        limit: limit,
        context: context,
        userContext: userContext,
      );
      
      // Log recommendation for ML learning
      await _logRecommendationEvent(userId, recommendations, 'personalized');
      
      return recommendations;
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }

  // Get contextual recommendations based on time, weather, location
  Future<List<Product>> getContextualRecommendations({
    required String userId,
    String? timeOfDay,
    String? weather,
    String? location,
    int limit = 5,
  }) async {
    try {
      final userPreferences = await _getUserPreferences(userId);
      final allProducts = await _getAllProducts();
      
      List<Product> contextualProducts = [];
      
      // Time-based filtering
      if (timeOfDay != null) {
        final timeBasedProducts = _filterByTimeOfDay(allProducts, timeOfDay);
        contextualProducts.addAll(timeBasedProducts);
      }
      
      // Weather-based filtering
      if (weather != null) {
        final weatherBasedProducts = _filterByWeather(allProducts, weather);
        contextualProducts.addAll(weatherBasedProducts);
      }
      
      // Location-based filtering
      if (location != null) {
        final locationBasedProducts = _filterByLocation(allProducts, location);
        contextualProducts.addAll(locationBasedProducts);
      }
      
      // Remove duplicates and apply user preferences
      final uniqueProducts = contextualProducts.toSet().toList();
      final filteredByPreferences = _applyUserPreferences(uniqueProducts, userPreferences);
      
      return filteredByPreferences.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting contextual recommendations: $e');
      return [];
    }
  }

  // Similar products recommendation
  Future<List<Product>> getSimilarProducts({
    required String productId,
    int limit = 5,
  }) async {
    try {
      // Get the target product
      final targetProduct = await _getProductById(productId);
      if (targetProduct == null) return [];
      
      // Get all products in the same category
      final categoryProducts = await _getProductsByCategory(targetProduct.categoryId);
      
      // Remove the target product
      categoryProducts.removeWhere((p) => p.id == productId);
      
      // Sort by similarity (price range, rating, etc.)
      final similarProducts = _sortBySimilarity(categoryProducts, targetProduct);
      
      return similarProducts.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting similar products: $e');
      return [];
    }
  }

  // Trending products based on recent orders
  Future<List<Product>> getTrendingProducts({
    int days = 7,
    int limit = 10,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      
      final ordersQuery = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();
      
      final productOrderCounts = <String, int>{};
      
      for (var doc in ordersQuery.docs) {
        final orderData = doc.data();
        if (orderData['items'] != null) {
          for (var item in orderData['items']) {
            final productId = item['productId'] as String?;
            if (productId != null) {
              productOrderCounts[productId] = (productOrderCounts[productId] ?? 0) + 1;
            }
          }
        }
      }
      
      // Sort products by order count
      final sortedProductIds = productOrderCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      final trendingProducts = <Product>[];
      for (var entry in sortedProductIds.take(limit)) {
        final product = await _getProductById(entry.key);
        if (product != null) {
          trendingProducts.add(product);
        }
      }
      
      return trendingProducts;
    } catch (e) {
      debugPrint('Error getting trending products: $e');
      return [];
    }
  }

  // Update user preferences based on recent activity
  Future<void> updateUserPreferencesFromActivity({
    required String userId,
    required String productId,
    required UserActivity activity,
  }) async {
    try {
      final preferences = await _getUserPreferences(userId);
      final product = await _getProductById(productId);
      
      if (product == null) return;
      
      // Update preferences based on activity
      switch (activity) {
        case UserActivity.ordered:
          await _updatePreferencesForOrder(preferences, product);
          break;
        case UserActivity.favorited:
          await _updatePreferencesForFavorite(preferences, product);
          break;
        case UserActivity.rated:
          await _updatePreferencesForRating(preferences, product);
          break;
        case UserActivity.viewed:
          await _updatePreferencesForView(preferences, product);
          break;
      }
      
      // Save updated preferences
      await _saveUserPreferences(preferences);
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
    }
  }

  // Private helper methods
  Future<UserPreferences> _getUserPreferences(String userId) async {
    final doc = await _firestore.collection('userPreferences').doc(userId).get();
    if (doc.exists) {
      return UserPreferences.fromJson(doc.data()!);
    } else {
      // Create default preferences
      return UserPreferences(
        userId: userId,
        favoriteCategories: [],
        favoriteRestaurants: [],
        dietaryRestrictions: {},
        preferredPriceRange: PriceRange(min: 0, max: 100),
        allergyInfo: [],
        orderTimePreference: TimePreference(preferredDays: [], preferredTimeSlots: []),
        cuisinePreferences: [],
        averageOrderValue: 0.0,
        orderFrequency: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<List<app_order.Order>> _getUserOrderHistory(String userId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Get the product data from the order or create a minimal product
      final productId = data['productId'] ?? '';
      final productData = data['productData'] ?? {};
      
      // If we don't have separate product data, create a minimal product from order data
      Product product;
      if (productData.isNotEmpty) {
        product = Product.fromFirestore(productId, productData);
      } else {
        // Create a minimal product with basic info from order
        product = Product(
          id: productId,
          name: data['productName'] ?? 'Unknown Product',
          price: (data['unitPrice'] ?? 0.0).toDouble(),
          categoryId: data['categoryId'] ?? '',
          restaurantId: data['restaurantId'] ?? '',
        );
      }
      
      return app_order.Order(
        id: doc.id,
        product: product,
        quantity: data['quantity'] ?? 1,
        date: (data['orderDate'] as Timestamp).toDate(),
        totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
        status: data['status'] ?? 'Delivered',
      );
    }).toList();
  }

  Future<List<Review>> _getUserReviews(String userId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Review.fromJson(doc.id, data);
    }).toList();
  }

  Future<List<Product>> _getAllProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map((doc) {
      return Product.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  Future<Product?> _getProductById(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      return Product.fromFirestore(doc.id, doc.data() ?? {});
    }
    return null;
  }

  Future<List<Product>> _getProductsByCategory(String categoryId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    
    return snapshot.docs.map((doc) {
      return Product.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  List<Product> _filterByTimeOfDay(List<Product> products, String timeOfDay) {
    // Simple time-based filtering logic
    switch (timeOfDay) {
      case 'breakfast':
        return products.where((p) => 
          p.name.toLowerCase().contains('breakfast') ||
          p.name.toLowerCase().contains('coffee') ||
          p.name.toLowerCase().contains('pastry')
        ).toList();
      case 'lunch':
        return products.where((p) => 
          p.name.toLowerCase().contains('salad') ||
          p.name.toLowerCase().contains('wrap') ||
          p.price < 20
        ).toList();
      case 'dinner':
        return products.where((p) => 
          p.name.toLowerCase().contains('pizza') ||
          p.name.toLowerCase().contains('pasta') ||
          p.name.toLowerCase().contains('dinner')
        ).toList();
      case 'late_night':
        return products.where((p) => 
          p.name.toLowerCase().contains('snack') ||
          p.name.toLowerCase().contains('dessert') ||
          p.price < 15
        ).toList();
      default:
        return products;
    }
  }

  List<Product> _filterByWeather(List<Product> products, String weather) {
    // Weather-based filtering logic
    switch (weather) {
      case 'hot':
        return products.where((p) => 
          p.name.toLowerCase().contains('salad') ||
          p.name.toLowerCase().contains('cold') ||
          p.name.toLowerCase().contains('ice')
        ).toList();
      case 'cold':
        return products.where((p) => 
          p.name.toLowerCase().contains('hot') ||
          p.name.toLowerCase().contains('soup') ||
          p.name.toLowerCase().contains('warm')
        ).toList();
      case 'rainy':
        return products.where((p) => 
          p.name.toLowerCase().contains('warm') ||
          p.name.toLowerCase().contains('comfort') ||
          p.price < 15
        ).toList();
      default:
        return products;
    }
  }

  List<Product> _filterByLocation(List<Product> products, String location) {
    // Location-based filtering (simplified)
    // In a real app, this would use restaurant location data
    if (products.isEmpty) return [];
    final half = products.length ~/ 2;
    return products.take(half).toList();
  }

  List<Product> _applyUserPreferences(List<Product> products, UserPreferences preferences) {
    return products.where((product) {
      // Filter by price range
      if (product.price < preferences.preferredPriceRange.min ||
          product.price > preferences.preferredPriceRange.max) {
        return false;
      }
      
      // Filter by dietary restrictions
      for (var restriction in preferences.dietaryRestrictions.keys) {
        if (product.description?.toLowerCase().contains(restriction.toLowerCase()) == true) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  List<Product> _sortBySimilarity(List<Product> products, Product targetProduct) {
    final productSimilarities = <Product, double>{};
    
    for (final product in products) {
      final similarity = _calculateSimilarity(product, targetProduct);
      productSimilarities[product] = similarity;
    }
    
    final sortedProducts = productSimilarities.entries.toList();
    sortedProducts.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedProducts.map((entry) => entry.key).toList();
  }

  double _calculateSimilarity(Product product1, Product product2) {
    double similarity = 0.0;
    
    // Category similarity
    if (product1.categoryId == product2.categoryId) {
      similarity += 0.4;
    }
    
    // Price similarity
    final priceDiff = (product1.price - product2.price).abs();
    final priceSimilarity = priceDiff >= 0 ? 1.0 / (1.0 + priceDiff) : 0.0;
    similarity += priceSimilarity * 0.3;
    
    // Rating similarity
    if (product1.rating != null && product2.rating != null &&
        product1.rating! >= 0 && product2.rating! >= 0) {
      final ratingDiff = (product1.rating! - product2.rating!).abs();
      final ratingSimilarity = ratingDiff >= 0 ? 1.0 / (1.0 + ratingDiff) : 0.0;
      similarity += ratingSimilarity * 0.3;
    }
    
    return similarity;
  }


  Future<void> _updatePreferencesForOrder(UserPreferences preferences, Product product) async {
    // Add category to favorites if not already there
    if (!preferences.favoriteCategories.contains(product.categoryId)) {
      preferences.favoriteCategories.add(product.categoryId);
    }
    
    // Update average order value (we need to create a mutable copy)
    final updatedPreferences = UserPreferences(
      userId: preferences.userId,
      favoriteCategories: preferences.favoriteCategories,
      favoriteRestaurants: preferences.favoriteRestaurants,
      dietaryRestrictions: preferences.dietaryRestrictions,
      preferredPriceRange: preferences.preferredPriceRange,
      allergyInfo: preferences.allergyInfo,
      orderTimePreference: preferences.orderTimePreference,
      cuisinePreferences: preferences.cuisinePreferences,
      averageOrderValue: (preferences.averageOrderValue + product.price) / 2,
      orderFrequency: preferences.orderFrequency + 1,
      lastUpdated: DateTime.now(),
    );
    
    // Save the updated preferences
    await _saveUserPreferences(updatedPreferences);
  }

  Future<void> _updatePreferencesForFavorite(UserPreferences preferences, Product product) async {
    if (!preferences.favoriteCategories.contains(product.categoryId)) {
      preferences.favoriteCategories.add(product.categoryId);
    }
    
    final updatedPreferences = UserPreferences(
      userId: preferences.userId,
      favoriteCategories: preferences.favoriteCategories,
      favoriteRestaurants: preferences.favoriteRestaurants,
      dietaryRestrictions: preferences.dietaryRestrictions,
      preferredPriceRange: preferences.preferredPriceRange,
      allergyInfo: preferences.allergyInfo,
      orderTimePreference: preferences.orderTimePreference,
      cuisinePreferences: preferences.cuisinePreferences,
      averageOrderValue: preferences.averageOrderValue,
      orderFrequency: preferences.orderFrequency,
      lastUpdated: DateTime.now(),
    );
    
    await _saveUserPreferences(updatedPreferences);
  }

  Future<void> _updatePreferencesForRating(UserPreferences preferences, Product product) async {
    final updatedPreferences = UserPreferences(
      userId: preferences.userId,
      favoriteCategories: preferences.favoriteCategories,
      favoriteRestaurants: preferences.favoriteRestaurants,
      dietaryRestrictions: preferences.dietaryRestrictions,
      preferredPriceRange: preferences.preferredPriceRange,
      allergyInfo: preferences.allergyInfo,
      orderTimePreference: preferences.orderTimePreference,
      cuisinePreferences: preferences.cuisinePreferences,
      averageOrderValue: preferences.averageOrderValue,
      orderFrequency: preferences.orderFrequency,
      lastUpdated: DateTime.now(),
    );
    
    await _saveUserPreferences(updatedPreferences);
  }

  Future<void> _updatePreferencesForView(UserPreferences preferences, Product product) async {
    final updatedPreferences = UserPreferences(
      userId: preferences.userId,
      favoriteCategories: preferences.favoriteCategories,
      favoriteRestaurants: preferences.favoriteRestaurants,
      dietaryRestrictions: preferences.dietaryRestrictions,
      preferredPriceRange: preferences.preferredPriceRange,
      allergyInfo: preferences.allergyInfo,
      orderTimePreference: preferences.orderTimePreference,
      cuisinePreferences: preferences.cuisinePreferences,
      averageOrderValue: preferences.averageOrderValue,
      orderFrequency: preferences.orderFrequency,
      lastUpdated: DateTime.now(),
    );
    
    await _saveUserPreferences(updatedPreferences);
  }

  Future<void> _saveUserPreferences(UserPreferences preferences) async {
    await _firestore
        .collection('userPreferences')
        .doc(preferences.userId)
        .set(preferences.toJson());
  }

  // Find users with similar preferences (Collaborative Filtering)
  Future<List<UserPreferences>> _findSimilarUsers(UserPreferences targetUser, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('userPreferences')
        .where('userId', isNotEqualTo: targetUser.userId)
        .limit(limit * 2) // Get more to filter from
        .get();
    
    final users = <UserPreferences>[];
    
    for (var doc in snapshot.docs) {
      try {
        final user = UserPreferences.fromJson(doc.data());
        final similarity = _calculateUserSimilarity(targetUser, user);
        
        if (similarity > 0.3) { // Threshold for similarity
          users.add(user);
        }
      } catch (e) {
        debugPrint('Error parsing user preferences: $e');
      }
    }
    
    // Sort by similarity and return top matches
    users.sort((a, b) => _calculateUserSimilarity(targetUser, b)
        .compareTo(_calculateUserSimilarity(targetUser, a)));
    
    return users.take(limit).toList();
  }

  // Calculate similarity between two users
  double _calculateUserSimilarity(UserPreferences user1, UserPreferences user2) {
    double similarity = 0.0;
    int factors = 0;
    
    // Category preference similarity
    final totalCategories = user1.favoriteCategories.length + user2.favoriteCategories.length;
    if (totalCategories > 0) {
      final commonCategories = user1.favoriteCategories
          .where((cat) => user2.favoriteCategories.contains(cat))
          .length;
      similarity += commonCategories / totalCategories;
      factors++;
    }
    
    // Price range similarity
    final priceOverlap = _calculateRangeOverlap(
      user1.preferredPriceRange.min, user1.preferredPriceRange.max,
      user2.preferredPriceRange.min, user2.preferredPriceRange.max,
    );
    similarity += priceOverlap;
    factors++;
    
    // Cuisine preference similarity
    final commonCuisines = _countCommonItems(user1.cuisinePreferences, user2.cuisinePreferences);
    final totalCuisines = _countTotalItems(user1.cuisinePreferences, user2.cuisinePreferences);
    if (totalCuisines > 0) {
      similarity += commonCuisines / totalCuisines;
      factors++;
    }
    
    return factors > 0 ? similarity / factors : 0.0;
  }

  // Advanced recommendation generation with multiple ML algorithms
  Future<List<Product>> _generateAdvancedRecommendations({
    required List<Product> allProducts,
    required UserPreferences userPreferences,
    required List<app_order.Order> orderHistory,
    required List<Review> userReviews,
    required List<UserPreferences> similarUsers,
    required int limit,
    String? context,
    Map<String, dynamic>? userContext,
  }) async {
    final recommendations = <Product>[];
    final productScores = <String, double>{};
    
    // Safety check for empty products list
    if (allProducts.isEmpty) {
      debugPrint('Warning: No products available for recommendations');
      return [];
    }
    
    // 1. Content-Based Filtering
    final contentBasedScores = _getContentBasedRecommendations(
      allProducts, userPreferences, orderHistory, context);
    
    // 2. Collaborative Filtering
    final collaborativeScores = _getCollaborativeScores(
      allProducts, similarUsers, orderHistory);
    
    // 3. Contextual Recommendations
    final contextualScores = _getContextualRecommendations(
      allProducts, userContext, context);
    
    // 4. Trending Products
    final trendingScores = await _getTrendingRecommendations(allProducts);
    
    // 5. Popularity-based (global trends)
    final popularityScores = _getPopularityRecommendations(allProducts);
    
    // Combine all scores with weights
    for (final product in allProducts) {
      final productId = product.id;
      
      double totalScore = 0.0;
      
      // Weighted combination of different algorithms
      totalScore += (contentBasedScores[productId] ?? 0.0) * 0.3;
      totalScore += (collaborativeScores[productId] ?? 0.0) * 0.25;
      totalScore += (contextualScores[productId] ?? 0.0) * 0.2;
      totalScore += (trendingScores[productId] ?? 0.0) * 0.15;
      totalScore += (popularityScores[productId] ?? 0.0) * 0.1;
      
      // Boost score for products in preferred price range
      if (_isInPriceRange(product, userPreferences.preferredPriceRange)) {
        totalScore += 0.1;
      }
      
      // Reduce score for recently ordered items
      final recentOrder = orderHistory.where((order) =>
        order.product.id == productId).toList();
      if (recentOrder.isNotEmpty) {
        final daysSinceOrder = DateTime.now().difference(recentOrder.first.date).inDays;
        if (daysSinceOrder < 7) {
          totalScore -= 0.3; // Penalize recently ordered items
        }
      }
      
      productScores[productId] = totalScore;
    }
    
    // Sort by scores and return top recommendations
    final sortedProducts = productScores.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take up to the limit, ensuring we have enough products
    final productsToTake = math.min(limit, sortedProducts.length);
    
    for (var entry in sortedProducts.take(productsToTake)) {
      try {
        final product = allProducts.firstWhere((p) => p.id == entry.key);
        recommendations.add(product);
      } catch (e) {
        debugPrint('Product not found for ID: ${entry.key}');
        // Skip this product instead of adding a wrong one
      }
    }
    
    return recommendations;
  }

  // Log recommendation events for ML learning
  Future<void> _logRecommendationEvent(String userId, List<Product> recommendations, String type) async {
    try {
      final event = {
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'recommendationType': type,
        'productIds': recommendations.map((p) => p.id).toList(),
        'algorithm': 'hybrid_ml',
        'userAgent': 'flutter_app',
      };
      
      await _firestore.collection('recommendationEvents').add(event);
    } catch (e) {
      debugPrint('Error logging recommendation event: $e');
    }
  }

  // Helper methods for scoring algorithms
  Map<String, double> _getContentBasedRecommendations(
    List<Product> products, UserPreferences preferences, List<app_order.Order> orderHistory, String? context) {
    final scores = <String, double>{};
    
    for (final product in products) {
      final productId = product.id;
      
      double score = 0.0;
      
      // Category preference boost
      if (preferences.favoriteCategories.contains(product.categoryId)) {
        score += 0.4;
      }
      
      // Price range match
      if (_isInPriceRange(product, preferences.preferredPriceRange)) {
        score += 0.2;
      }
      
      // Historical preference (based on order history)
      final pastOrders = orderHistory.where((order) =>
        order.product.categoryId == product.categoryId).length;
      score += pastOrders * 0.1;
      
      // Rating boost
      if (product.rating != null) {
        score += (product.rating! / 5.0) * 0.3;
      }
      
      scores[productId] = score;
    }
    
    return scores;
  }

  Map<String, double> _getCollaborativeScores(
    List<Product> products, List<UserPreferences> similarUsers, List<app_order.Order> userOrderHistory) {
    final scores = <String, double>{};
    final productPreferenceCount = <String, int>{};
    
    // Count preferences for each product from similar users
    for (final user in similarUsers) {
      for (final category in user.favoriteCategories) {
        final productsInCategory = products.where((p) => p.categoryId == category);
        for (final product in productsInCategory) {
          final productId = product.id;
          productPreferenceCount[productId] = (productPreferenceCount[productId] ?? 0) + 1;
        }
      }
    }
    
    // Also consider products ordered by similar users
    for (final order in userOrderHistory) {
      // Get the product ID from the order data or product object
      final productId = order.product.id;
      productPreferenceCount[productId] = (productPreferenceCount[productId] ?? 0) + 2; // Weighted higher for actual orders
    }
    
    // Normalize scores to 0-1 range
    final maxCount = productPreferenceCount.values.isEmpty ? 1 : productPreferenceCount.values.reduce(math.max);
    for (final entry in productPreferenceCount.entries) {
      scores[entry.key] = maxCount > 0 ? entry.value / maxCount : 0.0;
    }
    
    // Initialize scores for all products (0 for products without collaborative signals)
    for (final product in products) {
      if (!scores.containsKey(product.id)) {
        scores[product.id] = 0.0;
      }
    }
    
    return scores;
  }

  Map<String, double> _getContextualRecommendations(
    List<Product> products, Map<String, dynamic>? userContext, String? context) {
    final scores = <String, double>{};
    
    if (context == null) return scores;
    
    for (final product in products) {
      final productId = product.id;
      
      double score = 0.0;
      
      // Time-based context
      switch (context) {
        case 'breakfast':
          if (product.name.toLowerCase().contains('breakfast') ||
              product.name.toLowerCase().contains('coffee') ||
              product.name.toLowerCase().contains('pastry')) {
            score += 0.5;
          }
          break;
        case 'lunch':
          if (product.name.toLowerCase().contains('salad') ||
              product.name.toLowerCase().contains('wrap') ||
              product.price < 20) {
            score += 0.5;
          }
          break;
        case 'dinner':
          if (product.name.toLowerCase().contains('pizza') ||
              product.name.toLowerCase().contains('pasta') ||
              product.name.toLowerCase().contains('dinner')) {
            score += 0.5;
          }
          break;
      }
      
      scores[productId] = score;
    }
    
    return scores;
  }

  Future<Map<String, double>> _getTrendingRecommendations(List<Product> products) async {
    // Enhanced trending algorithm based on actual order data and ratings
    final scores = <String, double>{};
    final productOrderCounts = <String, int>{};
    
    try {
      // Get recent orders for trending calculation
      final since = DateTime.now().subtract(Duration(days: 7));
      final ordersQuery = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();
      
      // Count product orders
      for (var doc in ordersQuery.docs) {
        final orderData = doc.data();
        if (orderData['items'] != null) {
          for (var item in orderData['items']) {
            final productId = item['productId'] as String?;
            if (productId != null) {
              productOrderCounts[productId] = (productOrderCounts[productId] ?? 0) + 1;
            }
          }
        }
      }
      
      // Calculate trending scores
      final maxOrders = productOrderCounts.values.isEmpty ? 1 : productOrderCounts.values.reduce(math.max);
      
      for (final product in products) {
        final productId = product.id;
        
        double score = 0.0;
        
        // Trending factor based on recent order count
        final orderCount = productOrderCounts[productId] ?? 0;
        if (maxOrders > 0) {
          score += (orderCount / maxOrders) * 0.5;
        }
        
        // Rating factor
        if (product.rating != null) {
          score += (product.rating! / 5.0) * 0.3;
        }
        
        // Availability factor
        if (product.isAvailable) {
          score += 0.2;
        }
        
        scores[productId] = score;
      }
    } catch (e) {
      debugPrint('Error calculating trending recommendations: $e');
      // Fallback to simple rating-based scoring
      for (final product in products) {
        final productId = product.id;
        
        double score = 0.0;
        if (product.rating != null) {
          score += (product.rating! / 5.0) * 0.7;
        }
        if (product.isAvailable) {
          score += 0.3;
        }
        scores[productId] = score;
      }
    }
    
    return scores;
  }

  Map<String, double> _getPopularityRecommendations(List<Product> products) {
    // Global popularity based on ratings and review counts
    final scores = <String, double>{};
    
    for (final product in products) {
      final productId = product.id;
      
      double score = 0.0;
      
      if (product.rating != null) {
        score += (product.rating! / 5.0) * 0.6;
      }
      
      if (product.reviewCount > 0) {
        final normalizedReviews = math.min(product.reviewCount / 100.0, 1.0);
        score += normalizedReviews * 0.4;
      }
      
      scores[productId] = score;
    }
    
    return scores;
  }

  // Utility methods
  bool _isInPriceRange(Product product, PriceRange range) {
    return product.price >= range.min && product.price <= range.max;
  }

  double _calculateRangeOverlap(double min1, double max1, double min2, double max2) {
    final overlapMin = math.max(min1, min2);
    final overlapMax = math.min(max1, max2);
    final overlap = math.max(0, overlapMax - overlapMin);
    final total = math.max(max1, max2) - math.min(min1, min2);
    return total > 0 ? overlap / total : 0.0;
  }

  int _countCommonItems(Iterable<String> set1, Iterable<String> set2) {
    return set1.where((item) => set2.contains(item)).length;
  }

  int _countTotalItems(Iterable<String> set1, Iterable<String> set2) {
    return set1.toSet().union(set2.toSet()).length;
  }
}

enum UserActivity {
  ordered,
  favorited,
  rated,
  viewed,
}