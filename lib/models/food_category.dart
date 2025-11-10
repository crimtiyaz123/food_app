import 'product.dart';

class FoodCategory {
  final String? id;
  final String name;
  final String? imageUrl;
  final String? description;
  final List<Product> products;

  FoodCategory({
    this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.products = const [],
  });

  factory FoodCategory.fromJson(String? id, Map<String, dynamic> json) {
    List<Product> products = [];
    if (json['products'] != null) {
      products = (json['products'] as List).asMap().entries
          .map((entry) => Product.fromJson('${id}_${entry.key}', entry.value))
          .toList();
    }
    return FoodCategory(
      id: id,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      products: products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl ?? '',
      'description': description ?? '',
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  factory FoodCategory.fromFirestore(String id, Map<String, dynamic> data) {
    List<Product> products = [];
    if (data['products'] != null) {
      products = (data['products'] as List).asMap().entries
          .map((entry) => Product.fromJson('${id}_${entry.key}', entry.value))
          .toList();
    }
    return FoodCategory(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      products: products,
    );
  }
}
