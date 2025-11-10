class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final String phone;
  final double rating;
  final int reviewCount;
  final List<String> cuisines;
  final bool isOpen;
  final double deliveryFee;
  final int deliveryTime;
  final double minOrder;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    required this.cuisines,
    required this.isOpen,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.minOrder,
  });

  factory Restaurant.fromJson(String id, Map<String, dynamic> json) {
    return Restaurant(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      cuisines: List<String>.from(json['cuisines'] ?? []),
      isOpen: json['isOpen'] ?? true,
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      deliveryTime: json['deliveryTime'] ?? 30,
      minOrder: (json['minOrder'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'phone': phone,
      'rating': rating,
      'reviewCount': reviewCount,
      'cuisines': cuisines,
      'isOpen': isOpen,
      'deliveryFee': deliveryFee,
      'deliveryTime': deliveryTime,
      'minOrder': minOrder,
    };
  }
}