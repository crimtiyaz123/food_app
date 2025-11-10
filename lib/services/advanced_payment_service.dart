import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/advanced_payment.dart';

class AdvancedPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize payment process
  Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod method,
    required String gatewayId,
    required Currency currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get payment gateway
      final gateway = await _getPaymentGateway(gatewayId);
      if (gateway == null) {
        throw Exception('Payment gateway not found');
      }

      // Check if gateway supports the method
      if (!gateway.supportsMethod(method)) {
        throw Exception('Payment gateway does not support this payment method');
      }

      // Create payment transaction
      final transaction = PaymentTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderId: orderId,
        userId: userId,
        method: method,
        gatewayId: gatewayId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        gatewayResponse: {},
        metadata: metadata ?? {},
      );

      // Save transaction to database
      await _savePaymentTransaction(transaction);

      // Process payment based on method
      switch (method) {
        case PaymentMethod.creditCard:
        case PaymentMethod.debitCard:
          return await _processCardPayment(transaction, gateway);
        case PaymentMethod.digitalWallet:
          return await _processDigitalWalletPayment(transaction, gateway);
        case PaymentMethod.upi:
          return await _processUPIPayment(transaction, gateway);
        case PaymentMethod.netBanking:
          return await _processNetBankingPayment(transaction, gateway);
        case PaymentMethod.cash:
          return await _processCashOnDelivery(transaction);
        case PaymentMethod.buyNowPayLater:
          return await _processBNPLPayment(transaction, gateway);
        case PaymentMethod.crypto:
          return await _processCryptoPayment(transaction, gateway);
        case PaymentMethod.qrCode:
          return await _processQRCodePayment(transaction, gateway);
      }
    } catch (e) {
      debugPrint('Error initiating payment: $e');
      rethrow;
    }
  }

  // Confirm payment
  Future<bool> confirmPayment({
    required String transactionId,
    required String confirmationCode,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final transaction = await _getPaymentTransaction(transactionId);
      if (transaction == null) return false;

      // Update transaction status based on method
      switch (transaction.method) {
        case PaymentMethod.creditCard:
        case PaymentMethod.debitCard:
          return await _confirmCardPayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.digitalWallet:
          return await _confirmDigitalWalletPayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.upi:
          return await _confirmUPIPayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.netBanking:
          return await _confirmNetBankingPayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.buyNowPayLater:
          return await _confirmBNPLPayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.crypto:
          return await _confirmCryptoPayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.qrCode:
          return await _confirmQRCodePayment(transaction, confirmationCode, additionalData);
        case PaymentMethod.cash:
          return await _confirmCashPayment(transaction);
      }
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      return false;
    }
  }

  // Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String transactionId) async {
    try {
      final transaction = await _getPaymentTransaction(transactionId);
      if (transaction == null) {
        return {'status': 'not_found', 'message': 'Transaction not found'};
      }

      return {
        'status': transaction.status.name,
        'amount': transaction.amount,
        'currency': transaction.currency.name,
        'method': transaction.method.name,
        'createdAt': transaction.createdAt.millisecondsSinceEpoch,
        'completedAt': transaction.completedAt?.millisecondsSinceEpoch,
        'isSuccessful': transaction.isSuccessful,
        'isPending': transaction.isPending,
        'isFailed': transaction.isFailed,
        'processingTime': transaction.processingTime?.inSeconds,
      };
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Process refund
  Future<bool> processRefund({
    required String transactionId,
    required double refundAmount,
    required String reason,
  }) async {
    try {
      final transaction = await _getPaymentTransaction(transactionId);
      if (transaction == null) return false;

      if (!transaction.isSuccessful) return false;

      // Create refund record
      final refundId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Update transaction
      await _updatePaymentTransaction(transactionId, {
        'refundId': refundId,
        'refundAmount': refundAmount,
        'refundDate': DateTime.now().millisecondsSinceEpoch,
        'status': refundAmount >= transaction.amount 
            ? PaymentStatus.refunded.name 
            : PaymentStatus.partiallyRefunded.name,
      });

      // Process refund with gateway
      return await _processRefundWithGateway(transaction, refundAmount, reason);
    } catch (e) {
      debugPrint('Error processing refund: $e');
      return false;
    }
  }

  // Get saved payment methods for user
  Future<List<SavedPaymentMethod>> getSavedPaymentMethods(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('savedPaymentMethods')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('isDefault', descending: true)
          .orderBy('lastUsed', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return SavedPaymentMethod.fromJson(doc.id, data);
        }
        throw Exception('Invalid document data for SavedPaymentMethod');
      }).toList();
    } catch (e) {
      debugPrint('Error getting saved payment methods: $e');
      return [];
    }
  }

  // Save payment method
  Future<String> savePaymentMethod({
    required String userId,
    required PaymentMethod method,
    required String gatewayId,
    required Map<String, dynamic> paymentData,
    bool isDefault = false,
  }) async {
    try {
      final methodId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final savedMethod = SavedPaymentMethod(
        id: methodId,
        userId: userId,
        method: method,
        gatewayId: gatewayId,
        maskedCardNumber: paymentData['maskedCardNumber'],
        cardBrand: paymentData['cardBrand'],
        expiryMonth: paymentData['expiryMonth'],
        expiryYear: paymentData['expiryYear'],
        cardholderName: paymentData['cardholderName'],
        walletId: paymentData['walletId'],
        walletType: paymentData['walletType'],
        bankCode: paymentData['bankCode'],
        bankName: paymentData['bankName'],
        ifscCode: paymentData['ifscCode'],
        isDefault: isDefault,
        isActive: true,
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
        metadata: paymentData['metadata'] ?? {},
      );

      await _firestore.collection('savedPaymentMethods').doc(methodId).set(savedMethod.toJson());

      // If this is default, make other methods non-default
      if (isDefault) {
        await _setDefaultPaymentMethod(userId, methodId);
      }

      return methodId;
    } catch (e) {
      debugPrint('Error saving payment method: $e');
      rethrow;
    }
  }

  // Get available BNPL providers
  Future<List<BNPLConfiguration>> getAvailableBNPLProviders({
    required double amount,
    String? country,
    Currency? currency,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bnplConfigurations')
          .where('isActive', isEqualTo: true)
          .get();

      var providers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return BNPLConfiguration.fromJson(doc.id, data);
        }
        throw Exception('Invalid document data for BNPLConfiguration');
      }).toList();

      // Filter by amount, country, and currency
      providers = providers.where((provider) {
        if (!provider.isEligible(amount)) return false;
        if (country != null && !provider.supportedCountries.contains(country)) return false;
        if (currency != null && !provider.supportedCurrencies.contains(currency)) return false;
        return true;
      }).toList();

      return providers;
    } catch (e) {
      debugPrint('Error getting BNPL providers: $e');
      return [];
    }
  }

  // Initiate BNPL payment
  Future<Map<String, dynamic>> initiateBNPLPayment({
    required String orderId,
    required String userId,
    required String providerId,
    required double amount,
    required int installments,
  }) async {
    try {
      final provider = await _getBNPLConfiguration(providerId);
      if (provider == null) {
        throw Exception('BNPL provider not found');
      }

      final installmentAmount = provider.calculateInstallmentAmount(amount, installments);
      final processingFee = amount * provider.processingFee / 100;

      final paymentIntent = PaymentIntent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderId: orderId,
        userId: userId,
        bnplProvider: provider.provider,
        totalAmount: amount,
        installments: installments,
        installmentAmount: installmentAmount,
        processingFee: processingFee,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)), // 1 hour expiry
        providerResponse: {},
        metadata: {},
      );

      await _firestore.collection('paymentIntents').doc(paymentIntent.id).set(paymentIntent.toJson());

      // Process with BNPL provider
      return await _processWithBNPLProvider(paymentIntent, provider);
    } catch (e) {
      debugPrint('Error initiating BNPL payment: $e');
      rethrow;
    }
  }

  // Get payment analytics
  Future<PaymentAnalytics> getPaymentAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    String? gatewayId,
  }) async {
    try {
      Query query = _firestore
          .collection('paymentTransactions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (gatewayId != null) {
        query = query.where('gatewayId', isEqualTo: gatewayId);
      }

      final snapshot = await query.get();
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return PaymentTransaction.fromJson(doc.id, data);
        }
        throw Exception('Invalid document data for PaymentTransaction');
      }).toList();

      return _generatePaymentAnalytics(transactions, startDate, endDate);
    } catch (e) {
      debugPrint('Error getting payment analytics: $e');
      rethrow;
    }
  }

  // Private helper methods for different payment methods
  Future<Map<String, dynamic>> _processCardPayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Simulate card payment processing
    await Future.delayed(Duration(seconds: 2));
    
    final response = {
      'status': 'success',
      'transactionId': transaction.id,
      'authCode': 'AUTH${DateTime.now().millisecondsSinceEpoch}',
      'gatewayResponse': {
        'code': '00',
        'message': 'Approved',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };

    // Update transaction
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': response['authCode'],
      'gatewayResponse': response['gatewayResponse'],
    });

    return response;
  }

  Future<Map<String, dynamic>> _processDigitalWalletPayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Simulate digital wallet payment
    await Future.delayed(Duration(seconds: 3));
    
    final response = {
      'status': 'success',
      'transactionId': transaction.id,
      'paymentUrl': 'https://wallet.payment.com/pay/${transaction.id}',
      'qrCode': 'QR_${transaction.id}',
    };

    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.processing.name,
      'gatewayResponse': response,
    });

    return response;
  }

  Future<Map<String, dynamic>> _processUPIPayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Simulate UPI payment
    await Future.delayed(Duration(seconds: 1));
    
    final upiId = 'foodapp@upi';
    final response = {
      'status': 'pending',
      'transactionId': transaction.id,
      'upiId': upiId,
      'amount': transaction.amount,
      'reference': 'ORD${transaction.orderId}',
    };

    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.pending.name,
      'gatewayResponse': response,
    });

    return response;
  }

  Future<Map<String, dynamic>> _processNetBankingPayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Simulate net banking payment
    await Future.delayed(Duration(seconds: 2));
    
    final response = {
      'status': 'redirect',
      'transactionId': transaction.id,
      'redirectUrl': 'https://bank.payment.com/redirect/${transaction.id}',
      'bankList': ['HDFC', 'SBI', 'ICICI', 'AXIS', 'KOTAK'],
    };

    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.pending.name,
      'gatewayResponse': response,
    });

    return response;
  }

  Future<Map<String, dynamic>> _processCashOnDelivery(PaymentTransaction transaction) async {
    // Cash on delivery - no immediate processing needed
    final response = {
      'status': 'confirmed',
      'transactionId': transaction.id,
      'message': 'Cash on delivery confirmed',
    };

    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'gatewayResponse': response,
    });

    return response;
  }

  Future<Map<String, dynamic>> _processBNPLPayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Get available BNPL providers
    final providers = await getAvailableBNPLProviders(amount: transaction.amount);
    if (providers.isEmpty) {
      throw Exception('No BNPL providers available for this amount');
    }

    final provider = providers.first;
    return await initiateBNPLPayment(
      orderId: transaction.orderId,
      userId: transaction.userId,
      providerId: provider.id,
      amount: transaction.amount,
      installments: provider.installments,
    );
  }

  Future<Map<String, dynamic>> _processCryptoPayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Simulate crypto payment
    await Future.delayed(Duration(seconds: 5));
    
    final response = {
      'status': 'pending',
      'transactionId': transaction.id,
      'walletAddress': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
      'currency': 'BTC',
      'amount': transaction.amount / 50000, // Mock BTC price
      'confirmationsRequired': 6,
    };

    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.processing.name,
      'gatewayResponse': response,
    });

    return response;
  }

  Future<Map<String, dynamic>> _processQRCodePayment(
    PaymentTransaction transaction,
    PaymentGateway gateway,
  ) async {
    // Generate QR code for payment
    final qrData = {
      'transactionId': transaction.id,
      'amount': transaction.amount,
      'merchantId': gateway.credentials['merchantId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = {
      'status': 'success',
      'transactionId': transaction.id,
      'qrCode': 'QR_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}',
      'qrData': qrData,
    };

    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.pending.name,
      'gatewayResponse': response,
    });

    return response;
  }

  // Confirmation methods for each payment type
  Future<bool> _confirmCardPayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // Simulate card confirmation
    await Future.delayed(Duration(seconds: 2));
    
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmDigitalWalletPayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // Simulate wallet confirmation
    await Future.delayed(Duration(seconds: 1));
    
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmUPIPayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // UPI payment confirmed via bank
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmNetBankingPayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // Net banking confirmation
    await Future.delayed(Duration(seconds: 3));
    
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmBNPLPayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // BNPL payment confirmed
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmCryptoPayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // Crypto payment confirmed after blockchain confirmation
    await Future.delayed(Duration(seconds: 10));
    
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmQRCodePayment(
    PaymentTransaction transaction,
    String confirmationCode,
    Map<String, dynamic>? additionalData,
  ) async {
    // QR code payment confirmed
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'transactionReference': confirmationCode,
    });

    return true;
  }

  Future<bool> _confirmCashPayment(PaymentTransaction transaction) async {
    // Cash payment confirmed upon delivery
    await _updatePaymentTransaction(transaction.id, {
      'status': PaymentStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'notes': 'Cash payment confirmed at delivery',
    });

    return true;
  }

  // Additional helper methods
  Future<PaymentGateway?> _getPaymentGateway(String gatewayId) async {
    final doc = await _firestore.collection('paymentGateways').doc(gatewayId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        return PaymentGateway.fromJson(gatewayId, data);
      }
    }
    return null;
  }

  Future<PaymentTransaction?> _getPaymentTransaction(String transactionId) async {
    final doc = await _firestore.collection('paymentTransactions').doc(transactionId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        return PaymentTransaction.fromJson(transactionId, data);
      }
    }
    return null;
  }

  Future<void> _savePaymentTransaction(PaymentTransaction transaction) async {
    await _firestore.collection('paymentTransactions').doc(transaction.id).set(transaction.toJson());
  }

  Future<void> _updatePaymentTransaction(String transactionId, Map<String, dynamic> updates) async {
    await _firestore.collection('paymentTransactions').doc(transactionId).update(updates);
  }

  Future<void> _setDefaultPaymentMethod(String userId, String methodId) async {
    await _firestore.collection('savedPaymentMethods')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isDefault': false});
      }
    });

    await _firestore.collection('savedPaymentMethods').doc(methodId).update({'isDefault': true});
  }

  Future<BNPLConfiguration?> _getBNPLConfiguration(String providerId) async {
    final doc = await _firestore.collection('bnplConfigurations').doc(providerId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        return BNPLConfiguration.fromJson(providerId, data);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _processWithBNPLProvider(
    PaymentIntent paymentIntent,
    BNPLConfiguration provider,
  ) async {
    // Simulate BNPL provider processing
    await Future.delayed(Duration(seconds: 3));
    
    return {
      'status': 'pending_authorization',
      'paymentIntentId': paymentIntent.id,
      'provider': provider.provider,
      'redirectUrl': 'https://${provider.provider}.com/authorize/${paymentIntent.id}',
      'installments': paymentIntent.installments,
      'installmentAmount': paymentIntent.installmentAmount,
      'processingFee': paymentIntent.processingFee,
    };
  }

  Future<bool> _processRefundWithGateway(
    PaymentTransaction transaction,
    double refundAmount,
    String reason,
  ) async {
    // Simulate refund processing with gateway
    await Future.delayed(Duration(seconds: 5));
    
    debugPrint('Refund processed: $refundAmount for transaction ${transaction.id}');
    return true;
  }

  PaymentAnalytics _generatePaymentAnalytics(
    List<PaymentTransaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final paymentMethodStats = <String, int>{};
    final gatewayStats = <String, int>{};
    final transactionVolume = <String, double>{};
    final transactionValue = <String, double>{};
    final failedTransactionReasons = <String, int>{};
    
    double totalAmount = 0.0;
    double totalProcessingFees = 0.0;
    double totalRefunded = 0.0;
    int successfulCount = 0;
    int failedCount = 0;
    
    for (final transaction in transactions) {
      final method = transaction.method.name;
      final gateway = transaction.gatewayId;
      
      paymentMethodStats[method] = (paymentMethodStats[method] ?? 0) + 1;
      gatewayStats[gateway] = (gatewayStats[gateway] ?? 0) + 1;
      transactionVolume[method] = (transactionVolume[method] ?? 0) + 1;
      transactionValue[method] = (transactionValue[method] ?? 0) + transaction.amount;
      
      totalAmount += transaction.amount;
      
      if (transaction.isSuccessful) {
        successfulCount++;
      } else if (transaction.isFailed) {
        failedCount++;
        final reason = transaction.failureReason ?? 'Unknown';
        failedTransactionReasons[reason] = (failedTransactionReasons[reason] ?? 0) + 1;
      }
      
      if (transaction.isRefunded) {
        totalRefunded += transaction.refundAmount ?? 0.0;
      }
    }
    
    final totalTransactions = transactions.length;
    final averageAmount = totalTransactions > 0 ? totalAmount / totalTransactions : 0.0;
    final successRate = totalTransactions > 0 ? (successfulCount / totalTransactions) * 100 : 0.0;
    final refundRate = totalTransactions > 0 ? (totalRefunded / totalAmount) * 100 : 0.0;
    
    return PaymentAnalytics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      periodStart: startDate.toIso8601String(),
      periodEnd: endDate.toIso8601String(),
      paymentMethodStats: paymentMethodStats,
      gatewayStats: gatewayStats,
      transactionVolume: transactionVolume,
      transactionValue: transactionValue,
      averageTransactionAmount: averageAmount,
      totalProcessingFees: totalProcessingFees,
      totalRefunded: totalRefunded,
      successfulTransactions: successfulCount,
      failedTransactions: failedCount,
      successRate: successRate,
      refundRate: refundRate,
      failedTransactionReasons: failedTransactionReasons,
      generatedAt: DateTime.now(),
      metadata: {
        'totalTransactions': totalTransactions,
        'generatedBy': 'AdvancedPaymentService',
        'version': '1.0',
      },
    );
  }
}