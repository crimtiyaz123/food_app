import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryTracking {
  final String orderId;
  final String deliveryPartnerId;
  final String customerId;
  final LocationData currentLocation;
  final LocationData restaurantLocation;
  final LocationData deliveryAddress;
  final OrderStatus orderStatus;
  final DateTime lastUpdated;
  final String estimatedArrival;
  final List<TrackingUpdate> trackingHistory;
  final String deliveryPartnerName;
  final String deliveryPartnerPhone;
  final String vehicleInfo;
  final double distanceRemaining;
  final int deliveryTimeSeconds;

  DeliveryTracking({
    required this.orderId,
    required this.deliveryPartnerId,
    required this.customerId,
    required this.currentLocation,
    required this.restaurantLocation,
    required this.deliveryAddress,
    required this.orderStatus,
    required this.lastUpdated,
    required this.estimatedArrival,
    required this.trackingHistory,
    required this.deliveryPartnerName,
    required this.deliveryPartnerPhone,
    required this.vehicleInfo,
    required this.distanceRemaining,
    required this.deliveryTimeSeconds,
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) {
    return DeliveryTracking(
      orderId: json['orderId'] ?? '',
      deliveryPartnerId: json['deliveryPartnerId'] ?? '',
      customerId: json['customerId'] ?? '',
      currentLocation: LocationData.fromJson(json['currentLocation'] ?? {}),
      restaurantLocation: LocationData.fromJson(json['restaurantLocation'] ?? {}),
      deliveryAddress: LocationData.fromJson(json['deliveryAddress'] ?? {}),
      orderStatus: OrderStatus.fromString(json['orderStatus'] ?? 'pending'),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] ?? 0),
      estimatedArrival: json['estimatedArrival'] ?? '',
      trackingHistory: (json['trackingHistory'] as List<dynamic>?)
          ?.map((update) => TrackingUpdate.fromJson(update))
          .toList() ?? [],
      deliveryPartnerName: json['deliveryPartnerName'] ?? '',
      deliveryPartnerPhone: json['deliveryPartnerPhone'] ?? '',
      vehicleInfo: json['vehicleInfo'] ?? '',
      distanceRemaining: (json['distanceRemaining'] ?? 0.0).toDouble(),
      deliveryTimeSeconds: json['deliveryTimeSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'deliveryPartnerId': deliveryPartnerId,
      'customerId': customerId,
      'currentLocation': currentLocation.toJson(),
      'restaurantLocation': restaurantLocation.toJson(),
      'deliveryAddress': deliveryAddress.toJson(),
      'orderStatus': orderStatus.toString(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'estimatedArrival': estimatedArrival,
      'trackingHistory': trackingHistory.map((update) => update.toJson()).toList(),
      'deliveryPartnerName': deliveryPartnerName,
      'deliveryPartnerPhone': deliveryPartnerPhone,
      'vehicleInfo': vehicleInfo,
      'distanceRemaining': distanceRemaining,
      'deliveryTimeSeconds': deliveryTimeSeconds,
    };
  }

  DeliveryTracking copyWith({
    String? orderId,
    String? deliveryPartnerId,
    String? customerId,
    LocationData? currentLocation,
    LocationData? restaurantLocation,
    LocationData? deliveryAddress,
    OrderStatus? orderStatus,
    DateTime? lastUpdated,
    String? estimatedArrival,
    List<TrackingUpdate>? trackingHistory,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    String? vehicleInfo,
    double? distanceRemaining,
    int? deliveryTimeSeconds,
  }) {
    return DeliveryTracking(
      orderId: orderId ?? this.orderId,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      customerId: customerId ?? this.customerId,
      currentLocation: currentLocation ?? this.currentLocation,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      orderStatus: orderStatus ?? this.orderStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      trackingHistory: trackingHistory ?? this.trackingHistory,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      deliveryTimeSeconds: deliveryTimeSeconds ?? this.deliveryTimeSeconds,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
      placeName: json['placeName'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
      'timestamp': timestamp?.millisecondsSinceEpoch,
    };
  }
}

class TrackingUpdate {
  final String status;
  final String description;
  final DateTime timestamp;
  final LocationData? location;
  final String updatedBy;

  TrackingUpdate({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
    required this.updatedBy,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
      updatedBy: json['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': location?.toJson(),
      'updatedBy': updatedBy,
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  pickedUp,
  outForDelivery,
  arriving,
  delivered,
  cancelled;

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'outfordelivery':
        return OrderStatus.outForDelivery;
      case 'arriving':
        return OrderStatus.arriving;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String toString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.pickedUp:
        return 'pickedup';
      case OrderStatus.outForDelivery:
        return 'outfordelivery';
      case OrderStatus.arriving:
        return 'arriving';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Pending';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing Your Food';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up by Delivery Partner';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.arriving:
        return 'Arriving Soon';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order is being reviewed';
      case OrderStatus.confirmed:
        return 'Order confirmed by restaurant';
      case OrderStatus.preparing:
        return 'Restaurant is preparing your food';
      case OrderStatus.ready:
        return 'Food is ready for pickup';
      case OrderStatus.pickedUp:
        return 'Delivery partner picked up your order';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way';
      case OrderStatus.arriving:
        return 'Delivery partner is arriving';
      case OrderStatus.delivered:
        return 'Order has been delivered';
      case OrderStatus.cancelled:
        return 'Order has been cancelled';
    }
  }
}