/**
 * Comprehensive Firestore Database Schema for AI-Powered Food Delivery App
 * This schema supports all 14+ advanced features with proper relationships and indexing
 */

// ===============================
// 1. USER COLLECTIONS
// ===============================

/**
 * Core user data with AI preferences and personalization
 * Document ID: user_{userId}
 */
class UserDocument {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String profileImage;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isActive;
  final UserPreferences userPreferences;
  final LocationData defaultLocation;
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final String preferredLanguage;
  final String userType; // 'customer', 'restaurant_owner', 'delivery_partner', 'admin'
  final Map<String, dynamic> metadata;

  UserDocument({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.profileImage = '',
    required this.createdAt,
    required this.lastActive,
    this.isActive = true,
    required this.userPreferences,
    required this.defaultLocation,
    required this.dietaryRestrictions,
    required this.allergies,
    this.preferredLanguage = 'en',
    this.userType = 'customer',
    this.metadata = const {},
  });
}

/**
 * AI-powered user preferences and behavior tracking
 */
class UserPreferences {
  final String userId;
  final List<String> favoriteCategories;
  final List<String> favoriteRestaurants;
  final Map<String, double> cuisinePreferences; // cuisine -> preference score (0-1)
  final Map<String, double> dietaryPreferences; // restriction -> preference (0-1)
  final PriceRange preferredPriceRange;
  final List<String> spicePreferences;
  final TimePreference orderTimePreference;
  final double averageOrderValue;
  final int orderFrequency; // orders per week
  final List<String> favoriteItems;
  final Map<String, int> interactionCounts; // productId -> view count
  final DateTime lastUpdated;
  final double aiConfidenceScore; // How confident AI is about preferences
  final Map<String, dynamic> behavioralPatterns; // AI-detected patterns

  UserPreferences({
    required this.userId,
    this.favoriteCategories = const [],
    this.favoriteRestaurants = const [],
    this.cuisinePreferences = const {},
    this.dietaryPreferences = const {},
    required this.preferredPriceRange,
    this.spicePreferences = const [],
    required this.orderTimePreference,
    this.averageOrderValue = 0.0,
    this.orderFrequency = 0,
    this.favoriteItems = const [],
    this.interactionCounts = const {},
    required this.lastUpdated,
    this.aiConfidenceScore = 0.0,
    this.behavioralPatterns = const {},
  });
}

/**
 * Price range for user preferences
 */
class PriceRange {
  final double min;
  final double max;

  PriceRange({required this.min, required this.max});
}

/**
 * Time preferences for ordering
 */
class TimePreference {
  final List<int> preferredDays; // 0=Sunday, 1=Monday, etc.
  final List<String> preferredTimeSlots; // 'breakfast', 'lunch', 'dinner', 'late_night'
  final Map<String, double> timeSlotPreferences; // slot -> preference score

  TimePreference({
    required this.preferredDays,
    required this.preferredTimeSlots,
    this.timeSlotPreferences = const {},
  });
}

/**
 * User location data with geohashing for efficient queries
 */
class LocationData {
  final String id;
  final String label; // 'Home', 'Work', 'Other'
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String geohash; // For efficient location-based queries
  final bool isDefault;

  LocationData({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.geohash,
    this.isDefault = false,
  });
}

// ===============================
// 2. RESTAURANT COLLECTIONS
// ===============================

/**
 * Enhanced restaurant data with AI capabilities
 * Document ID: restaurant_{restaurantId}
 */
class RestaurantDocument {
  final String id;
  final String name;
  final String description;
  final String cuisine;
  final LocationData location;
  final List<String> categories;
  final RestaurantOperatingHours operatingHours;
  final List<String> images;
  final double rating;
  final int totalReviews;
  final double averageDeliveryTime; // minutes
  final double minimumOrderAmount;
  final double deliveryFee;
  final bool isActive;
  final bool isVerified;
  final String ownerId;
  final Map<String, dynamic> aiMetadata; // AI-generated insights
  final List<String> tags; // 'trending', 'new', 'premium', etc.
  final SustainabilityInfo sustainabilityInfo;

  RestaurantDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.location,
    required this.categories,
    required this.operatingHours,
    this.images = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.averageDeliveryTime = 0.0,
    this.minimumOrderAmount = 0.0,
    this.deliveryFee = 0.0,
    this.isActive = true,
    this.isVerified = false,
    required this.ownerId,
    this.aiMetadata = const {},
    this.tags = const [],
    required this.sustainabilityInfo,
  });
}

