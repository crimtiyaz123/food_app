import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_owner.dart';
import '../models/restaurant.dart';
import '../models/restaurant_order.dart';
import '../models/product.dart';

class RestaurantOwnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Restaurant Owner Management
  Future<void> registerRestaurantOwner(RestaurantOwner owner) async {
    await _firestore.collection('restaurantOwners').doc(owner.id).set(owner.toJson());
  }

  Future<RestaurantOwner?> getRestaurantOwner(String ownerId) async {
    final doc = await _firestore.collection('restaurantOwners').doc(ownerId).get();
    if (doc.exists) {
      return RestaurantOwner.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  // Restaurant Management
  Future<void> createRestaurant(Restaurant restaurant, String ownerId) async {
    await _firestore.collection('restaurants').doc(restaurant.id).set(restaurant.toJson());
    // Update owner with restaurant ID
    await _firestore.collection('restaurantOwners').doc(ownerId).update({
      'restaurantId': restaurant.id,
    });
  }

  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    await _firestore.collection('restaurants').doc(restaurantId).update(data);
  }

  Future<Restaurant?> getRestaurant(String restaurantId) async {
    final doc = await _firestore.collection('restaurants').doc(restaurantId).get();
    if (doc.exists) {
      return Restaurant.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  // Menu Management
  Future<void> addMenuItem(String restaurantId, Map<String, dynamic> menuItem) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .add(menuItem);
  }

  Future<void> updateMenuItem(String restaurantId, String itemId, Map<String, dynamic> data) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .doc(itemId)
        .update(data);
  }

  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .doc(itemId)
        .delete();
  }

  // Order Management
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

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'lastUpdated': Timestamp.now(),
    });
  }

  // Analytics
  Future<Map<String, dynamic>> getRestaurantAnalytics(String restaurantId) async {
    final orders = await getRestaurantOrders(restaurantId);

    double totalRevenue = 0;
    int totalOrders = orders.length;
    Map<String, int> ordersByStatus = {};
    Map<String, double> revenueByDay = {};

    for (var order in orders) {
      totalRevenue += order.totalAmount;

      ordersByStatus[order.status] = (ordersByStatus[order.status] ?? 0) + 1;

      final day = order.orderTime.toIso8601String().split('T')[0];
      revenueByDay[day] = (revenueByDay[day] ?? 0) + order.totalAmount;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'ordersByStatus': ordersByStatus,
      'revenueByDay': revenueByDay,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    };
  }

  // Get pending orders count
  Future<int> getPendingOrdersCount(String restaurantId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereIn: ['pending', 'accepted', 'preparing'])
        .get();
    return snapshot.docs.length;
  }

  // Get restaurant menu
  Future<List<Product>> getRestaurantMenu(String restaurantId) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.id, doc.data()))
        .toList();
  }
}