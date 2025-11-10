import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../models/order.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<CartModel>(context).orders;

    if (orders.isEmpty) {
      return const Center(
          child: Text(
        "You have no orders yet.",
        style: TextStyle(fontSize: 18),
      ));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(order.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${order.product.name} - ${order.quantity} pcs',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status: ${order.status}",
                      style: TextStyle(
                        color: order.status == 'Delivered' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (order.status == 'Delivered') ...[
                  const SizedBox(height: 12),
                  const Text("Rate this product:"),
                  Row(
                    children: List.generate(5, (starIndex) {
                      return IconButton(
                        icon: Icon(
                          starIndex < (order.rating ?? 0) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          Provider.of<CartModel>(context, listen: false).rateOrder(index, starIndex + 1.0);
                        },
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
