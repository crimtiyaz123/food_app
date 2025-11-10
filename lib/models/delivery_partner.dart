class DeliveryPartner {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType; // 'bike', 'car', 'scooter'
  final String vehicleNumber;
  final String licenseNumber;
  final bool isActive;
  final bool isAvailable;
  final double rating;
  final int totalDeliveries;
  final Location currentLocation;
  final DateTime joinedAt;

  DeliveryPartner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.licenseNumber,
    this.isActive = true,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    required this.currentLocation,
    required this.joinedAt,
  });

  factory DeliveryPartner.fromJson(String id, Map<String, dynamic> json) {
    return DeliveryPartner(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? 'bike',
      vehicleNumber: json['vehicleNumber'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      isActive: json['isActive'] ?? true,
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      currentLocation: Location.fromJson(json['currentLocation'] ?? {}),
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'currentLocation': currentLocation.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class DeliveryAssignment {
  final String id;
  final String orderId;
  final String deliveryPartnerId;
  final String restaurantId;
  final String customerId;
  final Location pickupLocation;
  final Location deliveryLocation;
  final DeliveryStatus status;
  final DateTime assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final double earnings;
  final String? notes;

  DeliveryAssignment({
    required this.id,
    required this.orderId,
    required this.deliveryPartnerId,
    required this.restaurantId,
    required this.customerId,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.status = DeliveryStatus.assigned,
    required this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.earnings,
    this.notes,
  });

  factory DeliveryAssignment.fromJson(String id, Map<String, dynamic> json) {
    return DeliveryAssignment(
      id: id,
      orderId: json['orderId'] ?? '',
      deliveryPartnerId: json['deliveryPartnerId'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      customerId: json['customerId'] ?? '',
      pickupLocation: Location.fromJson(json['pickupLocation'] ?? {}),
      deliveryLocation: Location.fromJson(json['deliveryLocation'] ?? {}),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.assigned,
      ),
      assignedAt: DateTime.parse(json['assignedAt'] ?? DateTime.now().toIso8601String()),
      pickedUpAt: json['pickedUpAt'] != null ? DateTime.parse(json['pickedUpAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'deliveryPartnerId': deliveryPartnerId,
      'restaurantId': restaurantId,
      'customerId': customerId,
      'pickupLocation': pickupLocation.toJson(),
      'deliveryLocation': deliveryLocation.toJson(),
      'status': status.name,
      'assignedAt': assignedAt.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'earnings': earnings,
      'notes': notes,
    };
  }
}

enum DeliveryStatus {
  assigned('Assigned'),
  pickedUp('Picked Up'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  failed('Failed');

  const DeliveryStatus(this.displayName);
  final String displayName;
}

class Location {
  final double latitude;
  final double longitude;
  final String address;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}