import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import 'package:provider/provider.dart';

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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.orange),
            title: Text(orders[index], style: const TextStyle(fontSize: 18)),
            subtitle: const Text("Order status: Delivered"),
          ),
        );
      },
    );
  }
}
