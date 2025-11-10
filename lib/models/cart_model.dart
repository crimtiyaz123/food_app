import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/restaurant_order.dart';

// Item customization options
class ItemCustomization {
  final Map<String, dynamic> options; // e.g., {"spice_level": "medium", "extras": ["cheese"]}
  final double additionalPrice;
  
  ItemCustomization({required this.options, this.additionalPrice = 0.0});
}

// Membership levels
enum MembershipLevel { regular, gold, pro }

// Smart offers
class SmartOffer {
  final String id;
  final String title;
  final String description;
  final double discountAmount;
  final String offerType; // 'percentage', 'fixed', 'free_item'
  final List<String> applicableItemIds;
  final bool isActive;
  
  SmartOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.offerType,
    required this.applicableItemIds,
    this.isActive = true,
  });
}

// Upsell item
class UpsellItem {
  final Product product;
  final double discountPercentage;
  final String reason; // why this item is suggested
  
  UpsellItem({
    required this.product,
    required this.discountPercentage,
    required this.reason,
  });
}

class CartModel extends ChangeNotifier {
  final Map<Product, int> _items = {}; // item -> quantity
  final Map<Product, ItemCustomization?> _customizations = {}; // item -> customization
  final List<Order> _orders = [];
  String? _selectedRestaurantId;
  String? _deliveryAddress;
  String? _specialInstructions;
  String? _promoCode;
  double _deliveryFee = 0.0;
  
  // New features
  MembershipLevel _membershipLevel = MembershipLevel.regular;
  final List<SmartOffer> _availableOffers = [];
  final List<SmartOffer> _appliedOffers = [];
  final List<UpsellItem> _upsellSuggestions = [];
  String? _paymentMethod;
  bool _sendingNotes = true;
  final List<String> _activeCoupons = [];
  double _savingsAmount = 0.0;

  Map<Product, int> get items => _items;
  Map<Product, ItemCustomization?> get customizations => _customizations;
  List<Order> get orders => _orders;
  String? get selectedRestaurantId => _selectedRestaurantId;
  String? get deliveryAddress => _deliveryAddress;
  String? get specialInstructions => _specialInstructions;
  String? get promoCode => _promoCode;
  double get deliveryFee => _deliveryFee;
  MembershipLevel get membershipLevel => _membershipLevel;
  List<SmartOffer> get availableOffers => _availableOffers;
  List<SmartOffer> get appliedOffers => _appliedOffers;
  List<UpsellItem> get upsellSuggestions => _upsellSuggestions;
  String? get paymentMethod => _paymentMethod;
  bool get sendingNotes => _sendingNotes;
  List<String> get activeCoupons => _activeCoupons;
  double get savingsAmount => _savingsAmount;

// Enhanced item management with customizations
void addItem(Product item, {String? restaurantId, ItemCustomization? customization}) {
  // If cart is empty, set the restaurant
  if (_items.isEmpty && restaurantId != null) {
    _selectedRestaurantId = restaurantId;
    _loadSmartOffers();
    _generateUpsellSuggestions();
  }
  
  // If cart has items from a different restaurant, clear the cart
  if (_selectedRestaurantId != null && restaurantId != null &&
      _selectedRestaurantId != restaurantId) {
    _items.clear();
    _customizations.clear();
    _selectedRestaurantId = restaurantId;
    _loadSmartOffers();
    _generateUpsellSuggestions();
  }
  
  if (_items.containsKey(item)) {
    _items[item] = _items[item]! + 1;
  } else {
    _items[item] = 1;
    _customizations[item] = customization;
  }
  _calculateSavings();
  notifyListeners();
}

void updateItemQuantity(Product item, int newQuantity) {
  if (newQuantity <= 0) {
    removeItem(item);
  } else {
    _items[item] = newQuantity;
    _calculateSavings();
    notifyListeners();
  }
}

void removeItem(Product item) {
  if (_items.containsKey(item) && _items[item]! > 0) {
    _items[item] = _items[item]! - 1;
    if (_items[item] == 0) {
      _items.remove(item);
      _customizations.remove(item);
    }
    _calculateSavings();
    notifyListeners();
  }
}

void deleteItem(Product item) {
  _items.remove(item);
  _customizations.remove(item);
  _calculateSavings();
  notifyListeners();
}

void updateItemCustomization(Product item, ItemCustomization? customization) {
  _customizations[item] = customization;
  _calculateSavings();
  notifyListeners();
}

