import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final NotificationService _service = NotificationService();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  String _userId = 'current_user_id'; // TODO: Get from auth

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final preferences = await _service.getNotificationPreferences(_userId);
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading preferences: $e')),
      );
    }
  }

  Future<void> _updatePreferences() async {
    if (_preferences == null) return;

    try {
      await _service.updateNotificationPreferences(_preferences!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preferences: $e')),
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

    if (_preferences == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading preferences')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Colors.green,
        actions: [
          TextButton(
            onPressed: _updatePreferences,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose which notifications you want to receive',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Order Updates
          Card(
            child: SwitchListTile(
              title: const Text('Order Updates'),
              subtitle: const Text('Get notified about your order status changes'),
              secondary: const Icon(Icons.receipt_long, color: Colors.blue),
              value: _preferences!.orderUpdates,
              onChanged: (value) => setState(() => _preferences!.orderUpdates = value),
            ),
          ),

          // Delivery Updates
          Card(
            child: SwitchListTile(
              title: const Text('Delivery Updates'),
              subtitle: const Text('Track your order delivery in real-time'),
              secondary: const Icon(Icons.delivery_dining, color: Colors.orange),
              value: _preferences!.deliveryUpdates,
              onChanged: (value) => setState(() => _preferences!.deliveryUpdates = value),
            ),
          ),

          // Promotions
          Card(
            child: SwitchListTile(
              title: const Text('Promotions & Offers'),
              subtitle: const Text('Receive special offers and promotional notifications'),
              secondary: const Icon(Icons.local_offer, color: Colors.green),
              value: _preferences!.promotions,
              onChanged: (value) => setState(() => _preferences!.promotions = value),
            ),
          ),

          // General Notifications
          Card(
            child: SwitchListTile(
              title: const Text('General Notifications'),
              subtitle: const Text('Important app updates and announcements'),
              secondary: const Icon(Icons.notifications, color: Colors.grey),
              value: _preferences!.generalNotifications,
              onChanged: (value) => setState(() => _preferences!.generalNotifications = value),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Sound & Vibration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Sound
          Card(
            child: SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sound for notifications'),
              secondary: const Icon(Icons.volume_up),
              value: _preferences!.soundEnabled,
              onChanged: (value) => setState(() => _preferences!.soundEnabled = value),
            ),
          ),

          // Vibration
          Card(
            child: SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate device for notifications'),
              secondary: const Icon(Icons.vibration),
              value: _preferences!.vibrationEnabled,
              onChanged: (value) => setState(() => _preferences!.vibrationEnabled = value),
            ),
          ),

          const SizedBox(height: 32),

          // Test Notification
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await _service.sendNotificationToUser(
                  _userId,
                  'Test Notification',
                  'This is a test notification to check your preferences',
                  NotificationType.general,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sending test notification: $e')),
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Note: Push notifications require device permissions and may be delayed based on your device settings.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}