class Payment {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentMethod method;
  PaymentStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  String? transactionId;
  String? failureReason;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.failureReason,
    this.metadata,
  });

  factory Payment.fromJson(String id, Map<String, dynamic> json) {
    return Payment(
      id: id,
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.card,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      transactionId: json['transactionId'],
      failureReason: json['failureReason'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'method': method.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'transactionId': transactionId,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }
}

enum PaymentMethod {
  card('Credit/Debit Card'),
  upi('UPI'),
  wallet('Digital Wallet'),
  netBanking('Net Banking'),
  cod('Cash on Delivery');

  const PaymentMethod(this.displayName);
  final String displayName;
}

enum PaymentStatus {
  pending('Pending'),
  processing('Processing'),
  completed('Completed'),
  failed('Failed'),
  refunded('Refunded'),
  cancelled('Cancelled');

  const PaymentStatus(this.displayName);
  final String displayName;
}

class Refund {
  final String id;
  final String paymentId;
  final String orderId;
  final double amount;
  final RefundReason reason;
  RefundStatus status;
  final DateTime requestedAt;
  DateTime? processedAt;
  final String? processedBy;
  final String? notes;

  Refund({
    required this.id,
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
    this.notes,
  });

  factory Refund.fromJson(String id, Map<String, dynamic> json) {
    return Refund(
      id: id,
      paymentId: json['paymentId'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      reason: RefundReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => RefundReason.customerRequest,
      ),
      status: RefundStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RefundStatus.pending,
      ),
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
      processedBy: json['processedBy'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'reason': reason.name,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'processedBy': processedBy,
      'notes': notes,
    };
  }
}

enum RefundReason {
  customerRequest('Customer Request'),
  orderCancelled('Order Cancelled'),
  itemUnavailable('Item Unavailable'),
  wrongOrder('Wrong Order'),
  qualityIssue('Quality Issue'),
  deliveryIssue('Delivery Issue'),
  technicalError('Technical Error');

  const RefundReason(this.displayName);
  final String displayName;
}

enum RefundStatus {
  pending('Pending'),
  approved('Approved'),
  processing('Processing'),
  completed('Completed'),
  rejected('Rejected');

  const RefundStatus(this.displayName);
  final String displayName;
}

class PaymentCard {
  final String id;
  final String userId;
  final String cardNumber; // Last 4 digits only for security
  final String cardHolderName;
  final String expiryMonth;
  final String expiryYear;
  final String cardType; // visa, mastercard, etc.
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardType,
    this.isDefault = false,
  });

  factory PaymentCard.fromJson(String id, Map<String, dynamic> json) {
    return PaymentCard(
      id: id,
      userId: json['userId'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
      cardHolderName: json['cardHolderName'] ?? '',
      expiryMonth: json['expiryMonth'] ?? '',
      expiryYear: json['expiryYear'] ?? '',
      cardType: json['cardType'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardType': cardType,
      'isDefault': isDefault,
    };
  }
}

class UPIDetails {
  final String id;
  final String userId;
  final String upiId;
  final String name;
  final bool isDefault;

  UPIDetails({
    required this.id,
    required this.userId,
    required this.upiId,
    required this.name,
    this.isDefault = false,
  });

  factory UPIDetails.fromJson(String id, Map<String, dynamic> json) {
    return UPIDetails(
      id: id,
      userId: json['userId'] ?? '',
      upiId: json['upiId'] ?? '',
      name: json['name'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'upiId': upiId,
      'name': name,
      'isDefault': isDefault,
    };
  }
}