class RestaurantOwner {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String restaurantId;
  final String businessLicense;
  final bool isVerified;

  RestaurantOwner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.restaurantId,
    required this.businessLicense,
    this.isVerified = false,
  });

  factory RestaurantOwner.fromJson(String id, Map<String, dynamic> json) {
    return RestaurantOwner(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      businessLicense: json['businessLicense'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'restaurantId': restaurantId,
      'businessLicense': businessLicense,
      'isVerified': isVerified,
    };
  }
}