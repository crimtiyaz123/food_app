import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wazwaango/models/User.dart';
import 'package:wazwaango/services/firestore_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirestoreService<User> _firestore = FirestoreService<User>(
    collectionPath: 'users',
    fromMap: (data, documentId) => User.fromJson(data, documentId),
  );

  // ---------------- Email & Password ----------------

  Future<firebase_auth.User?> signUpWithEmail(RegistrationUser user) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: user.personalInfo.email,
        password: user.personalInfo.password,
      );

        await _firestore.addDocument(user.toJson(), docId: result.user?.uid);

      return result.user;

    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('SignUp Error [${e.code}]: ${e.message}');
      return null;

    } catch (e) {
      debugPrint('SignUp Error: $e');
      return null;
    }
  }

  Future<firebase_auth.User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
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
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) {
          debugPrint('Auto verification completed');
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
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

  Future<firebase_auth.User?> verifyOTP(String verificationId, String smsCode) async {
    try {
      firebase_auth.PhoneAuthCredential credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Verify OTP Error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      return null;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Change Password Error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Change Password Error: $e');
      return false;
    }
  }

}