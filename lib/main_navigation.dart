import 'package:flutter/material.dart';
import 'screens/settings_screen.dart';
import 'screens/restaurant_list_screen.dart';
import 'screens/favorites_screen.dart';

// ===================== MAIN NAVIGATION =====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // ✅ Shared cart list
  final List<String> cartItems = [];

  // Pages with restaurant browsing
  List<Widget> _pages() => [
        const RestaurantListScreen(),
        const FavoritesScreen(),
        const OrdersScreen(),
        CartScreen(cartItems: cartItems),
        const SettingsScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WazWaanGo'),
        backgroundColor: Colors.green,
      ),
      body: _pages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ===================== ORDERS SCREEN =====================
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('🧾 My Orders Page'));
  }
}

// ===================== CART SCREEN =====================
class CartScreen extends StatelessWidget {
  final List<String> cartItems;
  const CartScreen({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return const Center(child: Text('🛒 Cart is empty'));
    }

    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.orange),
            title: Text(cartItems[index]),
          ),
        );
      },
    );
  }
}
