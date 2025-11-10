import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/restaurant_service.dart';
import 'models/restaurant.dart';

class TestRestaurantScreen extends StatefulWidget {
  const TestRestaurantScreen({super.key});

  @override
  State<TestRestaurantScreen> createState() => _TestRestaurantScreenState();
}

class _TestRestaurantScreenState extends State<TestRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantService = RestaurantService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cuisinesController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _minOrderController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cuisinesController.dispose();
    _deliveryFeeController.dispose();
    _deliveryTimeController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _addTestRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final restaurant = Restaurant(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        rating: 0.0,
        reviewCount: 0,
        cuisines: _cuisinesController.text.split(',').map((e) => e.trim()).toList(),
        isOpen: true,
        deliveryFee: double.tryParse(_deliveryFeeController.text) ?? 0.0,
        deliveryTime: int.tryParse(_deliveryTimeController.text) ?? 30,
        minOrder: double.tryParse(_minOrderController.text) ?? 0.0,
      );

      await _restaurantService.createRestaurant(restaurant);

      Fluttertoast.showToast(
        msg: "Test restaurant added successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _addressController.clear();
      _phoneController.clear();
      _cuisinesController.clear();
      _deliveryFeeController.clear();
      _deliveryTimeController.clear();
      _minOrderController.clear();

    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to add restaurant: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Test Restaurant"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Add a Test Restaurant",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Restaurant Name *",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter restaurant name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description *",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: "Image URL",
                  border: OutlineInputBorder(),
                  hintText: "https://example.com/image.jpg",
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address *",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter address";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Cuisines
              TextFormField(
                controller: _cuisinesController,
                decoration: const InputDecoration(
                  labelText: "Cuisines * (comma separated)",
                  border: OutlineInputBorder(),
                  hintText: "Italian, Pizza, Pasta",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter at least one cuisine";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Delivery Fee
              TextFormField(
                controller: _deliveryFeeController,
                decoration: const InputDecoration(
                  labelText: "Delivery Fee",
                  border: OutlineInputBorder(),
                  hintText: "2.99",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Delivery Time
              TextFormField(
                controller: _deliveryTimeController,
                decoration: const InputDecoration(
                  labelText: "Delivery Time (minutes)",
                  border: OutlineInputBorder(),
                  hintText: "30",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Minimum Order
              TextFormField(
                controller: _minOrderController,
                decoration: const InputDecoration(
                  labelText: "Minimum Order Amount",
                  border: OutlineInputBorder(),
                  hintText: "15.00",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _addTestRestaurant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add Test Restaurant",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
