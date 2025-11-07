import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_field.dart';
import 'otp_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
const RegistrationScreen({super.key});

@override
State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final authService = AuthService();
  bool isLoading = false;
  bool verifyPhone = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (phone.isNotEmpty && phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number (at least 10 digits)')),
      );
      return;
    }

    if (verifyPhone && !phone.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must include country code (e.g., +91XXXXXXXXXX) for verification')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.signUpWithEmail(email, password);
      if (user != null && mounted) {
        // Update display name
        await user.updateDisplayName(nameController.text.trim());
        if (mounted) {
          if (verifyPhone && phone.isNotEmpty) {
            // Navigate to OTP verification
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(phoneNumber: phone),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful!')),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // void registerWithPhone() {
  //   // Temporarily disabled due to Firebase package callback issues
  //   // Will be re-enabled when Firebase Auth stabilizes
  // }

  // Future<void> signupWithGoogle() async {
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final user = await authService.signInWithGoogle();
  //     if (user != null && mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Google Sign-In Successful')),
  //       );
  //       Navigator.pushReplacementNamed(context, '/');
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
                  'Food App Registration\n(Phone Optional)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: nameController,
                  hintText: 'Full Name',
                  keyboardType: TextInputType.name,
                  prefixIcon: Icon(Icons.person, color: Colors.red),
                ),
                const SizedBox(height: 12),

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

                CustomTextField(
                  controller: phoneController,
                  hintText: verifyPhone ? 'Phone Number (e.g., +91XXXXXXXXXX)' : 'Phone Number (Optional)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone, color: Colors.red),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: verifyPhone,
                      onChanged: phoneController.text.trim().isEmpty ? null : (value) {
                        setState(() {
                          verifyPhone = value ?? false;
                        });
                      },
                      activeColor: Colors.red,
                    ),
                    Expanded(
                      child: Text(
                        phoneController.text.trim().isEmpty
                          ? 'Add phone number to enable OTP verification'
                          : 'Verify phone number with OTP (recommended)',
                        style: TextStyle(
                          fontSize: 14,
                          color: phoneController.text.trim().isEmpty ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Register'),
                      ),
                const SizedBox(height: 12),


                const SizedBox(height: 12),

                // Google Sign-In temporarily disabled due to package API changes
                // TODO: Re-enable when google_sign_in package stabilizes
                // isLoading
                //     ? const SizedBox()
                //     : ElevatedButton.icon(
                //         onPressed: signupWithGoogle,
                //         icon: Icon(Icons.g_mobiledata),
                //         label: const Text('Sign Up with Google'),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.white,
                //           foregroundColor: Colors.black,
                //           minimumSize: const Size(double.infinity, 50),
                //         ),
                //       ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Already have an account? Login'),
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