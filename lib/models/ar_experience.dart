// AR Menu Experience Models for 3D food visualization and virtual environments

import 'package:cloud_firestore/cloud_firestore.dart';

// AR Experience Types
enum ARExperienceType {
  foodVisualization,    // 3D food preview
  restaurantTour,       // Virtual restaurant walkthrough
  nutritionOverlay,     // Nutritional information display
  allergenHighlight,    // Allergen warnings in AR
  portionComparison,    // Size comparison visualization
  cookingProcess,       // Step-by-step cooking visualization
  ingredientExplore,    // 3D ingredient breakdown
  specialOffer,         // AR promotional experiences
  dietaryFilters,       // Visual dietary information
  comboVisualization    // Bundle/combo item visualization
}

// 3D Model Information
class AR3DModel {
  final String id;
  final String name;
  final String description;
  final String modelUrl; // URL to 3D model file (GLB/GLTF)
  final String textureUrl; // URL to texture file
  final List<String> animationUrls; // URLs to animation files
  final Vector3 scale; // 3D scale (x, y, z)
  final Vector3 position; // 3D position (x, y, z)
  final Vector3 rotation; // 3D rotation (x, y, z)
  final Map<String, dynamic> materials; // Material properties
  final Map<String, dynamic> metadata; // Additional model data
  final int polygonCount; // 3D model complexity
  final double fileSize; // File size in MB
  final List<String> supportedDevices; // Device compatibility

  AR3DModel({
    required this.id,
    required this.name,
    required this.description,
    required this.modelUrl,
    required this.textureUrl,
    required this.animationUrls,
    required this.scale,
    required this.position,
    required this.rotation,
    required this.materials,
    required this.metadata,
    required this.polygonCount,
    required this.fileSize,
    required this.supportedDevices,
  });