  // Enhanced setters for new features
  void setRestaurant(String restaurantId) {
    _selectedRestaurantId = restaurantId;
    _loadSmartOffers();
    _generateUpsellSuggestions();
    notifyListeners();
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setSpecialInstructions(String instructions) {
    _specialInstructions = instructions;
    notifyListeners();
  }

  void setPromoCode(String code) {
    _promoCode = code;
    _calculateSavings();
    notifyListeners();
  }

  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    notifyListeners();
  }

  void setMembershipLevel(MembershipLevel level) {
    _membershipLevel = level;
    _calculateSavings();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setSendingNotes(bool sending) {
    _sendingNotes = sending;
    notifyListeners();
  }

  void addCoupon(String couponCode) {
    if (!_activeCoupons.contains(couponCode)) {
      _activeCoupons.add(couponCode);
      _calculateSavings();
      notifyListeners();
    }
  }

  void removeCoupon(String couponCode) {
    _activeCoupons.remove(couponCode);
    _calculateSavings();
    notifyListeners();
  }

  void applyOffer(SmartOffer offer) {
    if (!_appliedOffers.contains(offer)) {
      _appliedOffers.add(offer);
      _calculateSavings();
      notifyListeners();
    }
  }

  void removeOffer(SmartOffer offer) {
    _appliedOffers.remove(offer);
    _calculateSavings();
    notifyListeners();
  }

  void addUpsellItem(Product product) {
    addItem(product);
  }

  // Smart features implementation
  void _loadSmartOffers() {
    _availableOffers.clear();
    
    // Sample offers based on membership level
    if (_membershipLevel == MembershipLevel.gold) {
      _availableOffers.addAll([
        SmartOffer(
          id: 'gold_10_percent',
          title: 'Gold Member 10% Off',
          description: 'Enjoy 10% discount on your entire order',
          discountAmount: 0.10,
          offerType: 'percentage',
          applicableItemIds: [],
        ),
        SmartOffer(
          id: 'free_delivery',
          title: 'Free Delivery',
          description: 'Free delivery on orders above \$20',
          discountAmount: _deliveryFee,
          offerType: 'fixed',
          applicableItemIds: [],
        ),
      ]);
    } else if (_membershipLevel == MembershipLevel.pro) {
      _availableOffers.addAll([
        SmartOffer(
          id: 'pro_15_percent',
          title: 'Pro Member 15% Off',
          description: 'Enjoy 15% discount on your entire order',
          discountAmount: 0.15,
          offerType: 'percentage',
          applicableItemIds: [],
        ),
        SmartOffer(
          id: 'free_delivery_pro',
          title: 'Free Delivery',
          description: 'Free delivery on all orders',
          discountAmount: _deliveryFee,
          offerType: 'fixed',
          applicableItemIds: [],
        ),
        SmartOffer(
          id: 'free_dessert',
          title: 'Free Dessert',
          description: 'Add any dessert for free',
          discountAmount: 5.0,
          offerType: 'free_item',
          applicableItemIds: ['dessert'],
        ),
      ]);
    } else {
      // Regular member offers
      _availableOffers.addAll([
        SmartOffer(
          id: 'first_order_20',
          title: 'First Order Discount',
          description: '20% off on your first order',
          discountAmount: 0.20,
          offerType: 'percentage',
          applicableItemIds: [],
        ),
        SmartOffer(
          id: 'free_delivery_25',
          title: 'Free Delivery',
          description: 'Free delivery on orders above \$25',
          discountAmount: _deliveryFee,
          offerType: 'fixed',
          applicableItemIds: [],
        ),
      ]);
    }
  }

  void _generateUpsellSuggestions() {
    _upsellSuggestions.clear();
    
    // Sample upsell items based on current cart
    // This would ideally be powered by AI recommendations
    _upsellSuggestions.addAll([
      UpsellItem(
        product: Product(
          id: 'upsell_1',
          name: 'Chocolate Brownie',
          price: 4.99,
          categoryId: 'desserts',
          description: 'Rich chocolate brownie with ice cream',
          imageUrl: 'assets/brownie.jpg',
          restaurantId: 'upsell_restaurant',
        ),
        discountPercentage: 25.0,
        reason: 'Perfect complement to your meal',
      ),
      UpsellItem(
        product: Product(
          id: 'upsell_2',
          name: 'Fresh Orange Juice',
          price: 3.99,
          categoryId: 'beverages',
          description: 'Freshly squeezed orange juice',
          imageUrl: 'assets/orange_juice.jpg',
          restaurantId: 'upsell_restaurant',
        ),
        discountPercentage: 15.0,
        reason: 'Great with spicy food',
      ),
      UpsellItem(
        product: Product(
          id: 'upsell_3',
          name: 'Garlic Bread',
          price: 2.99,
          categoryId: 'appetizers',
          description: 'Crispy garlic bread with herbs',
          imageUrl: 'assets/garlic_bread.jpg',
          restaurantId: 'upsell_restaurant',
        ),
        discountPercentage: 20.0,
        reason: 'Start your meal right',
      ),
    ]);
  }

  void _calculateSavings() {
    double savings = 0.0;
    
    // Add membership discounts
    if (_membershipLevel == MembershipLevel.gold) {
      savings += subtotal * 0.10; // 10% gold discount
    } else if (_membershipLevel == MembershipLevel.pro) {
      savings += subtotal * 0.15; // 15% pro discount
    }
    
    // Add applied offers
    for (final offer in _appliedOffers) {
      if (offer.offerType == 'percentage') {
        savings += subtotal * offer.discountAmount;
      } else if (offer.offerType == 'fixed') {
        savings += offer.discountAmount;
      }
    }
    
    // Add promo code discount
    if (_promoCode != null && _promoCode!.isNotEmpty) {
      savings += discountAmount;
    }
    
    // Add upsell item discounts (if they're in the cart)
    for (final upsell in _upsellSuggestions) {
      if (_items.containsKey(upsell.product)) {
        final itemTotal = upsell.product.price * _items[upsell.product]!;
        savings += itemTotal * (upsell.discountPercentage / 100);
      }
    }
    
    _savingsAmount = savings;
  }

  double get subtotal {
    double total = 0.0;
    _items.forEach((product, qty) {
      total += product.price * qty;
    });
    return total;
  }

  double get discountAmount {
    if (_promoCode != null && _promoCode!.isNotEmpty) {
      // Simple 10% discount for demo
      return subtotal * 0.1;
    }
    return 0.0;
  }

  double get gstAmount => (subtotal - discountAmount) * 0.18; // 18% GST

  double get totalAmount => subtotal - discountAmount + gstAmount + _deliveryFee;

  // Backward compatibility
  double get totalWithGst => totalAmount;

  void placeOrder() {
    if (_selectedRestaurantId == null || _deliveryAddress == null) {
      throw Exception('Restaurant and delivery address must be selected');
    }

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final orderDate = DateTime.now();

    // Create order items
    final orderItems = _items.entries.map((entry) {
      return OrderItem(
        product: entry.key,
        quantity: entry.value,
        price: entry.key.price,
      );
    }).toList();

    // Create restaurant order
    final restaurantOrder = RestaurantOrder(
      id: orderId,
      customerId: 'current_user_id', // TODO: Get from auth
      customerName: 'Current User', // TODO: Get from user profile
      items: orderItems,
      totalAmount: totalAmount,
      status: 'pending',
      orderTime: orderDate,
      deliveryAddress: _deliveryAddress!,
      paymentMethod: 'card', // TODO: Get from payment
      specialInstructions: _specialInstructions ?? '',
      deliveryFee: _deliveryFee,
    );

    // TODO: Save to Firestore
    // For now, just create local orders for display
    _items.forEach((item, qty) {
      final totalPrice = item.price * qty;
      _orders.add(Order(
        id: orderId,
        product: item,
        quantity: qty,
        date: orderDate,
        totalPrice: totalPrice,
        status: 'pending',
      ));
    });

    _items.clear();
    notifyListeners();
  }

  void rateOrder(int index, double rating) {
    if (index >= 0 && index < _orders.length) {
      _orders[index].rating = rating;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedRestaurantId = null;
    _deliveryAddress = null;
    _specialInstructions = null;
    _promoCode = null;
    _deliveryFee = 0.0;
    notifyListeners();
  }
}
