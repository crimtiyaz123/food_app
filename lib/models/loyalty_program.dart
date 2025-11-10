// Loyalty Programs and Referral System Models

import 'package:cloud_firestore/cloud_firestore.dart';

// Loyalty Tier Levels
enum LoyaltyTier {
  bronze,    // 0-999 points
  silver,    // 1000-2999 points
  gold,      // 3000-5999 points
  platinum,  // 6000-9999 points
  diamond,   // 10000+ points
}

// Reward Types
enum RewardType {
  discount,        // Percentage or fixed discount
  freeItem,        // Free food item
  freeDelivery,    // Free delivery
  cashback,        // Cash back to wallet
  merchandise,     // Branded items
  experience,      // VIP experiences
  charity,         // Donate to charity
  points,          // Bonus loyalty points
}

// Referral Status
enum ReferralStatus {
  pending,    // Referral sent but not signed up
  signedUp,   // Referred user signed up
  firstOrder, // Referred user placed first order
  completed,  // Referral completed (rewards earned)
  expired,    // Referral link expired
  cancelled,  // Referral cancelled
}

// Challenge Types
enum ChallengeType {
  daily,      // Daily challenges
  weekly,     // Weekly challenges
  monthly,    // Monthly challenges
  seasonal,   // Seasonal challenges
  special,    // Special event challenges
  milestone,  // Milestone challenges
}

// Points Transaction Types
enum PointsTransactionType {
  earn,       // Points earned
  redeem,     // Points redeemed
  bonus,      // Bonus points
  expire,     // Points expired
  adjust,     // Points adjusted
  refund,     // Points refunded
}

// Loyalty Program Configuration
class LoyaltyProgram {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final Map<LoyaltyTier, TierConfig> tierConfigs;
  final Map<String, dynamic> pointsRules;
  final Map<String, dynamic> rewardsCatalog;
  final Map<String, dynamic> referralConfig;
  final Map<String, dynamic> challenges;
  final Map<String, String> termsAndConditions;
  final String currency; // Points currency name
  final int pointsExpirationDays;
  final Map<String, dynamic> metadata;

  LoyaltyProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.tierConfigs,
    required this.pointsRules,
    required this.rewardsCatalog,
    required this.referralConfig,
    required this.challenges,
    required this.termsAndConditions,
    required this.currency,
    required this.pointsExpirationDays,
    required this.metadata,
  });

  factory LoyaltyProgram.fromJson(String id, Map<String, dynamic> json) {
    return LoyaltyProgram(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      isActive: json['isActive'] ?? false,
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      tierConfigs: (json['tierConfigs'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          LoyaltyTier.values.firstWhere(
            (tier) => tier.name == key,
            orElse: () => LoyaltyTier.bronze,
          ),
          TierConfig.fromJson(value),
        ),
      ) ?? {},
      pointsRules: Map<String, dynamic>.from(json['pointsRules'] ?? {}),
      rewardsCatalog: Map<String, dynamic>.from(json['rewardsCatalog'] ?? {}),
      referralConfig: Map<String, dynamic>.from(json['referralConfig'] ?? {}),
      challenges: Map<String, dynamic>.from(json['challenges'] ?? {}),
      termsAndConditions: Map<String, String>.from(json['termsAndConditions'] ?? {}),
      currency: json['currency'] ?? 'Points',
      pointsExpirationDays: json['pointsExpirationDays'] ?? 365,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'tierConfigs': tierConfigs.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      ),
      'pointsRules': pointsRules,
      'rewardsCatalog': rewardsCatalog,
      'referralConfig': referralConfig,
      'challenges': challenges,
      'termsAndConditions': termsAndConditions,
      'currency': currency,
      'pointsExpirationDays': pointsExpirationDays,
      'metadata': metadata,
    };
  }

  // Get tier for specific points amount
  LoyaltyTier getTierForPoints(int points) {
    for (final tier in LoyaltyTier.values.reversed) {
      final config = tierConfigs[tier];
      if (config != null && points >= config.minPoints) {
        return tier;
      }
    }
    return LoyaltyTier.bronze;
  }

  // Check if program is active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Get next tier for current points
  LoyaltyTier? getNextTier(int currentPoints) {
    final currentTier = getTierForPoints(currentPoints);
    final tierOrder = LoyaltyTier.values;
    final currentIndex = tierOrder.indexOf(currentTier);
    
    if (currentIndex < tierOrder.length - 1) {
      return tierOrder[currentIndex + 1];
    }
    return null;
  }

  // Get points needed for next tier
  int? getPointsNeededForNextTier(int currentPoints) {
    final nextTier = getNextTier(currentPoints);
    if (nextTier == null) return null;
    
    final config = tierConfigs[nextTier];
    return config != null ? config.minPoints - currentPoints : null;
  }
}

