import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/iot_device.dart';
import '../services/iot_service.dart';
import '../theme/app_theme.dart';

class IoTDashboardScreen extends StatefulWidget {
  const IoTDashboardScreen({super.key});

  @override
  State<IoTDashboardScreen> createState() => _IoTDashboardScreenState();
}

class _IoTDashboardScreenState extends State<IoTDashboardScreen> {
  final IoTService _iotService = IoTService();
  List<IoTDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _initializeIoT();
  }

  Future<void> _initializeIoT() async {
    try {
      await _iotService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize IoT: $e')),
        );
      }
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _iotService.getDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load devices: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Device Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDeviceGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceGrid() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No IoT devices found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showAddDeviceDialog,
              child: const Text('Add First Device'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        return _buildDeviceCard(_devices[index]);
      },
    );
  }

  Widget _buildDeviceCard(IoTDevice device) {
    final isOnline = device.status == IoTDeviceStatus.online;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDeviceIcon(device.type),
                  color: isOnline ? Colors.green : Colors.red,
                  size: 32,
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              device.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              device.type.toString().split('.').last,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            _buildDeviceReadings(device),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDeviceDetails(device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceReadings(IoTDevice device) {
    final readings = device.currentReadings;
    if (readings.isEmpty) {
      return const Text(
        'No readings',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: readings.entries.take(2).map((entry) {
        return Text(
          '${entry.key}: ${entry.value}',
          style: const TextStyle(fontSize: 12),
        );
      }).toList(),
    );
  }

  IconData _getDeviceIcon(IoTDeviceType type) {
    switch (type) {
      case IoTDeviceType.smartOven:
        return Icons.kitchen;
      case IoTDeviceType.smartFridge:
        return Icons.kitchen;
      case IoTDeviceType.smartLocker:
        return Icons.lock;
      case IoTDeviceType.deliveryDrone:
        return Icons.airplanemode_active;
      case IoTDeviceType.smartScale:
        return Icons.scale;
      case IoTDeviceType.temperatureSensor:
        return Icons.thermostat;
      case IoTDeviceType.humiditySensor:
        return Icons.water_drop;
    }
  }

  void _showDeviceDetails(IoTDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', device.type.toString().split('.').last),
              _buildDetailRow('Status', device.status.toString().split('.').last),
              _buildDetailRow('Category', device.category.toString().split('.').last),
              _buildDetailRow('Last Seen', device.lastSeen.toString()),
              const SizedBox(height: 16),
              const Text(
                'Current Readings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...device.currentReadings.entries.map(
                (entry) => _buildDetailRow(entry.key, entry.value.toString()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _showDeviceCommands(device),
            child: const Text('Commands'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeviceCommands(IoTDevice device) {
    // Navigate to commands screen or show commands dialog
    Navigator.of(context).pop(); // Close details dialog
    // TODO: Implement device commands UI
  }

  void _showAddDeviceDialog() {
    // TODO: Implement add device dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add device feature coming soon!')),
    );
  }
}
