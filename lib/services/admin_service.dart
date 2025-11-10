import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin.dart';
import '../models/User.dart';
import '../models/restaurant.dart';
import '../models/restaurant_order.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin User Management
  Future<void> createAdminUser(AdminUser admin) async {
    await _firestore.collection('adminUsers').doc(admin.id).set(admin.toJson());
  }

  Future<AdminUser?> getAdminUser(String adminId) async {
    final doc = await _firestore.collection('adminUsers').doc(adminId).get();
    if (doc.exists) {
      return AdminUser.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  // User Management
  Future<List<User>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => User.fromJson(doc.data()))
        .toList();
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // Restaurant Management
  Future<List<Restaurant>> getAllRestaurants() async {
    final snapshot = await _firestore.collection('restaurants').get();
    return snapshot.docs
        .map((doc) => Restaurant.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> approveRestaurant(String restaurantId) async {
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'isApproved': true,
      'approvedAt': Timestamp.now(),
    });
  }

  Future<void> rejectRestaurant(String restaurantId, String reason) async {
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'isApproved': false,
      'rejectionReason': reason,
      'rejectedAt': Timestamp.now(),
    });
  }

  Future<void> updateRestaurantStatus(String restaurantId, bool isActive) async {
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'isActive': isActive,
    });
  }

  // Order Management
  Future<List<RestaurantOrder>> getAllOrders() async {
    final snapshot = await _firestore.collection('orders').get();
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
  Future<AdminAnalytics> getAdminAnalytics() async {
    // Get all data
    final users = await getAllUsers();
    final restaurants = await getAllRestaurants();
    final orders = await getAllOrders();

    // Calculate metrics
    final totalUsers = users.length;
    final totalRestaurants = restaurants.length;
    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
    final activeOrders = orders.where((order) => !['delivered', 'cancelled'].contains(order.status)).length;
    final pendingApprovals = restaurants.where((r) => !(r as dynamic).isApproved ?? false).length;

    // Orders by status
    final ordersByStatus = <String, int>{};
    for (var order in orders) {
      ordersByStatus[order.status] = (ordersByStatus[order.status] ?? 0) + 1;
    }

    // Revenue by day (last 30 days)
    final revenueByDay = <String, double>{};
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    for (var order in orders.where((o) => o.orderTime.isAfter(thirtyDaysAgo))) {
      final day = order.orderTime.toIso8601String().split('T')[0];
      revenueByDay[day] = (revenueByDay[day] ?? 0) + order.totalAmount;
    }

    // Top restaurants
    final restaurantOrderCounts = <String, int>{};
    final restaurantRevenues = <String, double>{};
    for (var order in orders) {
      final restaurantId = order.id.split('_')[0]; // Extract from order ID
      restaurantOrderCounts[restaurantId] = (restaurantOrderCounts[restaurantId] ?? 0) + 1;
      restaurantRevenues[restaurantId] = (restaurantRevenues[restaurantId] ?? 0) + order.totalAmount;
    }

    final topRestaurants = restaurantOrderCounts.entries
        .map((entry) {
          final restaurant = restaurants.firstWhere(
            (r) => r.id == entry.key,
            orElse: () => Restaurant(
              id: entry.key,
              name: 'Unknown Restaurant',
              description: '',
              imageUrl: '',
              address: '',
              phone: '',
              rating: 0,
              reviewCount: 0,
              cuisines: [],
              isOpen: false,
              deliveryFee: 0,
              deliveryTime: 0,
              minOrder: 0,
            ),
          );
          return TopRestaurant(
            id: entry.key,
            name: restaurant.name,
            orderCount: entry.value,
            revenue: restaurantRevenues[entry.key] ?? 0,
          );
        })
        .toList()
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));

    // Top customers
    final customerOrderCounts = <String, int>{};
    final customerSpendings = <String, double>{};
    for (var order in orders) {
      customerOrderCounts[order.customerId] = (customerOrderCounts[order.customerId] ?? 0) + 1;
      customerSpendings[order.customerId] = (customerSpendings[order.customerId] ?? 0) + order.totalAmount;
    }

    final topCustomers = customerOrderCounts.entries
        .map((entry) {
          final user = users.firstWhere(
            (u) => u.id == entry.key,
            orElse: () => User(
              id: entry.key,
              email: '',
              name: 'Unknown User',
              phone: '',
              password: '',
              personalInfo: PersonalInfo(
                name: 'Unknown User',
                email: '',
                phone: '',
                password: '',
              ),
            ),
          );
          return TopCustomer(
            id: entry.key,
            name: user.name,
            orderCount: entry.value,
            totalSpent: customerSpendings[entry.key] ?? 0,
          );
        })
        .toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return AdminAnalytics(
      totalUsers: totalUsers,
      totalRestaurants: totalRestaurants,
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      activeOrders: activeOrders,
      pendingApprovals: pendingApprovals,
      ordersByStatus: ordersByStatus,
      revenueByDay: revenueByDay,
      topRestaurants: topRestaurants.take(10).toList(),
      topCustomers: topCustomers.take(10).toList(),
    );
  }

  // Support Ticket Management
  Future<List<SupportTicket>> getAllSupportTickets() async {
    final snapshot = await _firestore.collection('supportTickets').get();
    return snapshot.docs
        .map((doc) => SupportTicket.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> createSupportTicket(SupportTicket ticket) async {
    await _firestore.collection('supportTickets').doc(ticket.id).set(ticket.toJson());
  }

  Future<void> updateSupportTicketStatus(String ticketId, SupportStatus status, {String? assignedTo}) async {
    final updateData = {
      'status': status.name,
      'lastUpdated': Timestamp.now(),
    };

    if (assignedTo != null) {
      updateData['assignedTo'] = assignedTo;
    }

    if (status == SupportStatus.resolved) {
      updateData['resolvedAt'] = Timestamp.now();
    }

    await _firestore.collection('supportTickets').doc(ticketId).update(updateData);
  }

  Future<void> addSupportMessage(String ticketId, SupportMessage message) async {
    await _firestore.collection('supportTickets').doc(ticketId).update({
      'messages': FieldValue.arrayUnion([message.toJson()]),
      'lastUpdated': Timestamp.now(),
    });
  }

  // System Settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    final doc = await _firestore.collection('systemSettings').doc('main').get();
    return doc.exists ? doc.data()! : {};
  }

  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('systemSettings').doc('main').set(settings);
  }

  // Promotional Campaigns
  Future<List<Map<String, dynamic>>> getPromotionalCampaigns() async {
    final snapshot = await _firestore.collection('promotionalCampaigns').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> createPromotionalCampaign(Map<String, dynamic> campaign) async {
    await _firestore.collection('promotionalCampaigns').add(campaign);
  }

  Future<void> updatePromotionalCampaign(String campaignId, Map<String, dynamic> data) async {
    await _firestore.collection('promotionalCampaigns').doc(campaignId).update(data);
  }

  Future<void> deletePromotionalCampaign(String campaignId) async {
    await _firestore.collection('promotionalCampaigns').doc(campaignId).delete();
  }
}