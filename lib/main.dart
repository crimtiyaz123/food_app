import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:food_app/screens/customer/auth/login_screen.dart';
import 'package:food_app/screens/customer/home_screen.dart';
import 'package:food_app/screens/customer/auth/signup_screen.dart' as signup;
import 'package:food_app/screens/customer/auth/forgot_password_screen.dart';
import 'package:food_app/screens/customer/auth/otp_verification_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const FoodApp());
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery App - Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const signup.RegistrationScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/otp-verification': (context) => OTPVerificationScreen(phoneNumber: ModalRoute.of(context)!.settings.arguments as String),
      },
    );
  }
}