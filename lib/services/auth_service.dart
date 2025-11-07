import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- Email & Password ----------------

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp Error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('SignUp Error: $e');
      return null;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login Error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
  
  Future<void> Test() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Password Reset Error: $e');
    }
  }

  // ---------------- Google Sign-In ----------------

  Future<User?> signInWithGoogle() async {
    try {
      // For now, disable Google Sign-In due to API changes
      // This would need to be updated when the package stabilizes
      debugPrint('Google Sign-In temporarily disabled due to package API changes');
      return null;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  // ---------------- Phone Authentication ----------------

  Future<String?> sendOTP(String phoneNumber) async {
    try {
      String? verificationId;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          throw e;
        },
        codeSent: (String verId, int? resendToken) {
          debugPrint('OTP sent successfully');
          verificationId = verId;
        },
        codeAutoRetrievalTimeout: (String verId) {
          debugPrint('Timeout reached');
          verificationId = verId;
        },
      );
      return verificationId;
    } catch (e) {
      debugPrint('Send OTP Error: $e');
      return null;
    }
  }

  Future<User?> verifyOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Verify OTP Error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      return null;
    }
  }

}