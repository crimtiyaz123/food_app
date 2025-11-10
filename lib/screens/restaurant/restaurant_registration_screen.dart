import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../models/restaurant_owner.dart';
import '../../services/restaurant_owner_service.dart';

class RestaurantRegistrationScreen extends StatefulWidget {
  const RestaurantRegistrationScreen({super.key});

  @override
  State<RestaurantRegistrationScreen> createState() => _RestaurantRegistrationScreenState();
}

class _RestaurantRegistrationScreenState extends State<RestaurantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final RestaurantOwnerService _service = RestaurantOwnerService();

  // Owner fields
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _businessLicenseController = TextEditingController();

  // Restaurant fields
  final _restaurantNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cuisinesController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _minOrderController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _businessLicenseController.dispose();
    _restaurantNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cuisinesController.dispose();
    _deliveryFeeController.dispose();
    _deliveryTimeController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _registerRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create restaurant owner
      final ownerId = DateTime.now().millisecondsSinceEpoch.toString();
      final owner = RestaurantOwner(
        id: ownerId,
        name: _ownerNameController.text,
        email: _ownerEmailController.text,
        phone: _ownerPhoneController.text,
        restaurantId: '', // Will be set after restaurant creation
        businessLicense: _businessLicenseController.text,
      );

      // Create restaurant
      final restaurantId = DateTime.now().millisecondsSinceEpoch.toString() + '_restaurant';
      final restaurant = Restaurant(
        id: restaurantId,
        name: _restaurantNameController.text,
        description: _descriptionController.text,
        imageUrl: '', // TODO: Add image upload
        address: _addressController.text,
        phone: _phoneController.text,
        rating: 0.0,
        reviewCount: 0,
        cuisines: _cuisinesController.text.split(',').map((c) => c.trim()).toList(),
        isOpen: true,
        deliveryFee: double.parse(_deliveryFeeController.text),
        deliveryTime: int.parse(_deliveryTimeController.text),
        minOrder: double.parse(_minOrderController.text),
      );

      // Register owner and create restaurant
      await _service.registerRestaurantOwner(owner);
      await _service.createRestaurant(restaurant, ownerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant registered successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Restaurant'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Owner Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessLicenseController,
                decoration: const InputDecoration(
                  labelText: 'Business License Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              const Text(
                'Restaurant Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _restaurantNameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cuisinesController,
                decoration: const InputDecoration(
                  labelText: 'Cuisines (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'Italian, Pizza, Pasta',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Fee',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _minOrderController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Order Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerRestaurant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register Restaurant', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}