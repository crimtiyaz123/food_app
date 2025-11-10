import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';

class AddressScreen extends StatefulWidget {
  final bool autoPopulateFromFirestore;
  
  const AddressScreen({super.key, this.autoPopulateFromFirestore = true});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  // Load current address from Firestore
  Future<void> _loadAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['address'] != null) {
      _addressController.text = doc.data()!['address'];
    }
  }

  // Save address to Firestore
  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Address cannot be empty")),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'address': address}, SetOptions(merge: true));

      // Also set the delivery address in cart model
      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.setDeliveryAddress(address);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Address updated successfully!")),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update address: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Address"),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text("Save Address"),
            ),
          ],
        ),
      ),
    );
  }
}
