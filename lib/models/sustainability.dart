// Sustainability Models for Eco-Friendly Delivery Services

// Sustainability Categories
enum SustainabilityCategory {
  carbonFootprint,    // Carbon emissions tracking
  packaging,          // Eco-friendly packaging options
  delivery,           // Sustainable delivery methods
  food,              // Sustainable food sources
  waste,             // Waste reduction initiatives
  energy,            // Energy efficiency
  water,             // Water conservation
  social,            // Social sustainability initiatives
}

// Carbon Emission Sources
enum EmissionSource {
  delivery,          // Vehicle emissions
  food,             // Food production emissions
  packaging,        // Packaging materials
  energy,           // Kitchen energy usage
  waste,            // Waste disposal
  transportation,   // Supply chain transportation
}

// Packaging Types
enum EcoPackagingType {
  compostable,       // Biodegradable packaging
  reusable,          // Reusable containers
  recycled,          // Recycled materials
  minimal,           // Minimal packaging
  paper,            // Paper-based packaging
  bamboo,           // Bamboo-based packaging
  glass,            // Glass containers
  stainlessSteel,   // Stainless steel containers
}

// Sustainability Metrics
class SustainabilityMetrics {
  final String id;
  final String userId;
  final String orderId;
  final DateTime timestamp;
  final double totalCarbonEmissions; // kg CO2
  final double carbonPerDelivery; // kg CO2 per delivery
  final Map<String, double> emissionBreakdown; // Breakdown by source
  final double packagingWaste; // kg of packaging waste
  final double foodWaste; // kg of food waste
  final double waterUsage; // liters of water used
  final double energyConsumption; // kWh consumed
  final double sustainableScore; // 0-100 score
  final Map<String, int> ecoFriendlyChoices; // Count of eco choices
  final List<String> sustainabilityBadges; // Achieved badges
  final Map<String, dynamic> metadata;

  SustainabilityMetrics({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.timestamp,
    required this.totalCarbonEmissions,
    required this.carbonPerDelivery,
    required this.emissionBreakdown,
    required this.packagingWaste,
    required this.foodWaste,
    required this.waterUsage,
    required this.energyConsumption,
    required this.sustainableScore,
    required this.ecoFriendlyChoices,
    required this.sustainabilityBadges,
    required this.metadata,
  });