/**
 * Operating hours with time slots for scheduled deliveries
 */
class RestaurantOperatingHours {
  final String restaurantId;
  final Map<int, List<TimeSlot>> dailySlots; // dayOfWeek -> list of time slots
  final Map<String, List<TimeSlot>> specialHours; // date -> list of time slots
  final bool isClosed;
  final Map<String, dynamic> exceptions; // holiday closures
  final Duration minimumAdvanceTime; // Minimum time for advance booking
  final int maxAdvanceBookingDays; // Maximum days to book in advance

  RestaurantOperatingHours({
    required this.restaurantId,
    required this.dailySlots,
    this.specialHours = const {},
    this.isClosed = false,
    this.exceptions = const {},
    this.minimumAdvanceTime = const Duration(minutes: 120),
    this.maxAdvanceBookingDays = 30,
  });
}

/**
 * Time slot for delivery scheduling
 */
class TimeSlot {
  final String id;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final int maxOrders;
  final int currentOrders;
  final double fee;
  final bool isAvailable;
  final Map<String, dynamic> restrictions;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.maxOrders,
    this.currentOrders = 0,
    this.fee = 0.0,
    this.isAvailable = true,
    this.restrictions = const {},
  });
}

/**
 * Restaurant sustainability information
 */
class SustainabilityInfo {
  final double carbonFootprint; // kg CO2 per order
  final List<String> ecoFriendlyPractices; // 'recyclable packaging', 'local sourcing', etc.
  final double sustainabilityScore; // 0-100
  final Map<String, bool> certifications; // 'organic', 'fair_trade', etc.
  final String packagingType; // 'eco_friendly', 'standard', 'minimal'
  final List<String> sustainabilityBadges; // 'carbon_neutral', 'zero_waste', etc.

  SustainabilityInfo({
    this.carbonFootprint = 0.0,
    this.ecoFriendlyPractices = const [],
    this.sustainabilityScore = 0.0,
    this.certifications = const {},
    this.packagingType = 'standard',
    this.sustainabilityBadges = const [],
  });
}

// ===============================
// 3. PRODUCT/MENU COLLECTIONS
// ===============================

/**
 * Enhanced product data with AI and AR capabilities
 * Document ID: product_{productId}
 */
class ProductDocument {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String restaurantId;
  final double basePrice;
  final double currentPrice; // Dynamic pricing
  final List<String> images;
  final double rating;
  final int reviewCount;
  final List<String> tags; // 'spicy', 'vegetarian', 'gluten_free', etc.
  final List<String> ingredients;
  final NutritionalInfo nutritionalInfo;
  final List<CustomizationOption> customizationOptions;
  final int estimatedPrepTime; // minutes
  final bool isAvailable;
  final bool isTrending;
  final double trendingScore; // AI-calculated
  final ARModelData arModelData; // For AR visualization
  final Map<String, double> demandMetrics; // Real-time demand tracking
  final DateTime lastUpdated;
  final Map<String, dynamic> aiMetadata; // AI insights and recommendations

  ProductDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.restaurantId,
    required this.basePrice,
    required this.currentPrice,
    this.images = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.tags = const [],
    this.ingredients = const [],
    required this.nutritionalInfo,
    this.customizationOptions = const [],
    this.estimatedPrepTime = 0,
    this.isAvailable = true,
    this.isTrending = false,
    this.trendingScore = 0.0,
    required this.arModelData,
    this.demandMetrics = const {},
    required this.lastUpdated,
    this.aiMetadata = const {},
  });
}

/**
 * Nutritional information for products
 */
class NutritionalInfo {
  final double calories;
  final double protein; // grams
  final double carbohydrates; // grams
  final double fat; // grams
  final double fiber; // grams
  final double sodium; // milligrams
  final double sugar; // grams
  final List<String> allergens; // 'nuts', 'dairy', 'gluten', etc.
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isKetoFriendly;

  NutritionalInfo({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbohydrates = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.sodium = 0.0,
    this.sugar = 0.0,
    this.allergens = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isKetoFriendly = false,
  });
}

/**
 * Customization options for products (sizes, extras, etc.)
 */
class CustomizationOption {
  final String id;
  final String name;
  final String type; // 'size', 'extra', 'spice_level', etc.
  final List<OptionValue> values;
  final bool isRequired;
  final int maxSelections; // -1 for unlimited
  final double additionalCost; // Cost for this option group

