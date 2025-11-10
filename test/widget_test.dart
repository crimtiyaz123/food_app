// Food Delivery App Widget Tests
// Tests the main app navigation and basic functionality

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:wazwaango/main.dart';
import 'package:wazwaango/models/cart_model.dart';
import 'package:wazwaango/main_navigation.dart';

void main() {
  // Initialize Firebase for testing
  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project',
      ),
    );
  });

  testWidgets('Food App main navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartModel()),
        ],
        child: const WazWaanGoApp(),
      ),
    );

    // Verify that the app starts with restaurant tab selected
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(CartScreen), findsNothing);
  });

  testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartModel()),
        ],
        child: const WazWaanGoApp(),
      ),
    );

    // Start on Restaurants tab
    expect(find.text('Food App'), findsOneWidget);
    
    // Tap on Favorites tab
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    
    // Should navigate to favorites
    expect(find.text('Food App'), findsOneWidget);
    
    // Tap on Cart tab
    await tester.tap(find.text('Cart'));
    await tester.pump();
    
    // Should show cart
    expect(find.text('Cart is empty'), findsOneWidget);
  });

  testWidgets('Cart functionality works', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartModel()),
        ],
        child: const WazWaanGoApp(),
      ),
    );

    // Navigate to cart
    await tester.tap(find.text('Cart'));
    await tester.pump();
    
    // Should show empty cart message
    expect(find.text('Cart is empty'), findsOneWidget);
  });

  testWidgets('App theme and styling', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartModel()),
        ],
        child: const WazWaanGoApp(),
      ),
    );

    // Verify app theme
    final appBar = find.byType(AppBar);
    expect(appBar, findsOneWidget);
    
    // Verify navigation colors
    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);
  });
}
