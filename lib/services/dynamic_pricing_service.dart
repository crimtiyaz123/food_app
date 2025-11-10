import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/dynamic_pricing.dart';

class DynamicPricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get dynamically priced menu items for a restaurant
  Future<List<DynamicMenuItem>> getDynamicMenuItems({
    required String restaurantId,
    String? categoryId,
  }) async {
    try {
      Query query = _firestore
          .collection('dynamicMenuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isActive', isEqualTo: true);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} has null data');
          return null;
        }
        return DynamicMenuItem.fromJson(doc.id, data);
      }).whereType<DynamicMenuItem>().toList();
    } catch (e) {
      debugPrint('Error getting dynamic menu items: $e');
      return [];
    }
  }

  // Calculate dynamic price for a menu item
  Future<double> calculateDynamicPrice({
    required String menuItemId,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Get menu item
      final menuItem = await getMenuItem(menuItemId);
      if (menuItem == null) return 0.0;

      double finalPrice = menuItem.basePrice;
      final applicableRules = await _getApplicableRules(menuItemId, context);

      // Apply pricing rules
      for (final rule in applicableRules) {
        final priceAdjustment = _applyPricingRule(rule, finalPrice, context);
        finalPrice += priceAdjustment;
      }

      // Apply market intelligence
      final marketAdjustedPrice = await _applyMarketIntelligence(
        menuItemId, 
        finalPrice, 
        context,
      );

      return marketAdjustedPrice;
    } catch (e) {
      debugPrint('Error calculating dynamic price: $e');
      return 0.0;
    }
  }

  // Update menu item price dynamically
  Future<bool> updateMenuItemPrice({
    required String menuItemId,
    required double newPrice,
    required String reason,
    String? userId,
  }) async {
    try {
      final menuItemRef = _firestore.collection('dynamicMenuItems').doc(menuItemId);
      
      await menuItemRef.update({
        'currentPrice': newPrice,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'lastPriceChangeReason': reason,
        'lastUpdatedBy': userId,
        'priceChangeHistory': FieldValue.arrayUnion([
          {
            'previousPrice': FieldValue.delete(), // Will be set by transaction
            'newPrice': newPrice,
            'reason': reason,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'updatedBy': userId,
          }
        ]),
      });

      // Log the price change
      await _logPriceChange(menuItemId, newPrice, reason, userId);

      return true;
    } catch (e) {
      debugPrint('Error updating menu item price: $e');
      return false;
    }
  }

  // Generate AI pricing recommendations
  Future<List<PricingRecommendation>> generatePricingRecommendations({
    required String restaurantId,
    String? menuItemId,
  }) async {
    try {
      final recommendations = <PricingRecommendation>[];
      
      // Get market intelligence data
      final marketIntelligence = await _getMarketIntelligence(restaurantId);
      
      // Get menu items
      final menuItems = await getDynamicMenuItems(restaurantId: restaurantId);
      final targetItems = menuItemId != null 
          ? menuItems.where((item) => item.id == menuItemId).toList()
          : menuItems;

      for (final menuItem in targetItems) {
        final recommendation = await _generateIndividualRecommendation(
          menuItem,
          marketIntelligence,
        );
        if (recommendation != null) {
          recommendations.add(recommendation);
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error generating pricing recommendations: $e');
      return [];
    }
  }

  // Apply bulk pricing updates
  Future<bool> applyBulkPricingUpdate({
    required String restaurantId,
    required List<String> menuItemIds,
    required String updateType, // 'percentage_increase', 'percentage_decrease', 'fixed_amount', 'competitor_match'
    required dynamic value,
    required String reason,
    String? userId,
  }) async {
    try {
      final batch = _firestore.batch();
      final updateTimestamp = DateTime.now();

      for (final menuItemId in menuItemIds) {
        final menuItemRef = _firestore.collection('dynamicMenuItems').doc(menuItemId);
        
        // Get current price
        final currentDoc = await menuItemRef.get();
        if (!currentDoc.exists) continue;
        
        final currentData = currentDoc.data() as Map<String, dynamic>?;
        if (currentData == null) {
          debugPrint('Warning: Document $menuItemId has null data, skipping');
          continue;
        }
        final currentItem = DynamicMenuItem.fromJson(menuItemId, currentData);
        double newPrice = currentItem.currentPrice;

        // Calculate new price based on update type
        switch (updateType) {
          case 'percentage_increase':
            newPrice = currentItem.currentPrice * (1 + (value as double) / 100);
            break;
          case 'percentage_decrease':
            newPrice = currentItem.currentPrice * (1 - (value as double) / 100);
            break;
          case 'fixed_amount':
            newPrice = currentItem.currentPrice + (value as double);
            break;
          case 'competitor_match':
            // This would use competitor pricing data
            newPrice = _getCompetitorPrice(currentItem.name, value as Map<String, dynamic>);
            break;
        }

        // Ensure price is not negative
        newPrice = newPrice < 0 ? 0 : newPrice;

        batch.update(menuItemRef, {
          'currentPrice': newPrice,
          'lastUpdated': updateTimestamp.millisecondsSinceEpoch,
          'lastPriceChangeReason': reason,
          'lastUpdatedBy': userId,
        });
      }

      await batch.commit();

      // Log bulk update
      await _logBulkPriceChange(
        restaurantId,
        menuItemIds,
        updateType,
        value,
        reason,
        userId,
      );

      return true;
    } catch (e) {
      debugPrint('Error applying bulk pricing update: $e');
      return false;
    }
  }

  // Get menu customization for an item
  Future<List<MenuCustomization>> getMenuCustomizations(String menuItemId) async {
    try {
      final snapshot = await _firestore
          .collection('menuCustomizations')
          .where('menuItemId', isEqualTo: menuItemId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} has null data');
          return null;
        }
        return MenuCustomization.fromJson(doc.id, data);
      }).whereType<MenuCustomization>().toList();
    } catch (e) {
      debugPrint('Error getting menu customizations: $e');
      return [];
    }
  }

  // Update menu customization
  Future<bool> updateMenuCustomization({
    required String menuItemId,
    required List<MenuCustomization> customizations,
  }) async {
    try {
      final batch = _firestore.batch();

      // Delete existing customizations
      final existingSnapshot = await _firestore
          .collection('menuCustomizations')
          .where('menuItemId', isEqualTo: menuItemId)
          .get();

      for (final doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new customizations
      for (final customization in customizations) {
        final docRef = _firestore.collection('menuCustomizations').doc();
        batch.set(docRef, {
          ...customization.toJson(),
          'menuItemId': menuItemId,
          'id': docRef.id,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error updating menu customization: $e');
      return false;
    }
  }

  // Get pricing analytics
  Future<Map<String, dynamic>> getPricingAnalytics({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final menuItems = await getDynamicMenuItems(restaurantId: restaurantId);
      
      final analytics = {
        'totalItems': menuItems.length,
        'averagePrice': menuItems.isEmpty ? 0.0 : 
            menuItems.fold<double>(0, (sum, item) => sum + item.currentPrice) / menuItems.length,
        'itemsOnPromotion': menuItems.where((item) => item.isOnPromotion()).length,
        'priceRange': {
          'min': menuItems.isEmpty ? 0.0 : menuItems.map((item) => item.currentPrice).reduce(min),
          'max': menuItems.isEmpty ? 0.0 : menuItems.map((item) => item.currentPrice).reduce(max),
        },
        'popularityDistribution': _calculatePopularityDistribution(menuItems),
        'demandScoreAverage': menuItems.isEmpty ? 0.0 : 
            menuItems.fold<double>(0, (sum, item) => sum + item.demandScore) / menuItems.length,
        'stockLevels': _calculateStockLevels(menuItems),
        'customizationUsage': await _calculateCustomizationUsage(restaurantId),
      };

      return analytics;
    } catch (e) {
      debugPrint('Error getting pricing analytics: $e');
      return {};
    }
  }

  // Private helper methods
  Future<DynamicMenuItem?> getMenuItem(String menuItemId) async {
    try {
      final doc = await _firestore.collection('dynamicMenuItems').doc(menuItemId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Warning: Document ${doc.id} exists but has null data');
          return null;
        }
        return DynamicMenuItem.fromJson(doc.id, data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting menu item: $e');
      return null;
    }
  }

  Future<List<PricingRule>> _getApplicableRules(
    String menuItemId, 
    Map<String, dynamic> context,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('pricingRules')
          .where('menuItemId', isEqualTo: menuItemId)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      final applicableRules = <PricingRule>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Warning: Pricing rule document ${doc.id} has null data, skipping');
          continue;
        }
        
        final rule = PricingRule.fromJson(doc.id, data);
        
        // Check if rule conditions are met
        bool allConditionsMet = true;
        for (final condition in rule.conditions) {
          if (!condition.evaluate(context)) {
            allConditionsMet = false;
            break;
          }
        }
        
        if (allConditionsMet) {
          applicableRules.add(rule);
        }
      }

      return applicableRules;
    } catch (e) {
      debugPrint('Error getting applicable rules: $e');
      return [];
    }
  }

  double _applyPricingRule(
    PricingRule rule, 
    double currentPrice, 
    Map<String, dynamic> context,
  ) {
    double adjustment = 0.0;

    for (final action in rule.actions) {
      switch (action.type) {
        case 'set_price':
          adjustment = (action.value as double) - currentPrice;
          break;
        case 'adjust_price':
          if (action.value is double) {
            adjustment += action.value;
          } else if (action.value is String && action.value.startsWith('+')) {
            adjustment += double.parse(action.value.substring(1));
          } else if (action.value is String && action.value.startsWith('-')) {
            adjustment -= double.parse(action.value.substring(1));
          }
          break;
        case 'apply_discount':
          final discountPercent = action.value as double;
          adjustment = - (currentPrice * discountPercent / 100);
          break;
        case 'set_availability':
          // This would handle stock-based availability
          break;
      }
    }

    return adjustment;
  }

  Future<double> _applyMarketIntelligence(
    String menuItemId,
    double basePrice,
    Map<String, dynamic> context,
  ) async {
    try {
      // Get market intelligence for the restaurant
      final marketData = await _getMarketIntelligence(context['restaurantId'] as String);
      
      // Apply market-based adjustments
      double adjustedPrice = basePrice;
      
      // Adjust based on market score
      if (marketData.marketScore > 0.7) {
        adjustedPrice *= 1.1; // Premium market
      } else if (marketData.marketScore < 0.3) {
        adjustedPrice *= 0.9; // Budget market
      }

      // Apply competitor-based adjustments
      final competitorPrice = _getCompetitorPrice(menuItemId, marketData.competitorPrices);
      if (competitorPrice > 0) {
        final priceDiff = (competitorPrice - adjustedPrice) / competitorPrice;
        if (priceDiff > 0.2) {
          adjustedPrice = competitorPrice * 0.95; // Slightly under competitor
        }
      }

      return adjustedPrice;
    } catch (e) {
      debugPrint('Error applying market intelligence: $e');
      return basePrice;
    }
  }

  Future<PricingRecommendation?> _generateIndividualRecommendation(
    DynamicMenuItem menuItem,
    MarketIntelligence marketIntelligence,
  ) async {
    try {
      // AI algorithm to determine optimal price
      final factors = <String>[];
      double recommendedPrice = menuItem.currentPrice;
      String rationale = '';

      // Factor 1: Demand score
      if (menuItem.demandScore > 0.7) {
        recommendedPrice *= 1.15;
        factors.add('High demand (+15%)');
      } else if (menuItem.demandScore < 0.3) {
        recommendedPrice *= 0.9;
        factors.add('Low demand (-10%)');
      }

      // Factor 2: Stock level
      if (menuItem.stockLevel < 10) {
        recommendedPrice *= 1.1;
        factors.add('Limited stock (+10%)');
      }

      // Factor 3: Market competition
      final competitorPrice = _getCompetitorPrice(menuItem.name, marketIntelligence.competitorPrices);
      if (competitorPrice > 0) {
        if (recommendedPrice < competitorPrice * 0.8) {
          recommendedPrice = competitorPrice * 0.9;
          factors.add('Below market (-10% to match)');
        } else if (recommendedPrice > competitorPrice * 1.2) {
          recommendedPrice = competitorPrice * 1.1;
          factors.add('Above market (+10% reduction)');
        }
      }

      // Factor 4: Time-based adjustments
      final currentHour = DateTime.now().hour;
      if (currentHour >= 11 && currentHour <= 14) {
        // Lunch rush
        recommendedPrice *= 1.05;
        factors.add('Lunch rush (+5%)');
      } else if (currentHour >= 17 && currentHour <= 21) {
        // Dinner rush
        recommendedPrice *= 1.08;
        factors.add('Dinner rush (+8%)');
      }

      // Factor 5: Popularity
      if (menuItem.popularityScore > 80) {
        recommendedPrice *= 1.12;
        factors.add('High popularity (+12%)');
      }

      // Ensure price is reasonable
      final maxPrice = menuItem.basePrice * 2.0; // Max 100% markup
      final minPrice = menuItem.basePrice * 0.7; // Min 30% discount
      recommendedPrice = recommendedPrice.clamp(minPrice, maxPrice);

      // Calculate confidence score
      double confidenceScore = 0.5;
      if (factors.isNotEmpty) confidenceScore += 0.1;
      if (marketIntelligence.marketScore > 0.5) confidenceScore += 0.2;
      if (menuItem.stockLevel > 0) confidenceScore += 0.1;
      confidenceScore = confidenceScore.clamp(0.0, 1.0);

      if (factors.isNotEmpty) {
        rationale = 'Recommended price based on: ${factors.join(', ')}';
        
        return PricingRecommendation(
          menuItemId: menuItem.id,
          recommendedPrice: recommendedPrice,
          confidenceScore: confidenceScore,
          rationale: rationale,
          factors: factors,
          generatedAt: DateTime.now(),
          metadata: {
            'basePrice': menuItem.basePrice,
            'currentPrice': menuItem.currentPrice,
            'demandScore': menuItem.demandScore,
            'stockLevel': menuItem.stockLevel,
            'marketScore': marketIntelligence.marketScore,
          },
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error generating individual recommendation: $e');
      return null;
    }
  }

  Future<MarketIntelligence> _getMarketIntelligence(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('marketIntelligence')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return MarketIntelligence(
          restaurantId: restaurantId,
          timestamp: DateTime.now(),
          competitorPrices: {},
          demandPatterns: {},
          seasonalTrends: {},
          localEvents: {},
          marketScore: 0.5,
          insights: [],
        );
      }

      final marketData = snapshot.docs.first.data() as Map<String, dynamic>?;
      if (marketData == null) {
        debugPrint('Warning: Market intelligence document has null data');
        return MarketIntelligence(
          restaurantId: restaurantId,
          timestamp: DateTime.now(),
          competitorPrices: {},
          demandPatterns: {},
          seasonalTrends: {},
          localEvents: {},
          marketScore: 0.5,
          insights: [],
        );
      }
      return MarketIntelligence.fromJson(marketData);
    } catch (e) {
      debugPrint('Error getting market intelligence: $e');
      return MarketIntelligence(
        restaurantId: restaurantId,
        timestamp: DateTime.now(),
        competitorPrices: {},
        demandPatterns: {},
        seasonalTrends: {},
        localEvents: {},
        marketScore: 0.5,
        insights: [],
      );
    }
  }

  double _getCompetitorPrice(String itemName, Map<String, dynamic> competitorPrices) {
    // Simple lookup - in a real implementation, this would use more sophisticated matching
    return (competitorPrices[itemName] as double?) ?? 0.0;
  }

  Map<String, int> _calculatePopularityDistribution(List<DynamicMenuItem> items) {
    final distribution = <String, int>{
      'High (80-100)': items.where((item) => item.popularityScore >= 80).length,
      'Medium (50-79)': items.where((item) => item.popularityScore >= 50 && item.popularityScore < 80).length,
      'Low (0-49)': items.where((item) => item.popularityScore < 50).length,
    };
    return distribution;
  }

  Map<String, int> _calculateStockLevels(List<DynamicMenuItem> items) {
    final distribution = <String, int>{
      'High (50+)': items.where((item) => item.stockLevel >= 50).length,
      'Medium (10-49)': items.where((item) => item.stockLevel >= 10 && item.stockLevel < 50).length,
      'Low (1-9)': items.where((item) => item.stockLevel >= 1 && item.stockLevel < 10).length,
      'Out of Stock': items.where((item) => item.stockLevel == 0).length,
    };
    return distribution;
  }

  Future<Map<String, dynamic>> _calculateCustomizationUsage(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('menuCustomizations')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      final totalCustomizations = snapshot.docs.length;
      final activeCustomizations = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      return {
        'totalCustomizations': totalCustomizations,
        'activeCustomizations': activeCustomizations,
        'usageRate': totalCustomizations > 0 ? activeCustomizations / totalCustomizations : 0.0,
      };
    } catch (e) {
      debugPrint('Error calculating customization usage: $e');
      return {
        'totalCustomizations': 0,
        'activeCustomizations': 0,
        'usageRate': 0.0,
      };
    }
  }

  Future<void> _logPriceChange(
    String menuItemId,
    double newPrice,
    String reason,
    String? userId,
  ) async {
    try {
      await _firestore.collection('priceChangeLogs').add({
        'menuItemId': menuItemId,
        'newPrice': newPrice,
        'reason': reason,
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'individual',
      });
    } catch (e) {
      debugPrint('Error logging price change: $e');
    }
  }

  Future<void> _logBulkPriceChange(
    String restaurantId,
    List<String> menuItemIds,
    String updateType,
    dynamic value,
    String reason,
    String? userId,
  ) async {
    try {
      await _firestore.collection('priceChangeLogs').add({
        'restaurantId': restaurantId,
        'menuItemIds': menuItemIds,
        'updateType': updateType,
        'value': value,
        'reason': reason,
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'bulk',
      });
    } catch (e) {
      debugPrint('Error logging bulk price change: $e');
    }
  }

  // Schedule automatic price updates
  Future<void> scheduleAutomaticPriceUpdates(String restaurantId) async {
    try {
      // This would typically be called by a background job
      final recommendations = await generatePricingRecommendations(
        restaurantId: restaurantId,
      );

      for (final recommendation in recommendations) {
        if (recommendation.confidenceScore > 0.7) {
          await updateMenuItemPrice(
            menuItemId: recommendation.menuItemId,
            newPrice: recommendation.recommendedPrice,
            reason: 'AI Recommendation: ${recommendation.rationale}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling automatic price updates: $e');
    }
  }
}