import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_field.dart';
import 'home_screen.dart';
import 'auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.loginWithEmail(email, password);
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Future<void> loginWithGoogle() async {
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final user = await authService.signInWithGoogle();
  //     if (user != null && mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Google Sign-In Successful')),
  //       );
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Google Sign-In failed')),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => isLoading = false);
  //     }
  // }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 12),

                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 12),


                const SizedBox(height: 12),



                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: 12),

                // Google Sign-In temporarily disabled due to package API changes
                // TODO: Re-enable when google_sign_in package stabilizes
                // ElevatedButton.icon(
                //   onPressed: loginWithGoogle,
                //   icon: Icon(Icons.g_mobiledata),
                //   label: const Text('Login with Google'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.white,
                //     foregroundColor: Colors.black,
                //     minimumSize: const Size(double.infinity, 50),
                //   ),
                // ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                      Navigator.pushNamed(context, '/registration');
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}