// Dynamic Pricing Models for AI-powered menu optimization

import 'package:cloud_firestore/cloud_firestore.dart';

// Pricing Strategy Types
enum PricingStrategy {
  demandBased,        // High demand = higher prices
  timeBased,          // Peak hours pricing
  stockBased,         // Low stock = higher prices
  competitorBased,    // Market competition
  seasonal,          // Seasonal adjustments
  personalized,      // User-specific pricing
  promotional,       // Special offers/discounts
  bulk,             // Volume-based pricing
  loyalty           // Loyalty program pricing
}

// Menu Item Customization
class MenuCustomization {
  final String id;
  final String name;
  final String description;
  final List<CustomizationOption> options;
  final double additionalPrice;
  final bool isRequired;
  final int maxSelections;
  final int minSelections;
  final Map<String, dynamic> aiMetadata;

  MenuCustomization({
    required this.id,
    required this.name,
    required this.description,
    required this.options,
    required this.additionalPrice,
    required this.isRequired,
    required this.maxSelections,
    required this.minSelections,
    required this.aiMetadata,
  });

  factory MenuCustomization.fromJson(String id, Map<String, dynamic> json) {
    return MenuCustomization(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => CustomizationOption.fromJson(e))
          .toList() ?? [],
      additionalPrice: (json['additionalPrice'] ?? 0.0).toDouble(),
      isRequired: json['isRequired'] ?? false,
      maxSelections: json['maxSelections'] ?? 1,
      minSelections: json['minSelections'] ?? 0,
      aiMetadata: Map<String, dynamic>.from(json['aiMetadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'options': options.map((e) => e.toJson()).toList(),
      'additionalPrice': additionalPrice,
      'isRequired': isRequired,
      'maxSelections': maxSelections,
      'minSelections': minSelections,
      'aiMetadata': aiMetadata,
    };
  }
}

// Customization Option
class CustomizationOption {
  final String id;
  final String name;
  final String description;
  final double priceAdjustment;
  final bool isAvailable;
  final int popularityScore;
  final Map<String, dynamic> nutritionalInfo;

  CustomizationOption({
    required this.id,
    required this.name,
    required this.description,
    required this.priceAdjustment,
    required this.isAvailable,
    required this.popularityScore,
    required this.nutritionalInfo,
  });

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      priceAdjustment: (json['priceAdjustment'] ?? 0.0).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      popularityScore: json['popularityScore'] ?? 0,
      nutritionalInfo: Map<String, dynamic>.from(json['nutritionalInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceAdjustment': priceAdjustment,
      'isAvailable': isAvailable,
      'popularityScore': popularityScore,
      'nutritionalInfo': nutritionalInfo,
    };
  }
}

// Dynamic Pricing Rule
class PricingRule {
  final String id;
  final String name;
  final PricingStrategy strategy;
  final List<PricingCondition> conditions;
  final List<PricingAction> actions;
  final double priority;
  final bool isActive;
  final DateTime validFrom;
  final DateTime validUntil;
  final Map<String, dynamic> metadata;

  PricingRule({
    required this.id,
    required this.name,
    required this.strategy,
    required this.conditions,
    required this.actions,
    required this.priority,
    required this.isActive,
    required this.validFrom,
    required this.validUntil,
    required this.metadata,
  });

