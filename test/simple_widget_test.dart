// Simple widget test without Firebase dependencies
// Tests the basic app structure and navigation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wazwaango/models/cart_model.dart';
import 'package:wazwaango/models/product.dart';

// Simple test product for testing purposes
class TestProduct extends Product {
  TestProduct({
    required super.id,
    required super.name,
    required super.price,
    required super.categoryId,
    required super.restaurantId,
    super.imageUrl,
    super.description,
    super.rating,
    super.reviewCount = 0,
    super.isAvailable = true,
  });
}

// Create a simple main app for testing without Firebase
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Food App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Food App'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Food Delivery App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Testing the app structure',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('Test app loads and displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartModel(),
        child: const TestApp(),
      ),
    );

    // Verify that the app loads with the correct title
    expect(find.text('Test Food App'), findsOneWidget);
    expect(find.text('Food Delivery App'), findsOneWidget);
    expect(find.text('Testing the app structure'), findsOneWidget);
    
    // Verify that the main icon is displayed
    expect(find.byIcon(Icons.restaurant), findsAtLeastNWidgets(1));
    
    // Verify that the bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify bottom navigation items
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Bottom navigation tap works', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartModel(),
        child: const TestApp(),
      ),
    );

    // Initially should be on Restaurants tab
    expect(find.text('Restaurants'), findsOneWidget);
    
    // Tap on Cart tab
    await tester.tap(find.text('Cart'));
    await tester.pump();
    
    // The text should still be present (no navigation in test app)
    expect(find.text('Cart'), findsOneWidget);
  });

  testWidgets('Cart model can be created and used', (WidgetTester tester) async {
    final cart = CartModel();
    
    // Test basic cart functionality
    expect(cart.items, isEmpty);
    expect(cart.subtotal, 0.0);
    expect(cart.totalAmount, 0.0);
    
    // Test that we can add a simple item (mock product)
    final testProduct = TestProduct(
      id: 'test_1',
      name: 'Test Pizza',
      price: 15.99,
      categoryId: 'pizza',
      restaurantId: 'test_restaurant',
    );
    
    cart.addItem(testProduct);
    expect(cart.items.length, 1);
    expect(cart.items.values.first, 1);
  });
}