  CustomizationOption({
    required this.id,
    required this.name,
    required this.type,
    required this.values,
    this.isRequired = false,
    this.maxSelections = 1,
    this.additionalCost = 0.0,
  });
}

/**
 * Individual option value
 */
class OptionValue {
  final String id;
  final String name;
  final double price;
  final bool isDefault;
  final Map<String, dynamic> metadata;

  OptionValue({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
    this.metadata = const {},
  });
}

/**
 * AR model data for 3D visualization
 */
class ARModelData {
  final String modelUrl; // URL to 3D model file
  final String thumbnailUrl; // AR preview image
  final Map<String, dynamic> placementInstructions; // Position, scale, rotation
  final List<ARInteractionPoint> interactionPoints; // Hotspots with information
  final String animationType; // 'none', 'spin', 'bounce', etc.
  final Map<String, dynamic> materialProperties; // Texture, lighting info

  ARModelData({
    required this.modelUrl,
    required this.thumbnailUrl,
    this.placementInstructions = const {},
    this.interactionPoints = const [],
    this.animationType = 'none',
    this.materialProperties = const {},
  });
}

/**
 * Interactive point in AR model
 */
class ARInteractionPoint {
  final String id;
  final String title;
  final String description;
  final String type; // 'nutritional', 'ingredient', 'allergen', etc.
  final Map<String, dynamic> position; // 3D coordinates
  final Map<String, dynamic> data; // Additional information to display

  ARInteractionPoint({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.position,
    this.data = const {},
  });
}

// ===============================
// 4. ORDER COLLECTIONS
// ===============================

/**
 * Enhanced order data with AI tracking and delivery optimization
 * Document ID: order_{orderId}
 */
class OrderDocument {
  final String id;
  final String userId;
  final String restaurantId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double tip;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final LocationData deliveryAddress;
  final String? specialInstructions;
  final String? deliveryNotes;
  final String? deliveryPartnerId;
  final DeliveryTrackingInfo trackingInfo;
  final PaymentInfo paymentInfo;
  final List<String> promoCodesApplied;
  final ScheduledDeliveryInfo? scheduledInfo;
  final List<ChatSession> relatedChats; // Customer support sessions
  final Map<String, dynamic> aiMetadata; // AI insights and optimization data
  final List<OrderTimelineEvent> timeline; // Chronological order events

  OrderDocument({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    this.tip = 0.0,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.deliveryAddress,
    this.specialInstructions,
    this.deliveryNotes,
    this.deliveryPartnerId,
    required this.trackingInfo,
    required this.paymentInfo,
    this.promoCodesApplied = const [],
    this.scheduledInfo,
    this.relatedChats = const [],
    this.aiMetadata = const {},
    this.timeline = const [],
  });
}

/**
 * Individual order item
 */
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final List<CustomizationSelection> customizations;
  final double totalPrice;
  final Map<String, dynamic> specialRequests; // AI-extracted from voice/text

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.customizations = const [],
    required this.totalPrice,
    this.specialRequests = const {},
  });
}

/**
 * Selected customization for an order item
 */
class CustomizationSelection {
  final String optionId;
  final String optionName;
  final String valueId;
  final String valueName;
  final double additionalCost;

  CustomizationSelection({
    required this.optionId,
    required this.optionName,
    required this.valueId,
    required this.valueName,
    this.additionalCost = 0.0,
  });
}

/**
 * Order status tracking
 */
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  picked_up,
  in_transit,
  delivered,
  cancelled,
  refunded
}

/**
 * Real-time delivery tracking information
 */
class DeliveryTrackingInfo {
  final String deliveryId;
  final String deliveryPartnerId;
  final DeliveryPartnerInfo partnerInfo;
  final List<LocationUpdate> locationUpdates;
  final String? currentStatus;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? estimatedArrivalTime;
  final String? actualArrivalTime;
  final RouteOptimizationInfo routeInfo;
  final bool isContactlessDelivery;
  final String? qrCode; // For contactless delivery
  final String? deliveryPhoto; // Photo of delivered order
  final String? signaturePhoto; // Customer signature/photo confirmation

  DeliveryTrackingInfo({
    required this.deliveryId,
    required this.deliveryPartnerId,
    required this.partnerInfo,
    this.locationUpdates = const [],
    this.currentStatus,
    this.currentLatitude,
    this.currentLongitude,
    this.estimatedArrivalTime,
    this.actualArrivalTime,
    required this.routeInfo,
    this.isContactlessDelivery = false,
    this.qrCode,
    this.deliveryPhoto,
    this.signaturePhoto,
  });
}

