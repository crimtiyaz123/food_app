// User Preferences Model for AI Recommendations
class UserPreferences {
  final String userId;
  final List<String> favoriteCategories;
  final List<String> favoriteRestaurants;
  final Map<String, double> dietaryRestrictions;
  final PriceRange preferredPriceRange;
  final List<String> allergyInfo;
  final TimePreference orderTimePreference;
  final List<String> cuisinePreferences;
  final double averageOrderValue;
  final int orderFrequency; // orders per week
  final DateTime lastUpdated;

  UserPreferences({
    required this.userId,
    required this.favoriteCategories,
    required this.favoriteRestaurants,
    required this.dietaryRestrictions,
    required this.preferredPriceRange,
    required this.allergyInfo,
    required this.orderTimePreference,
    required this.cuisinePreferences,
    required this.averageOrderValue,
    required this.orderFrequency,
    required this.lastUpdated,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] ?? '',
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
      favoriteRestaurants: List<String>.from(json['favoriteRestaurants'] ?? []),
      dietaryRestrictions: Map<String, double>.from(json['dietaryRestrictions'] ?? {}),
      preferredPriceRange: PriceRange.fromJson(json['preferredPriceRange'] ?? {}),
      allergyInfo: List<String>.from(json['allergyInfo'] ?? []),
      orderTimePreference: TimePreference.fromJson(json['orderTimePreference'] ?? {}),
      cuisinePreferences: List<String>.from(json['cuisinePreferences'] ?? []),
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      orderFrequency: json['orderFrequency'] ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'favoriteCategories': favoriteCategories,
      'favoriteRestaurants': favoriteRestaurants,
      'dietaryRestrictions': dietaryRestrictions,
      'preferredPriceRange': preferredPriceRange.toJson(),
      'allergyInfo': allergyInfo,
      'orderTimePreference': orderTimePreference.toJson(),
      'cuisinePreferences': cuisinePreferences,
      'averageOrderValue': averageOrderValue,
      'orderFrequency': orderFrequency,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}

class PriceRange {
  final double min;
  final double max;

  PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

class TimePreference {
  final List<int> preferredDays; // 0=Sunday, 1=Monday, etc.
  final List<String> preferredTimeSlots; // ['breakfast', 'lunch', 'dinner', 'late_night']

  TimePreference({
    required this.preferredDays,
    required this.preferredTimeSlots,
  });

  factory TimePreference.fromJson(Map<String, dynamic> json) {
    return TimePreference(
      preferredDays: List<int>.from(json['preferredDays'] ?? []),
      preferredTimeSlots: List<String>.from(json['preferredTimeSlots'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredDays': preferredDays,
      'preferredTimeSlots': preferredTimeSlots,
    };
  }
}