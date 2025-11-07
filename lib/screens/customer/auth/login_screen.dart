import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_field.dart';
import 'otp_verification_screen.dart';
// ✅ add this line to fix OTP error
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final authService = AuthService();
  bool isLoading = false;
  bool isPhoneLogin = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isPhoneLogin) {
      final phone = phoneController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter phone number')),
        );
        return;
      }
      if (!phone.startsWith('+')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must include country code (e.g., +91XXXXXXXXXX)')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(phoneNumber: phone),
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
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
        Navigator.pushReplacementNamed(context, '/');
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



  Future<void> loginWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final user = await authService.signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In Successful')),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0x80FFFFFF), // Semi-transparent white overlay
          image: DecorationImage(
            image: NetworkImage('https://www.precisionorthomd.com/wp-content/uploads/2023/10/percision-blog-header-junk-food-102323.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
              children: [
                Icon(Icons.restaurant, size: 60, color: Colors.green),
                const SizedBox(height: 10),
                const Text(
                  'Food App Login',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 20),

                if (!isPhoneLogin) ...[
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email, color: Colors.red),
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    prefixIcon: Icon(Icons.lock, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Phone Number (e.g., +91XXXXXXXXXX)',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icon(Icons.phone, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],


                const SizedBox(height: 20),

                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isPhoneLogin ? 'Send OTP' : 'Login'),
                      ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    setState(() {
                      isPhoneLogin = !isPhoneLogin;
                      emailController.clear();
                      passwordController.clear();
                      phoneController.clear();
                    });
                  },
                  child: Text(
                    isPhoneLogin ? 'Login with Email & Password' : 'Login with Phone OTP',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),


                isLoading
                    ? const SizedBox()
                    : ElevatedButton.icon(
                        onPressed: loginWithGoogle,
                        label: const Text('Login with Google'),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text('Forgot Password?'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
