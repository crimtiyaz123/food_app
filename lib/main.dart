import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_stripe/flutter_stripe.dart'; // Temporarily commented

// Theme
import 'theme/app_theme.dart';

// Models
import 'models/cart_model.dart';

// Navigation
import 'main_navigation.dart';

// Auth Wrapper
import 'widgets/auth_wrapper.dart';

// Screens
import 'screens/customer/auth/login_screen.dart';
import 'screens/customer/auth/signup_screen.dart';

// Firebase options
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Stripe for production (commented to prevent crashes)
  // Stripe.publishableKey = const String.fromEnvironment(
  //   'STRIPE_PUBLISHABLE_KEY',
  //   defaultValue: 'pk_test_your_key_here',
  // );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
      ],
      child: const WazWaanGoApp(),
    ),
  );
}

class WazWaanGoApp extends StatelessWidget {
  const WazWaanGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WazWaanGo (WWG)',
      theme: AppTheme.darkThemeData,
      
      // Use auth wrapper to handle authentication flow
      home: const AuthWrapper(),

      // Define all routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        // '/forgot-password': (context) => const ForgotPasswordScreen(),
        // '/otp-verification': (context) => OTPVerificationScreen(
        //       phoneNumber: ModalRoute.of(context)!.settings.arguments as String,
        //     ),
      },
    );
  }
}
