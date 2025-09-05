import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Getter for current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _communitiesCol => 
      _db.collection('communities');
  CollectionReference<Map<String, dynamic>> get _communityMembersCol => 
      _db.collection('community_members');
  CollectionReference<Map<String, dynamic>> get _communityPostsCol => 
      _db.collection('community_posts');
  CollectionReference<Map<String, dynamic>> get _communityCommentsCol => 
      _db.collection('community_comments');

  /// Create a new community
  Future<String> createCommunity(Community community) async {
    try {
      final doc = await _communitiesCol.add(community.toFirestore());
      
      // Add creator as admin member
      await _communityMembersCol.doc(doc.id).collection('members').doc(_auth.currentUser!.uid).set({
        'userId': _auth.currentUser!.uid,
        'communityId': doc.id,
        'role': 'admin',
        'status': 'active',
        'joinedAt': Timestamp.now(),
      });

      // Update member count
      await _communitiesCol.doc(doc.id).update({'memberCount': 1});
      
      return doc.id;
    } catch (e) {
      print('Error creating community: $e');
      throw Exception('Failed to create community: $e');
    }
  }

  /// Get all active communities
  Stream<List<Community>> getCommunities({
    String? category,
    String? searchQuery,
  }) {
    // Use a simpler query to avoid index requirements
    Query<Map<String, dynamic>> query = _communitiesCol
        .where('isActive', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      final communities = snapshot.docs
          .map((doc) => Community.fromFirestore(doc))
          .toList();

      // Apply filters in memory to avoid complex Firebase queries
      var filteredCommunities = communities;

      // Filter by category
      if (category != null && category.isNotEmpty && category != 'All') {
        filteredCommunities = filteredCommunities
            .where((community) => community.category == category)
            .toList();
      }

      // Filter by search query
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final search = searchQuery.toLowerCase();
        filteredCommunities = filteredCommunities.where((community) {
          return community.name.toLowerCase().contains(search) ||
                 community.description.toLowerCase().contains(search) ||
                 community.tags.any((tag) => tag.toLowerCase().contains(search));
        }).toList();
      }

      // Sort by creation date (newest first)
      filteredCommunities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredCommunities;
    });
  }

  /// Get a specific community
  Future<Community?> getCommunity(String communityId) async {
    try {
      final doc = await _communitiesCol.doc(communityId).get();
      if (doc.exists) {
        return Community.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting community: $e');
      throw Exception('Failed to get community: $e');
    }
  }

  /// Update community
  Future<void> updateCommunity(Community community) async {
    try {
      await _communitiesCol.doc(community.id).update(community.toFirestore());
    } catch (e) {
      print('Error updating community: $e');
      throw Exception('Failed to update community: $e');
    }
  }

  /// Delete community (admin only)
  Future<void> deleteCommunity(String communityId) async {
    try {
      // Delete community
      await _communitiesCol.doc(communityId).delete();
      
      // Delete all members
      final membersSnapshot = await _communityMembersCol
          .doc(communityId)
          .collection('members')
          .get();
      
      for (var doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all posts
      final postsSnapshot = await _communityPostsCol
          .doc(communityId)
          .collection('posts')
          .get();
      
      for (var doc in postsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting community: $e');
      throw Exception('Failed to delete community: $e');
    }
  }

  /// Join a community
  Future<void> joinCommunity(String communityId) async {
    try {
      final userId = _auth.currentUser!.uid;
      
      // Check if already a member
      final memberDoc = await _communityMembersCol
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      if (memberDoc.exists) {
        throw Exception('Already a member of this community');
      }

      // Add member
      await _communityMembersCol
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .set({
        'userId': userId,
        'communityId': communityId,
        'role': 'member',
        'status': 'active',
        'joinedAt': Timestamp.now(),
      });

      // Update member count
      await _communitiesCol.doc(communityId).update({
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error joining community: $e');
      throw Exception('Failed to join community: $e');
    }
  }

  /// Leave a community
  Future<void> leaveCommunity(String communityId) async {
    try {
      final userId = _auth.currentUser!.uid;
      
      // Remove member
      await _communityMembersCol
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .delete();

      // Update member count
      await _communitiesCol.doc(communityId).update({
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error leaving community: $e');
      throw Exception('Failed to leave community: $e');
    }
  }

  /// Check if user is a member of a community
  Future<bool> isUserMember(String communityId) async {
    try {
      final userId = _auth.currentUser!.uid;
      final memberDoc = await _communityMembersCol
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();
      
      return memberDoc.exists;
    } catch (e) {
      print('Error checking membership: $e');
      return false;
    }
  }

  /// Get community members
  Stream<List<CommunityMember>> getCommunityMembers(String communityId) {
    return _communityMembersCol
        .doc(communityId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMember.fromFirestore(doc))
            .toList());
  }

  /// Create a new post in a community
  Future<String> createPost(CommunityPost post) async {
    try {
      final doc = await _communityPostsCol
          .doc(post.communityId)
          .collection('posts')
          .add(post.toFirestore());
      
      return doc.id;
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get posts for a community
  Stream<List<CommunityPost>> getCommunityPosts(String communityId) {
    return _communityPostsCol
        .doc(communityId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['status'] == 'active')
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  /// Like a post
  Future<void> likePost(String communityId, String postId) async {
    try {
      await _communityPostsCol
          .doc(communityId)
          .collection('posts')
          .doc(postId)
          .update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error liking post: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  /// Delete a post (admin/creator only)
  Future<void> deletePost(String communityId, String postId) async {
    try {
      await _communityPostsCol
          .doc(communityId)
          .collection('posts')
          .doc(postId)
          .update({
        'status': 'deleted',
      });
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Add a comment to a post
  Future<String> addComment(String communityId, String postId, CommunityComment comment) async {
    try {
      final doc = await _communityCommentsCol
          .doc(communityId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(comment.toFirestore());
      
      // Update comment count
      await _communityPostsCol
          .doc(communityId)
          .collection('posts')
          .doc(postId)
          .update({
        'comments': FieldValue.increment(1),
      });
      
      return doc.id;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a post
  Stream<List<CommunityComment>> getPostComments(String communityId, String postId) {
    return _communityCommentsCol
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityComment.fromFirestore(doc))
            .toList());
  }

  /// Delete a comment (admin/creator only)
  Future<void> deleteComment(String communityId, String postId, String commentId) async {
    try {
      await _communityCommentsCol
          .doc(communityId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'status': 'deleted',
      });
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Share news article to community
  Future<String> shareNewsToCommunity({
    required String communityId,
    required String newsTitle,
    required String newsContent,
    required String newsId,
    required String authorName,
  }) async {
    try {
      final post = CommunityPost(
        id: '',
        communityId: communityId,
        title: '📰 $newsTitle',
        content: newsContent,
        authorId: _auth.currentUser!.uid,
        authorName: authorName,
        createdAt: DateTime.now(),
        likes: 0,
        comments: 0,
        images: [],
        tags: ['news', 'shared'],
        isPinned: false,
        isReported: false,
        reportReason: '',
        status: 'active',
        sharedFrom: newsId,
        sharedFromType: 'news',
      );

      return await createPost(post);
    } catch (e) {
      print('Error sharing news to community: $e');
      throw Exception('Failed to share news to community: $e');
    }
  }

  /// Get user's communities
  Stream<List<Community>> getUserCommunities() {
    final userId = _auth.currentUser!.uid;
    print('🔍 Getting communities for user: $userId');
    
    // Use a simpler approach: get all communities and check membership for each
    return _communitiesCol
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      print('📋 Found ${snapshot.docs.length} active communities');
      final userCommunities = <Community>[];
      
      // Check each community to see if user is a member
      for (var doc in snapshot.docs) {
        final communityId = doc.id;
        print('🔍 Checking membership in community: $communityId');
        
        final memberDoc = await _communityMembersCol
            .doc(communityId)
            .collection('members')
            .doc(userId)
            .get();
        
        print('👤 Member doc exists: ${memberDoc.exists}');
        if (memberDoc.exists) {
          final community = Community.fromFirestore(doc);
          userCommunities.add(community);
          print('✅ Added community: ${community.name}');
        }
      }
      
      print('🎉 User is member of ${userCommunities.length} communities');
      return userCommunities;
    });
  }
}
