import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';

class ConcernManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all concerns for anti-corruption officer
  static Stream<List<Concern>> getConcernsForOfficer() {
    return _firestore
        .collection('concerns')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }

  // Get concerns by status
  static Stream<List<Concern>> getConcernsByStatus(ConcernStatus status) {
    return _firestore
        .collection('concerns')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }

  // Get priority concerns (high support count)
  static Stream<List<Concern>> getPriorityConcerns() {
    return _firestore
        .collection('concerns')
        .where('supportCount', isGreaterThan: 100)
        .orderBy('supportCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }

  // Get concern statistics
  static Future<Map<String, int>> getConcernStats() async {
    try {
      final concerns = await _firestore.collection('concerns').get();
      
      int activeCases = 0;
      int resolved = 0;
      int underReview = 0;
      int priority = 0;

      for (var doc in concerns.docs) {
        final concern = Concern.fromFirestore(doc);
        
        switch (concern.status) {
          case ConcernStatus.pending:
          case ConcernStatus.inProgress:
            activeCases++;
            break;
          case ConcernStatus.resolved:
            resolved++;
            break;
          case ConcernStatus.underReview:
            underReview++;
            break;
          default:
            break;
        }

        if (concern.supportCount > 100) {
          priority++;
        }
      }

      return {
        'activeCases': activeCases,
        'resolved': resolved,
        'underReview': underReview,
        'priority': priority,
      };
    } catch (e) {
      print('Error getting concern stats: $e');
      return {
        'activeCases': 0,
        'resolved': 0,
        'underReview': 0,
        'priority': 0,
      };
    }
  }

  // Update concern status
  static Future<void> updateConcernStatus({
    required String concernId,
    required ConcernStatus newStatus,
    required String officerId,
    required String officerName,
    String? comment,
  }) async {
    try {
      final now = DateTime.now();
      
      // Update the concern
      await _firestore.collection('concerns').doc(concernId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(now),
        'assignedOfficerId': officerId,
        'assignedOfficerName': officerName,
        if (newStatus == ConcernStatus.resolved) 'resolvedAt': Timestamp.fromDate(now),
      });

      // Add update record
      final updateId = _firestore.collection('concern_updates').doc().id;
      final update = ConcernUpdate(
        id: updateId,
        concernId: concernId,
        officerId: officerId,
        officerName: officerName,
        action: 'status_changed',
        description: comment ?? 'Status updated to ${newStatus.name}',
        createdAt: now,
        changes: {'status': newStatus.name},
      );

      await _firestore.collection('concern_updates').doc(updateId).set(update.toFirestore());

      // Add comment if provided
      if (comment != null && comment.isNotEmpty) {
        await addOfficerComment(concernId, comment, officerId, officerName);
      }

      print('✅ Concern status updated successfully');
    } catch (e) {
      print('❌ Error updating concern status: $e');
      throw Exception('Failed to update concern status');
    }
  }

  // Add officer comment
  static Future<void> addOfficerComment(
    String concernId,
    String comment,
    String officerId,
    String officerName,
  ) async {
    try {
      final commentId = _firestore.collection('concern_comments').doc().id;
      final concernComment = ConcernComment(
        id: commentId,
        concernId: concernId,
        authorId: officerId,
        authorName: officerName,
        content: comment,
        createdAt: DateTime.now(),
        isOfficial: true,
        officerId: officerId,
      );

      await _firestore.collection('concern_comments').doc(commentId).set(concernComment.toFirestore());
      
      // Update comment count
      await _firestore.collection('concerns').doc(concernId).update({
        'commentCount': FieldValue.increment(1),
      });

      print('✅ Officer comment added successfully');
    } catch (e) {
      print('❌ Error adding officer comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Get concern details with updates
  static Future<Concern> getConcernDetails(String concernId) async {
    try {
      final doc = await _firestore.collection('concerns').doc(concernId).get();
      if (doc.exists) {
        return Concern.fromFirestore(doc);
      } else {
        throw Exception('Concern not found');
      }
    } catch (e) {
      print('❌ Error getting concern details: $e');
      throw Exception('Failed to get concern details');
    }
  }

  // Get concern updates/activity
  static Stream<List<ConcernUpdate>> getConcernUpdates(String concernId) {
    return _firestore
        .collection('concern_updates')
        .where('concernId', isEqualTo: concernId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConcernUpdate.fromFirestore(doc))
            .toList());
  }

  // Get concern comments
  static Stream<List<ConcernComment>> getConcernComments(String concernId) {
    return _firestore
        .collection('concern_comments')
        .where('concernId', isEqualTo: concernId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConcernComment.fromFirestore(doc))
            .toList());
  }

  // Get recent concerns for dashboard
  static Stream<List<Concern>> getRecentConcerns({int limit = 5}) {
    return _firestore
        .collection('concerns')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }

  // Listen for new concerns (for notifications)
  static Stream<Concern> getNewConcernsStream() {
    return _firestore
        .collection('concerns')
        .where('status', isEqualTo: ConcernStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return Concern.fromFirestore(snapshot.docs.first);
          }
          throw Exception('No new concerns');
        });
  }

  // Get concerns by filter
  static Stream<List<Concern>> getConcernsByFilter(ConcernFilter filter) {
    Query query = _firestore.collection('concerns');

    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.name);
    }
    if (filter.category != null) {
      query = query.where('category', isEqualTo: filter.category!.name);
    }
    if (filter.priority != null) {
      query = query.where('priority', isEqualTo: filter.priority!.name);
    }
    if (filter.assignedOfficerId != null) {
      query = query.where('assignedOfficerId', isEqualTo: filter.assignedOfficerId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }
}