/**
 * Delivery partner information
 */
class DeliveryPartnerInfo {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final double rating;
  final int totalDeliveries;
  final String vehicleType; // 'bike', 'car', 'walking', 'drone', etc.
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isOnline;

  DeliveryPartnerInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.vehicleType = 'bike',
    this.currentLatitude,
    this.currentLongitude,
    this.isOnline = false,
  });
}

/**
 * Location update during delivery
 */
class LocationUpdate {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double speed; // km/h
  final double accuracy; // GPS accuracy in meters
  final String status; // 'en_route', 'arrived_restaurant', 'picked_up', etc.

  LocationUpdate({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.speed = 0.0,
    this.accuracy = 0.0,
    required this.status,
  });
}

/**
 * AI-powered route optimization information
 */
class RouteOptimizationInfo {
  final String routeId;
  final List<String> waypoints; // Order of stops
  final double totalDistance; // km
  final Duration estimatedDuration;
  final Duration actualDuration;
  final double fuelEfficiency; // km/liter
  final double carbonFootprint; // kg CO2
  final String optimizationMethod; // 'ai_optimized', 'shortest_path', etc.
  final DateTime lastOptimized;
  final Map<String, dynamic> trafficData; // Real-time traffic information
  final String? optimizationReason; // Why this route was chosen

  RouteOptimizationInfo({
    required this.routeId,
    required this.waypoints,
    this.totalDistance = 0.0,
    required this.estimatedDuration,
    this.actualDuration = Duration.zero,
    this.fuelEfficiency = 0.0,
    this.carbonFootprint = 0.0,
    this.optimizationMethod = 'ai_optimized',
    required this.lastOptimized,
    this.trafficData = const {},
    this.optimizationReason,
  });
}

/**
 * Payment information for orders
 */
class PaymentInfo {
  final String paymentId;
  final String paymentMethod; // 'card', 'upi', 'wallet', 'cash', 'netbanking'
  final String? gateway; // 'razorpay', 'stripe', 'paypal'
  final String? transactionId;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final DateTime processedAt;
  final Map<String, dynamic> gatewayData; // Gateway-specific data
  final bool isRecurringPayment;
  final String? recurringPatternId;

  PaymentInfo({
    required this.paymentId,
    required this.paymentMethod,
    this.gateway,
    this.transactionId,
    required this.amount,
    this.currency = 'INR',
    this.status = 'pending',
    required this.processedAt,
    this.gatewayData = const {},
    this.isRecurringPayment = false,
    this.recurringPatternId,
  });
}

/**
 * Scheduled delivery information
 */
class ScheduledDeliveryInfo {
  final String scheduleId;
  final DateTime scheduledDateTime;
  final String scheduleType; // 'immediate', 'scheduled', 'recurring', 'rush'
  final String priority; // 'low', 'normal', 'high', 'urgent', 'vip'
  final String? timeSlotId;
  final double deliveryFee;
  final double rushFee;
  final bool isRecurringActive;
  final String? recurringPatternId;
  final int? recurringCount;
  final int? maxRecurringCount;
  final String? confirmationCode;

  ScheduledDeliveryInfo({
    required this.scheduleId,
    required this.scheduledDateTime,
    this.scheduleType = 'scheduled',
    this.priority = 'normal',
    this.timeSlotId,
    this.deliveryFee = 0.0,
    this.rushFee = 0.0,
    this.isRecurringActive = false,
    this.recurringPatternId,
    this.recurringCount,
    this.maxRecurringCount,
    this.confirmationCode,
  });
}

/**
 * Chat session related to an order
 */
class ChatSession {
  final String sessionId;
  final String type; // 'customer_support', 'delivery_chat', 'restaurant_chat'
  final List<String> participants;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? status; // 'active', 'closed', 'escalated'

  ChatSession({
    required this.sessionId,
    required this.type,
    required this.participants,
    required this.startedAt,
    this.endedAt,
    this.status = 'active',
  });
}

/**
 * Order timeline event for tracking
 */
class OrderTimelineEvent {
  final String eventId;
  final String status;
  final String description;
  final DateTime timestamp;
  final String? performedBy; // userId, system, or deliveryPartnerId
  final Map<String, dynamic> metadata;

  OrderTimelineEvent({
    required this.eventId,
    required this.status,
    required this.description,
    required this.timestamp,
    this.performedBy,
    this.metadata = const {},
  });
}

// ===============================
// 5. RECOMMENDATION COLLECTIONS
// ===============================