  factory SustainabilityMetrics.fromJson(String id, Map<String, dynamic> json) {
    return SustainabilityMetrics(
      id: id,
      userId: json['userId'] ?? '',
      orderId: json['orderId'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      totalCarbonEmissions: (json['totalCarbonEmissions'] ?? 0.0).toDouble(),
      carbonPerDelivery: (json['carbonPerDelivery'] ?? 0.0).toDouble(),
      emissionBreakdown: Map<String, double>.from(json['emissionBreakdown'] ?? {}),
      packagingWaste: (json['packagingWaste'] ?? 0.0).toDouble(),
      foodWaste: (json['foodWaste'] ?? 0.0).toDouble(),
      waterUsage: (json['waterUsage'] ?? 0.0).toDouble(),
      energyConsumption: (json['energyConsumption'] ?? 0.0).toDouble(),
      sustainableScore: (json['sustainableScore'] ?? 0.0).toDouble(),
      ecoFriendlyChoices: Map<String, int>.from(json['ecoFriendlyChoices'] ?? {}),
      sustainabilityBadges: List<String>.from(json['sustainabilityBadges'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'orderId': orderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'totalCarbonEmissions': totalCarbonEmissions,
      'carbonPerDelivery': carbonPerDelivery,
      'emissionBreakdown': emissionBreakdown,
      'packagingWaste': packagingWaste,
      'foodWaste': foodWaste,
      'waterUsage': waterUsage,
      'energyConsumption': energyConsumption,
      'sustainableScore': sustainableScore,
      'ecoFriendlyChoices': ecoFriendlyChoices,
      'sustainabilityBadges': sustainabilityBadges,
      'metadata': metadata,
    };
  }

  // Calculate environmental impact level
  String get impactLevel {
    if (sustainableScore >= 80) return 'Excellent';
    if (sustainableScore >= 60) return 'Good';
    if (sustainableScore >= 40) return 'Fair';
    return 'Needs Improvement';
  }
  
  // Check if order is carbon neutral
  bool get isCarbonNeutral => totalCarbonEmissions <= 0.1;
  
  // Get emission trend compared to average
  double get emissionTrend {
    // This would compare to user's historical average
    return -0.15; // Mock 15% reduction
  }
}

// Eco-Friendly Packaging Option
class EcoPackagingOption {
  final String id;
  final String name;
  final String description;
  final EcoPackagingType type;
  final double price; // Additional cost (can be negative for discount)
  final double carbonFootprint; // kg CO2 per unit
  final double biodegradabilityFactor; // 0-1, 1 = fully biodegradable
  final int recyclingPotential; // 0-100, how easily recycled
  final String material;
  final List<String> certifications; // Eco certifications
  final bool isReusable;
  final int reuseCycles; // How many times it can be reused
  final Map<String, dynamic> specifications;
  final Map<String, dynamic> availability;
  final double rating; // Customer rating
  final int usageCount; // How many times used

  EcoPackagingOption({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    required this.carbonFootprint,
    required this.biodegradabilityFactor,
    required this.recyclingPotential,
    required this.material,
    required this.certifications,
    required this.isReusable,
    required this.reuseCycles,
    required this.specifications,
    required this.availability,
    required this.rating,
    required this.usageCount,
  });

  factory EcoPackagingOption.fromJson(String id, Map<String, dynamic> json) {
    return EcoPackagingOption(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: EcoPackagingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EcoPackagingType.compostable,
      ),
      price: (json['price'] ?? 0.0).toDouble(),
      carbonFootprint: (json['carbonFootprint'] ?? 0.0).toDouble(),
      biodegradabilityFactor: (json['biodegradabilityFactor'] ?? 0.0).toDouble(),
      recyclingPotential: json['recyclingPotential'] ?? 0,
      material: json['material'] ?? '',
      certifications: List<String>.from(json['certifications'] ?? []),
      isReusable: json['isReusable'] ?? false,
      reuseCycles: json['reuseCycles'] ?? 0,
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      availability: Map<String, dynamic>.from(json['availability'] ?? {}),
      rating: (json['rating'] ?? 0.0).toDouble(),
      usageCount: json['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'price': price,
      'carbonFootprint': carbonFootprint,
      'biodegradabilityFactor': biodegradabilityFactor,
      'recyclingPotential': recyclingPotential,
      'material': material,
      'certifications': certifications,
      'isReusable': isReusable,
      'reuseCycles': reuseCycles,
      'specifications': specifications,
      'availability': availability,
      'rating': rating,
      'usageCount': usageCount,
    };
  }

  // Calculate total environmental benefit score
  double get environmentalScore {
    double score = 0.0;
    
    // Biodegradability (40% weight)
    score += biodegradabilityFactor * 40;
    
    // Recycling potential (30% weight)
    score += (recyclingPotential / 100.0) * 30;
    
    // Low carbon footprint (20% weight)
    score += (1.0 - (carbonFootprint / 5.0)) * 20; // Assuming 5 kg is high
    
    // Reusability (10% weight)
    if (isReusable) {
      score += (reuseCycles / 10.0) * 10; // Assuming 10 cycles is excellent
    }
    
    return score;
  }
  
  // Check if it's certified organic/eco-friendly
  bool get isCertified => certifications.isNotEmpty;
  
  // Check if it's cost-effective
  bool get isCostEffective => price <= 0.5; // Less than $0.50 additional cost
}

// Sustainability Goal
class SustainabilityGoal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final SustainabilityCategory category;
  final double targetValue;
  final double currentValue;
  final String unit; // 'kg CO2', 'percentage', 'number', etc.
  final DateTime createdAt;
  final DateTime targetDate;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final String status; // 'active', 'completed', 'paused', 'cancelled'
  final List<String> milestones;
  final Map<String, double> progressHistory;
  final Map<String, dynamic> rewards;
  final bool isPublic;
  final List<String> sharedWith; // Friends/family who can see progress

  SustainabilityGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.createdAt,
    required this.targetDate,
    required this.frequency,
    required this.status,
    required this.milestones,
    required this.progressHistory,
    required this.rewards,
    required this.isPublic,
    required this.sharedWith,
  });

