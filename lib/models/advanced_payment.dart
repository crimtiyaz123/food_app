// Advanced Payment Models for Modern Delivery Apps

import 'package:cloud_firestore/cloud_firestore.dart';

// Payment Methods Enum
enum PaymentMethod {
  creditCard,    // Credit cards
  debitCard,     // Debit cards
  netBanking,    // Online banking
  digitalWallet, // PhonePe, Google Pay, etc.
  upi,          // UPI payments
  cash,         // Cash on delivery
  buyNowPayLater, // Klarna, Afterpay, etc.
  crypto,       // Cryptocurrency
  qrCode,       // QR code payments
}

// Payment Status
enum PaymentStatus {
  pending,      // Payment initiated
  processing,   // Payment being processed
  completed,    // Payment successful
  failed,       // Payment failed
  cancelled,    // Payment cancelled
  refunded,     // Payment refunded
  partiallyRefunded, // Partial refund
  dispute,      // Payment disputed
  onHold,       // Payment on hold
}

// Currency Types
enum Currency {
  USD,
  EUR,
  GBP,
  INR,
  JPY,
  AUD,
  CAD,
  CNY,
}

// Digital Wallet Types
enum DigitalWalletType {
  googlePay,
  applePay,
  samsungPay,
  phonePe,
  paytm,
  amazonPay,
  airtelMoney,
  jioMoney,
  payzapp,
  mobikwik,
}

// Buy Now Pay Later Providers
enum BNPLProvider {
  klarna,
  afterpay,
  affirm,
  sezzle,
  zip,
  laybuy,
  clearPay,
  payIn3,
  tabby,
  Tamara,
}

// Payment Gateway
class PaymentGateway {
  final String id;
  final String name;
  final String displayName;
  final List<PaymentMethod> supportedMethods;
  final String logoUrl;
  final bool isActive;
  final double transactionFee; // Percentage
  final double fixedFee; // Fixed amount per transaction
  final Map<String, dynamic> supportedCurrencies;
  final Map<String, dynamic> supportedCountries;
  final String apiEndpoint;
  final Map<String, String> credentials;
  final Map<String, dynamic> configuration;
  final DateTime lastUpdated;
  final String version;
  final Map<String, dynamic> metadata;

  PaymentGateway({
    required this.id,
    required this.name,
    required this.displayName,
    required this.supportedMethods,
    required this.logoUrl,
    required this.isActive,
    required this.transactionFee,
    required this.fixedFee,
    required this.supportedCurrencies,
    required this.supportedCountries,
    required this.apiEndpoint,
    required this.credentials,
    required this.configuration,
    required this.lastUpdated,
    required this.version,
    required this.metadata,
  });

  factory PaymentGateway.fromJson(String id, Map<String, dynamic> json) {
    return PaymentGateway(
      id: id,
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      supportedMethods: (json['supportedMethods'] as List<dynamic>?)
          ?.map((e) => PaymentMethod.values.firstWhere(
            (method) => method.name == e,
            orElse: () => PaymentMethod.creditCard,
          ))
          .toList() ?? [],
      logoUrl: json['logoUrl'] ?? '',
      isActive: json['isActive'] ?? false,
      transactionFee: (json['transactionFee'] ?? 0.0).toDouble(),
      fixedFee: (json['fixedFee'] ?? 0.0).toDouble(),
      supportedCurrencies: Map<String, dynamic>.from(json['supportedCurrencies'] ?? {}),
      supportedCountries: Map<String, dynamic>.from(json['supportedCountries'] ?? {}),
      apiEndpoint: json['apiEndpoint'] ?? '',
      credentials: Map<String, String>.from(json['credentials'] ?? {}),
      configuration: Map<String, dynamic>.from(json['configuration'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      version: json['version'] ?? '1.0',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'supportedMethods': supportedMethods.map((e) => e.name).toList(),
      'logoUrl': logoUrl,
      'isActive': isActive,
      'transactionFee': transactionFee,
      'fixedFee': fixedFee,
      'supportedCurrencies': supportedCurrencies,
      'supportedCountries': supportedCountries,
      'apiEndpoint': apiEndpoint,
      'credentials': credentials,
      'configuration': configuration,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'version': version,
      'metadata': metadata,
    };
  }

  // Calculate total fee for a transaction
  double calculateTransactionFee(double amount) {
    return (amount * transactionFee / 100) + fixedFee;
  }

  // Check if method is supported
  bool supportsMethod(PaymentMethod method) {
    return supportedMethods.contains(method);
  }

  // Check if currency is supported
  bool supportsCurrency(Currency currency) {
    return supportedCurrencies.containsKey(currency.name);
  }

  // Check if country is supported
  bool supportsCountry(String countryCode) {
    return supportedCountries.containsKey(countryCode);
  }
}

// Payment Transaction
class PaymentTransaction {
  final String id;
  final String orderId;
  final String userId;
  final PaymentMethod method;
  final String gatewayId;
  final double amount;
  final Currency currency;
  final PaymentStatus status;
  final String? transactionReference; // Gateway transaction ID
  final String? externalTransactionId; // Bank/Provider transaction ID
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final Map<String, dynamic> gatewayResponse;
  final Map<String, dynamic> metadata;
  final String? refundId;
  final double? refundAmount;
  final DateTime? refundDate;
  final String? disputeId;
  final String? notes;
  final String? ipAddress;
  final String? userAgent;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.method,
    required this.gatewayId,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionReference,
    this.externalTransactionId,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    required this.gatewayResponse,
    required this.metadata,
    this.refundId,
    this.refundAmount,
    this.refundDate,
    this.disputeId,
    this.notes,
    this.ipAddress,
    this.userAgent,
  });

