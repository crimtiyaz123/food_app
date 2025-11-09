import 'package:flutter/material.dart';
import '../models/food_category.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class ProductScreen extends StatefulWidget {
  final FoodCategory category;

  const ProductScreen({super.key, required this.category});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Map<String, int> _cart = {};

  void _increment(Product product) {
    setState(() {
      _cart[product.name] = (_cart[product.name] ?? 0) + 1;
    });
  }

  void _decrement(Product product) {
    setState(() {
      if (_cart[product.name] != null && _cart[product.name]! > 1) {
        _cart[product.name] = _cart[product.name]! - 1;
      } else {
        _cart.remove(product.name);
      }
    });
  }

  int _getQuantity(Product product) => _cart[product.name] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.orange,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(cart: _cart, products: widget.category.products),
                    ),
                  );
                },
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cart.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: ListView.builder(
        itemCount: widget.category.products.length,
        itemBuilder: (context, index) {
          final product = widget.category.products[index];
          final qty = _getQuantity(product);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : CircleAvatar(child: Text(product.name[0])),
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.description ?? ''),
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              trailing: qty == 0
                  ? ElevatedButton(
                      onPressed: () => _increment(product),
                      child: const Text('Add +'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _decrement(product),
                        ),
                        Text(qty.toString(), style: const TextStyle(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _increment(product),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}