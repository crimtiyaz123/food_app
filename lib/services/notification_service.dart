import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // TODO: Add Firebase Messaging package
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // TODO: Uncomment when package is added

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    // TODO: Uncomment when Firebase Messaging package is added
    /*
    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Store token in Firestore for the current user
      // TODO: Associate with current user
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    */
  }

  // Send notification to user
  Future<void> sendNotificationToUser(
    String userId,
    String title,
    String message,
    NotificationType type, {
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('notifications').add(notification.toJson());

    // Send push notification
    await _sendPushNotification(userId, title, message, data);
  }

  // Send push notification via FCM
  Future<void> _sendPushNotification(
    String userId,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) async {
    // Get user's FCM token
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final token = userDoc.data()?['fcmToken'];

    if (token != null) {
      // In production, send via Firebase Cloud Functions or your backend
      // For now, we'll just log it
      print('Sending push notification to token: $token');
      print('Title: $title');
      print('Message: $message');
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Get notification preferences
  Future<NotificationPreferences> getNotificationPreferences(String userId) async {
    final doc = await _firestore.collection('notificationPreferences').doc(userId).get();
    if (doc.exists) {
      return NotificationPreferences.fromJson(userId, doc.data()!);
    }
    return NotificationPreferences(userId: userId);
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences(NotificationPreferences preferences) async {
    await _firestore
        .collection('notificationPreferences')
        .doc(preferences.userId)
        .set(preferences.toJson());
  }

  // Send order status update notification
  Future<void> sendOrderStatusUpdate(
    String userId,
    String orderId,
    String status,
  ) async {
    final preferences = await getNotificationPreferences(userId);
    if (!preferences.orderUpdates) return;

    await sendNotificationToUser(
      userId,
      'Order Update',
      'Your order #$orderId is now $status',
      NotificationType.orderUpdate,
      data: {'orderId': orderId, 'status': status},
    );
  }

  // Send delivery update notification
  Future<void> sendDeliveryUpdate(
    String userId,
    String orderId,
    String message,
  ) async {
    final preferences = await getNotificationPreferences(userId);
    if (!preferences.deliveryUpdates) return;

    await sendNotificationToUser(
      userId,
      'Delivery Update',
      message,
      NotificationType.deliveryUpdate,
      data: {'orderId': orderId},
    );
  }

  // Send promotional notification
  Future<void> sendPromotion(
    String userId,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) async {
    final preferences = await getNotificationPreferences(userId);
    if (!preferences.promotions) return;

    await sendNotificationToUser(
      userId,
      title,
      message,
      NotificationType.promotion,
      data: data,
    );
  }

  // Update FCM token for user
  Future<void> updateFCMToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'lastTokenUpdate': Timestamp.now(),
    });
  }

  // Handle incoming messages when app is in foreground
  void setupForegroundMessageHandler(Function(dynamic) onMessage) {
    // TODO: Uncomment when Firebase Messaging package is added
    // FirebaseMessaging.onMessage.listen(onMessage);
  }

  // Handle notification tap when app is in background
  void setupBackgroundMessageHandler(Function(dynamic) onMessageOpened) {
    // TODO: Uncomment when Firebase Messaging package is added
    // FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpened);
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  print('Handling background message');
  // Handle background messages here
}