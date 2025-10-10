import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/concern_models.dart';
import 'concern_management_service.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications
  static Future<void> initializeNotifications() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Listen for background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.notification?.title}');
    });
  }

  // Show local notification
  static void _showLocalNotification(RemoteMessage message) {
    // This would typically use a local notification plugin
    // For now, we'll use a simple approach with SnackBar
    print('Local notification: ${message.notification?.title}');
  }

  // Send notification to anti-corruption officers about new concern
  static Future<void> notifyNewConcern(Concern concern) async {
    try {
      // Get all anti-corruption officers
      final officers = await _firestore
          .collection('users')
          .where('role.id', isEqualTo: 'anti_corruption_officer')
          .get();

      for (var officerDoc in officers.docs) {
        final officerData = officerDoc.data();
        final officerId = officerDoc.id;
        
        // Create notification
        await _firestore.collection('notifications').add({
          'userId': officerId,
          'title': 'New Concern Reported',
          'body': '${concern.title} (${concern.supportCount} supports)',
          'type': 'new_concern',
          'concernId': concern.id,
          'priority': concern.supportCount > 100 ? 'high' : 'normal',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'isRead': false,
        });

        // Send push notification
        await _sendPushNotification(
          officerId,
          'New Concern Reported',
          '${concern.title} (${concern.supportCount} supports)',
          {'concernId': concern.id, 'type': 'new_concern'},
        );
      }

      print('✅ Notifications sent for new concern: ${concern.id}');
    } catch (e) {
      print('❌ Error sending notifications: $e');
    }
  }

  // Send notification to user about concern update
  static Future<void> notifyConcernUpdate({
    required String concernId,
    required String userId,
    required String title,
    required String message,
    required String action,
  }) async {
    try {
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': message,
        'type': 'concern_update',
        'concernId': concernId,
        'action': action,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });

      // Send push notification
      await _sendPushNotification(
        userId,
        title,
        message,
        {'concernId': concernId, 'type': 'concern_update', 'action': action},
      );

      print('✅ Notification sent for concern update: $concernId');
    } catch (e) {
      print('❌ Error sending concern update notification: $e');
    }
  }

  // Send push notification
  static Future<void> _sendPushNotification(
    String userId,
    String title,
    String body,
    Map<String, String> data,
  ) async {
    try {
      // This would typically use Firebase Cloud Functions or a service
      // For now, we'll just log it
      print('Push notification to $userId: $title - $body');
      print('Data: $data');
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }

  // Get user notifications
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Listen for new concerns and send notifications
  static void startConcernNotificationListener() {
    _firestore
        .collection('concerns')
        .where('status', isEqualTo: ConcernStatus.pending.name)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final concern = Concern.fromFirestore(change.doc);
          notifyNewConcern(concern);
        }
      }
    });
  }

  // Send notification when concern status changes
  static Future<void> notifyStatusChange({
    required String concernId,
    required String userId,
    required ConcernStatus oldStatus,
    required ConcernStatus newStatus,
    String? comment,
  }) async {
    String title = 'Concern Status Updated';
    String message = 'Your concern status has been updated to ${newStatus.name}';
    
    if (comment != null && comment.isNotEmpty) {
      message += '\n\nOfficer Comment: $comment';
    }

    await notifyConcernUpdate(
      concernId: concernId,
      userId: userId,
      title: title,
      message: message,
      action: 'status_changed',
    );
  }

  // Send notification when officer adds comment
  static Future<void> notifyOfficerComment({
    required String concernId,
    required String userId,
    required String comment,
    required String officerName,
  }) async {
    await notifyConcernUpdate(
      concernId: concernId,
      userId: userId,
      title: 'Officer Comment Added',
      message: '$officerName commented: $comment',
      action: 'officer_comment',
    );
  }

  // Create notification (for backward compatibility)
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'data': data ?? {},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // Send approval notification
  static Future<void> sendApprovalNotification(String userEmail, String userRole) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userEmail,
        'title': 'Account Approved',
        'body': 'Your $userRole account has been approved. You can now access the system.',
        'type': 'approval',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      print('❌ Error sending approval notification: $e');
    }
  }

  // Send rejection notification
  static Future<void> sendRejectionNotification(String userEmail) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userEmail,
        'title': 'Account Rejected',
        'body': 'Your account application has been rejected. Please contact support for more information.',
        'type': 'rejection',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      print('❌ Error sending rejection notification: $e');
    }
  }

  // Notify new budget allocation
  static Future<void> notifyNewBudgetAllocation({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': message,
        'type': 'budget_allocation',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      print('❌ Error sending budget allocation notification: $e');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': data['type'] ?? 'general',
        'data': data,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });

      // Send push notification
      await _sendPushNotification(
        userId,
        title,
        body,
        data.map((key, value) => MapEntry(key, value.toString())),
      );

      print('✅ Notification sent to user $userId: $title');
    } catch (e) {
      print('❌ Error sending notification to user: $e');
    }
  }
}