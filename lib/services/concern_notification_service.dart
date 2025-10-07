import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';

class ConcernNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send notification when concern status changes
  Future<void> notifyStatusChange({
    required String concernId,
    required ConcernStatus oldStatus,
    required ConcernStatus newStatus,
    required String officerId,
    required String officerName,
    String? comment,
  }) async {
    try {
      // Get the concern to find the author
      final concernDoc = await _db.collection('concerns').doc(concernId).get();
      if (!concernDoc.exists) return;

      final concern = Concern.fromFirestore(concernDoc);
      
      // Don't notify if the author is the same as the officer making the change
      if (concern.authorId == officerId) return;

      // Create notification
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'concern_status_change',
        'concernId': concernId,
        'concernTitle': concern.title,
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'officerId': officerId,
        'officerName': officerName,
        'comment': comment,
        'createdAt': Timestamp.now(),
        'isRead': false,
        'userId': concern.authorId,
      };

      // Save notification to Firestore
      await _db.collection('notifications').add(notification);

      // Also create an in-app notification for the concern author
      await _createInAppNotification(
        userId: concern.authorId,
        title: _getStatusChangeTitle(newStatus),
        body: _getStatusChangeMessage(concern.title, newStatus, officerName, comment),
        type: 'concern_update',
        concernId: concernId,
      );

    } catch (e) {
      print('Error sending concern status notification: $e');
    }
  }

  /// Send notification when concern is assigned to an officer
  Future<void> notifyAssignment({
    required String concernId,
    required String assignedOfficerId,
    required String assignedOfficerName,
    required String assignedBy,
  }) async {
    try {
      // Get the concern
      final concernDoc = await _db.collection('concerns').doc(concernId).get();
      if (!concernDoc.exists) return;

      final concern = Concern.fromFirestore(concernDoc);

      // Create notification for the assigned officer
      await _createInAppNotification(
        userId: assignedOfficerId,
        title: 'New Concern Assignment',
        body: 'You have been assigned to handle: "${concern.title}"',
        type: 'concern_assignment',
        concernId: concernId,
      );

      // Create notification for the concern author
      await _createInAppNotification(
        userId: concern.authorId,
        title: 'Concern Assigned',
        body: 'Your concern "${concern.title}" has been assigned to an officer',
        type: 'concern_assignment',
        concernId: concernId,
      );

    } catch (e) {
      print('Error sending assignment notification: $e');
    }
  }

  /// Send notification when a comment is added to a concern
  Future<void> notifyNewComment({
    required String concernId,
    required String commentAuthorId,
    required String commentAuthorName,
    required String commentContent,
    required bool isOfficial,
  }) async {
    try {
      // Get the concern
      final concernDoc = await _db.collection('concerns').doc(concernId).get();
      if (!concernDoc.exists) return;

      final concern = Concern.fromFirestore(concernDoc);

      // Don't notify the comment author
      if (concern.authorId == commentAuthorId) return;

      // Create notification
      await _createInAppNotification(
        userId: concern.authorId,
        title: isOfficial ? 'Official Response' : 'New Comment',
        body: isOfficial 
            ? 'An officer has responded to your concern: "${concern.title}"'
            : 'Someone commented on your concern: "${concern.title}"',
        type: 'concern_comment',
        concernId: concernId,
      );

    } catch (e) {
      print('Error sending comment notification: $e');
    }
  }

  /// Create an in-app notification
  Future<void> _createInAppNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String concernId,
  }) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'concernId': concernId,
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      await _db.collection('user_notifications').add(notification);
    } catch (e) {
      print('Error creating in-app notification: $e');
    }
  }

  /// Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _db
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('user_notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Helper methods for notification messages
  String _getStatusChangeTitle(ConcernStatus status) {
    switch (status) {
      case ConcernStatus.pending:
        return 'Concern Status Updated';
      case ConcernStatus.underReview:
        return 'Concern Under Review';
      case ConcernStatus.inProgress:
        return 'Concern In Progress';
      case ConcernStatus.resolved:
        return 'Concern Resolved';
      case ConcernStatus.dismissed:
        return 'Concern Dismissed';
      case ConcernStatus.escalated:
        return 'Concern Escalated';
    }
  }

  String _getStatusChangeMessage(String concernTitle, ConcernStatus status, String officerName, String? comment) {
    final baseMessage = 'Your concern "$concernTitle" status has been updated to ${status.name}';
    
    if (comment != null && comment.isNotEmpty) {
      return '$baseMessage by $officerName. Comment: $comment';
    }
    
    return '$baseMessage by $officerName';
  }
}
