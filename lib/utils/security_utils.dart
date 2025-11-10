import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Security utility class for handling sensitive operations
class SecurityUtils {
  static const String _kSecretKey = 'foodapp-secret-key-2024';
  
  /// Hash password using SHA-256 with salt
  static String hashPassword(String password, {String? salt}) {
    final saltString = salt ?? _generateSalt();
    final bytes = utf8.encode(password + saltString);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}:$saltString';
  }
  
  /// Verify password against hash
  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) return false;
      
      final storedHash = parts[0];
      final salt = parts[1];
      final computedHash = sha256.convert(utf8.encode(password + salt)).toString();
      
      return storedHash == computedHash;
    } catch (e) {
      debugPrint('Password verification error: $e');
      return false;
    }
  }
  
  /// Generate cryptographically secure random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (index) => random.nextInt(256));
    return base64.encode(saltBytes);
  }
  
  /// Encrypt sensitive data (for local storage)
  static String encryptData(String data) {
    try {
      // Simple XOR encryption for demo (use proper encryption in production)
      final key = utf8.encode(_kSecretKey);
      final dataBytes = utf8.encode(data);
      final encrypted = <int>[];
      
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ key[i % key.length]);
      }
      
      return base64.encode(encrypted);
    } catch (e) {
      debugPrint('Encryption error: $e');
      return data;
    }
  }
  
  /// Decrypt sensitive data
  static String decryptData(String encryptedData) {
    try {
      final key = utf8.encode(_kSecretKey);
      final encryptedBytes = base64.decode(encryptedData);
      final decrypted = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ key[i % key.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedData;
    }
  }
  
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+').hasMatch(email);
  }
  
  /// Validate password strength
  static Map<String, dynamic> validatePassword(String password) {
    final issues = <String>[];
    
    if (password.length < 8) {
      issues.add('Password must be at least 8 characters long');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('Password must contain at least one uppercase letter');
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('Password must contain at least one lowercase letter');
    }
    
    if (!RegExp(r'\d').hasMatch(password)) {
      issues.add('Password must contain at least one number');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      issues.add('Password must contain at least one special character');
    }
    
    return {
      'isValid': issues.isEmpty,
      'issues': issues,
    };
  }
}