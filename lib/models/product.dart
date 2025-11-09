class Product {
  final String? id;
  final String name;
  final String? imageUrl;
  final String? description;
  final double price;
  final String categoryId;

  Product({
    this.id,
    required this.name,
    this.imageUrl,
    this.description,
    required this.price,
    required this.categoryId,
  });

  factory Product.fromJson(String? id, Map<String, dynamic> json) {
    return Product(
      id: id,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      categoryId: json['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl ?? '',
      'description': description ?? '',
      'price': price,
      'categoryId': categoryId,
    };
  }

  // Optional: Convert Firestore doc directly
  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'] ?? '',
    );
  }
}