  factory PaymentTransaction.fromJson(String id, Map<String, dynamic> json) {
    return PaymentTransaction(
      id: id,
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      gatewayId: json['gatewayId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: Currency.values.firstWhere(
        (e) => e.name == json['currency'],
        orElse: () => Currency.USD,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionReference: json['transactionReference'],
      externalTransactionId: json['externalTransactionId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      completedAt: json['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt']) 
          : null,
      failureReason: json['failureReason'],
      gatewayResponse: Map<String, dynamic>.from(json['gatewayResponse'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      refundId: json['refundId'],
      refundAmount: json['refundAmount']?.toDouble(),
      refundDate: json['refundDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['refundDate']) 
          : null,
      disputeId: json['disputeId'],
      notes: json['notes'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'method': method.name,
      'gatewayId': gatewayId,
      'amount': amount,
      'currency': currency.name,
      'status': status.name,
      'transactionReference': transactionReference,
      'externalTransactionId': externalTransactionId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'failureReason': failureReason,
      'gatewayResponse': gatewayResponse,
      'metadata': metadata,
      'refundId': refundId,
      'refundAmount': refundAmount,
      'refundDate': refundDate?.millisecondsSinceEpoch,
      'disputeId': disputeId,
      'notes': notes,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  // Check if payment is successful
  bool get isSuccessful => status == PaymentStatus.completed;
  
  // Check if payment is pending
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;
  
  // Check if payment failed
  bool get isFailed => status == PaymentStatus.failed;
  
  // Check if payment is refunded
  bool get isRefunded => status == PaymentStatus.refunded || status == PaymentStatus.partiallyRefunded;
  
  // Get processing time
  Duration? get processingTime {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }
}

// Saved Payment Method
class SavedPaymentMethod {
  final String id;
  final String userId;
  final PaymentMethod method;
  final String gatewayId;
  final String? maskedCardNumber; // For card payments
  final String? cardBrand; // Visa, Mastercard, etc.
  final String? expiryMonth;
  final String? expiryYear;
  final String? cardholderName;
  final String? walletId; // For digital wallets
  final String? walletType; // GooglePay, ApplePay, etc.
  final String? bankCode; // For net banking
  final String? bankName;
  final String? ifscCode;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUsed;
  final Map<String, dynamic> metadata;

  SavedPaymentMethod({
    required this.id,
    required this.userId,
    required this.method,
    required this.gatewayId,
    this.maskedCardNumber,
    this.cardBrand,
    this.expiryMonth,
    this.expiryYear,
    this.cardholderName,
    this.walletId,
    this.walletType,
    this.bankCode,
    this.bankName,
    this.ifscCode,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
    required this.lastUsed,
    required this.metadata,
  });

  factory SavedPaymentMethod.fromJson(String id, Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: id,
      userId: json['userId'] ?? '',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      gatewayId: json['gatewayId'] ?? '',
      maskedCardNumber: json['maskedCardNumber'],
      cardBrand: json['cardBrand'],
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      cardholderName: json['cardholderName'],
      walletId: json['walletId'],
      walletType: json['walletType'],
      bankCode: json['bankCode'],
      bankName: json['bankName'],
      ifscCode: json['ifscCode'],
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(json['lastUsed'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'method': method.name,
      'gatewayId': gatewayId,
      'maskedCardNumber': maskedCardNumber,
      'cardBrand': cardBrand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardholderName': cardholderName,
      'walletId': walletId,
      'walletType': walletType,
      'bankCode': bankCode,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUsed': lastUsed.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Check if method is a card
  bool get isCard => method == PaymentMethod.creditCard || method == PaymentMethod.debitCard;
  
  // Check if method is digital wallet
  bool get isWallet => method == PaymentMethod.digitalWallet;
  
  // Check if method is bank transfer
  bool get isBank => method == PaymentMethod.netBanking;
  
  // Get display name for UI
  String get displayName {
    if (isCard) {
      return '$cardBrand ****$maskedCardNumber';
    } else if (isWallet) {
      return walletType ?? 'Digital Wallet';
    } else if (isBank) {
      return bankName ?? 'Net Banking';
    } else {
      return method.name;
    }
  }
}

// Buy Now Pay Later (BNPL) Configuration
class BNPLConfiguration {
  final String id;
  final String provider; // klarna, afterpay, etc.
  final String displayName;
  final String logoUrl;
  final List<String> supportedCountries;
  final List<Currency> supportedCurrencies;
  final double minAmount;
  final double maxAmount;
  final int installments; // Number of installments
  final double processingFee; // Provider's processing fee
  final Map<String, dynamic> installmentPlans; // Available installment options
  final Map<String, String> credentials;
  final bool isActive;
  final Map<String, dynamic> configuration;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  BNPLConfiguration({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.logoUrl,
    required this.supportedCountries,
    required this.supportedCurrencies,
    required this.minAmount,
    required this.maxAmount,
    required this.installments,
    required this.processingFee,
    required this.installmentPlans,
    required this.credentials,
    required this.isActive,
    required this.configuration,
    required this.lastUpdated,
    required this.metadata,
  });

  factory BNPLConfiguration.fromJson(String id, Map<String, dynamic> json) {
    return BNPLConfiguration(
      id: id,
      provider: json['provider'] ?? '',
      displayName: json['displayName'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      supportedCountries: List<String>.from(json['supportedCountries'] ?? []),
      supportedCurrencies: (json['supportedCurrencies'] as List<dynamic>?)
          ?.map((e) => Currency.values.firstWhere(
            (currency) => currency.name == e,
            orElse: () => Currency.USD,
          ))
          .toList() ?? [],
      minAmount: (json['minAmount'] ?? 0.0).toDouble(),
      maxAmount: (json['maxAmount'] ?? 0.0).toDouble(),
      installments: json['installments'] ?? 4,
      processingFee: (json['processingFee'] ?? 0.0).toDouble(),
      installmentPlans: Map<String, dynamic>.from(json['installmentPlans'] ?? {}),
      credentials: Map<String, String>.from(json['credentials'] ?? {}),
      isActive: json['isActive'] ?? false,
      configuration: Map<String, dynamic>.from(json['configuration'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'displayName': displayName,
      'logoUrl': logoUrl,
      'supportedCountries': supportedCountries,
      'supportedCurrencies': supportedCurrencies.map((e) => e.name).toList(),
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'installments': installments,
      'processingFee': processingFee,
      'installmentPlans': installmentPlans,
      'credentials': credentials,
      'isActive': isActive,
      'configuration': configuration,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Check if amount is eligible for BNPL
  bool isEligible(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }

  // Calculate installment amount
  double calculateInstallmentAmount(double totalAmount, int installmentIndex) {
    final plan = installmentPlans['$installmentIndex installments'];
    if (plan != null) {
      return (totalAmount * (plan['percentage'] ?? 100)) / 100;
    }
    return totalAmount / installments;
  }
}

// Payment Intent for BNPL
class PaymentIntent {
  final String id;
  final String orderId;
  final String userId;
  final String bnplProvider;
  final double totalAmount;
  final int installments;
  final double installmentAmount;
  final double processingFee;
  final String? authorizationToken; // Provider's authorization token
  final String? redirectUrl; // For redirect-based providers
  final String? status; // pending, authorized, captured, cancelled
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> providerResponse;
  final Map<String, dynamic> metadata;

  PaymentIntent({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.bnplProvider,
    required this.totalAmount,
    required this.installments,
    required this.installmentAmount,
    required this.processingFee,
    this.authorizationToken,
    this.redirectUrl,
    this.status,
    required this.createdAt,
    this.expiresAt,
    required this.providerResponse,
    required this.metadata,
  });

  factory PaymentIntent.fromJson(String id, Map<String, dynamic> json) {
    return PaymentIntent(
      id: id,
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      bnplProvider: json['bnplProvider'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      installments: json['installments'] ?? 4,
      installmentAmount: (json['installmentAmount'] ?? 0.0).toDouble(),
      processingFee: (json['processingFee'] ?? 0.0).toDouble(),
      authorizationToken: json['authorizationToken'],
      redirectUrl: json['redirectUrl'],
      status: json['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt']) 
          : null,
      providerResponse: Map<String, dynamic>.from(json['providerResponse'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'bnplProvider': bnplProvider,
      'totalAmount': totalAmount,
      'installments': installments,
      'installmentAmount': installmentAmount,
      'processingFee': processingFee,
      'authorizationToken': authorizationToken,
      'redirectUrl': redirectUrl,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'providerResponse': providerResponse,
      'metadata': metadata,
    };
  }

  // Check if intent is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if intent is active
  bool get isActive {
    return !isExpired && (status == 'pending' || status == 'authorized');
  }
}

// Payment Analytics
class PaymentAnalytics {
  final String id;
  final String periodStart;
  final String periodEnd;
  final Map<String, int> paymentMethodStats;
  final Map<String, int> gatewayStats;
  final Map<String, double> transactionVolume;
  final Map<String, double> transactionValue;
  final double averageTransactionAmount;
  final double totalProcessingFees;
  final double totalRefunded;
  final int successfulTransactions;
  final int failedTransactions;
  final double successRate;
  final double refundRate;
  final Map<String, int> failedTransactionReasons;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  PaymentAnalytics({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.paymentMethodStats,
    required this.gatewayStats,
    required this.transactionVolume,
    required this.transactionValue,
    required this.averageTransactionAmount,
    required this.totalProcessingFees,
    required this.totalRefunded,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.successRate,
    required this.refundRate,
    required this.failedTransactionReasons,
    required this.generatedAt,
    required this.metadata,
  });

  factory PaymentAnalytics.fromJson(String id, Map<String, dynamic> json) {
    return PaymentAnalytics(
      id: id,
      periodStart: json['periodStart'] ?? '',
      periodEnd: json['periodEnd'] ?? '',
      paymentMethodStats: Map<String, int>.from(json['paymentMethodStats'] ?? {}),
      gatewayStats: Map<String, int>.from(json['gatewayStats'] ?? {}),
      transactionVolume: Map<String, double>.from(json['transactionVolume'] ?? {}),
      transactionValue: Map<String, double>.from(json['transactionValue'] ?? {}),
      averageTransactionAmount: (json['averageTransactionAmount'] ?? 0.0).toDouble(),
      totalProcessingFees: (json['totalProcessingFees'] ?? 0.0).toDouble(),
      totalRefunded: (json['totalRefunded'] ?? 0.0).toDouble(),
      successfulTransactions: json['successfulTransactions'] ?? 0,
      failedTransactions: json['failedTransactions'] ?? 0,
      successRate: (json['successRate'] ?? 0.0).toDouble(),
      refundRate: (json['refundRate'] ?? 0.0).toDouble(),
      failedTransactionReasons: Map<String, int>.from(json['failedTransactionReasons'] ?? {}),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(json['generatedAt'] ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'paymentMethodStats': paymentMethodStats,
      'gatewayStats': gatewayStats,
      'transactionVolume': transactionVolume,
      'transactionValue': transactionValue,
      'averageTransactionAmount': averageTransactionAmount,
      'totalProcessingFees': totalProcessingFees,
      'totalRefunded': totalRefunded,
      'successfulTransactions': successfulTransactions,
      'failedTransactions': failedTransactions,
      'successRate': successRate,
      'refundRate': refundRate,
      'failedTransactionReasons': failedTransactionReasons,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Get most popular payment method
  String get mostPopularMethod {
    if (paymentMethodStats.isEmpty) return 'Unknown';
    return paymentMethodStats.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get most profitable gateway
  String get mostProfitableGateway {
    if (transactionValue.isEmpty) return 'Unknown';
    return transactionValue.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}