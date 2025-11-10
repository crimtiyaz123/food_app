import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/loyalty_program.dart';


class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize or get user loyalty profile
  Future<UserLoyaltyProfile> getOrCreateUserProfile({
    required String userId,
    String programId = 'default',
  }) async {
    try {
      // Try to get existing profile
      final existingProfile = await getUserLoyaltyProfile(userId, programId);
      if (existingProfile != null) {
        return existingProfile;
      }

      // Create new profile
      return await _createUserLoyaltyProfile(userId, programId);
    } catch (e) {
      debugPrint('Error getting/creating user loyalty profile: $e');
      rethrow;
    }
  }

  // Get user's loyalty profile
  Future<UserLoyaltyProfile?> getUserLoyaltyProfile(String userId, String programId) async {
    try {
      final doc = await _firestore
          .collection('userLoyaltyProfiles')
          .doc('$userId-$programId')
          .get();

      if (doc.exists) {
        return UserLoyaltyProfile.fromJson(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user loyalty profile: $e');
      return null;
    }
  }

  // Award points for an order
  Future<Map<String, dynamic>> awardPointsForOrder({
    required String userId,
    required String orderId,
    required double orderAmount,
    String? category,
  }) async {
    try {
      final profile = await getOrCreateUserProfile(userId: userId);
      final program = await getActiveLoyaltyProgram(profile.programId);
      
      if (program == null) {
        throw Exception('No active loyalty program found');
      }

      // Calculate points to award
      final pointsToAward = _calculatePointsForOrder(
        orderAmount,
        program,
        profile.currentTier,
        category,
      );

      // Create transaction record
      final transaction = PointsTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        programId: program.id,
        type: PointsTransactionType.earn,
        points: pointsToAward,
        relatedOrderId: orderId,
        description: 'Points earned for order',
        timestamp: DateTime.now(),
        source: 'order',
        metadata: {
          'orderAmount': orderAmount,
          'category': category,
          'tierMultiplier': program.tierConfigs[profile.currentTier]?.multiplier ?? 1.0,
        },
        expiresInDays: program.pointsExpirationDays,
      );

      // Save transaction
      await _savePointsTransaction(transaction);

      // Update user profile
      await _updateUserProfileWithPoints(
        userId,
        program.id,
        pointsToAward,
        category,
        transaction,
      );

      // Check for tier upgrade
      final tierUpgrade = await _checkForTierUpgrade(userId, program.id);

      // Check for challenge progress updates
      await _updateChallengeProgress(userId, orderId, orderAmount);

      return {
        'pointsAwarded': pointsToAward,
        'tierUpgrade': tierUpgrade,
        'transactionId': transaction.id,
        'newTotalPoints': profile.totalPoints + pointsToAward,
      };
    } catch (e) {
      debugPrint('Error awarding points for order: $e');
      rethrow;
    }
  }

  // Redeem reward
  Future<Map<String, dynamic>> redeemReward({
    required String userId,
    required String rewardId,
  }) async {
    try {
      final profile = await getOrCreateUserProfile(userId: userId);
      final reward = await getReward(rewardId);
      
      if (reward == null) {
        throw Exception('Reward not found');
      }

      // Check if user is eligible
      if (!reward.isEligibleForUser(profile)) {
        throw Exception('User not eligible for this reward');
      }

      if (profile.availablePoints < reward.pointsCost) {
        throw Exception('Insufficient points');
      }

      // Create redemption transaction
      final transaction = PointsTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        programId: reward.programId,
        type: PointsTransactionType.redeem,
        points: reward.pointsCost,
        description: 'Redeemed: ${reward.name}',
        timestamp: DateTime.now(),
        source: 'reward_redemption',
        metadata: {
          'rewardId': rewardId,
          'rewardType': reward.type.name,
          'rewardValue': reward.value,
        },
      );

      // Save transaction
      await _savePointsTransaction(transaction);

      // Update user profile
      await _updateUserProfileAfterRedemption(
        userId,
        reward.programId,
        reward.pointsCost,
        transaction,
      );

      // Update reward claim count
      await _updateRewardClaimCount(rewardId);

      // Generate reward code/QR code
      final rewardCode = await _generateRewardCode(rewardId, userId);

      return {
        'success': true,
        'transactionId': transaction.id,
        'rewardCode': rewardCode,
        'pointsRemaining': profile.availablePoints - reward.pointsCost,
        'message': '${reward.name} redeemed successfully!',
      };
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create referral
  Future<Map<String, dynamic>> createReferral({
    required String referrerId,
    String? sharedVia,
  }) async {
    try {
      final referrerProfile = await getOrCreateUserProfile(userId: referrerId);
      final program = await getActiveLoyaltyProgram(referrerProfile.programId);
      
      if (program == null) {
        throw Exception('No active loyalty program found');
      }

      // Generate unique referral code
      final referralCode = _generateReferralCode(referrerId);

      // Create referral record
      final referral = Referral(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        referrerId: referrerId,
        referredId: '', // Will be filled when referred user signs up
        programId: program.id,
        referralCode: referralCode,
        sharedVia: sharedVia,
        status: ReferralStatus.pending,
        createdAt: DateTime.now(),
        rewardEarned: {},
        metadata: {
          'expiresAt': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch,
        },
      );

      await _saveReferral(referral);

      // Generate shareable link
      final shareableLink = _generateShareableLink(referralCode, program);

      return {
        'referralCode': referralCode,
        'shareableLink': shareableLink,
        'referralId': referral.id,
        'expiresAt': referral.metadata['expiresAt'],
        'rewards': _getReferralRewards(program),
      };
    } catch (e) {
      debugPrint('Error creating referral: $e');
      rethrow;
    }
  }

  // Process referral signup
  Future<Map<String, dynamic>> processReferralSignup({
    required String referredId,
    required String referralCode,
  }) async {
    try {
      // Find referral by code
      final referral = await _getReferralByCode(referralCode);
      if (referral == null) {
        throw Exception('Invalid referral code');
      }

      if (referral.referredId.isNotEmpty) {
        throw Exception('Referral code already used');
      }

      // Update referral
      await _updateReferral(referral.id, {
        'referredId': referredId,
        'signedUpAt': DateTime.now().millisecondsSinceEpoch,
        'status': ReferralStatus.signedUp.name,
      });

      // Award signup bonus
      final program = await getActiveLoyaltyProgram(referral.programId);
      if (program != null) {
        await _awardReferralSignupBonus(referral, program);
      }

      // Update referrer's profile
      await _updateReferrerProfile(referral.referrerId, 'signed_up');

      return {
        'success': true,
        'message': 'Referral bonus awarded!',
        'bonusPoints': _getReferralSignupBonus(program),
      };
    } catch (e) {
      debugPrint('Error processing referral signup: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Process referral first order
  Future<Map<String, dynamic>> processReferralFirstOrder({
    required String referredId,
    required String orderId,
    required double orderAmount,
  }) async {
    try {
      // Find active referral for this user
      final referral = await _getActiveReferralForUser(referredId);
      if (referral == null) {
        return {'success': false, 'error': 'No active referral found'};
      }

      // Update referral
      await _updateReferral(referral.id, {
        'firstOrderAt': DateTime.now().millisecondsSinceEpoch,
        'status': ReferralStatus.firstOrder.name,
      });

      // Award first order bonus
      final program = await getActiveLoyaltyProgram(referral.programId);
      if (program != null) {
        await _awardReferralFirstOrderBonus(referral, program, orderAmount);
      }

      // Update referrer's profile
      await _updateReferrerProfile(referral.referrerId, 'first_order');

      return {
        'success': true,
        'message': 'Referral first order bonus awarded!',
      };
    } catch (e) {
      debugPrint('Error processing referral first order: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Join challenge
  Future<Map<String, dynamic>> joinChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final challenge = await getChallenge(challengeId);
      if (challenge == null) {
        throw Exception('Challenge not found');
      }

      if (!challenge.isCurrentlyActive) {
        throw Exception('Challenge is not currently active');
      }

      if (challenge.isParticipating(userId)) {
        return {
          'success': false,
          'message': 'Already participating in this challenge',
        };
      }

      // Check requirements
      if (!_meetsChallengeRequirements(userId, challenge.requirements)) {
        throw Exception('User does not meet challenge requirements');
      }

      // Add user to challenge
      await _addUserToChallenge(challengeId, userId);

      // Create progress record
      final progress = UserChallengeProgress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        challengeId: challengeId,
        currentProgress: 0,
        lastUpdated: DateTime.now(),
        isCompleted: false,
        metadata: {},
      );

      await _saveChallengeProgress(progress);

      return {
        'success': true,
        'message': 'Successfully joined challenge!',
        'challengeName': challenge.name,
        'targetValue': challenge.targetValue,
        'unit': challenge.unit,
        'timeRemaining': challenge.timeRemaining.inDays,
      };
    } catch (e) {
      debugPrint('Error joining challenge: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update challenge progress
  Future<Map<String, dynamic>> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required int progressIncrement,
    String? source, // 'order', 'daily_login', etc.
  }) async {
    try {
      final progress = await getUserChallengeProgress(userId, challengeId);
      if (progress == null) {
        return {
          'success': false,
          'error': 'User not participating in this challenge',
        };
      }

      final challenge = await getChallenge(challengeId);
      if (challenge == null) {
        return {
          'success': false,
          'error': 'Challenge not found',
        };
      }

      final newProgress = progress.currentProgress + progressIncrement;
      final isCompleted = newProgress >= challenge.targetValue;

      // Update progress
      await _updateChallengeProgressRecord(userId, challengeId, newProgress, isCompleted);

      // Check if completed and award rewards
      if (isCompleted && !progress.isCompleted) {
        await _awardChallengeRewards(userId, challengeId, challenge);
      }

      return {
        'success': true,
        'currentProgress': newProgress,
        'targetValue': challenge.targetValue,
        'isCompleted': isCompleted,
        'progressPercentage': (newProgress / challenge.targetValue * 100).round(),
      };
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get active challenges for user
  Future<List<Challenge>> getActiveChallengesForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .get();

      var challenges = snapshot.docs.map((doc) {
        return Challenge.fromJson(doc.id, doc.data());
      }).toList();

      // Filter active challenges
      challenges = challenges.where((challenge) {
        return challenge.isCurrentlyActive;
      }).toList();

      // Filter by user eligibility
      challenges = challenges.where((challenge) {
        return !challenge.requirements.values.any((req) => !_meetsRequirement(userId, req));
      }).toList();

      return challenges;
    } catch (e) {
      debugPrint('Error getting active challenges: $e');
      return [];
    }
  }

  // Get user's referral stats
  Future<Map<String, dynamic>> getUserReferralStats(String userId) async {
    try {
      final profile = await getOrCreateUserProfile(userId: userId);
      
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();

      final referrals = snapshot.docs.map((doc) {
        return Referral.fromJson(doc.id, doc.data());
      }).toList();

      final stats = {
        'totalReferrals': profile.referralCount,
        'successfulReferrals': profile.successfulReferrals,
        'pendingReferrals': referrals.where((r) => r.isActive).length,
        'completedReferrals': referrals.where((r) => r.isCompleted).length,
        'successRate': profile.getReferralSuccessRate(),
        'totalEarnings': referrals
            .where((r) => r.isCompleted)
            .fold(0.0, (total, r) => total + _calculateReferralEarnings(r)),
        'recentReferrals': referrals
            .take(5)
            .map((r) => {
              'status': r.status.name,
              'daysSinceReferral': r.daysSinceReferral,
              'progress': r.progressPercentage,
            })
            .toList(),
      };

      return stats;
    } catch (e) {
      debugPrint('Error getting user referral stats: $e');
      return {};
    }
  }

  // Get available rewards
  Future<List<Reward>> getAvailableRewards({
    required String userId,
    String programId = 'default',
  }) async {
    try {
      final profile = await getOrCreateUserProfile(userId: userId);
      
      final snapshot = await _firestore
          .collection('rewards')
          .where('programId', isEqualTo: programId)
          .where('isActive', isEqualTo: true)
          .get();

      var rewards = snapshot.docs.map((doc) {
        return Reward.fromJson(doc.id, doc.data());
      }).toList();

      // Filter available rewards
      rewards = rewards.where((reward) {
        return reward.isAvailable && reward.isEligibleForUser(profile);
      }).toList();

      return rewards;
    } catch (e) {
      debugPrint('Error getting available rewards: $e');
      return [];
    }
  }

  // Get loyalty analytics for user
  Future<Map<String, dynamic>> getUserLoyaltyAnalytics(String userId) async {
    try {
      final profile = await getOrCreateUserProfile(userId: userId);
      final program = await getActiveLoyaltyProgram(profile.programId);
      
      if (program == null) {
        return {};
      }

      // Get recent transactions
      final transactions = await getUserRecentTransactions(userId, 30); // Last 30 days
      
      // Calculate metrics
      final totalEarned = transactions
          .where((t) => t.type == PointsTransactionType.earn)
          .fold(0, (total, t) => total + t.points);
      
      final totalRedeemed = transactions
          .where((t) => t.type == PointsTransactionType.redeem)
          .fold(0, (total, t) => total + t.points.abs());
      
      final expiredPoints = transactions
          .where((t) => t.isExpired)
          .fold(0, (total, t) => total + t.points);
      
      final analytics = {
        'currentTier': profile.currentTier.name,
        'tierProgress': _calculateTierProgress(profile, program),
        'pointsToNextTier': profile.getPointsToNextTier(program),
        'totalPointsEarned': profile.lifetimePoints,
        'availablePoints': profile.availablePoints,
        'recentActivity': {
          'pointsEarned': totalEarned,
          'pointsRedeemed': totalRedeemed,
          'expiredPoints': expiredPoints,
          'activeStreaks': profile.streakCounts,
        },
        'categoryBreakdown': profile.categoryPoints,
        'badges': profile.earnedBadges,
        'monthlyActivity': _calculateMonthlyActivity(transactions),
        'recommendations': await _getPersonalizedRecommendations(profile, program),
      };

      return analytics;
    } catch (e) {
      debugPrint('Error getting user loyalty analytics: $e');
      return {};
    }
  }

  // Private helper methods
  
  Future<UserLoyaltyProfile> _createUserLoyaltyProfile(String userId, String programId) async {
    final profile = UserLoyaltyProfile(
      id: '$userId-$programId',
      userId: userId,
      programId: programId,
      totalPoints: 0,
      availablePoints: 0,
      lifetimePoints: 0,
      currentTier: LoyaltyTier.bronze,
      tierJoinedDate: DateTime.now(),
      lastActivity: DateTime.now(),
      createdAt: DateTime.now(),
      categoryPoints: {},
      earnedBadges: [],
      streakCounts: {},
      referralCount: 0,
      successfulReferrals: 0,
      preferences: {},
      challengeProgress: {},
    );

    await _firestore.collection('userLoyaltyProfiles').doc(profile.id).set(profile.toJson());
    return profile;
  }

  int _calculatePointsForOrder(
    double orderAmount,
    LoyaltyProgram program,
    LoyaltyTier tier,
    String? category,
  ) {
    final basePoints = (orderAmount * (program.pointsRules['pointsPerDollar'] ?? 1)).round();
    final tierMultiplier = program.tierConfigs[tier]?.multiplier ?? 1.0;
    final categoryBonus = category != null 
        ? (program.pointsRules['categoryBonuses']?[category] ?? 1.0)
        : 1.0;
    
    return (basePoints * tierMultiplier * categoryBonus).round();
  }

  Future<void> _savePointsTransaction(PointsTransaction transaction) async {
    await _firestore
        .collection('pointsTransactions')
        .doc(transaction.id)
        .set(transaction.toJson());
  }

  Future<void> _updateUserProfileWithPoints(
    String userId,
    String programId,
    int points,
    String? category,
    PointsTransaction transaction,
  ) async {
    final profileId = '$userId-$programId';
    final doc = await _firestore.collection('userLoyaltyProfiles').doc(profileId).get();
    
    if (doc.exists) {
      final updates = {
        'totalPoints': FieldValue.increment(points),
        'availablePoints': FieldValue.increment(points),
        'lifetimePoints': FieldValue.increment(points),
        'lastActivity': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (category != null) {
        updates['categoryPoints.$category'] = FieldValue.increment(points);
      }
      
      await _firestore.collection('userLoyaltyProfiles').doc(profileId).update(updates);
    }
  }

  Future<Map<String, dynamic>?> _checkForTierUpgrade(String userId, String programId) async {
    final profile = await getUserLoyaltyProfile(userId, programId);
    final program = await getActiveLoyaltyProgram(programId);
    
    if (profile == null || program == null) return null;
    
    final newTier = program.getTierForPoints(profile.totalPoints);
    
    if (newTier != profile.currentTier) {
      // Update tier
      await _firestore.collection('userLoyaltyProfiles').doc(profile.id).update({
        'currentTier': newTier.name,
        'tierUpgradeDate': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Award tier upgrade bonus
      final bonusPoints = (program.tierConfigs[newTier]?.perks['upgradeBonus'] ?? 500);
      await _awardTierUpgradeBonus(userId, programId, newTier, bonusPoints);
      
      return {
        'oldTier': profile.currentTier.name,
        'newTier': newTier.name,
        'bonusPoints': bonusPoints,
        'newBenefits': program.tierConfigs[newTier]?.benefits ?? [],
      };
    }
    
    return null;
  }

  Future<void> _awardTierUpgradeBonus(
    String userId,
    String programId,
    LoyaltyTier newTier,
    int bonusPoints,
  ) async {
    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      programId: programId,
      type: PointsTransactionType.bonus,
      points: bonusPoints,
      description: 'Tier upgrade bonus: ${newTier.name}',
      timestamp: DateTime.now(),
      source: 'tier_upgrade',
      metadata: {
        'newTier': newTier.name,
        'tierUpgradeBonus': true,
      },
    );
    
    await _savePointsTransaction(transaction);
    await _updateUserProfileWithPoints(userId, programId, bonusPoints, null, transaction);
  }

  Future<void> _updateChallengeProgress(
    String userId,
    String orderId,
    double orderAmount,
  ) async {
    // Update daily order challenges
    final dailyChallenges = await getActiveChallengesForUser(userId);
    for (final challenge in dailyChallenges) {
      if (challenge.unit == 'orders' && challenge.type == ChallengeType.daily) {
        await updateChallengeProgress(
          userId: userId,
          challengeId: challenge.id,
          progressIncrement: 1,
          source: 'order',
        );
      }
    }
  }

  String _generateReferralCode(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = (userId + timestamp.toString()).hashCode.abs();
    return 'REF${hash.toString().substring(0, 6).toUpperCase()}';
  }

  String _generateShareableLink(String referralCode, LoyaltyProgram program) {
    final baseUrl = program.metadata['baseUrl'] ?? 'https://foodapp.com';
    return '$baseUrl/join?ref=$referralCode';
  }

  List<Map<String, dynamic>> _getReferralRewards(LoyaltyProgram program) {
    final referralConfig = program.referralConfig;
    return [
      {
        'type': 'referrer_signup',
        'points': referralConfig['referrerSignupBonus'] ?? 250,
        'description': 'Friend signs up',
      },
      {
        'type': 'referrer_first_order',
        'points': referralConfig['referrerFirstOrderBonus'] ?? 500,
        'description': 'Friend places first order',
      },
      {
        'type': 'referred_signup',
        'points': referralConfig['referredSignupBonus'] ?? 100,
        'description': 'Signup bonus for friend',
      },
    ];
  }

  int _getReferralSignupBonus(LoyaltyProgram? program) {
    return program?.referralConfig['referredSignupBonus'] ?? 100;
  }

  Future<void> _saveReferral(Referral referral) async {
    await _firestore.collection('referrals').doc(referral.id).set(referral.toJson());
  }

  Future<Referral?> _getReferralByCode(String referralCode) async {
    final snapshot = await _firestore
        .collection('referrals')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return Referral.fromJson(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<void> _updateReferral(String referralId, Map<String, dynamic> updates) async {
    await _firestore.collection('referrals').doc(referralId).update(updates);
  }

  Future<Referral?> _getActiveReferralForUser(String userId) async {
    final snapshot = await _firestore
        .collection('referrals')
        .where('referredId', isEqualTo: userId)
        .where('status', whereIn: [ReferralStatus.pending.name, ReferralStatus.signedUp.name])
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return Referral.fromJson(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<void> _awardReferralSignupBonus(Referral referral, LoyaltyProgram program) async {
    final bonusPoints = program.referralConfig['referredSignupBonus'] ?? 100;
    
    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: referral.referredId,
      programId: referral.programId,
      type: PointsTransactionType.bonus,
      points: bonusPoints,
      description: 'Referral signup bonus',
      timestamp: DateTime.now(),
      source: 'referral',
      metadata: {
        'referralId': referral.id,
        'referrerId': referral.referrerId,
      },
    );
    
    await _savePointsTransaction(transaction);
    await _updateUserProfileWithPoints(referral.referredId, referral.programId, bonusPoints, null, transaction);
  }

  Future<void> _awardReferralFirstOrderBonus(Referral referral, LoyaltyProgram program, double orderAmount) async {
    // Bonus for referred user
    final referredBonus = (orderAmount * 0.1).round(); // 10% of order amount
    final referrerBonus = program.referralConfig['referrerFirstOrderBonus'] ?? 500;
    
    // Award to referred user
    final referredTransaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: referral.referredId,
      programId: referral.programId,
      type: PointsTransactionType.bonus,
      points: referredBonus,
      description: 'Referral first order bonus',
      timestamp: DateTime.now(),
      source: 'referral',
      metadata: {
        'referralId': referral.id,
        'orderAmount': orderAmount,
      },
    );
    
    await _savePointsTransaction(referredTransaction);
    await _updateUserProfileWithPoints(referral.referredId, referral.programId, referredBonus, null, referredTransaction);
    
    // Award to referrer
    final referrerTransaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: referral.referrerId,
      programId: referral.programId,
      type: PointsTransactionType.bonus,
      points: referrerBonus,
      description: 'Referral successful - friend ordered',
      timestamp: DateTime.now(),
      source: 'referral',
      metadata: {
        'referralId': referral.id,
        'referredId': referral.referredId,
      },
    );
    
    await _savePointsTransaction(referrerTransaction);
    await _updateUserProfileWithPoints(referral.referrerId, referral.programId, referrerBonus, null, referrerTransaction);
    
    // Mark referral as completed
    await _updateReferral(referral.id, {
      'status': ReferralStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'rewardEarned': {
        'referredBonus': referredBonus,
        'referrerBonus': referrerBonus,
      },
    });
  }

  Future<void> _updateReferrerProfile(String referrerId, String milestone) async {
    final profileId = '$referrerId-default';
    final Map<String, dynamic> updates = {
      'lastActivity': DateTime.now().millisecondsSinceEpoch,
    };
    
    switch (milestone) {
      case 'signed_up':
        updates['referralCount'] = FieldValue.increment(1);
        break;
      case 'first_order':
        updates['successfulReferrals'] = FieldValue.increment(1);
        break;
    }
    
    await _firestore.collection('userLoyaltyProfiles').doc(profileId).update(updates);
  }

  bool _meetsChallengeRequirements(String userId, Map<String, dynamic> requirements) {
    // Simplified requirements check
    for (final entry in requirements.entries) {
      switch (entry.key) {
        case 'minOrders':
          // Would check user's order history
          break;
        case 'minPoints':
          // Would check user's point balance
          break;
        case 'tier':
          // Would check user's tier
          break;
      }
    }
    return true; // Simplified for now
  }

  bool _meetsRequirement(String userId, String requirement) {
    // Check individual requirement
    switch (requirement) {
      case 'hasOrderHistory':
        return true; // Simplified
      case 'minPoints100':
        return true; // Simplified
      case 'tierBronze':
        return true; // Simplified
      default:
        return true;
    }
  }

  Future<void> _addUserToChallenge(String challengeId, String userId) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
      'currentParticipants': FieldValue.increment(1),
      'participantProgress.$userId': 0,
    });
  }

  Future<void> _saveChallengeProgress(UserChallengeProgress progress) async {
    await _firestore
        .collection('userChallengeProgress')
        .doc(progress.id)
        .set(progress.toJson());
  }

  Future<void> _updateChallengeProgressRecord(
    String userId,
    String challengeId,
    int newProgress,
    bool isCompleted,
  ) async {
    final updates = {
      'currentProgress': newProgress,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
    
    if (isCompleted) {
      updates['completedAt'] = DateTime.now().millisecondsSinceEpoch;
    }
    
    await _firestore.collection('userChallengeProgress')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update(updates);
      }
    });
  }

  Future<void> _awardChallengeRewards(String userId, String challengeId, Challenge challenge) async {
    // Award points
    final pointsTransaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      programId: challenge.programId,
      type: PointsTransactionType.bonus,
      points: challenge.pointsReward,
      description: 'Challenge completed: ${challenge.name}',
      timestamp: DateTime.now(),
      source: 'challenge',
      metadata: {
        'challengeId': challengeId,
        'challengeType': challenge.type.name,
      },
    );
    
    await _savePointsTransaction(pointsTransaction);
    await _updateUserProfileWithPoints(userId, challenge.programId, challenge.pointsReward, null, pointsTransaction);
    
    // Award additional rewards
    for (final _reward in challenge.additionalRewards) {
      // Would process additional rewards
    }
  }

  // Additional helper methods
  Future<LoyaltyProgram?> getActiveLoyaltyProgram(String programId) async {
    final doc = await _firestore.collection('loyaltyPrograms').doc(programId).get();
    if (doc.exists) {
      return LoyaltyProgram.fromJson(programId, doc.data()!);
    }
    return null;
  }

  Future<Reward?> getReward(String rewardId) async {
    final doc = await _firestore.collection('rewards').doc(rewardId).get();
    if (doc.exists) {
      return Reward.fromJson(rewardId, doc.data()!);
    }
    return null;
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    final doc = await _firestore.collection('challenges').doc(challengeId).get();
    if (doc.exists) {
      return Challenge.fromJson(challengeId, doc.data()!);
    }
    return null;
  }

  Future<UserChallengeProgress?> getUserChallengeProgress(String userId, String challengeId) async {
    final snapshot = await _firestore
        .collection('userChallengeProgress')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return UserChallengeProgress.fromJson(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<void> _updateUserProfileAfterRedemption(
    String userId,
    String programId,
    int pointsUsed,
    PointsTransaction transaction,
  ) async {
    final profileId = '$userId-$programId';
    await _firestore.collection('userLoyaltyProfiles').doc(profileId).update({
      'availablePoints': FieldValue.increment(-pointsUsed),
      'lastActivity': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _updateRewardClaimCount(String rewardId) async {
    await _firestore.collection('rewards').doc(rewardId).update({
      'claimedQuantity': FieldValue.increment(1),
    });
  }

  Future<String> _generateRewardCode(String rewardId, String userId) async {
    // Generate unique reward code
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = (rewardId + userId + timestamp.toString()).hashCode.abs();
    return 'RW${hash.toString().substring(0, 8).toUpperCase()}';
  }

  Future<List<PointsTransaction>> getUserRecentTransactions(String userId, int days) async {
    final since = DateTime.now().subtract(Duration(days: days));
    
    final snapshot = await _firestore
        .collection('pointsTransactions')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      return PointsTransaction.fromJson(doc.id, doc.data());
    }).toList();
  }

  double _calculateTierProgress(UserLoyaltyProfile profile, LoyaltyProgram program) {
    final currentTier = program.tierConfigs[profile.currentTier];
    if (currentTier == null) return 0.0;
    
    final nextTier = program.getNextTier(profile.totalPoints);
    if (nextTier == null) return 100.0; // Already at highest tier
    
    final nextTierConfig = program.tierConfigs[nextTier];
    if (nextTierConfig == null) return 0.0;
    
    final progress = (profile.totalPoints - currentTier.minPoints) / 
                    (nextTierConfig.minPoints - currentTier.minPoints);
    
    return (progress * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> _calculateMonthlyActivity(List<PointsTransaction> transactions) {
    final monthly = <String, int>{};
    
    for (final transaction in transactions) {
      final monthKey = '${transaction.timestamp.year}-${transaction.timestamp.month.toString().padLeft(2, '0')}';
      monthly[monthKey] = (monthly[monthKey] ?? 0) + transaction.pointsValue;
    }
    
    return monthly;
  }

  Future<List<String>> _getPersonalizedRecommendations(
    UserLoyaltyProfile profile,
    LoyaltyProgram program,
  ) async {
    final recommendations = <String>[];
    
    // Tier-based recommendations
    final pointsToNext = profile.getPointsToNextTier(program);
    if (pointsToNext != null) {
      recommendations.add('Earn $pointsToNext more points to reach ${program.getNextTier(profile.totalPoints)?.name} tier!');
    }
    
    // Challenge recommendations
    if (profile.streakCounts['orders'] == 0) {
      recommendations.add('Join daily ordering challenges to earn bonus points!');
    }
    
    // Referral recommendations
    if (profile.referralCount < 3) {
      recommendations.add('Invite friends to earn referral bonuses!');
    }
    
    return recommendations;
  }

  double _calculateReferralEarnings(Referral referral) {
    // Calculate total points earned from this referral
    final rewardEarned = referral.rewardEarned;
    return (rewardEarned['referrerBonus'] ?? 0) + (rewardEarned['referredBonus'] ?? 0);
  }
}