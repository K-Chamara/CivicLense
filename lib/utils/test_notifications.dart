import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

/// Utility class to test push notifications
class NotificationTester {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test 1: Check if FCM token is saved
  static Future<bool> testFCMTokenSaved() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('❌ User document not found');
        return false;
      }

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null || fcmToken.toString().isEmpty) {
        print('❌ FCM token not saved');
        return false;
      }

      print('✅ FCM token is saved: ${fcmToken.toString().substring(0, 20)}...');
      return true;
    } catch (e) {
      print('❌ Error checking FCM token: $e');
      return false;
    }
  }

  /// Test 2: Send test notification to current user
  static Future<bool> testSendNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      await NotificationService.createNotification(
        userId: user.uid,
        title: '🧪 Test Notification',
        body: 'This is a test notification from CivicLense',
        type: 'test',
        data: {'timestamp': DateTime.now().toIso8601String()},
      );

      print('✅ Test notification created in Firestore');
      return true;
    } catch (e) {
      print('❌ Error sending test notification: $e');
      return false;
    }
  }

  /// Test 3: Check notification permissions
  static Future<bool> testNotificationPermissions() async {
    try {
      final settings = await NotificationService.getNotificationSettings();

      print('📱 Notification permissions:');
      print('   Authorization: ${settings.authorizationStatus}');
      print('   Alert: ${settings.alert}');
      print('   Badge: ${settings.badge}');
      print('   Sound: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notifications authorized');
        return true;
      } else {
        print('⚠️ Notifications not authorized');
        return false;
      }
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Test 4: Count unread notifications
  static Future<int> testUnreadNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return -1;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final count = snapshot.docs.length;
      print('📬 Unread notifications: $count');
      return count;
    } catch (e) {
      print('❌ Error counting notifications: $e');
      return -1;
    }
  }

  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    print('\n========================================');
    print('🧪 RUNNING NOTIFICATION TESTS');
    print('========================================\n');

    final results = <String, bool>{};

    print('Test 1: FCM Token Saved...');
    results['fcmTokenSaved'] = await testFCMTokenSaved();
    print('');

    print('Test 2: Notification Permissions...');
    results['permissionsGranted'] = await testNotificationPermissions();
    print('');

    print('Test 3: Send Test Notification...');
    results['canSendNotification'] = await testSendNotification();
    print('');

    print('Test 4: Unread Count...');
    final count = await testUnreadNotificationCount();
    results['canCountNotifications'] = count >= 0;
    print('');

    print('========================================');
    print('📊 TEST RESULTS');
    print('========================================');
    results.forEach((test, passed) {
      print('${passed ? "✅" : "❌"} $test: ${passed ? "PASSED" : "FAILED"}');
    });
    print('========================================\n');

    return results;
  }
}


