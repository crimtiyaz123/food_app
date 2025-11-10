import 'product.dart';

class RestaurantOrder {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'accepted', 'preparing', 'ready', 'picked_up', 'delivered', 'cancelled'
  final DateTime orderTime;
  final DateTime? estimatedDeliveryTime;
  final String deliveryAddress;
  final String paymentMethod;
  final String specialInstructions;
  final double deliveryFee;

  RestaurantOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderTime,
    this.estimatedDeliveryTime,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.specialInstructions = '',
    required this.deliveryFee,
  });

  factory RestaurantOrder.fromJson(String id, Map<String, dynamic> json) {
    return RestaurantOrder(
      id: id,
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      orderTime: DateTime.parse(json['orderTime'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      specialInstructions: json['specialInstructions'] ?? '',
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderTime': orderTime.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'specialInstructions': specialInstructions,
      'deliveryFee': deliveryFee,
    };
  }
}

class OrderItem {
  final Product product;
  final int quantity;
  final double price; // Price at the time of order
  final String specialInstructions;

  OrderItem({
    required this.product,
    required this.quantity,
    required this.price,
    this.specialInstructions = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] ?? {};
    final productId = 'order_item_${productData['id'] ?? DateTime.now().millisecondsSinceEpoch}';
    return OrderItem(
      product: Product.fromJson(productId, productData),
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      specialInstructions: json['specialInstructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'specialInstructions': specialInstructions,
    };
  }
}