// Tier Configuration
class TierConfig {
  final String name;
  final String displayName;
  final String description;
  final int minPoints;
  final int maxPoints;
  final List<String> benefits;
  final double multiplier; // Points earning multiplier
  final String color; // UI color for the tier
  final String iconUrl;
  final List<String> exclusiveRewards;
  final Map<String, dynamic> perks;

  TierConfig({
    required this.name,
    required this.displayName,
    required this.description,
    required this.minPoints,
    required this.maxPoints,
    required this.benefits,
    required this.multiplier,
    required this.color,
    required this.iconUrl,
    required this.exclusiveRewards,
    required this.perks,
  });

  factory TierConfig.fromJson(Map<String, dynamic> json) {
    return TierConfig(
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
      minPoints: json['minPoints'] ?? 0,
      maxPoints: json['maxPoints'] ?? 999,
      benefits: List<String>.from(json['benefits'] ?? []),
      multiplier: (json['multiplier'] ?? 1.0).toDouble(),
      color: json['color'] ?? '#FFA500',
      iconUrl: json['iconUrl'] ?? '',
      exclusiveRewards: List<String>.from(json['exclusiveRewards'] ?? []),
      perks: Map<String, dynamic>.from(json['perks'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'description': description,
      'minPoints': minPoints,
      'maxPoints': maxPoints,
      'benefits': benefits,
      'multiplier': multiplier,
      'color': color,
      'iconUrl': iconUrl,
      'exclusiveRewards': exclusiveRewards,
      'perks': perks,
    };
  }

  // Check if points fall within this tier
  bool containsPoints(int points) {
    return points >= minPoints && (maxPoints == -1 || points <= maxPoints);
  }
}

// User Loyalty Profile
class UserLoyaltyProfile {
  final String id;
  final String userId;
  final String programId;
  final int totalPoints;
  final int availablePoints;
  final int lifetimePoints;
  final LoyaltyTier currentTier;
  final DateTime tierJoinedDate;
  final DateTime lastActivity;
  final DateTime createdAt;
  final Map<String, int> categoryPoints; // Points by category
  final List<String> earnedBadges;
  final Map<String, int> streakCounts; // Various streak counts
  final int referralCount;
  final int successfulReferrals;
  final Map<String, dynamic> preferences;
  final Map<String, int> challengeProgress;
  final DateTime? tierUpgradeDate;

  UserLoyaltyProfile({
    required this.id,
    required this.userId,
    required this.programId,
    required this.totalPoints,
    required this.availablePoints,
    required this.lifetimePoints,
    required this.currentTier,
    required this.tierJoinedDate,
    required this.lastActivity,
    required this.createdAt,
    required this.categoryPoints,
    required this.earnedBadges,
    required this.streakCounts,
    required this.referralCount,
    required this.successfulReferrals,
    required this.preferences,
    required this.challengeProgress,
    this.tierUpgradeDate,
  });

  factory UserLoyaltyProfile.fromJson(String id, Map<String, dynamic> json) {
    return UserLoyaltyProfile(
      id: id,
      userId: json['userId'] ?? '',
      programId: json['programId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      availablePoints: json['availablePoints'] ?? 0,
      lifetimePoints: json['lifetimePoints'] ?? 0,
      currentTier: LoyaltyTier.values.firstWhere(
        (tier) => tier.name == json['currentTier'],
        orElse: () => LoyaltyTier.bronze,
      ),
      tierJoinedDate: DateTime.fromMillisecondsSinceEpoch(json['tierJoinedDate'] ?? 0),
      lastActivity: DateTime.fromMillisecondsSinceEpoch(json['lastActivity'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      categoryPoints: Map<String, int>.from(json['categoryPoints'] ?? {}),
      earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
      streakCounts: Map<String, int>.from(json['streakCounts'] ?? {}),
      referralCount: json['referralCount'] ?? 0,
      successfulReferrals: json['successfulReferrals'] ?? 0,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      challengeProgress: Map<String, int>.from(json['challengeProgress'] ?? {}),
      tierUpgradeDate: json['tierUpgradeDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['tierUpgradeDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'programId': programId,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'lifetimePoints': lifetimePoints,
      'currentTier': currentTier.name,
      'tierJoinedDate': tierJoinedDate.millisecondsSinceEpoch,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'categoryPoints': categoryPoints,
      'earnedBadges': earnedBadges,
      'streakCounts': streakCounts,
      'referralCount': referralCount,
      'successfulReferrals': successfulReferrals,
      'preferences': preferences,
      'challengeProgress': challengeProgress,
      'tierUpgradeDate': tierUpgradeDate?.millisecondsSinceEpoch,
    };
  }

  // Calculate points to next tier
  int? getPointsToNextTier(LoyaltyProgram program) {
    return program.getPointsNeededForNextTier(totalPoints);
  }

  // Check if user is eligible for tier upgrade
  bool isEligibleForUpgrade(LoyaltyProgram program) {
    return program.getPointsNeededForNextTier(totalPoints) != null;
  }

  // Get activity streak
  int getActivityStreak() {
    return streakCounts['activity'] ?? 0;
  }

  // Get order streak
  int getOrderStreak() {
    return streakCounts['orders'] ?? 0;
  }

  // Get referral success rate
  double getReferralSuccessRate() {
    if (referralCount == 0) return 0.0;
    return (successfulReferrals / referralCount) * 100;
  }
}

// Points Transaction
class PointsTransaction {
  final String id;
  final String userId;
  final String programId;
  final PointsTransactionType type;
  final int points;
  final String? relatedOrderId;
  final String? relatedReferralId;
  final String description;
  final DateTime timestamp;
  final DateTime? expiryDate;
  final String? source; // 'order', 'referral', 'challenge', 'bonus', etc.
  final Map<String, dynamic> metadata;
  final int? expiresInDays;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.programId,
    required this.type,
    required this.points,
    this.relatedOrderId,
    this.relatedReferralId,
    required this.description,
    required this.timestamp,
    this.expiryDate,
    this.source,
    required this.metadata,
    this.expiresInDays,
  });

  factory PointsTransaction.fromJson(String id, Map<String, dynamic> json) {
    return PointsTransaction(
      id: id,
      userId: json['userId'] ?? '',
      programId: json['programId'] ?? '',
      type: PointsTransactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PointsTransactionType.earn,
      ),
      points: json['points'] ?? 0,
      relatedOrderId: json['relatedOrderId'],
      relatedReferralId: json['relatedReferralId'],
      description: json['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      expiryDate: json['expiryDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['expiryDate'])
          : null,
      source: json['source'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      expiresInDays: json['expiresInDays'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'programId': programId,
      'type': type.name,
      'points': points,
      'relatedOrderId': relatedOrderId,
      'relatedReferralId': relatedReferralId,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'source': source,
      'metadata': metadata,
      'expiresInDays': expiresInDays,
    };
  }

  // Check if transaction points are expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Get points value (negative for redemptions)
  int get pointsValue {
    switch (type) {
      case PointsTransactionType.earn:
      case PointsTransactionType.bonus:
        return points;
      case PointsTransactionType.redeem:
      case PointsTransactionType.expire:
      case PointsTransactionType.refund:
        return -points.abs();
      case PointsTransactionType.adjust:
        return points; // Can be positive or negative
    }
  }
}

// Reward
class Reward {
  final String id;
  final String programId;
  final String name;
  final String description;
  final String imageUrl;
  final RewardType type;
  final int pointsCost;
  final Map<String, dynamic> value; // Depends on reward type
  final int availableQuantity;
  final int claimedQuantity;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> eligibleTiers;
  final List<String> terms;
  final bool isActive;
  final Map<String, dynamic> metadata;

  Reward({
    required this.id,
    required this.programId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.pointsCost,
    required this.value,
    required this.availableQuantity,
    required this.claimedQuantity,
    this.startDate,
    this.endDate,
    required this.eligibleTiers,
    required this.terms,
    required this.isActive,
    required this.metadata,
  });

  factory Reward.fromJson(String id, Map<String, dynamic> json) {
    return Reward(
      id: id,
      programId: json['programId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: RewardType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RewardType.discount,
      ),
      pointsCost: json['pointsCost'] ?? 0,
      value: Map<String, dynamic>.from(json['value'] ?? {}),
      availableQuantity: json['availableQuantity'] ?? -1, // -1 for unlimited
      claimedQuantity: json['claimedQuantity'] ?? 0,
      startDate: json['startDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['startDate'])
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      eligibleTiers: List<String>.from(json['eligibleTiers'] ?? []),
      terms: List<String>.from(json['terms'] ?? []),
      isActive: json['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'pointsCost': pointsCost,
      'value': value,
      'availableQuantity': availableQuantity,
      'claimedQuantity': claimedQuantity,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'eligibleTiers': eligibleTiers,
      'terms': terms,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // Check if reward is available
  bool get isAvailable {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (availableQuantity >= 0 && claimedQuantity >= availableQuantity) return false;
    
    return true;
  }

  // Check if user is eligible for this reward
  bool isEligibleForUser(UserLoyaltyProfile userProfile) {
    // Check tier eligibility
    if (eligibleTiers.isNotEmpty && !eligibleTiers.contains(userProfile.currentTier.name)) {
      return false;
    }
    
    // Check if user has enough points
    if (userProfile.availablePoints < pointsCost) {
      return false;
    }
    
    return true;
  }

  // Get display value for the reward
  String get displayValue {
    switch (type) {
      case RewardType.discount:
        final discountType = value['type'] ?? 'percentage';
        if (discountType == 'percentage') {
          return '${value['value']}% off';
        } else {
          return '\$${value['value']} off';
        }
      case RewardType.freeItem:
        return 'Free ${value['itemName'] ?? 'item'}';
      case RewardType.freeDelivery:
        return 'Free delivery';
      case RewardType.cashback:
        return '\$${value['amount']} cashback';
      case RewardType.merchandise:
        return value['itemName'] ?? 'Merchandise';
      case RewardType.experience:
        return value['experienceName'] ?? 'VIP Experience';
      case RewardType.charity:
        return 'Donate to ${value['charityName'] ?? 'charity'}';
      case RewardType.points:
        return '${value['bonusPoints'] ?? 0} bonus points';
      default:
        return 'Reward';
    }
  }
}

// Referral
class Referral {
  final String id;
  final String referrerId;
  final String referredId;
  final String programId;
  final String referralCode;
  final String? sharedVia; // 'link', 'code', 'whatsapp', 'email', etc.
  final ReferralStatus status;
  final DateTime createdAt;
  final DateTime? signedUpAt;
  final DateTime? firstOrderAt;
  final DateTime? completedAt;
  final Map<String, dynamic> rewardEarned;
  final Map<String, dynamic> metadata;

  Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.programId,
    required this.referralCode,
    this.sharedVia,
    required this.status,
    required this.createdAt,
    this.signedUpAt,
    this.firstOrderAt,
    this.completedAt,
    required this.rewardEarned,
    required this.metadata,
  });

  factory Referral.fromJson(String id, Map<String, dynamic> json) {
    return Referral(
      id: id,
      referrerId: json['referrerId'] ?? '',
      referredId: json['referredId'] ?? '',
      programId: json['programId'] ?? '',
      referralCode: json['referralCode'] ?? '',
      sharedVia: json['sharedVia'],
      status: ReferralStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      signedUpAt: json['signedUpAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['signedUpAt'])
          : null,
      firstOrderAt: json['firstOrderAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['firstOrderAt'])
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      rewardEarned: Map<String, dynamic>.from(json['rewardEarned'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referrerId': referrerId,
      'referredId': referredId,
      'programId': programId,
      'referralCode': referralCode,
      'sharedVia': sharedVia,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'signedUpAt': signedUpAt?.millisecondsSinceEpoch,
      'firstOrderAt': firstOrderAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'rewardEarned': rewardEarned,
      'metadata': metadata,
    };
  }

  // Check if referral is completed
  bool get isCompleted => status == ReferralStatus.completed;
  
  // Check if referral is active
  bool get isActive => status == ReferralStatus.pending || status == ReferralStatus.signedUp;
  
  // Get days since referral
  int get daysSinceReferral => DateTime.now().difference(createdAt).inDays;
  
  // Get referral progress percentage
  double get progressPercentage {
    switch (status) {
      case ReferralStatus.pending:
        return 0.0;
      case ReferralStatus.signedUp:
        return 33.0;
      case ReferralStatus.firstOrder:
        return 66.0;
      case ReferralStatus.completed:
        return 100.0;
      case ReferralStatus.expired:
      case ReferralStatus.cancelled:
        return 0.0;
    }
  }
}

// Challenge
class Challenge {
  final String id;
  final String programId;
  final String name;
  final String description;
  final String imageUrl;
  final ChallengeType type;
  final int targetValue;
  final String unit; // 'orders', 'points', 'days', etc.
  final int pointsReward;
  final List<String> additionalRewards;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final Map<String, int> participantProgress;
  final bool isActive;
  final Map<String, dynamic> requirements;
  final List<String> tags;

  Challenge({
    required this.id,
    required this.programId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.targetValue,
    required this.unit,
    required this.pointsReward,
    required this.additionalRewards,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.participantIds,
    required this.participantProgress,
    required this.isActive,
    required this.requirements,
    required this.tags,
  });

  factory Challenge.fromJson(String id, Map<String, dynamic> json) {
    return Challenge(
      id: id,
      programId: json['programId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: ChallengeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChallengeType.daily,
      ),
      targetValue: json['targetValue'] ?? 0,
      unit: json['unit'] ?? '',
      pointsReward: json['pointsReward'] ?? 0,
      additionalRewards: List<String>.from(json['additionalRewards'] ?? []),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      maxParticipants: json['maxParticipants'] ?? -1, // -1 for unlimited
      currentParticipants: json['currentParticipants'] ?? 0,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      participantProgress: Map<String, int>.from(json['participantProgress'] ?? {}),
      isActive: json['isActive'] ?? true,
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'targetValue': targetValue,
      'unit': unit,
      'pointsReward': pointsReward,
      'additionalRewards': additionalRewards,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'participantIds': participantIds,
      'participantProgress': participantProgress,
      'isActive': isActive,
      'requirements': requirements,
      'tags': tags,
    };
  }

  // Check if challenge is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           now.isBefore(endDate) &&
           (maxParticipants == -1 || currentParticipants < maxParticipants);
  }

  // Check if user is participating
  bool isParticipating(String userId) {
    return participantIds.contains(userId);
  }

  // Get user's progress in this challenge
  int getUserProgress(String userId) {
    return participantProgress[userId] ?? 0;
  }

  // Check if user has completed the challenge
  bool isCompletedByUser(String userId) {
    return getUserProgress(userId) >= targetValue;
  }

  // Get time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }
}

// User Challenge Progress
class UserChallengeProgress {
  final String id;
  final String userId;
  final String challengeId;
  final int currentProgress;
  final DateTime lastUpdated;
  final bool isCompleted;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  UserChallengeProgress({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.currentProgress,
    required this.lastUpdated,
    required this.isCompleted,
    this.completedAt,
    required this.metadata,
  });

  factory UserChallengeProgress.fromJson(String id, Map<String, dynamic> json) {
    return UserChallengeProgress(
      id: id,
      userId: json['userId'] ?? '',
      challengeId: json['challengeId'] ?? '',
      currentProgress: json['currentProgress'] ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'currentProgress': currentProgress,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}