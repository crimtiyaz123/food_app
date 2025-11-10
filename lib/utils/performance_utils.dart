import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Performance optimization utilities
class PerformanceUtils {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Queue<Function> _taskQueue = Queue<Function>();
  static bool _isProcessing = false;
  
  /// Start timing a function
  static void startTimer(String label) {
    _stopwatches[label] = Stopwatch()..start();
  }
  
  /// End timing and log the result
  static void endTimer(String label) {
    final stopwatch = _stopwatches.remove(label);
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      if (kDebugMode) {
        print('$label took ${duration}ms');
      }
    }
  }
  
  /// Debounce function calls
  static Map<String, Timer> _debounceTimers = {};
  
  static void debounce(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }
  
  /// Throttle function calls
  static Map<String, DateTime> _lastExecution = {};
  
  static bool throttle(String key, {Duration delay = const Duration(milliseconds: 1000)}) {
    final now = DateTime.now();
    final lastExec = _lastExecution[key];
    
    if (lastExec == null || now.difference(lastExec) > delay) {
      _lastExecution[key] = now;
      return true;
    }
    return false;
  }
  
  /// Process tasks in queue to avoid UI blocking
  static Future<void> processTaskQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      try {
        await task();
      } catch (e, stackTrace) {
        debugPrint('Error processing task: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
      // Yield to the event loop to keep UI responsive
      await Future.delayed(const Duration(milliseconds: 1));
    }
    
    _isProcessing = false;
  }
  
  /// Add task to queue
  static void queueTask(Function task) {
    _taskQueue.add(task);
    processTaskQueue();
  }
  
  /// Batch updates to reduce rebuilds
  static void batchUpdates(VoidCallback updates, {String? label}) {
    if (label != null) startTimer('batch_$label');
    final Watchdog watchdog = Watchdog(timeout: const Duration(seconds: 5));
    updates();
    watchdog.stop();
    if (label != null) endTimer('batch_$label');
  }
}

/// Memory-efficient image caching
class ImageCacheManager {
  static const int _maxCacheSize = 50; // Limit cached images
  
  static final Map<String, List<int>> _imageCache = {};
  static final Queue<String> _lruQueue = Queue<String>();
  
  /// Cache image data with LRU eviction
  static void cacheImage(String key, List<int> data) {
    if (_imageCache.length >= _maxCacheSize) {
      final removedKey = _lruQueue.removeFirst();
      _imageCache.remove(removedKey);
    }
    
    _imageCache[key] = data;
    _lruQueue.add(key);
  }
  
  /// Get cached image
  static List<int>? getCachedImage(String key) {
    final data = _imageCache[key];
    if (data != null) {
      // Move to end (most recently used)
      _lruQueue.remove(key);
      _lruQueue.add(key);
    }
    return data;
  }
  
  /// Clear cache
  static void clearCache() {
    _imageCache.clear();
    _lruQueue.clear();
  }
}

/// Memory watchdog to detect long-running operations
class Watchdog {
  final DateTime _startTime;
  final Duration _timeout;
  final Timer? _timer;
  
  Watchdog({required Duration timeout})
    : _startTime = DateTime.now(),
      _timeout = timeout,
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (DateTime.now().difference(DateTime.now()).inMilliseconds > timeout.inMilliseconds) {
          final duration = DateTime.now().difference(DateTime.now());
          debugPrint('Watchdog: Operation took ${duration.inMilliseconds}ms (timeout: ${timeout.inMilliseconds}ms)');
        }
      });
  
  void stop() {
    _timer?.cancel();
  }
}

/// Database connection pooling
class ConnectionPool {
  static const int _maxConnections = 10;
  static int _activeConnections = 0;
  static final Queue<Function> _waitingQueue = Queue<Function>();
  
  static Future<T> execute<T>(Future<T> Function() operation) async {
    if (_activeConnections < _maxConnections) {
      _activeConnections++;
      try {
        return await operation();
      } finally {
        _activeConnections--;
        _processWaitingQueue();
      }
    } else {
      return _waitAndExecute<T>(operation);
    }
  }
  
  static Future<T> _waitAndExecute<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _waitingQueue.add(() async {
      try {
        completer.complete(await operation());
      } catch (e) {
        completer.completeError(e);
      } finally {
        _activeConnections--;
        _processWaitingQueue();
      }
    });
    
    return completer.future;
  }
  
  static void _processWaitingQueue() {
    while (_activeConnections < _maxConnections && _waitingQueue.isNotEmpty) {
      final task = _waitingQueue.removeFirst();
      _activeConnections++;
      task();
    }
  }
  
  static int get activeConnections => _activeConnections;
  static int get waitingQueueLength => _waitingQueue.length;
}

/// Memory leak detector (for development)
class MemoryLeakDetector {
  static final Set<String> _allocated = {};
  static final Set<String> _freed = {};
  
  static void trackAllocation(String id) {
    if (kDebugMode) {
      _allocated.add(id);
    }
  }
  
  static void trackDeallocation(String id) {
    if (kDebugMode) {
      _freed.add(id);
    }
  }
  
  static void checkMemoryLeaks() {
    if (kDebugMode) {
      final leaks = _allocated.difference(_freed);
      if (leaks.isNotEmpty) {
        debugPrint('Potential memory leaks detected: $leaks');
      }
    }
  }
}