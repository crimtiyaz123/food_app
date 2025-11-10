import '../models/product.dart';

class Order {
  final String id;
  final Product product;
  final int quantity;
  final DateTime date;
  final double totalPrice;
  String status;
  double? rating;

  Order({
    required this.id,
    required this.product,
    required this.quantity,
    required this.date,
    required this.totalPrice,
    this.status = 'Delivered',
    this.rating,
  });
}