  factory PricingRule.fromJson(String id, Map<String, dynamic> json) {
    return PricingRule(
      id: id,
      name: json['name'] ?? '',
      strategy: PricingStrategy.values.firstWhere(
        (e) => e.toString().split('.').last == json['strategy'],
        orElse: () => PricingStrategy.demandBased,
      ),
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((e) => PricingCondition.fromJson(e))
          .toList() ?? [],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => PricingAction.fromJson(e))
          .toList() ?? [],
      priority: (json['priority'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      validFrom: DateTime.fromMillisecondsSinceEpoch(json['validFrom'] ?? 0),
      validUntil: DateTime.fromMillisecondsSinceEpoch(json['validUntil'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'strategy': strategy.toString().split('.').last,
      'conditions': conditions.map((e) => e.toJson()).toList(),
      'actions': actions.map((e) => e.toJson()).toList(),
      'priority': priority,
      'isActive': isActive,
      'validFrom': validFrom.millisecondsSinceEpoch,
      'validUntil': validUntil.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}

// Pricing Condition
class PricingCondition {
  final String field;
  final String operator; // 'equals', 'greater_than', 'less_than', 'between', 'in_list'
  final dynamic value;
  final String? logicalOperator; // 'and', 'or'

  PricingCondition({
    required this.field,
    required this.operator,
    required this.value,
    this.logicalOperator,
  });

  factory PricingCondition.fromJson(Map<String, dynamic> json) {
    return PricingCondition(
      field: json['field'] ?? '',
      operator: json['operator'] ?? '',
      value: json['value'],
      logicalOperator: json['logicalOperator'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator,
      'value': value,
      'logicalOperator': logicalOperator,
    };
  }

  bool evaluate(Map<String, dynamic> context) {
    final contextValue = context[field];
    
    switch (operator) {
      case 'equals':
        return contextValue == value;
      case 'greater_than':
        return (contextValue as num?) != null && (contextValue as num) > (value as num);
      case 'less_than':
        return (contextValue as num?) != null && (contextValue as num) < (value as num);
      case 'between':
        if (value is List && value.length == 2) {
          final numValue = contextValue as num?;
          return numValue != null && numValue >= (value[0] as num) && numValue <= (value[1] as num);
        }
        return false;
      case 'in_list':
        return value is List && (value as List).contains(contextValue);
      default:
        return false;
    }
  }
}

// Pricing Action
class PricingAction {
  final String type; // 'set_price', 'adjust_price', 'apply_discount', 'set_availability'
  final dynamic value;
  final String? description;

  PricingAction({
    required this.type,
    required this.value,
    this.description,
  });

  factory PricingAction.fromJson(Map<String, dynamic> json) {
    return PricingAction(
      type: json['type'] ?? '',
      value: json['value'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'description': description,
    };
  }
}

// Dynamic Menu Item
class DynamicMenuItem {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double basePrice;
  final double currentPrice;
  final double? originalPrice;
  final List<MenuCustomization> customizations;
  final Map<String, dynamic> nutritionalInfo;
  final List<String> allergens;
  final List<String> dietaryTags;
  final int popularityScore;
  final double demandScore;
  final int stockLevel;
  final int maxDailyQuantity;
  final List<String> imageUrls;
  final Map<String, dynamic> aiMetadata;
  final DateTime lastUpdated;
  final List<PricingRule> activePricingRules;

  DynamicMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.basePrice,
    required this.currentPrice,
    this.originalPrice,
    required this.customizations,
    required this.nutritionalInfo,
    required this.allergens,
    required this.dietaryTags,
    required this.popularityScore,
    required this.demandScore,
    required this.stockLevel,
    required this.maxDailyQuantity,
    required this.imageUrls,
    required this.aiMetadata,
    required this.lastUpdated,
    required this.activePricingRules,
  });

  factory DynamicMenuItem.fromJson(String id, Map<String, dynamic> json) {
    return DynamicMenuItem(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      customizations: (json['customizations'] as List<dynamic>?)
          ?.map((e) => MenuCustomization.fromJson(e['id'] ?? '', e))
          .toList() ?? [],
      nutritionalInfo: Map<String, dynamic>.from(json['nutritionalInfo'] ?? {}),
      allergens: List<String>.from(json['allergens'] ?? []),
      dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
      popularityScore: json['popularityScore'] ?? 0,
      demandScore: (json['demandScore'] ?? 0.0).toDouble(),
      stockLevel: json['stockLevel'] ?? 0,
      maxDailyQuantity: json['maxDailyQuantity'] ?? 0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      aiMetadata: Map<String, dynamic>.from(json['aiMetadata'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      activePricingRules: (json['activePricingRules'] as List<dynamic>?)
          ?.map((e) => PricingRule.fromJson(e['id'] ?? '', e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'basePrice': basePrice,
      'currentPrice': currentPrice,
      'originalPrice': originalPrice,
      'customizations': customizations.map((e) => e.toJson()).toList(),
      'nutritionalInfo': nutritionalInfo,
      'allergens': allergens,
      'dietaryTags': dietaryTags,
      'popularityScore': popularityScore,
      'demandScore': demandScore,
      'stockLevel': stockLevel,
      'maxDailyQuantity': maxDailyQuantity,
      'imageUrls': imageUrls,
      'aiMetadata': aiMetadata,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'activePricingRules': activePricingRules.map((e) => e.toJson()).toList(),
    };
  }

  // Check if item is available
  bool isAvailable() {
    return stockLevel > 0 && maxDailyQuantity > 0;
  }

  // Check if item is on promotion
  bool isOnPromotion() {
    return originalPrice != null && originalPrice! > currentPrice;
  }

  // Get discount percentage
  double? getDiscountPercentage() {
    if (originalPrice == null || originalPrice! <= 0) return null;
    return ((originalPrice! - currentPrice) / originalPrice!) * 100;
  }

  // Get final price with customizations
  double getFinalPriceWithCustomizations(List<CustomizationSelection> selections) {
    double totalPrice = currentPrice;
    
    for (final selection in selections) {
      final customization = customizations.firstWhere(
        (c) => c.id == selection.customizationId,
        orElse: () => throw Exception('Customization not found: ${selection.customizationId}'),
      );
      
      // Find the selected option within the customization
      final option = customization.options.firstWhere(
        (o) => o.id == selection.optionId,
        orElse: () => throw Exception('Option not found: ${selection.optionId} in customization ${selection.customizationId}'),
      );
      
      // Use the additional cost from selection if available, otherwise use option's price adjustment
      totalPrice += selection.additionalCost > 0 ? selection.additionalCost : option.priceAdjustment;
    }
    
    return totalPrice;
  }
}

// Customization Selection - Aligned with database schema
class CustomizationSelection {
  final String customizationId;
  final String optionId;
  final String optionName;
  final String valueId;
  final String valueName;
  final double additionalCost;

  CustomizationSelection({
    required this.customizationId,
    required this.optionId,
    required this.optionName,
    required this.valueId,
    required this.valueName,
    this.additionalCost = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'customizationId': customizationId,
      'optionId': optionId,
      'optionName': optionName,
      'valueId': valueId,
      'valueName': valueName,
      'additionalCost': additionalCost,
    };
  }

  factory CustomizationSelection.fromJson(Map<String, dynamic> json) {
    return CustomizationSelection(
      customizationId: json['customizationId'] ?? '',
      optionId: json['optionId'] ?? '',
      optionName: json['optionName'] ?? '',
      valueId: json['valueId'] ?? '',
      valueName: json['valueName'] ?? '',
      additionalCost: (json['additionalCost'] ?? 0.0).toDouble(),
    );
  }
}

// Market Intelligence Data
class MarketIntelligence {
  final String restaurantId;
  final DateTime timestamp;
  final Map<String, dynamic> competitorPrices;
  final Map<String, dynamic> demandPatterns;
  final Map<String, dynamic> seasonalTrends;
  final Map<String, dynamic> localEvents;
  final double marketScore;
  final List<String> insights;

  MarketIntelligence({
    required this.restaurantId,
    required this.timestamp,
    required this.competitorPrices,
    required this.demandPatterns,
    required this.seasonalTrends,
    required this.localEvents,
    required this.marketScore,
    required this.insights,
  });

  factory MarketIntelligence.fromJson(Map<String, dynamic> json) {
    return MarketIntelligence(
      restaurantId: json['restaurantId'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      competitorPrices: Map<String, dynamic>.from(json['competitorPrices'] ?? {}),
      demandPatterns: Map<String, dynamic>.from(json['demandPatterns'] ?? {}),
      seasonalTrends: Map<String, dynamic>.from(json['seasonalTrends'] ?? {}),
      localEvents: Map<String, dynamic>.from(json['localEvents'] ?? {}),
      marketScore: (json['marketScore'] ?? 0.0).toDouble(),
      insights: List<String>.from(json['insights'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'competitorPrices': competitorPrices,
      'demandPatterns': demandPatterns,
      'seasonalTrends': seasonalTrends,
      'localEvents': localEvents,
      'marketScore': marketScore,
      'insights': insights,
    };
  }
}

// AI Pricing Recommendation
class PricingRecommendation {
  final String menuItemId;
  final double recommendedPrice;
  final double confidenceScore;
  final String rationale;
  final List<String> factors;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  PricingRecommendation({
    required this.menuItemId,
    required this.recommendedPrice,
    required this.confidenceScore,
    required this.rationale,
    required this.factors,
    required this.generatedAt,
    required this.metadata,
  });

  factory PricingRecommendation.fromJson(Map<String, dynamic> json) {
    return PricingRecommendation(
      menuItemId: json['menuItemId'] ?? '',
      recommendedPrice: (json['recommendedPrice'] ?? 0.0).toDouble(),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      rationale: json['rationale'] ?? '',
      factors: List<String>.from(json['factors'] ?? []),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(json['generatedAt'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'recommendedPrice': recommendedPrice,
      'confidenceScore': confidenceScore,
      'rationale': rationale,
      'factors': factors,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}