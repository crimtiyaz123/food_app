import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../models/restaurant_order.dart';
import '../../services/restaurant_owner_service.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDashboardScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final RestaurantOwnerService _service = RestaurantOwnerService();

  Restaurant? _restaurant;
  List<RestaurantOrder> _orders = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final restaurant = await _service.getRestaurant(widget.restaurantId);
      final orders = await _service.getRestaurantOrders(widget.restaurantId);
      final analytics = await _service.getRestaurantAnalytics(widget.restaurantId);

      setState(() {
        _restaurant = restaurant;
        _orders = orders;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _service.updateOrderStatus(orderId, newStatus);
      await _loadData(); // Refresh data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurant == null) {
      return const Scaffold(
        body: Center(child: Text('Restaurant not found')),
      );
    }

    final pendingOrders = _orders.where((order) => order.status == 'pending').length;
    final preparingOrders = _orders.where((order) => order.status == 'preparing').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurant!.name),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Cards
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Total Revenue',
                    '\$${_analytics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Total Orders',
                    '${_analytics['totalOrders'] ?? 0}',
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Pending Orders',
                    '$pendingOrders',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Preparing',
                    '$preparingOrders',
                    Icons.restaurant,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Orders Section
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_orders.isEmpty)
              const Center(child: Text('No orders yet'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order.id.substring(0, 8)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              _buildStatusChip(order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Customer: ${order.customerName}'),
                          Text('Items: ${order.items.length}'),
                          Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          if (order.status == 'pending')
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _updateOrderStatus(order.id, 'accepted'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text('Accept'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Reject'),
                                ),
                              ],
                            )
                          else if (order.status == 'accepted')
                            ElevatedButton(
                              onPressed: () => _updateOrderStatus(order.id, 'preparing'),
                              child: const Text('Start Preparing'),
                            )
                          else if (order.status == 'preparing')
                            ElevatedButton(
                              onPressed: () => _updateOrderStatus(order.id, 'ready'),
                              child: const Text('Mark Ready'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'preparing':
        color = Colors.purple;
        break;
      case 'ready':
        color = Colors.green;
        break;
      case 'delivered':
        color = Colors.grey;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}