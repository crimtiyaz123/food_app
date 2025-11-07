import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/custom_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Form(
        key: _formKey,
        child: CustomTextField(
          controller: emailController,
          hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                return 'Please enter your email';
                }
                  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$");
                  if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email';
          }
          return null;
            },
            ),
            ),
            const SizedBox(height: 20),
            isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
              onPressed: sendResetEmail,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
               ),
                child: const Text('Send Reset Email'),
                ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}