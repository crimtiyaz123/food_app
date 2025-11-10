import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_category.dart';
import 'cart_screen.dart';
import 'product_screen.dart';

// FoodCategoryScreen
class FoodCategoryScreen extends StatefulWidget {
  const FoodCategoryScreen({super.key});

  @override
  State<FoodCategoryScreen> createState() => _FoodCategoryScreenState();
}

class _FoodCategoryScreenState extends State<FoodCategoryScreen> {
  List<FoodCategory> _categories = [];
  Map<String, int> _cart = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final String response =
        await rootBundle.loadString('lib/Seed/food_categories.json');
    final List data = json.decode(response);
    setState(() {
      _categories = data.map((e) => FoodCategory.fromJson(null, e)).toList();
      _isLoading = false;
    });
  }

  void _increment(FoodCategory category) {
    setState(() {
      _cart[category.name] = (_cart[category.name] ?? 0) + 1;
    });
  }

  void _decrement(FoodCategory category) {
    setState(() {
      if (_cart[category.name] != null && _cart[category.name]! > 1) {
        _cart[category.name] = _cart[category.name]! - 1;
      } else {
        _cart.remove(category.name);
      }
    });
  }

  int _getQuantity(FoodCategory category) => _cart[category.name] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🍴 Food Categories"),
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
                      builder: (_) => const CartScreen(),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final qty = _getQuantity(category);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductScreen(category: category),
                        ),
                      );
                    },
                    leading: category.imageUrl != null
                        ? Image.network(
                            category.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : CircleAvatar(child: Text(category.name[0])),
                    title: Text(category.name),
                    subtitle: Text('${category.products.length} items'),
                    trailing: qty == 0
                        ? ElevatedButton(
                            onPressed: () => _increment(category),
                            child: const Text('Add +'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _decrement(category),
                              ),
                              Text(qty.toString(), style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _increment(category),
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

