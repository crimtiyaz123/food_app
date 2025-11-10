import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_category.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import 'cart_screen.dart';

class ProductScreen extends StatefulWidget {
  final FoodCategory category;

  const ProductScreen({super.key, required this.category});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Map<String, int> _selectedQuantities = {};

  void _incrementSelected(Product product) {
    setState(() {
      _selectedQuantities[product.name] = (_selectedQuantities[product.name] ?? 0) + 1;
    });
  }

  void _decrementSelected(Product product) {
    setState(() {
      if (_selectedQuantities[product.name] != null && _selectedQuantities[product.name]! > 0) {
        _selectedQuantities[product.name] = _selectedQuantities[product.name]! - 1;
      }
    });
  }

  void _addToCart(Product product, int qty, BuildContext context) {
    final cartModel = context.read<CartModel>();
    for (int i = 0; i < qty; i++) {
      cartModel.addItem(product);
    }
    setState(() {
      _selectedQuantities[product.name] = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart!')),
    );
  }

  int _getCartQuantity(Product product) {
    final cartModel = context.read<CartModel>();
    return cartModel.items[product] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
              Consumer<CartModel>(
                builder: (context, cartModel, child) {
                  final itemCount = cartModel.items.length;
                  if (itemCount > 0)
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          itemCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  return const SizedBox.shrink();
                },
              ),
            ],
          )
        ],
      ),
      body: ListView.builder(
        itemCount: widget.category.products.length,
        itemBuilder: (context, index) {
          final product = widget.category.products[index];
          final selectedQty = _selectedQuantities[product.name] ?? 0;
          final cartQty = _getCartQuantity(product);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: product.imageUrl != null
                  ? Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 40,
                      child: Text(product.name[0], style: TextStyle(fontSize: 24)),
                    ),
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.description ?? ''),
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  if (cartQty > 0)
                    Text('In cart: $cartQty',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: selectedQty > 0 ? () => _decrementSelected(product) : null,
                      ),
                      Text(selectedQty.toString(), style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _incrementSelected(product),
                      ),
                    ],
                  ),
                  if (selectedQty > 0)
                    ElevatedButton(
                      onPressed: () => _addToCart(product, selectedQty, context),
                      child: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
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