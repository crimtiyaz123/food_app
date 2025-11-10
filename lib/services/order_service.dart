import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_order.dart';
import '../models/order_status.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Place a new order
  Future<void> placeOrder(RestaurantOrder order) async {
    await _firestore.collection('orders').doc(order.id).set({
      ...order.toJson(),
      'restaurantId': order.id.split('_')[0], // Extract restaurant ID from order ID
      'statusUpdates': [
        OrderStatusUpdate(
          status: OrderStatus.pending,
          timestamp: order.orderTime,
          note: 'Order placed',
        ).toJson()
      ],
    });
  }

  // Get orders for a customer
  Future<List<RestaurantOrder>> getCustomerOrders(String customerId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => RestaurantOrder.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Get orders for a restaurant
  Future<List<RestaurantOrder>> getRestaurantOrders(String restaurantId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('orderTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => RestaurantOrder.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note}) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    // Get current order data
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) return;

    final data = orderDoc.data()!;
    final statusUpdates = (data['statusUpdates'] as List<dynamic>?)
        ?.map((update) => OrderStatusUpdate.fromJson(update))
        .toList() ?? [];

    // Add new status update
    statusUpdates.add(OrderStatusUpdate(
      status: newStatus,
      timestamp: DateTime.now(),
      note: note,
    ));

    // Update order
    await orderRef.update({
      'status': newStatus.name,
      'statusUpdates': statusUpdates.map((update) => update.toJson()).toList(),
      'lastUpdated': Timestamp.now(),
    });
  }

  // Get order status tracker
  Future<OrderStatusTracker?> getOrderStatusTracker(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final statusUpdates = (data['statusUpdates'] as List<dynamic>?)
        ?.map((update) => OrderStatusUpdate.fromJson(update))
        .toList() ?? [];

    return OrderStatusTracker(
      orderId: orderId,
      updates: statusUpdates,
    );
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await updateOrderStatus(
      orderId,
      OrderStatus.cancelled,
      note: reason ?? 'Order cancelled by customer',
    );
  }

  // Get active orders count for restaurant
  Future<int> getActiveOrdersCount(String restaurantId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereNotIn: ['delivered', 'cancelled'])
        .get();
    return snapshot.docs.length;
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics(String restaurantId) async {
    final orders = await getRestaurantOrders(restaurantId);

    int totalOrders = orders.length;
    double totalRevenue = orders.fold(0, (sum, order) => sum + order.totalAmount);
    Map<String, int> ordersByStatus = {};

    for (var order in orders) {
      final status = OrderStatus.fromString(order.status);
      ordersByStatus[status.displayName] = (ordersByStatus[status.displayName] ?? 0) + 1;
    }

    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'ordersByStatus': ordersByStatus,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    };
  }
}