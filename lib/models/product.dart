class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final double price;
  final String categoryId;
  final double? rating;
  final int reviewCount;
  final bool isAvailable;
  final String restaurantId;

  Product({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    required this.price,
    required this.categoryId,
    this.rating,
    this.reviewCount = 0,
    this.isAvailable = true,
    required this.restaurantId,
  });

  factory Product.fromJson(String id, Map<String, dynamic> json) {
    return Product(
      id: id,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      price: _safeDouble(json['price']),
      categoryId: json['categoryId'] ?? '',
      rating: _safeNullableDouble(json['rating']),
      reviewCount: _safeInt(json['reviewCount']),
      isAvailable: _safeBool(json['isAvailable']),
      restaurantId: json['restaurantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl ?? '',
      'description': description ?? '',
      'price': price,
      'categoryId': categoryId,
      'rating': rating ?? 0.0,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'restaurantId': restaurantId,
    };
  }

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      price: _safeDouble(data['price']),
      categoryId: data['categoryId'] ?? '',
      rating: _safeNullableDouble(data['rating']),
      reviewCount: _safeInt(data['reviewCount']),
      isAvailable: _safeBool(data['isAvailable']),
      restaurantId: data['restaurantId'] ?? '',
    );
  }

  // Helper methods for type-safe conversions
  static double _safeDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static double? _safeNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static bool _safeBool(dynamic value) {
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value != 0;
    } else if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}