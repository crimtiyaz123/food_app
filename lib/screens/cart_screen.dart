import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import 'payment_screen.dart';
import 'address_screen.dart';
import 'restaurant_detail_screen.dart';
import '../models/restaurant.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _couponController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _validateAndProceedToPayment(BuildContext context, CartModel cartModel) {
    if (cartModel.selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a restaurant first")),
      );
      return;
    }

    if (cartModel.deliveryAddress == null) {
      // Show dialog to add address
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delivery Address Required"),
            content: const Text("Please add your delivery address before placing an order."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressScreen(autoPopulateFromFirestore: true),
                    ),
                  ).then((result) {
                    if (result == true) {
                      setState(() {});
                    }
                  });
                },
                child: const Text("Add Address"),
              ),
            ],
          );
        },
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PaymentScreen()),
    );
  }

  void _showEditItemDialog(Product product, int currentQuantity) {
    _quantityController.text = currentQuantity.toString();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Adjust Quantity:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      int current = int.parse(_quantityController.text);
                      if (current > 1) {
                        _quantityController.text = (current - 1).toString();
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      int current = int.parse(_quantityController.text);
                      _quantityController.text = (current + 1).toString();
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQuantity = int.parse(_quantityController.text);
                Provider.of<CartModel>(context, listen: false)
                    .updateItemQuantity(product, newQuantity);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomizationDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Customize ${product.name}'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customization options would be here'),
              Text('This is a placeholder for item customization features'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply customization
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showOfferDetails(SmartOffer offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(offer.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer.description),
              const SizedBox(height: 16),
              Text('Discount: ${offer.offerType == 'percentage' ? '${(offer.discountAmount * 100).toInt()}%' : '\$${offer.discountAmount.toStringAsFixed(2)}'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<CartModel>(context, listen: false).applyOffer(offer);
                Navigator.pop(context);
              },
              child: const Text('Apply Offer'),
            ),
          ],
        );
      },
    );
  }

  void _showCouponDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Apply Coupon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your coupon code:'),
              const SizedBox(height: 16),
              TextField(
                controller: _couponController,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_couponController.text.isNotEmpty) {
                  Provider.of<CartModel>(context, listen: false)
                      .setPromoCode(_couponController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon applied successfully!')),
                  );
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodDialog() {
    final paymentMethods = ['UPI', 'Credit Card', 'Debit Card', 'PayPal', 'Apple Pay', 'Google Pay'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: paymentMethods
                .map((method) => RadioListTile<String>(
                      title: Text(method),
                      value: method,
                      groupValue: Provider.of<CartModel>(context).paymentMethod,
                      onChanged: (value) {
                        Provider.of<CartModel>(context, listen: false)
                            .setPaymentMethod(value!);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = context.watch<CartModel>();
    final cart = cartModel.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Your Cart"),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              onPressed: () => cartModel.clearCart(),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Add some delicious items to get started!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Smart Offers Section
                        if (cartModel.availableOffers.isNotEmpty) ...[
                          _buildSmartOffersSection(cartModel),
                          const Divider(),
                        ],

                        // Selected Items List
                        _buildItemsList(cartModel, cart),

                        // Savings Highlight
                        if (cartModel.savingsAmount > 0) ...[
                          const Divider(),
                          _buildSavingsBanner(cartModel),
                          const Divider(),
                        ],

                        // Upsell Suggestions
                        if (cartModel.upsellSuggestions.isNotEmpty) ...[
                          _buildUpsellSection(cartModel),
                          const Divider(),
                        ],

                        // Order Notes & Preferences
                        _buildNotesSection(cartModel),

                        // Coupon & Payment Section
                        _buildCouponPaymentSection(cartModel),

                        const SizedBox(height: 100), // Space for sticky bar
                      ],
                    ),
                  ),
                ),
              ],
            ),
      // Sticky Summary Bar
      bottomSheet: cart.isEmpty ? null : _buildStickySummaryBar(cartModel),
    );
  }

  Widget _buildSmartOffersSection(CartModel cartModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.amber[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Smart Offers Available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...cartModel.availableOffers.map((offer) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.percent, color: Colors.green),
                  title: Text(offer.title),
                  subtitle: Text(offer.description),
                  trailing: ElevatedButton(
                    onPressed: () => _showOfferDetails(offer),
                    child: const Text('View'),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSavingsBanner(CartModel cartModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Row(
        children: [
          const Icon(Icons.savings, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You Saved!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '\$${cartModel.savingsAmount.toStringAsFixed(2)} in total savings',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(CartModel cartModel, Map<Product, int> cart) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...cart.entries.map((entry) {
            final product = entry.key;
            final qty = entry.value;
            final customization = cartModel.customizations[product];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Product Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: product.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(product.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey[200],
                          ),
                          child: product.imageUrl == null
                              ? const Icon(Icons.fastfood, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (product.description != null)
                                Text(
                                  product.description!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${product.price.toStringAsFixed(2)} each',
                                style: const TextStyle(color: Colors.green),
                              ),
                              if (customization != null)
                                Text(
                                  'Customized (+${customization.additionalPrice.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Quantity Controls
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => cartModel.removeItem(product),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  iconSize: 20,
                                ),
                                Text(
                                  qty.toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  onPressed: () => cartModel.addItem(product),
                                  icon: const Icon(Icons.add_circle_outline),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                            Text(
                              '\$${(product.price * qty + (customization?.additionalPrice ?? 0) * qty).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showEditItemDialog(product, qty),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showCustomizationDialog(product),
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('Customize'),
                        ),
                        TextButton.icon(
                          onPressed: () => cartModel.deleteItem(product),
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          label: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUpsellSection(CartModel cartModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Recommended for You',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cartModel.upsellSuggestions.length,
              itemBuilder: (context, index) {
                final upsell = cartModel.upsellSuggestions[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            image: upsell.product.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(upsell.product.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey[200],
                          ),
                          child: upsell.product.imageUrl == null
                              ? const Icon(Icons.fastfood, color: Colors.grey)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upsell.product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${upsell.product.price.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${upsell.discountPercentage}% off',
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => cartModel.addUpsellItem(upsell.product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  minimumSize: const Size(double.infinity, 32),
                                ),
                                child: const Text('Add', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(CartModel cartModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Special Instructions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text('Send to restaurant'),
                  Switch(
                    value: cartModel.sendingNotes,
                    onChanged: cartModel.setSendingNotes,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add special instructions (e.g., spice level, allergies)...',
              border: OutlineInputBorder(),
            ),
            onChanged: cartModel.setSpecialInstructions,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              // Navigate to menu to add more items
              Navigator.pushNamed(context, '/menu');
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add More Items'),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponPaymentSection(CartModel cartModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Coupons Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.purple),
              title: const Text('Coupons & Offers'),
              subtitle: Text(
                cartModel.activeCoupons.isNotEmpty
                    ? '${cartModel.activeCoupons.length} coupon(s) applied'
                    : 'Apply coupons to save more',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showCouponDialog,
            ),
          ),
          const SizedBox(height: 8),
          // Payment Method Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue),
              title: const Text('Payment Method'),
              subtitle: Text(
                cartModel.paymentMethod ?? 'Select payment method',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showPaymentMethodDialog,
            ),
          ),
          const SizedBox(height: 16),
          // Support Chat
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Need Help?'),
              subtitle: const Text('Chat with our support team'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/customer-support');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickySummaryBar(CartModel cartModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${cartModel.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (cartModel.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text(
                          '-\$${cartModel.discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST (18%):'),
                      Text('\$${cartModel.gstAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (cartModel.deliveryFee > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee:'),
                        Text('\$${cartModel.deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  if (cartModel.savingsAmount > 0) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Savings:',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text(
                          '-\$${cartModel.savingsAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${cartModel.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _validateAndProceedToPayment(context, cartModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
