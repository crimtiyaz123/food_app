import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ar_experience.dart';
import '../models/product.dart';

class ARExperienceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get AR menu items for a restaurant
  Future<List<ARMenuItem>> getARMenuItems({
    required String restaurantId,
    String? categoryId,
    ARExperienceType? experienceType,
  }) async {
    try {
      Query query = _firestore
          .collection('arMenuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('hasARExperience', isEqualTo: true);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} has null data');
          return null;
        }
        return ARMenuItem.fromJson(doc.id, data as Map<String, dynamic>);
      }).where((item) => item != null).cast<ARMenuItem>().where((item) {
        if (experienceType == null) return true;
        // Filter by experience type based on available models and features
        switch (experienceType) {
          case ARExperienceType.foodVisualization:
            return item.models3D.isNotEmpty;
          case ARExperienceType.nutritionOverlay:
            return item.nutritionOverlay.isNotEmpty;
          case ARExperienceType.allergenHighlight:
            return item.allergenHighlights.isNotEmpty;
          case ARExperienceType.portionComparison:
            return item.models3D.length > 1;
          case ARExperienceType.cookingProcess:
            return item.models3D.any((model) => 
                model.animationUrls.isNotEmpty);
          case ARExperienceType.ingredientExplore:
            return item.hotspots.any((hotspot) => 
                hotspot.type == 'ingredient');
          case ARExperienceType.specialOffer:
            return item.isOnPromotion;
          case ARExperienceType.dietaryFilters:
            return item.hotspots.any((hotspot) => 
                hotspot.type == 'dietary');
          case ARExperienceType.comboVisualization:
            return item.hotspots.any((hotspot) => 
                hotspot.type == 'combo');
          case ARExperienceType.restaurantTour:
            return false; // Restaurant tours are separate
        }
      }).toList();
    } catch (e) {
      debugPrint('Error getting AR menu items: $e');
      return [];
    }
  }

  // Get specific AR menu item with full details
  Future<ARMenuItem?> getARMenuItem(String menuItemId) async {
    try {
      final doc = await _firestore.collection('arMenuItems').doc(menuItemId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data == null) {
          debugPrint('Warning: Document $menuItemId has null data');
          return null;
        }
        return ARMenuItem.fromJson(doc.id, data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting AR menu item: $e');
      return null;
    }
  }

  // Start AR experience session
  Future<String> startARExperience({
    required String userId,
    required String menuItemId,
    required String sessionType,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final session = ARExperienceSession(
        id: '',
        userId: userId,
        menuItemId: menuItemId,
        sessionType: sessionType,
        startTime: DateTime.now(),
        interactionsCount: 0,
        visitedHotspots: [],
        deviceInfo: deviceInfo,
        satisfactionRating: 0.0,
        analytics: {},
      );

      final docRef = await _firestore.collection('arExperienceSessions').add(
        session.toJson()
      );

      // Update menu item usage analytics
      await _updateMenuItemAnalytics(menuItemId, 'session_started');

      return docRef.id;
    } catch (e) {
      debugPrint('Error starting AR experience: $e');
      rethrow;
    }
  }

  // End AR experience session
  Future<void> endARExperience({
    required String sessionId,
    required int interactionsCount,
    required List<String> visitedHotspots,
    required double satisfactionRating,
  }) async {
    try {
      final sessionRef = _firestore.collection('arExperienceSessions').doc(sessionId);
      
      await sessionRef.update({
        'endTime': DateTime.now().millisecondsSinceEpoch,
        'interactionsCount': interactionsCount,
        'visitedHotspots': visitedHotspots,
        'satisfactionRating': satisfactionRating,
      });

      // Get session data to update menu item analytics
      final sessionDoc = await sessionRef.get();
      if (sessionDoc.exists) {
        final data = sessionDoc.data();
        if (data == null) {
          debugPrint('Warning: Session document $sessionId has null data');
          return;
        }
        final session = ARExperienceSession.fromJson(sessionId, data);
        await _updateMenuItemAnalytics(session.menuItemId, 'session_ended', {
          'interactionsCount': interactionsCount,
          'sessionDuration': session.duration?.inSeconds ?? 0,
          'satisfactionRating': satisfactionRating,
        });
      }
    } catch (e) {
      debugPrint('Error ending AR experience: $e');
    }
  }

  // Record hotspot interaction
  Future<void> recordHotspotInteraction({
    required String sessionId,
    required String hotspotId,
    required String action, // 'tapped', 'viewed', 'dismissed'
  }) async {
    try {
      final sessionRef = _firestore.collection('arExperienceSessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();
      
      if (sessionDoc.exists) {
        final data = sessionDoc.data();
        if (data == null) {
          debugPrint('Warning: Session document $sessionId has null data');
          return;
        }
        final session = ARExperienceSession.fromJson(sessionId, data);
        final updatedVisitedHotspots = List<String>.from(session.visitedHotspots);
        
        if (!updatedVisitedHotspots.contains(hotspotId)) {
          updatedVisitedHotspots.add(hotspotId);
        }

        await sessionRef.update({
          'visitedHotspots': updatedVisitedHotspots,
          'interactionsCount': session.interactionsCount + 1,
        });

        // Update hotspot analytics
        await _updateHotspotAnalytics(hotspotId, action);
      }
    } catch (e) {
      debugPrint('Error recording hotspot interaction: $e');
    }
  }

  // Get AR restaurant tours
  Future<List<ARRestaurantTour>> getRestaurantTours(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('arRestaurantTours')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} has null data');
          return null;
        }
        return ARRestaurantTour.fromJson(doc.id, data as Map<String, dynamic>);
      }).where((tour) => tour != null).cast<ARRestaurantTour>().toList();
    } catch (e) {
      debugPrint('Error getting restaurant tours: $e');
      return [];
    }
  }

  // Get personalized AR recommendations
  Future<List<ARMenuItem>> getPersonalizedARRecommendations({
    required String userId,
    String? restaurantId,
    int limit = 5,
  }) async {
    try {
      // Get user preferences and AR history
      final userPreferences = await _getUserPreferences(userId);
      final userARHistory = await _getUserARHistory(userId);
      
      // Get available AR menu items
      final arItems = restaurantId != null 
          ? await getARMenuItems(restaurantId: restaurantId)
          : await _getAllARMenuItems();

      // Score items based on user preferences and history
      final scoredItems = <ARMenuItem, double>{};
      
      for (final item in arItems) {
        double score = 0.0;
        
        // Boost score for categories in user preferences
        if (userPreferences['favoriteCategories'] != null) {
          final favoriteCategories = userPreferences['favoriteCategories'] as List;
          if (favoriteCategories.contains(item.categoryId)) {
            score += 0.3;
          }
        }
        
        // Boost score for items with high usage count
        score += (item.usageCount / 100.0).clamp(0.0, 0.2);
        
        // Boost score for high satisfaction items
        if (item.analytics['averageSatisfaction'] != null) {
          final satisfaction = item.analytics['averageSatisfaction'] as double;
          score += satisfaction * 0.2;
        }
        
        // Reduce score for recently viewed items
        final recentlyViewed = userARHistory.any((historyItem) => 
            historyItem['menuItemId'] == item.id && 
            (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
                historyItem['lastViewed'])).inHours < 24));
        
        if (recentlyViewed) {
          score -= 0.4;
        }
        
        // Boost score for items with multiple AR features
        final featureCount = _countARFeatures(item);
        score += featureCount * 0.1;
        
        if (score > 0) {
          scoredItems[item] = score;
        }
      }
      
      // Sort by score and return top items
      final sortedItems = scoredItems.entries
          .toList();
      sortedItems.sort((a, b) => b.value.compareTo(a.value));
      
      return sortedItems
          .map((entry) => entry.key)
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('Error getting personalized AR recommendations: $e');
      return [];
    }
  }

  // Get AR analytics for restaurant
  Future<Map<String, dynamic>> getARAnalytics({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Query query = startDate != null && endDate != null
          ? _firestore
              .collection('arExperienceSessions')
              .where('startTime', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
              .where('startTime', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          : _firestore.collection('arExperienceSessions');

      final sessionsSnapshot = await query.get();
      final sessions = sessionsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data == null) {
              debugPrint('Warning: Document ${doc.id} has null data');
              return null;
            }
            return ARExperienceSession.fromJson(doc.id, data as Map<String, dynamic>);
          })
          .where((session) => session != null)
          .cast<ARExperienceSession>()
          .toList();

      // Filter sessions by restaurant
      final menuItems = await getARMenuItems(restaurantId: restaurantId);
      final restaurantMenuItemIds = menuItems.map((item) => item.id).toSet();
      final restaurantSessions = sessions
          .where((session) => restaurantMenuItemIds.contains(session.menuItemId))
          .toList();

      final analytics = {
        'totalSessions': restaurantSessions.length,
        'activeSessions': restaurantSessions.where((s) => s.isActive).length,
        'completedSessions': restaurantSessions.where((s) => !s.isActive).length,
        'averageSessionDuration': _calculateAverageSessionDuration(restaurantSessions),
        'averageInteractionsPerSession': _calculateAverageInteractions(restaurantSessions),
        'averageSatisfactionRating': _calculateAverageSatisfaction(restaurantSessions),
        'mostPopularItems': _getMostPopularARItems(restaurantSessions, menuItems),
        'hotspotInteractionStats': _getHotspotInteractionStats(restaurantSessions),
        'deviceCompatibilityStats': _getDeviceCompatibilityStats(restaurantSessions),
        'sessionTypeDistribution': _getSessionTypeDistribution(restaurantSessions),
        'errorRate': _calculateErrorRate(restaurantSessions),
        'popularTimeSlots': _getPopularTimeSlots(restaurantSessions),
      };

      return analytics;
    } catch (e) {
      debugPrint('Error getting AR analytics: $e');
      return {};
    }
  }

  // Generate AR 3D model recommendations
  Future<List<String>> generate3DModelRecommendations({
    required String itemName,
    required String category,
    required List<String> requiredFeatures,
  }) async {
    try {
      // This would integrate with AI services for 3D model generation
      // For now, return recommended features based on category
      final recommendations = <String>[];
      
      switch (category.toLowerCase()) {
        case 'burger':
        case 'sandwich':
          recommendations.addAll([
            'top_view_3d_model',
            'side_view_3d_model',
            'ingredient_highlight',
            'nutrition_overlay',
            'size_comparison'
          ]);
          break;
        case 'pizza':
          recommendations.addAll([
            'top_view_3d_model',
            'slice_visualization',
            'toppings_overlay',
            'nutrition_breakdown',
            'portion_size_guide'
          ]);
          break;
        case 'dessert':
          recommendations.addAll([
            'full_view_3d_model',
            'texture_detail',
            'serving_suggestion',
            'nutrition_info',
            'allergen_warning'
          ]);
          break;
        case 'drink':
          recommendations.addAll([
            'bottle_3d_model',
            'serving_size_visualization',
            'nutrition_facts',
            'ice_cube_animation',
            'stirring_animation'
          ]);
          break;
        default:
          recommendations.addAll([
            'basic_3d_model',
            'nutrition_overlay',
            'allergen_highlight'
          ]);
      }
      
      return recommendations;
    } catch (e) {
      debugPrint('Error generating 3D model recommendations: $e');
      return [];
    }
  }

  // Private helper methods
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('userPreferences').doc(userId).get();
      return doc.exists ? (doc.data() as Map<String, dynamic>) : {};
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getUserARHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('arExperienceSessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} has null data');
          return null;
        }
        return {
          'menuItemId': data['menuItemId'],
          'lastViewed': data['startTime'],
        };
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error getting user AR history: $e');
      return [];
    }
  }

  Future<List<ARMenuItem>> _getAllARMenuItems() async {
    try {
      final snapshot = await _firestore
          .collection('arMenuItems')
          .where('hasARExperience', isEqualTo: true)
          .limit(1000) // Limit for performance
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} has null data');
          return null;
        }
        return ARMenuItem.fromJson(doc.id, data as Map<String, dynamic>);
      }).where((item) => item != null).cast<ARMenuItem>().toList();
    } catch (e) {
      debugPrint('Error getting all AR menu items: $e');
      return [];
    }
  }

  int _countARFeatures(ARMenuItem item) {
    int count = 0;
    if (item.models3D.isNotEmpty) count++;
    if (item.hotspots.isNotEmpty) count++;
    if (item.nutritionOverlay.isNotEmpty) count++;
    if (item.allergenHighlights.isNotEmpty) count++;
    if (item.isOnPromotion) count++;
    return count;
  }

  Future<void> _updateMenuItemAnalytics(
    String menuItemId, 
    String event, [
    Map<String, dynamic>? additionalData,
  ]) async {
    try {
      final menuItemRef = _firestore.collection('arMenuItems').doc(menuItemId);
      
      final updateData = {
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'analytics.$event': FieldValue.increment(1),
        'analytics.lastEvent': event,
        'analytics.lastEventTime': DateTime.now().millisecondsSinceEpoch,
      };

      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          updateData['analytics.${entry.key}'] = entry.value;
        }
      }

      await menuItemRef.update(updateData);
    } catch (e) {
      debugPrint('Error updating menu item analytics: $e');
    }
  }

  Future<void> _updateHotspotAnalytics(String hotspotId, String action) async {
    try {
      await _firestore.collection('arHotspotAnalytics').doc('$hotspotId-$action').set({
        'hotspotId': hotspotId,
        'action': action,
        'count': FieldValue.increment(1),
        'lastAction': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating hotspot analytics: $e');
    }
  }

  // Analytics calculation methods
  double _calculateAverageSessionDuration(List<ARExperienceSession> sessions) {
    final completedSessions = sessions.where((s) => !s.isActive).toList();
    if (completedSessions.isEmpty) return 0.0;
    
    final totalDuration = completedSessions.fold<int>(0, (sum, session) {
      return sum + (session.duration?.inSeconds ?? 0);
    });
    
    return totalDuration / completedSessions.length;
  }

  double _calculateAverageInteractions(List<ARExperienceSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    
    final totalInteractions = sessions.fold<int>(0, (sum, session) {
      return sum + session.interactionsCount;
    });
    
    return totalInteractions / sessions.length;
  }

  double _calculateAverageSatisfaction(List<ARExperienceSession> sessions) {
    final ratedSessions = sessions.where((s) => s.satisfactionRating > 0).toList();
    if (ratedSessions.isEmpty) return 0.0;
    
    final totalRating = ratedSessions.fold<double>(0, (sum, session) {
      return sum + session.satisfactionRating;
    });
    
    return totalRating / ratedSessions.length;
  }

  List<Map<String, dynamic>> _getMostPopularARItems(
    List<ARExperienceSession> sessions, 
    List<ARMenuItem> menuItems,
  ) {
    final itemCount = <String, int>{};
    
    for (final session in sessions) {
      itemCount[session.menuItemId] = (itemCount[session.menuItemId] ?? 0) + 1;
    }
    
    final sortedItems = itemCount.entries
        .toList();
    sortedItems.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedItems
        .take(10)
        .map((entry) {
      final menuItem = menuItems.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => throw Exception('Menu item not found'),
      );
      
      return {
        'menuItem': menuItem,
        'sessionCount': entry.value,
      };
    }).toList();
  }

  Map<String, int> _getHotspotInteractionStats(List<ARExperienceSession> sessions) {
    final interactionCount = <String, int>{};
    
    for (final session in sessions) {
      for (final hotspotId in session.visitedHotspots) {
        interactionCount[hotspotId] = (interactionCount[hotspotId] ?? 0) + 1;
      }
    }
    
    return interactionCount;
  }

  Map<String, int> _getDeviceCompatibilityStats(List<ARExperienceSession> sessions) {
    final deviceStats = <String, int>{};
    
    for (final session in sessions) {
      final deviceType = session.deviceInfo['deviceType'] ?? 'Unknown';
      deviceStats[deviceType] = (deviceStats[deviceType] ?? 0) + 1;
    }
    
    return deviceStats;
  }

  Map<String, int> _getSessionTypeDistribution(List<ARExperienceSession> sessions) {
    final typeCount = <String, int>{};
    
    for (final session in sessions) {
      typeCount[session.sessionType] = (typeCount[session.sessionType] ?? 0) + 1;
    }
    
    return typeCount;
  }

  double _calculateErrorRate(List<ARExperienceSession> sessions) {
    final sessionsWithErrors = sessions.where((s) => s.errorMessage != null).toList();
    if (sessions.isEmpty) return 0.0;
    
    return sessionsWithErrors.length / sessions.length;
  }

  Map<String, int> _getPopularTimeSlots(List<ARExperienceSession> sessions) {
    final timeSlotCount = <String, int>{};
    
    for (final session in sessions) {
      final hour = session.startTime.hour;
      String timeSlot;
      
      if (hour >= 6 && hour < 12) {
        timeSlot = 'Morning (6-12)';
      } else if (hour >= 12 && hour < 17) {
        timeSlot = 'Afternoon (12-17)';
      } else if (hour >= 17 && hour < 22) {
        timeSlot = 'Evening (17-22)';
      } else {
        timeSlot = 'Night (22-6)';
      }
      
      timeSlotCount[timeSlot] = (timeSlotCount[timeSlot] ?? 0) + 1;
    }
    
    return timeSlotCount;
  }

  // AR content management methods
  Future<void> uploadARContent({
    required String menuItemId,
    required AR3DModel model3D,
    List<ARHotspot>? hotspots,
    List<ARNutritionInfo>? nutritionInfo,
    List<ARAllergenInfo>? allergenInfo,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update menu item with new AR content
      final menuItemRef = _firestore.collection('arMenuItems').doc(menuItemId);
      
      final updateData = {
        'hasARExperience': true,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      batch.update(menuItemRef, updateData);

      // Add/update 3D model
      if (model3D.id.isEmpty) {
        final modelRef = _firestore.collection('ar3DModels').doc();
        batch.set(modelRef, {
          ...model3D.toJson(),
          'id': modelRef.id,
          'menuItemId': menuItemId,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Add hotspots if provided
      if (hotspots != null) {
        for (final hotspot in hotspots) {
          final hotspotRef = _firestore.collection('arHotspots').doc();
          batch.set(hotspotRef, {
            ...hotspot.toJson(),
            'id': hotspotRef.id,
            'menuItemId': menuItemId,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error uploading AR content: $e');
      rethrow;
    }
  }

  // Performance optimization methods
  Future<Map<String, dynamic>> getARPerformanceMetrics(String restaurantId) async {
    try {
      final arItems = await getARMenuItems(restaurantId: restaurantId);
      
      final metrics = {
        'totalARItems': arItems.length,
        'itemsWith3DModels': arItems.where((item) => item.models3D.isNotEmpty).length,
        'averageFileSize': _calculateAverageFileSize(arItems),
        'itemsWithAnimations': arItems.where((item) => 
            item.models3D.any((model) => model.animationUrls.isNotEmpty)).length,
        'mostComplexModel': _getMostComplexModel(arItems),
        'storageUsage': _calculateStorageUsage(arItems),
        'optimizationSuggestions': _generateOptimizationSuggestions(arItems),
      };

      return metrics;
    } catch (e) {
      debugPrint('Error getting AR performance metrics: $e');
      return {};
    }
  }

  double _calculateAverageFileSize(List<ARMenuItem> items) {
    final totalSize = items.fold<double>(0, (sum, item) {
      return sum + item.models3D.fold<double>(0, (modelSum, model) {
        return modelSum + model.fileSize;
      });
    });
    
    final totalModels = items.fold<int>(0, (sum, item) => sum + item.models3D.length);
    
    return totalModels > 0 ? totalSize / totalModels : 0.0;
  }

  AR3DModel? _getMostComplexModel(List<ARMenuItem> items) {
    AR3DModel? mostComplex;
    
    for (final item in items) {
      for (final model in item.models3D) {
        if (mostComplex == null || model.polygonCount > mostComplex.polygonCount) {
          mostComplex = model;
        }
      }
    }
    
    return mostComplex;
  }

  double _calculateStorageUsage(List<ARMenuItem> items) {
    return items.fold<double>(0, (sum, item) {
      return sum + item.models3D.fold<double>(0, (modelSum, model) {
        return modelSum + model.fileSize;
      });
    });
  }

  List<String> _generateOptimizationSuggestions(List<ARMenuItem> items) {
    final suggestions = <String>[];
    
    // Check for large file sizes
    final largeFiles = items.where((item) => 
        item.models3D.any((model) => model.fileSize > 10.0)).toList();
    
    if (largeFiles.isNotEmpty) {
      suggestions.add('${largeFiles.length} items have large 3D files (>10MB). Consider optimization.');
    }
    
    // Check for high polygon counts
    final highPolyItems = items.where((item) => 
        item.models3D.any((model) => model.polygonCount > 50000)).toList();
    
    if (highPolyItems.isNotEmpty) {
      suggestions.add('${highPolyItems.length} items have high polygon counts. Consider mesh optimization.');
    }
    
    // Check for missing hotspots
    final itemsWithoutHotspots = items.where((item) => item.hotspots.isEmpty).toList();
    
    if (itemsWithoutHotspots.isNotEmpty) {
      suggestions.add('${itemsWithoutHotspots.length} items have no interactive hotspots. Add engagement features.');
    }
    
    return suggestions;
  }
}