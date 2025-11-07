import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _auth = FirebaseAuth.instance;
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;

  int _resendCooldown = 30;
  bool _canResend = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    // Validate phone number format
    if (!widget.phoneNumber.startsWith('+')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must include country code (e.g., +91XXXXXXXXXX)')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    debugPrint('Sending OTP to: ${widget.phoneNumber}');

    // Simple OTP sending without complex callbacks
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto verification - just log for now
        debugPrint('Auto verification completed');
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('Verification failed: ${e.message}');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.message}')),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('OTP sent successfully');
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent! Check SMS')),
          );
          _startResendCooldown();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Timeout reached');
        if (mounted) {
          _verificationId = verificationId;
          setState(() => _isLoading = false);
        }
      },
    ).catchError((error) {
      debugPrint('OTP send error: $error');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    });
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for OTP first')),
      );
      return;
    }

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    await _auth.signInWithCredential(credential).then((result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Success!')),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
    }).catchError((error) {
      debugPrint('Verification error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP')),
        );
      }
    }).whenComplete(() {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOtpFilled = _otpController.text.trim().isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.white,
              Colors.red.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo and welcome text
                Center(
                  child: Column(
                    children: [
                      // Zomato-style logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.orange.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade200,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verify Your Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the code sent to ${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // OTP form card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // OTP field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            counterText: '',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isOtpFilled && !_isLoading ? _verifyOTP : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: Colors.transparent,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Resend button
                      TextButton(
                        onPressed: _canResend ? _sendOTP : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                        child: _canResend
                            ? Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              )
                            : Text(
                                'Resend in $_resendCooldown s',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
