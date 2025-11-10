import 'package:flutter/material.dart';
import '../../models/admin.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _service = AdminService();
  AdminAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _service.getAdminAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
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

    if (_analytics == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading dashboard')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Users',
                    _analytics!.totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Total Restaurants',
                    _analytics!.totalRestaurants.toString(),
                    Icons.restaurant,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Orders',
                    _analytics!.totalOrders.toString(),
                    Icons.receipt_long,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Total Revenue',
                    '\$${_analytics!.totalRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Active Orders',
                    _analytics!.activeOrders.toString(),
                    Icons.pending,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Pending Approvals',
                    _analytics!.pendingApprovals.toString(),
                    Icons.approval,
                    Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActionCard(
                  'Manage Users',
                  Icons.people,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/admin/users'),
                ),
                _buildActionCard(
                  'Manage Restaurants',
                  Icons.restaurant,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/admin/restaurants'),
                ),
                _buildActionCard(
                  'Manage Orders',
                  Icons.receipt_long,
                  Colors.green,
                  () => Navigator.pushNamed(context, '/admin/orders'),
                ),
                _buildActionCard(
                  'Support Tickets',
                  Icons.support,
                  Colors.purple,
                  () => Navigator.pushNamed(context, '/admin/support'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Top Restaurants
            if (_analytics!.topRestaurants.isNotEmpty) ...[
              const Text(
                'Top Restaurants',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _analytics!.topRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = _analytics!.topRestaurants[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(restaurant.name),
                      subtitle: Text('${restaurant.orderCount} orders • \$${restaurant.revenue.toStringAsFixed(2)} revenue'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to restaurant details
                      },
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),

            // Top Customers
            if (_analytics!.topCustomers.isNotEmpty) ...[
              const Text(
                'Top Customers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _analytics!.topCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _analytics!.topCustomers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(customer.name),
                      subtitle: Text('${customer.orderCount} orders • \$${customer.totalSpent.toStringAsFixed(2)} spent'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to customer details
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}