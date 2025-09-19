import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Save token to Firestore for the current user
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      // You would get the current user ID here
      // For now, we'll just log it
      print('Saving FCM token: $token');
      // await _firestore.collection('users').doc(userId).update({
      //   'fcmToken': token,
      //   'tokenUpdatedAt': FieldValue.serverTimestamp(),
      // });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Send approval notification (simplified version)
  /// In production, this would be handled by Firebase Cloud Functions
  Future<void> sendApprovalNotification(String userEmail, String userRole) async {
    try {
      print('Sending approval notification to $userEmail for role: $userRole');
      
      // In a real implementation, you would:
      // 1. Get the user's FCM token from Firestore
      // 2. Send a push notification via Firebase Cloud Messaging
      // 3. Or use Firebase Cloud Functions to handle this
      
      // For now, we'll just log the notification
      print('📱 Push Notification: "Your account has been approved. You can now access your $userRole features."');
      
    } catch (e) {
      print('Error sending approval notification: $e');
    }
  }

  /// Send rejection notification
  Future<void> sendRejectionNotification(String userEmail) async {
    try {
      print('Sending rejection notification to $userEmail');
      print('📱 Push Notification: "Your account application has been reviewed. Please contact support for more information."');
    } catch (e) {
      print('Error sending rejection notification: $e');
    }
  }

  /// Get FCM token for a specific user
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcmToken'];
      }
      return null;
    } catch (e) {
      print('Error getting user FCM token: $e');
      return null;
    }
  }
}
