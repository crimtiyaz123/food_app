import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

/// Enhanced error handling and logging utility
class AppLogger {
  static const String _tag = 'FoodApp';
  static bool _isDebugMode = kDebugMode;
  
  /// Log debug messages (only in debug mode)
  static void debug(String message) {
    if (_isDebugMode) {
      _log('DEBUG', message);
    }
  }
  
  /// Log info messages
  static void info(String message) {
    _log('INFO', message);
  }
  
  /// Log warning messages
  static void warning(String message) {
    _log('WARNING', message);
  }
  
  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }
  
  /// Log API calls for debugging
  static void apiCall(String method, String url, {int? statusCode, String? response}) {
    final buffer = StringBuffer();
    buffer.writeln('API Call: $method $url');
    if (statusCode != null) buffer.writeln('Status: $statusCode');
    if (response != null && _isDebugMode) buffer.writeln('Response: $response');
    debug(buffer.toString());
  }
  
  static void _log(String level, String message, {dynamic error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message';
    
    if (_isDebugMode) {
      print(logMessage);
      if (error != null) print('Error: $error');
      if (stackTrace != null) print(stackTrace);
    }
    
    // In production, send logs to crash reporting service
    if (!_isDebugMode) {
      // TODO: Implement crash reporting (e.g., Firebase Crashlytics)
    }
  }
}

/// App exception types for better error handling
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError}) 
    : super(message, code: code, originalError: originalError);
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic originalError}) 
    : super(message, code: code, originalError: originalError);
}

/// API response wrapper for better error handling
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final int? statusCode;
  
  const ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.statusCode,
  });
  
  factory ApiResponse.success({T? data, int? statusCode}) {
    return ApiResponse._(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }
  
  factory ApiResponse.error(String error, {String? code, int? statusCode}) {
    return ApiResponse._(
      success: false,
      error: error,
      errorCode: code,
      statusCode: statusCode,
    );
  }
  
  /// Check if this is a network-related error
  bool get isNetworkError {
    return !success && (statusCode == null || statusCode! >= 500);
  }
  
  /// Check if this is an authentication error
  bool get isAuthError {
    return !success && (statusCode == 401 || statusCode == 403);
  }
}

/// Global error handler for the app
class GlobalErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    AppLogger.error('Global error occurred', error, stackTrace);
    
    if (error is SocketException) {
      AppLogger.warning('Network connectivity issue');
      // Could show network error dialog
    } else if (error is TimeoutException) {
      AppLogger.warning('Request timeout');
      // Could show timeout dialog
    } else if (error is AuthException) {
      AppLogger.warning('Authentication error: ${error.message}');
      // Could trigger logout or show auth dialog
    } else if (error is NetworkException) {
      AppLogger.warning('Network error: ${error.message}');
      // Could show network error dialog
    }
  }
}