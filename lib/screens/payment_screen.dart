import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccessRazorpay);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentErrorRazorpay);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  Future<void> _handlePaymentSuccess() async {
    final cartModel = context.read<CartModel>();
    cartModel.placeOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment successful! Order placed.")),
    );
    Navigator.of(context).pop();
  }

  void _handlePaymentError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: $error")),
    );
  }

  void _handlePaymentSuccessRazorpay(PaymentSuccessResponse response) {
    final cartModel = context.read<CartModel>();
    cartModel.placeOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment successful! Order placed.")),
    );
    Navigator.of(context).pop();
  }

  void _handlePaymentErrorRazorpay(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  void _placeOrderWithPayment(String paymentMethod) {
    final cartModel = context.read<CartModel>();
    cartModel.placeOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order placed successfully with $paymentMethod!")),
    );
    Navigator.of(context).pop();
  }

  Future<void> _openCheckout() async {
    final cartModel = context.read<CartModel>();
    try {
      // Create PaymentIntent on your backend
      final response = await http.post(
        Uri.parse('http://localhost:3000/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': cartModel.totalWithGst,
          'currency': 'usd',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['clientSecret'];

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'WazWaanGo',
            style: ThemeMode.system,
            billingDetails: const BillingDetails(
              name: 'Test User',
              email: 'test@example.com',
              phone: '1234567890',
            ),
          ),
        );

        await Stripe.instance.presentPaymentSheet();
        await _handlePaymentSuccess();
      } else {
        _handlePaymentError('Failed to create payment intent');
      }
    } catch (e) {
      _handlePaymentError(e.toString());
    }
  }

  Future<void> _openRazorpayCheckout() async {
    final cartModel = context.read<CartModel>();
    try {
      // Call backend to create order
      final response = await http.post(
        Uri.parse('http://localhost:3000/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': cartModel.totalWithGst,
          'currency': 'INR',
        }),
      );

      if (response.statusCode == 200) {
        final orderData = jsonDecode(response.body);
        var options = {
          'key': 'rzp_test_Rdhn5hZVFSFF2q', // Razorpay key_id
          'amount': (cartModel.totalWithGst * 100).toInt(), // Amount in paise
          'name': 'WazWaanGo',
          'description': 'Order Payment',
          'order_id': orderData['id'], // Use order ID from backend
          'prefill': {
            'contact': '1234567890',
            'email': 'test@example.com'
          },
          'external': {
            'wallets': ['paytm']
          }
        };
        _razorpay.open(options);
      } else {
        _handlePaymentError('Failed to create order');
      }
    } catch (e) {
      _handlePaymentError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = context.read<CartModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Payment Method"),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Amount Display
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${cartModel.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (cartModel.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('-\$${cartModel.discountAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST (18%):'),
                      Text('\$${cartModel.gstAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (cartModel.deliveryFee > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee:'),
                        Text('\$${cartModel.deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${cartModel.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Text(
              "Choose your payment method:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Pay with Stripe"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openRazorpayCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Pay with Razorpay"),
            ),
            const SizedBox(height: 20),
            const Text("Other Options:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _placeOrderWithPayment("Pay on Delivery"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Pay on Delivery"),
            ),
          ],
        ),
      ),
    );
  }
}