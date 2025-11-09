import 'package:flutter/material.dart';
import '../models/product.dart';

class CartScreen extends StatefulWidget {
  final Map<String, int> cart;
  final List<Product> products;

  const CartScreen({super.key, required this.cart, required this.products});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void increment(String name) {
    setState(() {
      widget.cart[name] = (widget.cart[name] ?? 0) + 1;
    });
  }

  void decrement(String name) {
    setState(() {
      if (widget.cart[name]! > 1) {
        widget.cart[name] = widget.cart[name]! - 1;
      } else {
        widget.cart.remove(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cart.keys.map((name) {
      return widget.products.firstWhere((p) => p.name == name);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛍 Your Cart"),
        backgroundColor: Colors.orange,
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final qty = widget.cart[item.name] ?? 0;
                      final totalPrice = item.price * qty;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: item.imageUrl != null
                              ? Image.network(item.imageUrl!, width: 60)
                              : CircleAvatar(child: Text(item.name[0])),
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description ?? ''),
                              Text('\$${item.price.toStringAsFixed(2)} each',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('Total: \$${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => decrement(item.name),
                              ),
                              Text(qty.toString(),
                                  style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => increment(item.name),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: () {
                      // Example: clear cart after "placing order"
                      setState(() {
                        widget.cart.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Order placed successfully!")),
                      );
                    },
                    child: const Text("Place Order"),
                  ),
                )
              ],
            ),
    );
  }
}