/**
 * AI recommendation history and analytics
 * Collection: recommendationHistory
 */
class RecommendationHistory {
  final String id;
  final String userId;
  final List<String> recommendedProducts;
  final List<double> scores; // Confidence scores for each recommendation
  final String recommendationType; // 'personalized', 'trending', 'contextual', 'similar'
  final Map<String, dynamic> context; // Time, weather, location, mood context
  final DateTime generatedAt;
  final DateTime? clickedAt; // When user clicked on recommendation
  final List<String> clickedProducts; // Which products were actually clicked
  final List<String> orderedProducts; // Which recommended products were ordered
  final double conversionRate; // 0-1
  final Map<String, dynamic> aiMetadata; // AI model versions, parameters

  RecommendationHistory({
    required this.id,
    required this.userId,
    required this.recommendedProducts,
    required this.scores,
    required this.recommendationType,
    this.context = const {},
    required this.generatedAt,
    this.clickedAt,
    this.clickedProducts = const [],
    this.orderedProducts = const [],
    this.conversionRate = 0.0,
    this.aiMetadata = const {},
  });
}

/**
 * Trending products analytics
 * Collection: trendingProducts
 */
class TrendingProduct {
  final String productId;
  final String restaurantId;
  final double trendingScore; // AI-calculated 0-100
  final int orderCount24h;
  final int orderCount7d;
  final int orderCount30d;
  final double growthRate; // % growth compared to previous period
  final String category;
  final List<String> tags;
  final DateTime lastUpdated;
  final Map<String, int> hourlyOrderCounts; // Hour -> count
  final List<String> customerSegments; // age groups, preferences
  final Map<String, dynamic> aiAnalysis; // AI insights about trending

  TrendingProduct({
    required this.productId,
    required this.restaurantId,
    required this.trendingScore,
    this.orderCount24h = 0,
    this.orderCount7d = 0,
    this.orderCount30d = 0,
    this.growthRate = 0.0,
    this.category = '',
    this.tags = const [],
    required this.lastUpdated,
    this.hourlyOrderCounts = const {},
    this.customerSegments = const [],
    this.aiAnalysis = const {},
  });
}

// ===============================
// 6. CHAT & COMMUNICATION COLLECTIONS
// ===============================

/**
 * Chat room for real-time communication
 * Document ID: chatRoom_{roomId}
 */
class ChatRoom {
  final String id;
  final String name;
  final String type; // 'customer_support', 'delivery_chat', 'group_chat', 'ai_assistant'
  final List<String> participants;
  final String? orderId; // If related to specific order
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final bool isActive;
  final Map<String, dynamic> metadata; // AI, settings, etc.

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.orderId,
    required this.createdBy,
    required this.createdAt,
    this.lastMessageAt,
    this.isActive = true,
    this.metadata = const {},
  });
}

/**
 * Individual chat message
 * Collection: chatMessages
 */
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType; // 'user', 'delivery_partner', 'restaurant', 'ai_bot', 'support_agent'
  final String content;
  final String messageType; // 'text', 'image', 'voice', 'file', 'location', 'ai_response'
  final DateTime timestamp;
  final List<String> attachments; // URLs to files, images, etc.
  final String? replyToMessageId; // For replies
  final List<String> reactions; // Emoji reactions
  final bool isRead; // Read status
  final bool isFromAI; // AI-generated message
  final Map<String, dynamic> aiMetadata; // AI confidence, intent, etc.
  final Map<String, dynamic> metadata; // Additional message data

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.messageType = 'text',
    required this.timestamp,
    this.attachments = const [],
    this.replyToMessageId,
    this.reactions = const [],
    this.isRead = false,
    this.isFromAI = false,
    this.aiMetadata = const {},
    this.metadata = const {},
  });
}

/**
 * AI chatbot knowledge base
 * Collection: knowledgeBase
 */
class KnowledgeBaseArticle {
  final String id;
  final String title;
  final String content;
  final String category; // 'orders', 'delivery', 'payment', 'account', etc.
  final List<String> tags;
  final List<String> keywords;
  final String? relatedQuestions; // FAQ-style questions
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final int viewCount;
  final double helpfulnessRating; // 1-5
  final bool isActive;
  final Map<String, double> aiScores; // Relevance scores by topic
  final String? language; // 'en', 'hi', 'es', etc.

  KnowledgeBaseArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    this.keywords = const [],
    this.relatedQuestions,
    required this.createdAt,
    this.lastUpdated,
    this.viewCount = 0,
    this.helpfulnessRating = 0.0,
    this.isActive = true,
    this.aiScores = const {},
    this.language = 'en',
  });
}

// ===============================
// 7. LOYALTY & REWARDS COLLECTIONS
// ===============================

/**
 * User loyalty program data
 * Document ID: loyalty_{userId}
 */
class LoyaltyAccount {
  final String id;
  final String userId;
  final int totalPoints;
  final int usedPoints;
  final int availablePoints;
  final String tier; // 'bronze', 'silver', 'gold', 'platinum', 'diamond'
  final DateTime joinedAt;
  final DateTime? tierUpgradeDate;
  final int totalOrders;
  final double totalSpent;
  final int referralCount;
  final int successfulReferrals;
  final List<LoyaltyTransaction> transactions;
  final Map<String, dynamic> metadata; // AI insights, preferences

  LoyaltyAccount({
    required this.id,
    required this.userId,
    this.totalPoints = 0,
    this.usedPoints = 0,
    this.availablePoints = 0,
    this.tier = 'bronze',
    required this.joinedAt,
    this.tierUpgradeDate,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.referralCount = 0,
    this.successfulReferrals = 0,
    this.transactions = const [],
    this.metadata = const {},
  });
}

/**
 * Individual loyalty transaction
 */
class LoyaltyTransaction {
  final String id;
  final String userId;
  final String type; // 'earned', 'redeemed', 'expired', 'bonus', 'referral'
  final int points;
  final String? orderId;
  final String description;
  final DateTime timestamp;
  final DateTime? expiryDate; // Points expiration
  final Map<String, dynamic> metadata;

  LoyaltyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    this.orderId,
    required this.description,
    required this.timestamp,
    this.expiryDate,
    this.metadata = const {},
  });
}

/**
 * Loyalty program challenges and rewards
 * Collection: loyaltyChallenges
 */
class LoyaltyChallenge {
  final String id;
  final String name;
  final String description;
  final String category; // 'order_frequency', 'spending', 'social', 'seasonal'
  final Map<String, dynamic> requirements; // Points, orders, spending, etc.
  final int rewardPoints;
  final String? rewardDescription;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int currentParticipants;
  final bool isActive;
  final List<String> eligibleUserSegments; // 'new_users', 'frequent_customers', etc.

  LoyaltyChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requirements,
    required this.rewardPoints,
    this.rewardDescription,
    required this.startDate,
    required this.endDate,
    this.maxParticipants = -1, // -1 for unlimited
    this.currentParticipants = 0,
    this.isActive = true,
    this.eligibleUserSegments = const [],
  });
}

// ===============================
// 8. SUSTAINABILITY COLLECTIONS
// ===============================

/**
 * User sustainability profile
 * Document ID: sustainability_{userId}
 */
class SustainabilityProfile {
  final String userId;
  final double carbonFootprintTotal; // Total kg CO2
  final double carbonFootprintThisMonth;
  final double carbonFootprintSaved; // Through eco-friendly choices
  final int ecoFriendlyOrders; // Orders with eco-friendly options
  final List<String> sustainabilityBadges; // Achieved badges
  final List<SustainabilityGoal> goals; // User's sustainability goals
  final Map<String, int> sustainableActions; // Action -> count
  final double sustainabilityScore; // 0-100
  final DateTime lastUpdated;
  final List<String> preferredEcoOptions; // Packaging, delivery method, etc.

  SustainabilityProfile({
    required this.userId,
    this.carbonFootprintTotal = 0.0,
    this.carbonFootprintThisMonth = 0.0,
    this.carbonFootprintSaved = 0.0,
    this.ecoFriendlyOrders = 0,
    this.sustainabilityBadges = const [],
    this.goals = const [],
    this.sustainableActions = const {},
    this.sustainabilityScore = 0.0,
    required this.lastUpdated,
    this.preferredEcoOptions = const [],
  });
}

/**
 * Individual sustainability goal
 */
class SustainabilityGoal {
  final String id;
  final String name;
  final String description;
  final String type; // 'carbon_reduction', 'plastic_free', 'local_sourcing', etc.
  final double target; // Target value
  final double current; // Current progress
  final String unit; // 'kg_co2', 'orders', 'percentage'
  final DateTime targetDate;
  final bool isCompleted;
  final String? reward; // Reward for completion

  SustainabilityGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.target,
    this.current = 0.0,
    required this.unit,
    required this.targetDate,
    this.isCompleted = false,
    this.reward,
  });
}