  factory SustainabilityGoal.fromJson(String id, Map<String, dynamic> json) {
    return SustainabilityGoal(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: SustainabilityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SustainabilityCategory.carbonFootprint,
      ),
      targetValue: (json['targetValue'] ?? 0.0).toDouble(),
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      targetDate: DateTime.fromMillisecondsSinceEpoch(json['targetDate'] ?? 0),
      frequency: json['frequency'] ?? '',
      status: json['status'] ?? 'active',
      milestones: List<String>.from(json['milestones'] ?? []),
      progressHistory: Map<String, double>.from(json['progressHistory'] ?? {}),
      rewards: Map<String, dynamic>.from(json['rewards'] ?? {}),
      isPublic: json['isPublic'] ?? false,
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'frequency': frequency,
      'status': status,
      'milestones': milestones,
      'progressHistory': progressHistory,
      'rewards': rewards,
      'isPublic': isPublic,
      'sharedWith': sharedWith,
    };
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue) * 100;
  }
  
  // Check if goal is achieved
  bool get isAchieved => currentValue >= targetValue;
  
  // Check if goal is overdue
  bool get isOverdue => targetDate.isBefore(DateTime.now()) && !isAchieved;
  
  // Calculate days remaining
  int get daysRemaining {
    if (isAchieved) return 0;
    final remaining = targetDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
  
  // Get progress status
  String get statusText {
    if (isAchieved) return 'Completed';
    if (isOverdue) return 'Overdue';
    if (progressPercentage >= 80) return 'Almost there';
    if (progressPercentage >= 50) return 'On track';
    if (progressPercentage >= 25) return 'Getting started';
    return 'Just started';
  }
}

// Additional data classes for integration testing

class UserSustainabilityProfile {
  final String userId;
  final double carbonFootprintThisMonth;
  final double totalCarbonSaved;
  final double ecoScore;
  final String sustainabilityLevel;
  final DateTime? lastOrderDate;

  UserSustainabilityProfile({
    required this.userId,
    required this.carbonFootprintThisMonth,
    required this.totalCarbonSaved,
    required this.ecoScore,
    required this.sustainabilityLevel,
    this.lastOrderDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'carbonFootprintThisMonth': carbonFootprintThisMonth,
      'totalCarbonSaved': totalCarbonSaved,
      'ecoScore': ecoScore,
      'sustainabilityLevel': sustainabilityLevel,
      'lastOrderDate': lastOrderDate?.millisecondsSinceEpoch,
    };
  }
}

class OrderSustainabilityImpact {
  final double carbonFootprint;
  final double ecoScore;
  final List<String> recommendations;

  OrderSustainabilityImpact({
    required this.carbonFootprint,
    required this.ecoScore,
    required this.recommendations,
  });
}

class SustainabilityImpactData {
  final double totalCarbonFootprint;
  final double carbonSaved;
  final double ecoScore;
  final List<String> badgesEarned;
  final String level;

  SustainabilityImpactData({
    required this.totalCarbonFootprint,
    required this.carbonSaved,
    required this.ecoScore,
    required this.badgesEarned,
    required this.level,
  });
}

// Carbon Offset Program
class CarbonOffsetProgram {
  final String id;
  final String name;
  final String description;
  final List<String> supportedProjects; // Forest restoration, renewable energy, etc.
  final double costPerTonCO2; // Cost to offset 1 ton of CO2
  final Map<String, double> projectDistribution; // Percentage allocation to projects
  final String certification; // Verified carbon standard
  final String provider; // Organization providing offsets
  final Map<String, dynamic> impactMetrics; // Expected environmental impact
  final List<String> benefits; // User benefits
  final double totalOffsetAvailable; // Total CO2 that can be offset
  final int participantCount; // Number of users participating
  final double averageOffsetPerUser; // Average offset per user
  final String status; // 'active', 'paused', 'discontinued'

  CarbonOffsetProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.supportedProjects,
    required this.costPerTonCO2,
    required this.projectDistribution,
    required this.certification,
    required this.provider,
    required this.impactMetrics,
    required this.benefits,
    required this.totalOffsetAvailable,
    required this.participantCount,
    required this.averageOffsetPerUser,
    required this.status,
  });

  factory CarbonOffsetProgram.fromJson(String id, Map<String, dynamic> json) {
    return CarbonOffsetProgram(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      supportedProjects: List<String>.from(json['supportedProjects'] ?? []),
      costPerTonCO2: (json['costPerTonCO2'] ?? 0.0).toDouble(),
      projectDistribution: Map<String, double>.from(json['projectDistribution'] ?? {}),
      certification: json['certification'] ?? '',
      provider: json['provider'] ?? '',
      impactMetrics: Map<String, dynamic>.from(json['impactMetrics'] ?? {}),
      benefits: List<String>.from(json['benefits'] ?? []),
      totalOffsetAvailable: (json['totalOffsetAvailable'] ?? 0.0).toDouble(),
      participantCount: json['participantCount'] ?? 0,
      averageOffsetPerUser: (json['averageOffsetPerUser'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'supportedProjects': supportedProjects,
      'costPerTonCO2': costPerTonCO2,
      'projectDistribution': projectDistribution,
      'certification': certification,
      'provider': provider,
      'impactMetrics': impactMetrics,
      'benefits': benefits,
      'totalOffsetAvailable': totalOffsetAvailable,
      'participantCount': participantCount,
      'averageOffsetPerUser': averageOffsetPerUser,
      'status': status,
    };
  }

  // Calculate total cost for offsetting specific amount
  double calculateOffsetCost(double tonsOfCO2) {
    return tonsOfCO2 * costPerTonCO2;
  }
  
  // Check if program has capacity
  bool get hasCapacity => totalOffsetAvailable > 0;
  
  // Get program rating
  double get rating {
    // This would be calculated based on participant feedback and impact metrics
    return 4.2; // Mock rating
  }
}

// User's Sustainability Journey
class SustainabilityJourney {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime lastUpdated;
  final double totalCarbonOffset; // kg CO2 offset
  final double totalCarbonSaved; // kg CO2 saved through choices
  final int ecoPackagingChoices; // Times user chose eco packaging
  final int greenDeliveryChoices; // Times user chose green delivery
  final int sustainabilityGoalsSet; // Number of goals created
  final int sustainabilityGoalsAchieved; // Number of goals achieved
  final double currentSustainabilityScore; // Overall score 0-100
  final Map<String, int> categoryScores; // Scores by category
  final List<String> earnedBadges; // Sustainability badges earned
  final List<String> joinedChallenges; // Sustainability challenges joined
  final Map<String, int> challengeProgress; // Progress in challenges
  final String currentLevel; // Sustainability level
  final Map<String, dynamic> achievements; // Unlocked achievements
  final List<String> sharedStories; // Stories shared with community

  SustainabilityJourney({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.lastUpdated,
    required this.totalCarbonOffset,
    required this.totalCarbonSaved,
    required this.ecoPackagingChoices,
    required this.greenDeliveryChoices,
    required this.sustainabilityGoalsSet,
    required this.sustainabilityGoalsAchieved,
    required this.currentSustainabilityScore,
    required this.categoryScores,
    required this.earnedBadges,
    required this.joinedChallenges,
    required this.challengeProgress,
    required this.currentLevel,
    required this.achievements,
    required this.sharedStories,
  });

  factory SustainabilityJourney.fromJson(String id, Map<String, dynamic> json) {
    return SustainabilityJourney(
      id: id,
      userId: json['userId'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      totalCarbonOffset: (json['totalCarbonOffset'] ?? 0.0).toDouble(),
      totalCarbonSaved: (json['totalCarbonSaved'] ?? 0.0).toDouble(),
      ecoPackagingChoices: json['ecoPackagingChoices'] ?? 0,
      greenDeliveryChoices: json['greenDeliveryChoices'] ?? 0,
      sustainabilityGoalsSet: json['sustainabilityGoalsSet'] ?? 0,
      sustainabilityGoalsAchieved: json['sustainabilityGoalsAchieved'] ?? 0,
      currentSustainabilityScore: (json['currentSustainabilityScore'] ?? 0.0).toDouble(),
      categoryScores: Map<String, int>.from(json['categoryScores'] ?? {}),
      earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
      joinedChallenges: List<String>.from(json['joinedChallenges'] ?? []),
      challengeProgress: Map<String, int>.from(json['challengeProgress'] ?? {}),
      currentLevel: json['currentLevel'] ?? 'Beginner',
      achievements: Map<String, dynamic>.from(json['achievements'] ?? {}),
      sharedStories: List<String>.from(json['sharedStories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'startDate': startDate.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'totalCarbonOffset': totalCarbonOffset,
      'totalCarbonSaved': totalCarbonSaved,
      'ecoPackagingChoices': ecoPackagingChoices,
      'greenDeliveryChoices': greenDeliveryChoices,
      'sustainabilityGoalsSet': sustainabilityGoalsSet,
      'sustainabilityGoalsAchieved': sustainabilityGoalsAchieved,
      'currentSustainabilityScore': currentSustainabilityScore,
      'categoryScores': categoryScores,
      'earnedBadges': earnedBadges,
      'joinedChallenges': joinedChallenges,
      'challengeProgress': challengeProgress,
      'currentLevel': currentLevel,
      'achievements': achievements,
      'sharedStories': sharedStories,
    };
  }

  // Calculate overall environmental impact
  double get totalEnvironmentalImpact {
    return totalCarbonOffset + totalCarbonSaved;
  }
  
  // Calculate goal achievement rate
  double get goalAchievementRate {
    if (sustainabilityGoalsSet == 0) return 0.0;
    return (sustainabilityGoalsAchieved / sustainabilityGoalsSet) * 100;
  }
  
  // Get next level requirements
  Map<String, dynamic> get nextLevelRequirements {
    final levels = {
      'Beginner': {'score': 25, 'badges': 1, 'goals': 1},
      'Eco-Warrior': {'score': 50, 'badges': 3, 'goals': 3},
      'Green Champion': {'score': 75, 'badges': 5, 'goals': 5},
      'Sustainability Hero': {'score': 90, 'badges': 8, 'goals': 8},
      'Planet Protector': {'score': 100, 'badges': 10, 'goals': 10},
    };
    
    return levels[currentLevel] ?? levels['Beginner']!;
  }
  
  // Check if ready for next level
  bool get isReadyForNextLevel {
    final reqs = nextLevelRequirements;
    final scoreReq = reqs['score'];
    final badgesReq = reqs['badges'];
    final goalsReq = reqs['goals'];
    
    final scoreThreshold = (scoreReq as num?)?.toDouble() ?? 0.0;
    final badgesThreshold = (badgesReq as num?)?.toInt() ?? 0;
    final goalsThreshold = (goalsReq as num?)?.toInt() ?? 0;
    
    return (currentSustainabilityScore >= scoreThreshold) &&
           (earnedBadges.length >= badgesThreshold) &&
           (sustainabilityGoalsAchieved >= goalsThreshold);
  }
}

// Sustainability Challenge
class SustainabilityChallenge {
  final String id;
  final String title;
  final String description;
  final SustainabilityCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final String frequency; // 'once', 'daily', 'weekly', 'monthly'
  final double targetValue;
  final String unit;
  final List<String> participants; // User IDs
  final Map<String, double> userProgress; // User progress tracking
  final List<String> rewards; // Rewards for completion
  final Map<String, int> leaderboard; // User rankings
  final String status; // 'upcoming', 'active', 'completed', 'cancelled'
  final String difficulty; // 'easy', 'medium', 'hard', 'expert'
  final List<String> requirements; // Pre-conditions to join
  final Map<String, dynamic> socialFeatures; // Share, comment, etc.
  final String imageUrl;
  final List<String> tags;

  SustainabilityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    required this.targetValue,
    required this.unit,
    required this.participants,
    required this.userProgress,
    required this.rewards,
    required this.leaderboard,
    required this.status,
    required this.difficulty,
    required this.requirements,
    required this.socialFeatures,
    required this.imageUrl,
    required this.tags,
  });

  factory SustainabilityChallenge.fromJson(String id, Map<String, dynamic> json) {
    return SustainabilityChallenge(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: SustainabilityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SustainabilityCategory.carbonFootprint,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      frequency: json['frequency'] ?? '',
      targetValue: (json['targetValue'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      userProgress: Map<String, double>.from(json['userProgress'] ?? {}),
      rewards: List<String>.from(json['rewards'] ?? []),
      leaderboard: Map<String, int>.from(json['leaderboard'] ?? {}),
      status: json['status'] ?? 'upcoming',
      difficulty: json['difficulty'] ?? 'medium',
      requirements: List<String>.from(json['requirements'] ?? []),
      socialFeatures: Map<String, dynamic>.from(json['socialFeatures'] ?? {}),
      imageUrl: json['imageUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'frequency': frequency,
      'targetValue': targetValue,
      'unit': unit,
      'participants': participants,
      'userProgress': userProgress,
      'rewards': rewards,
      'leaderboard': leaderboard,
      'status': status,
      'difficulty': difficulty,
      'requirements': requirements,
      'socialFeatures': socialFeatures,
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }

  // Check if challenge is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  // Check if user is participating
  bool isParticipating(String userId) {
    return participants.contains(userId);
  }
  
  // Get user's progress
  double getUserProgress(String userId) {
    return userProgress[userId] ?? 0.0;
  }
  
  // Check if challenge is completed
  bool get isCompleted => status == 'completed';
  
  // Get challenge statistics
  Map<String, dynamic> get statistics {
    return {
      'totalParticipants': participants.length,
      'averageProgress': userProgress.isNotEmpty 
          ? userProgress.values.reduce((a, b) => a + b) / userProgress.length 
          : 0.0,
      'completionRate': participants.isNotEmpty 
          ? (userProgress.values.where((p) => p >= targetValue).length / participants.length) * 100 
          : 0.0,
      'daysRemaining': endDate.difference(DateTime.now()).inDays,
    };
  }
}