  factory AR3DModel.fromJson(String id, Map<String, dynamic> json) {
    return AR3DModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      modelUrl: json['modelUrl'] ?? '',
      textureUrl: json['textureUrl'] ?? '',
      animationUrls: List<String>.from(json['animationUrls'] ?? []),
      scale: Vector3.fromJson(json['scale'] ?? {}),
      position: Vector3.fromJson(json['position'] ?? {}),
      rotation: Vector3.fromJson(json['rotation'] ?? {}),
      materials: Map<String, dynamic>.from(json['materials'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      polygonCount: json['polygonCount'] ?? 0,
      fileSize: (json['fileSize'] ?? 0.0).toDouble(),
      supportedDevices: List<String>.from(json['supportedDevices'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'modelUrl': modelUrl,
      'textureUrl': textureUrl,
      'animationUrls': animationUrls,
      'scale': scale.toJson(),
      'position': position.toJson(),
      'rotation': rotation.toJson(),
      'materials': materials,
      'metadata': metadata,
      'polygonCount': polygonCount,
      'fileSize': fileSize,
      'supportedDevices': supportedDevices,
    };
  }
}

// 3D Vector for AR positioning
class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3({
    required this.x,
    required this.y,
    required this.z,
  });

  factory Vector3.fromJson(Map<String, dynamic> json) {
    return Vector3(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      z: (json['z'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }

  static Vector3 get zero => Vector3(x: 0, y: 0, z: 0);
  static Vector3 get one => Vector3(x: 1, y: 1, z: 1);
}

// AR Menu Item with 3D visualization
class ARMenuItem {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double basePrice;
  final double? promotionalPrice;
  final List<AR3DModel> models3D; // Multiple 3D models for different views
  final List<ARHotspot> hotspots; // Interactive AR hotspots
  final List<ARNutritionInfo> nutritionOverlay; // Nutritional information
  final List<ARAllergenInfo> allergenHighlights; // Allergen warnings
  final Map<String, dynamic> interactiveElements; // Tap/gesture interactions
  final ARVisualizationConfig visualizationConfig; // AR display settings
  final DateTime lastUpdated;
  final int usageCount; // How often AR is used for this item
  final double averageInteractionTime; // Average time spent in AR view
  final Map<String, dynamic> analytics; // Usage analytics

  ARMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.basePrice,
    this.promotionalPrice,
    required this.models3D,
    required this.hotspots,
    required this.nutritionOverlay,
    required this.allergenHighlights,
    required this.interactiveElements,
    required this.visualizationConfig,
    required this.lastUpdated,
    required this.usageCount,
    required this.averageInteractionTime,
    required this.analytics,
  });

  factory ARMenuItem.fromJson(String id, Map<String, dynamic> json) {
    return ARMenuItem(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      promotionalPrice: json['promotionalPrice']?.toDouble(),
      models3D: (json['models3D'] as List<dynamic>?)
          ?.map((e) => AR3DModel.fromJson(e['id'] ?? '', e))
          .toList() ?? [],
      hotspots: (json['hotspots'] as List<dynamic>?)
          ?.map((e) => ARHotspot.fromJson(e))
          .toList() ?? [],
      nutritionOverlay: (json['nutritionOverlay'] as List<dynamic>?)
          ?.map((e) => ARNutritionInfo.fromJson(e))
          .toList() ?? [],
      allergenHighlights: (json['allergenHighlights'] as List<dynamic>?)
          ?.map((e) => ARAllergenInfo.fromJson(e))
          .toList() ?? [],
      interactiveElements: Map<String, dynamic>.from(json['interactiveElements'] ?? {}),
      visualizationConfig: ARVisualizationConfig.fromJson(json['visualizationConfig'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      usageCount: json['usageCount'] ?? 0,
      averageInteractionTime: (json['averageInteractionTime'] ?? 0.0).toDouble(),
      analytics: Map<String, dynamic>.from(json['analytics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'basePrice': basePrice,
      'promotionalPrice': promotionalPrice,
      'models3D': models3D.map((e) => e.toJson()).toList(),
      'hotspots': hotspots.map((e) => e.toJson()).toList(),
      'nutritionOverlay': nutritionOverlay.map((e) => e.toJson()).toList(),
      'allergenHighlights': allergenHighlights.map((e) => e.toJson()).toList(),
      'interactiveElements': interactiveElements,
      'visualizationConfig': visualizationConfig.toJson(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'usageCount': usageCount,
      'averageInteractionTime': averageInteractionTime,
      'analytics': analytics,
    };
  }

  // Check if item has AR experience
  bool get hasARExperience => models3D.isNotEmpty;
  
  // Get primary 3D model
  AR3DModel? get primaryModel => models3D.isNotEmpty ? models3D.first : null;
  
  // Calculate savings
  double? get savings => promotionalPrice != null 
      ? (basePrice - promotionalPrice!) 
      : null;
  
  // Check if on promotion
  bool get isOnPromotion => promotionalPrice != null && promotionalPrice! < basePrice;
}

// AR Hotspot for interactive elements
class ARHotspot {
  final String id;
  final String name;
  final String type; // 'info', 'nutrition', 'allergen', 'ingredient', 'custom'
  final Vector3 position; // 3D position in AR space
  final Vector2? screenPosition; // 2D position for fallback
  final String title;
  final String description;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic> metadata;
  final bool isVisible; // Default visibility
  final int zIndex; // Layer order

  ARHotspot({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.screenPosition,
    required this.title,
    required this.description,
    this.imageUrl,
    this.actionUrl,
    required this.metadata,
    required this.isVisible,
    required this.zIndex,
  });

  factory ARHotspot.fromJson(Map<String, dynamic> json) {
    return ARHotspot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      position: Vector3.fromJson(json['position'] ?? {}),
      screenPosition: json['screenPosition'] != null 
          ? Vector2.fromJson(json['screenPosition'])
          : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isVisible: json['isVisible'] ?? true,
      zIndex: json['zIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'position': position.toJson(),
      'screenPosition': screenPosition?.toJson(),
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'metadata': metadata,
      'isVisible': isVisible,
      'zIndex': zIndex,
    };
  }
}

// 2D Vector for AR positioning
class Vector2 {
  final double x;
  final double y;

  Vector2({
    required this.x,
    required this.y,
  });

  factory Vector2.fromJson(Map<String, dynamic> json) {
    return Vector2(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  static Vector2 get zero => Vector2(x: 0, y: 0);
  static Vector2 get one => Vector2(x: 1, y: 1);
}

// AR Nutrition Information Overlay
class ARNutritionInfo {
  final String nutrient; // 'calories', 'protein', 'carbs', 'fat', etc.
  final double value;
  final String unit; // 'g', 'mg', 'kcal'
  final String dailyValue; // % of daily value
  final String color; // Color for AR display
  final String icon; // Icon name for visualization
  final Vector3 position; // 3D position in AR space

  ARNutritionInfo({
    required this.nutrient,
    required this.value,
    required this.unit,
    required this.dailyValue,
    required this.color,
    required this.icon,
    required this.position,
  });

  factory ARNutritionInfo.fromJson(Map<String, dynamic> json) {
    return ARNutritionInfo(
      nutrient: json['nutrient'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      dailyValue: json['dailyValue'] ?? '',
      color: json['color'] ?? '',
      icon: json['icon'] ?? '',
      position: Vector3.fromJson(json['position'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nutrient': nutrient,
      'value': value,
      'unit': unit,
      'dailyValue': dailyValue,
      'color': color,
      'icon': icon,
      'position': position.toJson(),
    };
  }
}

// AR Allergen Information
class ARAllergenInfo {
  final String allergen; // 'peanuts', 'dairy', 'gluten', etc.
  final String severity; // 'low', 'medium', 'high'
  final String warningText; // Warning message
  final String color; // Color for warning (red, orange, yellow)
  final String icon; // Warning icon
  final Vector3 position; // 3D position in AR space
  final bool highlightModel; // Whether to highlight the 3D model

  ARAllergenInfo({
    required this.allergen,
    required this.severity,
    required this.warningText,
    required this.color,
    required this.icon,
    required this.position,
    required this.highlightModel,
  });

  factory ARAllergenInfo.fromJson(Map<String, dynamic> json) {
    return ARAllergenInfo(
      allergen: json['allergen'] ?? '',
      severity: json['severity'] ?? '',
      warningText: json['warningText'] ?? '',
      color: json['color'] ?? '',
      icon: json['icon'] ?? '',
      position: Vector3.fromJson(json['position'] ?? {}),
      highlightModel: json['highlightModel'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergen': allergen,
      'severity': severity,
      'warningText': warningText,
      'color': color,
      'icon': icon,
      'position': position.toJson(),
      'highlightModel': highlightModel,
    };
  }
}

// AR Visualization Configuration
class ARVisualizationConfig {
  final String environment; // 'kitchen', 'table', 'restaurant', 'outdoor'
  final String lighting; // 'bright', 'dim', 'natural', 'warm'
  final String background; // 'transparent', 'kitchen', 'restaurant', 'custom'
  final double modelScale; // Default scale multiplier
  final Vector3 modelPosition; // Default position
  final String animationStyle; // 'bounce', 'rotate', 'float', 'static'
  final bool showShadows; // Enable shadow rendering
  final bool enableParticleEffects; // Enable particle effects
  final List<String> interactiveGestures; // Supported gestures
  final Map<String, dynamic> customSettings; // Custom configuration

  ARVisualizationConfig({
    required this.environment,
    required this.lighting,
    required this.background,
    required this.modelScale,
    required this.modelPosition,
    required this.animationStyle,
    required this.showShadows,
    required this.enableParticleEffects,
    required this.interactiveGestures,
    required this.customSettings,
  });

  factory ARVisualizationConfig.fromJson(Map<String, dynamic> json) {
    return ARVisualizationConfig(
      environment: json['environment'] ?? 'table',
      lighting: json['lighting'] ?? 'natural',
      background: json['background'] ?? 'transparent',
      modelScale: (json['modelScale'] ?? 1.0).toDouble(),
      modelPosition: Vector3.fromJson(json['modelPosition'] ?? {}),
      animationStyle: json['animationStyle'] ?? 'static',
      showShadows: json['showShadows'] ?? true,
      enableParticleEffects: json['enableParticleEffects'] ?? false,
      interactiveGestures: List<String>.from(json['interactiveGestures'] ?? []),
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'environment': environment,
      'lighting': lighting,
      'background': background,
      'modelScale': modelScale,
      'modelPosition': modelPosition.toJson(),
      'animationStyle': animationStyle,
      'showShadows': showShadows,
      'enableParticleEffects': enableParticleEffects,
      'interactiveGestures': interactiveGestures,
      'customSettings': customSettings,
    };
  }
}

// AR Experience Session
class ARExperienceSession {
  final String id;
  final String userId;
  final String menuItemId;
  final String sessionType; // 'visualization', 'nutrition', 'allergen', 'tour'
  final DateTime startTime;
  final DateTime? endTime;
  final int interactionsCount; // Number of interactions
  final List<String> visitedHotspots; // Hotspots that were tapped
  final Map<String, dynamic> deviceInfo; // Device capabilities
  final String? errorMessage; // Any errors during session
  final double satisfactionRating; // User rating after session
  final Map<String, dynamic> analytics; // Session analytics

  ARExperienceSession({
    required this.id,
    required this.userId,
    required this.menuItemId,
    required this.sessionType,
    required this.startTime,
    this.endTime,
    required this.interactionsCount,
    required this.visitedHotspots,
    required this.deviceInfo,
    this.errorMessage,
    required this.satisfactionRating,
    required this.analytics,
  });

  factory ARExperienceSession.fromJson(String id, Map<String, dynamic> json) {
    return ARExperienceSession(
      id: id,
      userId: json['userId'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      sessionType: json['sessionType'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime']) 
          : null,
      interactionsCount: json['interactionsCount'] ?? 0,
      visitedHotspots: List<String>.from(json['visitedHotspots'] ?? []),
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] ?? {}),
      errorMessage: json['errorMessage'],
      satisfactionRating: (json['satisfactionRating'] ?? 0.0).toDouble(),
      analytics: Map<String, dynamic>.from(json['analytics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'menuItemId': menuItemId,
      'sessionType': sessionType,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'interactionsCount': interactionsCount,
      'visitedHotspots': visitedHotspots,
      'deviceInfo': deviceInfo,
      'errorMessage': errorMessage,
      'satisfactionRating': satisfactionRating,
      'analytics': analytics,
    };
  }

  // Calculate session duration
  Duration? get duration => endTime != null 
      ? endTime!.difference(startTime) 
      : null;
  
  // Check if session is still active
  bool get isActive => endTime == null;
}

// AR Restaurant Tour
class ARRestaurantTour {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final List<ARTourStop> stops; // Tour stop points
  final ARVisualizationConfig environmentConfig; // Environment settings
  final Duration estimatedDuration;
  final List<String> supportedLanguages;
  final Map<String, dynamic> metadata;

  ARRestaurantTour({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.stops,
    required this.environmentConfig,
    required this.estimatedDuration,
    required this.supportedLanguages,
    required this.metadata,
  });

  factory ARRestaurantTour.fromJson(String id, Map<String, dynamic> json) {
    return ARRestaurantTour(
      id: id,
      restaurantId: json['restaurantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stops: (json['stops'] as List<dynamic>?)
          ?.map((e) => ARTourStop.fromJson(e))
          .toList() ?? [],
      environmentConfig: ARVisualizationConfig.fromJson(json['environmentConfig'] ?? {}),
      estimatedDuration: Duration(seconds: json['estimatedDuration'] ?? 300),
      supportedLanguages: List<String>.from(json['supportedLanguages'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'stops': stops.map((e) => e.toJson()).toList(),
      'environmentConfig': environmentConfig.toJson(),
      'estimatedDuration': estimatedDuration.inSeconds,
      'supportedLanguages': supportedLanguages,
      'metadata': metadata,
    };
  }
}

// AR Tour Stop Point
class ARTourStop {
  final String id;
  final String name;
  final String description;
  final Vector3 position; // 3D position in restaurant
  final String content; // Text/multi-media content
  final List<String> mediaUrls; // Images/videos for this stop
  final Map<String, dynamic> interactiveElements;
  final int order; // Stop order in tour
  final Duration duration; // Suggested time at this stop

  ARTourStop({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.content,
    required this.mediaUrls,
    required this.interactiveElements,
    required this.order,
    required this.duration,
  });

  factory ARTourStop.fromJson(Map<String, dynamic> json) {
    return ARTourStop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      position: Vector3.fromJson(json['position'] ?? {}),
      content: json['content'] ?? '',
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      interactiveElements: Map<String, dynamic>.from(json['interactiveElements'] ?? {}),
      order: json['order'] ?? 0,
      duration: Duration(seconds: json['duration'] ?? 30),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'position': position.toJson(),
      'content': content,
      'mediaUrls': mediaUrls,
      'interactiveElements': interactiveElements,
      'order': order,
      'duration': duration.inSeconds,
    };
  }
}