/**
 * Sustainability challenges and initiatives
 * Collection: sustainabilityChallenges
 */
class SustainabilityChallenge {
  final String id;
  final String name;
  final String description;
  final String type; // 'monthly', 'seasonal', 'ongoing', 'community'
  final Map<String, dynamic> requirements;
  final List<String> rewards; // Badges, points, etc.
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final double totalImpact; // Collective impact measurement
  final bool isActive;
  final String? leaderboardId; // If it's a competitive challenge

  SustainabilityChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requirements,
    this.rewards = const [],
    required this.startDate,
    required this.endDate,
    this.participantCount = 0,
    this.totalImpact = 0.0,
    this.isActive = true,
    this.leaderboardId,
  });
}

// ===============================
// 9. ANALYTICS & AI COLLECTIONS
// ===============================

/**
 * AI model analytics and performance
 * Collection: aiModelAnalytics
 */
class AIModelAnalytics {
  final String modelId;
  final String modelType; // 'recommendation', 'pricing', 'route_optimization', etc.
  final DateTime timestamp;
  final double accuracy; // Model accuracy score
  final int totalPredictions; // Number of predictions made
  final int correctPredictions; // Correct predictions
  final Map<String, dynamic> performanceMetrics; // Precision, recall, F1, etc.
  final List<String> inputFeatures; // Features used by model
  final String modelVersion; // Version of the model
  final Map<String, dynamic> metadata; // Additional analytics data

  AIModelAnalytics({
    required this.modelId,
    required this.modelType,
    required this.timestamp,
    this.accuracy = 0.0,
    this.totalPredictions = 0,
    this.correctPredictions = 0,
    this.performanceMetrics = const {},
    this.inputFeatures = const [],
    required this.modelVersion,
    this.metadata = const {},
  });
}

/**
 * Business intelligence and insights
 * Collection: businessInsights
 */
class BusinessInsight {
  final String id;
  final String type; // 'sales', 'user_behavior', 'operational', 'ai_performance'
  final String title;
  final String description;
  final Map<String, dynamic> data; // Insight data
  final double confidence; // AI confidence in insight
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final List<String> recommendedActions;
  final bool isActionable;

  BusinessInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    this.confidence = 0.0,
    required this.generatedAt,
    this.expiresAt,
    this.priority = 'medium',
    this.recommendedActions = const [],
    this.isActionable = true,
  });
}

// ===============================
// 10. VOICE & AR SESSIONS
// ===============================

/**
 * Voice interaction session
 * Collection: voiceSessions
 */
class VoiceSession {
  final String id;
  final String userId;
  final String type; // 'ordering', 'support', 'navigation', 'account'
  final String language; // 'en', 'hi', 'es', etc.
  final String? transcript; // Full transcript of voice interaction
  final Map<String, double> confidenceScores; // Phrase -> confidence
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // 'active', 'completed', 'failed', 'cancelled'
  final Map<String, dynamic> extractedIntents; // AI-extracted user intents
  final List<String> actionsTaken; // Actions performed based on voice input
  final double audioDuration; // seconds
  final String? audioUrl; // URL to stored audio file

  VoiceSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.language,
    this.transcript,
    this.confidenceScores = const {},
    required this.startedAt,
    this.endedAt,
    this.status = 'active',
    this.extractedIntents = const {},
    this.actionsTaken = const [],
    this.audioDuration = 0.0,
    this.audioUrl,
  });
}

/**
 * AR experience session
 * Collection: arSessions
 */
class ARSession {
  final String id;
  final String userId;
  final String? orderId; // If related to specific order
  final String deviceType; // 'ios', 'android', 'web'
  final String arFramework; // 'arcore', 'arkit', 'webxr'
  final List<String> viewedProducts; // Products viewed in AR
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration sessionDuration;
  final String? sessionData; // JSON of AR session data
  final Map<String, dynamic> interactions; // User interactions in AR
  final bool wasSuccessful; // Whether user completed intended action

  ARSession({
    required this.id,
    required this.userId,
    this.orderId,
    required this.deviceType,
    required this.arFramework,
    this.viewedProducts = const [],
    required this.startedAt,
    this.endedAt,
    this.sessionDuration = Duration.zero,
    this.sessionData,
    this.interactions = const {},
    this.wasSuccessful = false,
  });
}

// ===============================
// COLLECTION INDEXES CONFIGURATION
// ===============================

