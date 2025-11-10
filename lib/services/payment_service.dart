import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/payment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _backendUrl = 'http://localhost:3000'; // Update with your backend URL

  // Process payment
  Future<Payment> processPayment(
    String orderId,
    String userId,
    double amount,
    PaymentMethod method, {
    Map<String, dynamic>? paymentData,
  }) async {
    final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';

    final payment = Payment(
      id: paymentId,
      orderId: orderId,
      userId: userId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      metadata: paymentData,
    );

    // Save payment to Firestore
    await _firestore.collection('payments').doc(paymentId).set(payment.toJson());

    try {
      // Process payment based on method
      switch (method) {
        case PaymentMethod.card:
          await _processCardPayment(payment, paymentData);
          break;
        case PaymentMethod.upi:
          await _processUPIPayment(payment, paymentData);
          break;
        case PaymentMethod.wallet:
          await _processWalletPayment(payment, paymentData);
          break;
        case PaymentMethod.netBanking:
          await _processNetBankingPayment(payment, paymentData);
          break;
        case PaymentMethod.cod:
          await _processCODPayment(payment);
          break;
      }

      return payment;
    } catch (e) {
      // Update payment status to failed
      await _updatePaymentStatus(paymentId, PaymentStatus.failed, failureReason: e.toString());
      payment.status = PaymentStatus.failed;
      payment.failureReason = e.toString();
      return payment;
    }
  }

  // Process card payment
  Future<void> _processCardPayment(Payment payment, Map<String, dynamic>? paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/process-card-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentId': payment.id,
          'amount': payment.amount,
          'cardToken': paymentData?['cardToken'], // Encrypted card token
          'currency': 'USD',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updatePaymentStatus(
          payment.id,
          PaymentStatus.completed,
          transactionId: data['transactionId'],
        );
      } else {
        throw Exception('Card payment failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Card payment processing error: $e');
    }
  }

  // Process UPI payment
  Future<void> _processUPIPayment(Payment payment, Map<String, dynamic>? paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/process-upi-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentId': payment.id,
          'amount': payment.amount,
          'upiId': paymentData?['upiId'],
          'currency': 'INR',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updatePaymentStatus(
          payment.id,
          PaymentStatus.completed,
          transactionId: data['transactionId'],
        );
      } else {
        throw Exception('UPI payment failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('UPI payment processing error: $e');
    }
  }

  // Process wallet payment
  Future<void> _processWalletPayment(Payment payment, Map<String, dynamic>? paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/process-wallet-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentId': payment.id,
          'amount': payment.amount,
          'walletId': paymentData?['walletId'],
          'currency': 'USD',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updatePaymentStatus(
          payment.id,
          PaymentStatus.completed,
          transactionId: data['transactionId'],
        );
      } else {
        throw Exception('Wallet payment failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Wallet payment processing error: $e');
    }
  }

  // Process net banking payment
  Future<void> _processNetBankingPayment(Payment payment, Map<String, dynamic>? paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/process-netbanking-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentId': payment.id,
          'amount': payment.amount,
          'bankCode': paymentData?['bankCode'],
          'currency': 'INR',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updatePaymentStatus(
          payment.id,
          PaymentStatus.completed,
          transactionId: data['transactionId'],
        );
      } else {
        throw Exception('Net banking payment failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Net banking payment processing error: $e');
    }
  }

  // Process COD payment
  Future<void> _processCODPayment(Payment payment) async {
    // COD is completed immediately since payment is collected on delivery
    await _updatePaymentStatus(payment.id, PaymentStatus.completed, transactionId: 'COD_${payment.id}');
  }

  // Update payment status
  Future<void> _updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
    String? failureReason,
  }) async {
    final updateData = {
      'status': status.name,
      'lastUpdated': Timestamp.now(),
    };

    if (transactionId != null) {
      updateData['transactionId'] = transactionId;
    }

    if (failureReason != null) {
      updateData['failureReason'] = failureReason;
    }

    if (status == PaymentStatus.completed) {
      updateData['completedAt'] = Timestamp.now();
    }

    await _firestore.collection('payments').doc(paymentId).update(updateData);
  }

  // Get payment by ID
  Future<Payment?> getPayment(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (doc.exists) {
      return Payment.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  // Get payments for user
  Future<List<Payment>> getUserPayments(String userId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Payment.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Process refund
  Future<Refund> processRefund(
    String paymentId,
    String orderId,
    double amount,
    RefundReason reason, {
    String? notes,
  }) async {
    final refundId = 'refund_${DateTime.now().millisecondsSinceEpoch}';

    final refund = Refund(
      id: refundId,
      paymentId: paymentId,
      orderId: orderId,
      amount: amount,
      reason: reason,
      status: RefundStatus.pending,
      requestedAt: DateTime.now(),
      notes: notes,
    );

    await _firestore.collection('refunds').doc(refundId).set(refund.toJson());

    try {
      // Process refund through payment gateway
      final response = await http.post(
        Uri.parse('$_backendUrl/process-refund'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refundId': refundId,
          'paymentId': paymentId,
          'amount': amount,
          'reason': reason.name,
        }),
      );

      if (response.statusCode == 200) {
        await _updateRefundStatus(refundId, RefundStatus.completed);
        refund.status = RefundStatus.completed;
        refund.processedAt = DateTime.now();
      } else {
        await _updateRefundStatus(refundId, RefundStatus.rejected);
        refund.status = RefundStatus.rejected;
      }
    } catch (e) {
      await _updateRefundStatus(refundId, RefundStatus.rejected);
      refund.status = RefundStatus.rejected;
    }

    return refund;
  }

  // Update refund status
  Future<void> _updateRefundStatus(String refundId, RefundStatus status) async {
    await _firestore.collection('refunds').doc(refundId).update({
      'status': status.name,
      'processedAt': status == RefundStatus.completed ? Timestamp.now() : null,
      'lastUpdated': Timestamp.now(),
    });
  }

  // Get refund by ID
  Future<Refund?> getRefund(String refundId) async {
    final doc = await _firestore.collection('refunds').doc(refundId).get();
    if (doc.exists) {
      return Refund.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  // Get refunds for user
  Future<List<Refund>> getUserRefunds(String userId) async {
    final snapshot = await _firestore
        .collection('refunds')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Refund.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Save payment method
  Future<void> savePaymentMethod(String userId, PaymentMethod method, Map<String, dynamic> methodData) async {
    final methodId = 'method_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      'userId': userId,
      'method': method.name,
      'isDefault': false,
      'createdAt': Timestamp.now(),
      ...methodData,
    };

    await _firestore.collection('paymentMethods').doc(methodId).set(data);
  }

  // Get user's saved payment methods
  Future<List<Map<String, dynamic>>> getUserPaymentMethods(String userId) async {
    final snapshot = await _firestore
        .collection('paymentMethods')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}