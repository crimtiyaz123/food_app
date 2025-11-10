import 'package:flutter/material.dart';
import '../../models/delivery_partner.dart';
import '../../models/delivery_partner.dart';
import '../../services/delivery_service.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final String partnerId;

  const DeliveryDashboardScreen({super.key, required this.partnerId});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  final DeliveryService _service = DeliveryService();
  DeliveryPartner? _partner;
  List<DeliveryAssignment> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final partner = await _service.getDeliveryPartner(widget.partnerId);
      final assignments = await _service.getPartnerAssignments(widget.partnerId);

      setState(() {
        _partner = partner;
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _updateStatus(String assignmentId, DeliveryStatus status) async {
    try {
      await _service.updateDeliveryStatus(assignmentId, status);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.displayName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _toggleAvailability() async {
    if (_partner == null) return;

    try {
      final newAvailability = !_partner!.isAvailable;
      await _service.updatePartnerAvailability(widget.partnerId, newAvailability);
      await _loadData(); // Reload to get updated data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating availability: $e')),
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

    if (_partner == null) {
      return const Scaffold(
        body: Center(child: Text('Partner not found')),
      );
    }

    final activeAssignment = _assignments.where((a) =>
        a.status != DeliveryStatus.delivered && a.status != DeliveryStatus.failed).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_partner!.name} - Delivery'),
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
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _partner!.isAvailable,
                          onChanged: (_) => _toggleAvailability(),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _partner!.isAvailable ? 'Available for deliveries' : 'Currently unavailable',
                      style: TextStyle(
                        color: _partner!.isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Rating', '${_partner!.rating.toStringAsFixed(1)} ⭐'),
                        _buildStatItem('Deliveries', _partner!.totalDeliveries.toString()),
                        _buildStatItem('Vehicle', _partner!.vehicleType.toUpperCase()),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Active Deliveries
            if (activeAssignment.isNotEmpty) ...[
              const Text(
                'Active Deliveries',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...activeAssignment.map((assignment) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${assignment.orderId.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(assignment.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Pickup: ${assignment.pickupLocation.address}'),
                      Text('Delivery: ${assignment.deliveryLocation.address}'),
                      const SizedBox(height: 12),
                      if (assignment.status == DeliveryStatus.assigned)
                        ElevatedButton(
                          onPressed: () => _updateStatus(assignment.id, DeliveryStatus.pickedUp),
                          child: const Text('Mark as Picked Up'),
                        )
                      else if (assignment.status == DeliveryStatus.pickedUp)
                        ElevatedButton(
                          onPressed: () => _updateStatus(assignment.id, DeliveryStatus.outForDelivery),
                          child: const Text('Start Delivery'),
                        )
                      else if (assignment.status == DeliveryStatus.outForDelivery)
                        ElevatedButton(
                          onPressed: () => _updateStatus(assignment.id, DeliveryStatus.delivered),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Mark as Delivered'),
                        ),
                    ],
                  ),
                ),
              )),
            ] else ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active deliveries',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'New orders will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Recent Deliveries
            if (_assignments.where((a) => a.status == DeliveryStatus.delivered).isNotEmpty) ...[
              const Text(
                'Recent Deliveries',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._assignments
                  .where((a) => a.status == DeliveryStatus.delivered)
                  .take(5)
                  .map((assignment) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Order #${assignment.orderId.substring(0, 8)}'),
                  subtitle: Text('Delivered • Earned \$${assignment.earnings.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatusChip(DeliveryStatus status) {
    Color color;
    switch (status) {
      case DeliveryStatus.assigned:
        color = Colors.blue;
        break;
      case DeliveryStatus.pickedUp:
        color = Colors.orange;
        break;
      case DeliveryStatus.outForDelivery:
        color = Colors.purple;
        break;
      case DeliveryStatus.delivered:
        color = Colors.green;
        break;
      case DeliveryStatus.failed:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}