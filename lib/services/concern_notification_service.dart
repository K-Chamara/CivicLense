import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';

class ConcernNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send notification to officers when a new concern is created
  Future<void> notifyNewConcern({
    required String concernId,
    required String concernTitle,
    required String authorName,
    required ConcernCategory category,
    required ConcernPriority priority,
    required List<ConcernAttachment> attachments,
  }) async {
    try {
      // Get all anti-corruption officers
      final officersQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'anti_corruption_officer')
          .get();

      if (officersQuery.docs.isEmpty) return;

      final attachmentCount = attachments.length;
      final hasEvidence = attachmentCount > 0;
      
      // Create notification for each officer
      for (final officerDoc in officersQuery.docs) {
        final officerId = officerDoc.id;
        final officerData = officerDoc.data();
        final officerName = officerData['name'] ?? 'Officer';
        
        final notification = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'new_concern',
          'title': 'New Concern Reported',
          'body': hasEvidence 
              ? '$concernTitle - ${authorName} reported a ${category.name} concern with ${attachmentCount} evidence file(s)'
              : '$concernTitle - ${authorName} reported a ${category.name} concern',
          'concernId': concernId,
          'concernTitle': concernTitle,
          'authorName': authorName,
          'category': category.name,
          'priority': priority.name,
          'hasEvidence': hasEvidence,
          'attachmentCount': attachmentCount,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'actionRequired': true,
        };

        // Add notification to officer's notifications collection
        await _db
            .collection('users')
            .doc(officerId)
            .collection('notifications')
            .add(notification);
      }

      print('✅ Notified ${officersQuery.docs.length} officers about new concern: $concernTitle');
    } catch (e) {
      print('❌ Error notifying officers about new concern: $e');
    }
  }

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

  /// Emit a notification when someone supports (likes/upvotes) a concern
  Future<void> notifyConcernSupport({
    required String concernAuthorId,
    required String concernId,
    required String concernTitle,
    required String supporterId,
    required String supporterName,
  }) async {
    try {
      // Do not notify if author supports their own concern
      if (concernAuthorId == supporterId) return;

      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': concernAuthorId,
        'type': 'concern_support',
        'title': 'Support for your concern',
        'body': '$supporterName supported your concern: "$concernTitle"',
        'concernId': concernId,
        'supporterId': supporterId,
        'supporterName': supporterName,
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      await _db.collection('user_notifications').add(notification);
    } catch (e) {
      print('Error sending concern support notification: $e');
    }
  }

  /// Emit notifications to community members when a new post is created
  Future<void> notifyCommunityPostToMembers({
    required List<String> memberUserIds,
    required String communityId,
    required String communityName,
    required String postId,
    required String postTitle,
  }) async {
    try {
      if (memberUserIds.isEmpty) return;

      final batch = _db.batch();
      for (final userId in memberUserIds) {
        final docRef = _db.collection('user_notifications').doc();
        batch.set(docRef, {
          'id': docRef.id,
          'userId': userId,
          'type': 'community_post',
          'title': 'New post in $communityName',
          'body': postTitle,
          'communityId': communityId,
          'communityName': communityName,
          'postId': postId,
          'createdAt': Timestamp.now(),
          'isRead': false,
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error sending community post notifications: $e');
    }
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
