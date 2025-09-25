import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a notification for a user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? tenderId,
    String? projectId,
    String priority = 'normal',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'tenderId': tenderId,
        'projectId': projectId,
        'priority': priority,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Notify all users when a new budget allocation is added
  Future<void> notifyNewBudgetAllocation({
    required String categoryName,
    required String subcategoryName,
    required String itemName,
    required double amount,
  }) async {
    try {
      // Get all users to notify them about new budget allocation
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (final userDoc in usersSnapshot.docs) {
        await createNotification(
          userId: userDoc.id,
          title: 'New Budget Allocation Added',
          message: 'A new budget item "$itemName" has been added to $categoryName > $subcategoryName with amount \$${amount.toStringAsFixed(0)}',
          type: 'budget_allocation',
          priority: 'normal',
        );
      }
    } catch (e) {
      print('Error notifying new budget allocation: $e');
    }
  }

  /// Check for projects with due dates approaching and create notifications
  Future<void> checkProjectDueDates() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      final oneWeekFromNow = now.add(const Duration(days: 7));

      // Get all projects
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final deadline = projectData['deadline'] as String?;
        final createdBy = projectData['createdBy'] as String?;
        
        if (deadline != null && createdBy != null) {
          try {
            final deadlineDate = DateTime.parse(deadline);
            
            // Check if deadline is within 3 days
            if (deadlineDate.isBefore(threeDaysFromNow) && deadlineDate.isAfter(now)) {
              await createNotification(
                userId: createdBy,
                title: 'Project Deadline Approaching',
                message: 'Project "${projectData['tenderTitle'] ?? 'Unknown'}" is due in ${deadlineDate.difference(now).inDays + 1} days',
                type: 'deadline_alert',
                projectId: projectDoc.id,
                priority: 'high',
              );
            }
            // Check if deadline is within 1 week
            else if (deadlineDate.isBefore(oneWeekFromNow) && deadlineDate.isAfter(threeDaysFromNow)) {
              await createNotification(
                userId: createdBy,
                title: 'Project Deadline Reminder',
                message: 'Project "${projectData['tenderTitle'] ?? 'Unknown'}" is due in ${deadlineDate.difference(now).inDays + 1} days',
                type: 'deadline_reminder',
                projectId: projectDoc.id,
                priority: 'normal',
              );
            }
          } catch (e) {
            print('Error parsing deadline for project ${projectDoc.id}: $e');
          }
        }
      }
    } catch (e) {
      print('Error checking project due dates: $e');
    }
  }

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'system',
          'isRead': data['isRead'] ?? false,
          'createdAt': data['createdAt'],
          'priority': data['priority'] ?? 'normal',
        };
      }).toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Send approval notification
  Future<void> sendApprovalNotification(String userEmail, String userRole) async {
    try {
      // Get user ID from email
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        final userId = usersSnapshot.docs.first.id;
        await createNotification(
          userId: userId,
          title: '✅ Approval Notification',
          message: 'Your $userRole account has been approved and is now active.',
          type: 'approval',
          priority: 'normal',
        );
      }
    } catch (e) {
      print('Error sending approval notification: $e');
    }
  }

  /// Send rejection notification
  Future<void> sendRejectionNotification(String userEmail) async {
    try {
      // Get user ID from email
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        final userId = usersSnapshot.docs.first.id;
        await createNotification(
          userId: userId,
          title: '❌ Rejection Notification',
          message: 'Your account has been rejected. Please contact support for more information.',
          type: 'rejection',
          priority: 'normal',
        );
      }
    } catch (e) {
      print('Error sending rejection notification: $e');
    }
  }
}