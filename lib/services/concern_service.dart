import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';

class ConcernService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference<Map<String, dynamic>> get _concernsCol => 
      _db.collection('concerns');
  CollectionReference<Map<String, dynamic>> get _concernCommentsCol => 
      _db.collection('concern_comments');
  CollectionReference<Map<String, dynamic>> get _concernUpdatesCol => 
      _db.collection('concern_updates');
  CollectionReference<Map<String, dynamic>> get _concernSupportsCol => 
      _db.collection('concern_supports');

  /// Create a new concern
  Future<String> createConcern(Concern concern) async {
    try {
      final doc = await _concernsCol.add(concern.toFirestore());
      
      // Create initial update record
      await _concernUpdatesCol.add(ConcernUpdate(
        id: '',
        concernId: doc.id,
        officerId: _auth.currentUser?.uid ?? '',
        officerName: concern.authorName,
        action: 'created',
        description: 'Concern created by ${concern.authorName}',
        createdAt: DateTime.now(),
        changes: {
          'status': concern.status.name,
          'priority': concern.priority.name,
        },
      ).toFirestore());
      
      return doc.id;
    } catch (e) {
      print('Error creating concern: $e');
      throw Exception('Failed to create concern: $e');
    }
  }

  /// Get concerns with filtering and pagination
  Stream<List<Concern>> getConcerns({
    ConcernFilter? filter,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    // Use index-free approach for public concerns filter
    if (filter?.isPublic == true) {
      return _concernsCol
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final allConcerns = snapshot.docs.map((doc) => Concern.fromFirestore(doc)).toList();
        
        // Apply filters in memory
        var filteredConcerns = allConcerns.where((concern) => concern.isPublic).toList();
        
        if (filter != null) {
          if (filter.category != null) {
            filteredConcerns = filteredConcerns.where((c) => c.category == filter.category).toList();
          }
          if (filter.type != null) {
            filteredConcerns = filteredConcerns.where((c) => c.type == filter.type).toList();
          }
          if (filter.priority != null) {
            filteredConcerns = filteredConcerns.where((c) => c.priority == filter.priority).toList();
          }
          if (filter.status != null) {
            filteredConcerns = filteredConcerns.where((c) => c.status == filter.status).toList();
          }
          if (filter.assignedOfficerId != null) {
            filteredConcerns = filteredConcerns.where((c) => c.assignedOfficerId == filter.assignedOfficerId).toList();
          }
          if (filter.dateFrom != null) {
            filteredConcerns = filteredConcerns.where((c) => c.createdAt.isAfter(filter.dateFrom!)).toList();
          }
          if (filter.dateTo != null) {
            filteredConcerns = filteredConcerns.where((c) => c.createdAt.isBefore(filter.dateTo!)).toList();
          }
        }
        
        return filteredConcerns.take(limit).toList();
      });
    }

    // For non-public concerns, use the original approach
    Query<Map<String, dynamic>> query = _concernsCol;

    // Apply filters
    if (filter != null) {
      if (filter.category != null) {
        query = query.where('category', isEqualTo: filter.category!.name);
      }
      if (filter.type != null) {
        query = query.where('type', isEqualTo: filter.type!.name);
      }
      if (filter.priority != null) {
        query = query.where('priority', isEqualTo: filter.priority!.name);
      }
      if (filter.status != null) {
        query = query.where('status', isEqualTo: filter.status!.name);
      }
      if (filter.assignedOfficerId != null) {
        query = query.where('assignedOfficerId', isEqualTo: filter.assignedOfficerId);
      }
      if (filter.isPublic != null && filter.isPublic == false) {
        query = query.where('isPublic', isEqualTo: false);
      }
      if (filter.dateFrom != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.dateFrom!));
      }
      if (filter.dateTo != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.dateTo!));
      }
    }

    // Order by creation date (newest first)
    query = query.orderBy('createdAt', descending: true);

    // Apply pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Concern.fromFirestore(doc)).toList();
    });
  }

  /// Get a specific concern
  Future<Concern?> getConcern(String concernId) async {
    try {
      final doc = await _concernsCol.doc(concernId).get();
      if (doc.exists) {
        return Concern.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting concern: $e');
      throw Exception('Failed to get concern: $e');
    }
  }

  /// Update concern status
  Future<void> updateConcernStatus({
    required String concernId,
    required ConcernStatus status,
    required String officerId,
    required String officerName,
    String? comment,
    ConcernPriority? newPriority,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (newPriority != null) {
        updateData['priority'] = newPriority.name;
      }

      if (status == ConcernStatus.resolved) {
        updateData['resolvedAt'] = Timestamp.now();
      }

      await _concernsCol.doc(concernId).update(updateData);

      // Create update record
      await _concernUpdatesCol.add(ConcernUpdate(
        id: '',
        concernId: concernId,
        officerId: officerId,
        officerName: officerName,
        action: 'status_update',
        description: comment ?? 'Status updated to ${status.name}',
        createdAt: DateTime.now(),
        changes: {
          'status': status.name,
          if (newPriority != null) 'priority': newPriority.name,
        },
      ).toFirestore());

      // Add comment if provided
      if (comment != null && comment.isNotEmpty) {
        await addComment(concernId, comment, officerId, officerName, isOfficial: true);
      }
    } catch (e) {
      print('Error updating concern status: $e');
      throw Exception('Failed to update concern status: $e');
    }
  }

  /// Assign concern to officer
  Future<void> assignConcern({
    required String concernId,
    required String officerId,
    required String officerName,
    required String assignedBy,
  }) async {
    try {
      await _concernsCol.doc(concernId).update({
        'assignedOfficerId': officerId,
        'assignedOfficerName': officerName,
        'updatedAt': Timestamp.now(),
      });

      // Create update record
      await _concernUpdatesCol.add(ConcernUpdate(
        id: '',
        concernId: concernId,
        officerId: assignedBy,
        officerName: assignedBy,
        action: 'assigned',
        description: 'Concern assigned to $officerName',
        createdAt: DateTime.now(),
        changes: {
          'assignedOfficerId': officerId,
          'assignedOfficerName': officerName,
        },
      ).toFirestore());
    } catch (e) {
      print('Error assigning concern: $e');
      throw Exception('Failed to assign concern: $e');
    }
  }

  /// Add comment to concern
  Future<String> addComment(
    String concernId,
    String content,
    String authorId,
    String authorName, {
    bool isOfficial = false,
    bool isInternal = false,
  }) async {
    try {
      final comment = ConcernComment(
        id: '',
        concernId: concernId,
        authorId: authorId,
        authorName: authorName,
        content: content,
        createdAt: DateTime.now(),
        isOfficial: isOfficial,
        isInternal: isInternal,
      );

      final doc = await _concernCommentsCol.add(comment.toFirestore());

      // Update comment count
      await _concernsCol.doc(concernId).update({
        'commentCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      return doc.id;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a concern
  Stream<List<ConcernComment>> getConcernComments(String concernId) {
    return _concernCommentsCol
        .where('concernId', isEqualTo: concernId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConcernComment.fromFirestore(doc))
            .toList());
  }

  /// Get updates for a concern
  Stream<List<ConcernUpdate>> getConcernUpdates(String concernId) {
    return _concernUpdatesCol
        .where('concernId', isEqualTo: concernId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConcernUpdate.fromFirestore(doc))
            .toList());
  }

  /// Vote on concern
  Future<void> voteOnConcern(String concernId, bool isUpvote) async {
    try {
      final userId = _auth.currentUser!.uid;
      final concernRef = _concernsCol.doc(concernId);
      
      // Check if user already voted
      final voteDoc = await _db
          .collection('concern_votes')
          .doc('${concernId}_$userId')
          .get();

      if (voteDoc.exists) {
        final existingVote = voteDoc.data()!['isUpvote'] as bool;
        if (existingVote == isUpvote) {
          // User is trying to vote the same way, remove vote
          await _db
              .collection('concern_votes')
              .doc('${concernId}_$userId')
              .delete();
          
          await concernRef.update({
            isUpvote ? 'upvotes' : 'downvotes': FieldValue.increment(-1),
          });
        } else {
          // User is changing their vote
          await _db
              .collection('concern_votes')
              .doc('${concernId}_$userId')
              .set({
            'concernId': concernId,
            'userId': userId,
            'isUpvote': isUpvote,
            'createdAt': Timestamp.now(),
          });
          
          await concernRef.update({
            isUpvote ? 'upvotes' : 'downvotes': FieldValue.increment(1),
            isUpvote ? 'downvotes' : 'upvotes': FieldValue.increment(-1),
          });
        }
      } else {
        // New vote
        await _db
            .collection('concern_votes')
            .doc('${concernId}_$userId')
            .set({
          'concernId': concernId,
          'userId': userId,
          'isUpvote': isUpvote,
          'createdAt': Timestamp.now(),
        });
        
        await concernRef.update({
          isUpvote ? 'upvotes' : 'downvotes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error voting on concern: $e');
      throw Exception('Failed to vote on concern: $e');
    }
  }

  /// Get user's concerns
  Stream<List<Concern>> getUserConcerns(String userId) {
    return _concernsCol
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }

  /// Get concerns assigned to officer
  Stream<List<Concern>> getOfficerConcerns(String officerId) {
    return _concernsCol
        .where('assignedOfficerId', isEqualTo: officerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Concern.fromFirestore(doc))
            .toList());
  }

  /// Get concern statistics
  Future<ConcernStats> getConcernStats() async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      // Get all concerns
      final allConcerns = await _concernsCol.get();
      final concerns = allConcerns.docs.map((doc) => Concern.fromFirestore(doc)).toList();

      // Calculate statistics
      final totalConcerns = concerns.length;
      final pendingConcerns = concerns.where((c) => c.status == ConcernStatus.pending).length;
      final inProgressConcerns = concerns.where((c) => c.status == ConcernStatus.inProgress).length;
      final resolvedConcerns = concerns.where((c) => c.status == ConcernStatus.resolved).length;
      final criticalConcerns = concerns.where((c) => c.priority == ConcernPriority.critical).length;

      // Concerns by category
      final concernsByCategory = <ConcernCategory, int>{};
      for (final category in ConcernCategory.values) {
        concernsByCategory[category] = concerns.where((c) => c.category == category).length;
      }

      // Concerns by priority
      final concernsByPriority = <ConcernPriority, int>{};
      for (final priority in ConcernPriority.values) {
        concernsByPriority[priority] = concerns.where((c) => c.priority == priority).length;
      }

      // Average resolution time
      final resolvedConcernsWithTime = concerns
          .where((c) => c.status == ConcernStatus.resolved && c.resolvedAt != null)
          .toList();
      
      double averageResolutionTime = 0;
      if (resolvedConcernsWithTime.isNotEmpty) {
        final totalTime = resolvedConcernsWithTime
            .map((c) => c.resolvedAt!.difference(c.createdAt).inHours)
            .reduce((a, b) => a + b);
        averageResolutionTime = totalTime / resolvedConcernsWithTime.length;
      }

      // Concerns this month
      final concernsThisMonth = concerns
          .where((c) => c.createdAt.isAfter(thisMonth))
          .length;

      // Concerns last month
      final concernsLastMonth = concerns
          .where((c) => c.createdAt.isAfter(lastMonth) && c.createdAt.isBefore(lastMonthEnd))
          .length;

      return ConcernStats(
        totalConcerns: totalConcerns,
        pendingConcerns: pendingConcerns,
        inProgressConcerns: inProgressConcerns,
        resolvedConcerns: resolvedConcerns,
        criticalConcerns: criticalConcerns,
        concernsByCategory: concernsByCategory,
        concernsByPriority: concernsByPriority,
        averageResolutionTime: averageResolutionTime,
        concernsThisMonth: concernsThisMonth,
        concernsLastMonth: concernsLastMonth,
      );
    } catch (e) {
      print('Error getting concern stats: $e');
      throw Exception('Failed to get concern statistics: $e');
    }
  }

  /// Search concerns
  Stream<List<Concern>> searchConcerns(String query) {
    return _concernsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final concerns = snapshot.docs.map((doc) => Concern.fromFirestore(doc)).toList();
      
      if (query.isEmpty) return concerns;
      
      final searchQuery = query.toLowerCase();
      return concerns.where((concern) {
        return concern.title.toLowerCase().contains(searchQuery) ||
               concern.description.toLowerCase().contains(searchQuery) ||
               concern.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
               concern.authorName.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  /// Support/Unsupport a concern (like Facebook/Instagram)
  Future<void> toggleSupport(String concernId) async {
    try {
      final userId = _auth.currentUser!.uid;
      final user = _auth.currentUser!;
      final userName = user.displayName ?? user.email?.split('@').first ?? 'Anonymous';
      
      final supportDocId = '${concernId}_$userId';
      final supportDoc = await _concernSupportsCol.doc(supportDocId).get();
      
      if (supportDoc.exists) {
        // User already supports this concern, remove support
        await _concernSupportsCol.doc(supportDocId).delete();
        await _concernsCol.doc(concernId).update({
          'supportCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.now(),
        });
        print('✅ Support removed for concern $concernId');
      } else {
        // User doesn't support this concern, add support
        await _concernSupportsCol.doc(supportDocId).set(ConcernSupport(
          id: supportDocId,
          concernId: concernId,
          userId: userId,
          userName: userName,
          supportedAt: DateTime.now(),
        ).toFirestore());
        
        await _concernsCol.doc(concernId).update({
          'supportCount': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
        print('✅ Support added for concern $concernId');
      }
    } catch (e) {
      print('Error toggling support: $e');
      throw Exception('Failed to toggle support: $e');
    }
  }

  /// Check if user supports a concern
  Future<bool> isUserSupporting(String concernId) async {
    try {
      final userId = _auth.currentUser!.uid;
      final supportDocId = '${concernId}_$userId';
      final supportDoc = await _concernSupportsCol.doc(supportDocId).get();
      return supportDoc.exists;
    } catch (e) {
      print('Error checking support status: $e');
      return false;
    }
  }

  /// Get public concerns sorted by support count (most supported first)
  Stream<List<Concern>> getPublicConcernsBySupport({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    // Use completely index-free approach
    return _concernsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Filter public concerns and sort by support count in memory
      final allConcerns = snapshot.docs.map((doc) => Concern.fromFirestore(doc)).toList();
      final publicConcerns = allConcerns.where((concern) => concern.isPublic).toList();
      
      // Sort by support count (most supported first) in memory
      publicConcerns.sort((a, b) => b.supportCount.compareTo(a.supportCount));
      
      return publicConcerns.take(limit).toList();
    });
  }

  /// Get all public concerns (fallback method - no index required)
  Stream<List<Concern>> getAllPublicConcerns() {
    return _concernsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Filter public concerns in memory to avoid index requirements
      final allConcerns = snapshot.docs.map((doc) => Concern.fromFirestore(doc)).toList();
      return allConcerns.where((concern) => concern.isPublic).toList();
    });
  }

  /// Get trending concerns (most supported in last 7 days)
  Stream<List<Concern>> getTrendingConcerns() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    // Use completely index-free approach
    return _concernsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allConcerns = snapshot.docs.map((doc) => Concern.fromFirestore(doc)).toList();
      
      // Filter by public status, date, and sort by support count in memory
      final publicConcerns = allConcerns.where((concern) => concern.isPublic).toList();
      final recentConcerns = publicConcerns.where((concern) => 
        concern.createdAt.isAfter(weekAgo)
      ).toList();
      
      // Sort by support count (most supported first)
      recentConcerns.sort((a, b) => b.supportCount.compareTo(a.supportCount));
      
      return recentConcerns.take(10).toList();
    });
  }

  /// Delete concern (admin only)
  Future<void> deleteConcern(String concernId) async {
    try {
      // Delete all comments
      final commentsSnapshot = await _concernCommentsCol
          .where('concernId', isEqualTo: concernId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all updates
      final updatesSnapshot = await _concernUpdatesCol
          .where('concernId', isEqualTo: concernId)
          .get();
      
      for (var doc in updatesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all votes
      final votesSnapshot = await _db
          .collection('concern_votes')
          .where('concernId', isEqualTo: concernId)
          .get();
      
      for (var doc in votesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the concern
      await _concernsCol.doc(concernId).delete();
    } catch (e) {
      print('Error deleting concern: $e');
      throw Exception('Failed to delete concern: $e');
    }
  }
}