/**
 * Firestore Indexes Configuration
 * These indexes should be created in Firebase Console for optimal performance
 */
class FirestoreIndexes {
  // User collections indexes
  static const Map<String, List<String>> userIndexes = {
    'users': [
      'email',
      'phone',
      'createdAt',
      'lastActive',
      'userType',
      'isActive',
      'preferredLanguage'
    ],
    'userPreferences': [
      'userId',
      'lastUpdated',
      'aiConfidenceScore'
    ]
  };

  // Restaurant indexes
  static const Map<String, List<String>> restaurantIndexes = {
    'restaurants': [
      'ownerId',
      'cuisine',
      'location.geohash', // Geospatial queries
      'isActive',
      'isVerified',
      'rating',
      'minimumOrderAmount',
      'deliveryFee'
    ],
    'restaurantOperatingHours': [
      'restaurantId',
      'specialHours' // For date-based queries
    ]
  };

  // Product indexes
  static const Map<String, List<String>> productIndexes = {
    'products': [
      'restaurantId',
      'categoryId',
      'isAvailable',
      'currentPrice',
      'rating',
      'isTrending',
      'trendingScore',
      'lastUpdated'
    ]
  };

  // Order indexes
  static const Map<String, List<String>> orderIndexes = {
    'orders': [
      'userId',
      'restaurantId',
      'status',
      'orderDate',
      'estimatedDeliveryTime',
      'totalAmount',
      'deliveryPartnerId'
    ],
    'deliveryTrackingInfo': [
      'deliveryId',
      'deliveryPartnerId',
      'currentStatus'
    ]
  };

  // Recommendation indexes
  static const Map<String, List<String>> recommendationIndexes = {
    'recommendationHistory': [
      'userId',
      'generatedAt',
      'recommendationType',
      'conversionRate'
    ],
    'trendingProducts': [
      'productId',
      'restaurantId',
      'trendingScore',
      'lastUpdated',
      'category'
    ]
  };

  // Chat indexes
  static const Map<String, List<String>> chatIndexes = {
    'chatRooms': [
      'participants',
      'type',
      'createdAt',
      'lastMessageAt',
      'isActive'
    ],
    'chatMessages': [
      'roomId',
      'timestamp',
      'senderId',
      'messageType',
      'isRead'
    ]
  };

  // Loyalty indexes
  static const Map<String, List<String>> loyaltyIndexes = {
    'loyaltyAccounts': [
      'userId',
      'tier',
      'totalPoints',
      'availablePoints',
      'joinedAt'
    ],
    'loyaltyTransactions': [
      'userId',
      'timestamp',
      'type',
      'points'
    ]
  };

  // Voice and AR indexes
  static const Map<String, List<String>> sessionIndexes = {
    'voiceSessions': [
      'userId',
      'type',
      'language',
      'startedAt',
      'status'
    ],
    'arSessions': [
      'userId',
      'orderId',
      'deviceType',
      'startedAt',
      'wasSuccessful'
    ]
  };

  // Sustainability indexes
  static const Map<String, List<String>> sustainabilityIndexes = {
    'sustainabilityProfiles': [
      'userId',
      'sustainabilityScore',
      'lastUpdated'
    ],
    'sustainabilityChallenges': [
      'type',
      'startDate',
      'endDate',
      'isActive'
    ]
  };
}

// ===============================
// SECURITY RULES TEMPLATE
// ===============================

/**
 * Firestore Security Rules Template
 * These rules should be applied in Firebase Console
 */
class SecurityRules {
  static const String rules = r'''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User Documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    // User Preferences
    match /userPreferences/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Simplified for now
    }
    
    // Orders
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }
    
    // Chat rooms and messages
    match /chatRooms/{roomId} {
      allow read, write: if request.auth != null;
    }
    
    match /chatMessages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // All other documents are read-only for authenticated users
    match /{document=**} {
      allow read: if request.auth != null;
    }
  }
}
''';
}

// ===============================
// DATABASE INITIALIZATION
// ===============================

/**
 * Database initialization and setup utility
 */
class DatabaseInitializer {
  static Future<void> initializeCollections() async {
    // Create collection groups for analytics
    // Set up batch writes for initial data
    // Configure security rules
    // Set up automatic data cleanup
  }
  
  static Future<void> createIndexes() async {
    // Programmatically create necessary indexes
    // This would typically be done through Firebase Console
  }
  
  static Future<void> setupTriggers() async {
    // Set up Cloud Functions triggers
    // Real-time data synchronization
    // Automated data validation
  }
}