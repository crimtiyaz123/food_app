import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile/edit_profile_screen.dart'; // Import your EditProfileScreen
import 'profile/change_password_screen.dart'; // Import ChangePasswordScreen
import 'address_screen.dart'; // Import AddressScreen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Firebase logout function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // ===== Profile Section =====
          const SizedBox(height: 10),
          const Text(
            "Account",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),

          // Edit Profile
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text("View & Edit Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          const Divider(),

          // Change Password
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.blue),
            title: const Text("Change Password"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(),

          // ===== Address Section =====
          const SizedBox(height: 10),
          const Text(
            "Delivery",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),

          // Update Address
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.orange),
            title: const Text("Change / Update Address"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressScreen()),
              );
            },
          ),
          const Divider(),

          // ===== Logout Section =====
          const SizedBox(height: 10),
          const Text(
            "Security",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
