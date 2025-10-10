import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Getter to access firestore for external use
  FirebaseFirestore get firestore => _firestore;

  // Create a new community
  Future<String> createCommunity({
    required String name,
    required String description,
    required List<String> categories,
    String? imageUrl,
    bool isPublic = true,
    List<String> rules = const [],
    List<String> tags = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for creator name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final creatorName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

      final communityData = {
        'name': name,
        'description': description,
        'categories': categories,
        'imageUrl': imageUrl,
        'createdBy': user.uid,
        'createdByName': creatorName,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'isActive': true,
        'rules': rules,
        'tags': tags,
        'privacy': isPublic ? 'public' : 'private',
        'coverImageUrl': null,
      };

      final docRef = await _firestore.collection('communities').add(communityData);
      
      // Add creator as first member
      await _firestore.collection('community_members').add({
        'userId': user.uid,
        'communityId': docRef.id,
        'role': 'admin',
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Community created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating community: $e');
      rethrow;
    }
  }

  // Get all communities
  Stream<List<Community>> getCommunities() {
    return _firestore
        .collection('communities')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final communities = snapshot.docs.map((doc) => Community.fromFirestore(doc)).toList();
          // Sort by creation date in descending order (newest first)
          communities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return communities;
        });
  }

  // Get user's joined communities
  Stream<List<Community>> getUserCommunities(String userId) {
    return _firestore
        .collection('community_members')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((memberSnapshot) async {
      final communityIds = memberSnapshot.docs.map((doc) => doc.data()['communityId'] as String).toList();
      
      if (communityIds.isEmpty) return <Community>[];
      
      final communitySnapshot = await _firestore
          .collection('communities')
          .where(FieldPath.documentId, whereIn: communityIds)
          .get();
      
      return communitySnapshot.docs.map((doc) => Community.fromFirestore(doc)).toList();
    });
  }

  // Get communities created by user
  Stream<List<Community>> getUserCreatedCommunities(String userId) {
    return _firestore
        .collection('communities')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Community.fromFirestore(doc)).toList());
  }

  // Join a community
  Future<bool> joinCommunity(String communityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is already a member
      final existingMember = await _firestore
          .collection('community_members')
          .where('userId', isEqualTo: user.uid)
          .where('communityId', isEqualTo: communityId)
          .get();

      if (existingMember.docs.isNotEmpty) {
        return true; // Already a member
      }

      // Add user to members collection
      await _firestore.collection('community_members').add({
        'userId': user.uid,
        'communityId': communityId,
        'role': 'member',
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Increment member count
      await _firestore.collection('communities').doc(communityId).update({
        'memberCount': FieldValue.increment(1),
      });

      print('✅ Successfully joined community: $communityId');
      return true;
    } catch (e) {
      print('❌ Error joining community: $e');
      return false;
    }
  }

  // Leave a community
  Future<bool> leaveCommunity(String communityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Remove from members collection
      final memberQuery = await _firestore
          .collection('community_members')
          .where('userId', isEqualTo: user.uid)
          .where('communityId', isEqualTo: communityId)
          .get();

      for (var doc in memberQuery.docs) {
        await doc.reference.delete();
      }

      // Decrement member count
      await _firestore.collection('communities').doc(communityId).update({
        'memberCount': FieldValue.increment(-1),
      });

      print('✅ Successfully left community: $communityId');
      return true;
    } catch (e) {
      print('❌ Error leaving community: $e');
      return false;
    }
  }

  // Check if user is member of community
  Future<bool> isUserMember(String communityId, String userId) async {
    try {
      final memberQuery = await _firestore
          .collection('community_members')
          .where('userId', isEqualTo: userId)
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: 'active')
          .get();

      return memberQuery.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking membership: $e');
      return false;
    }
  }

  // Get community by ID
  Future<Community?> getCommunity(String communityId) async {
    try {
      final doc = await _firestore.collection('communities').doc(communityId).get();
      if (!doc.exists) return null;

      return Community.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting community: $e');
      return null;
    }
  }

  // Create a post in community
  Future<String> createCommunityPost({
    required String communityId,
    required String title,
    required String content,
    List<String> images = const [],
    List<String> tags = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for author name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final authorName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

      final postData = {
        'communityId': communityId,
        'title': title,
        'content': content,
        'authorId': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'images': images,
        'tags': tags,
        'isPinned': false,
        'isReported': false,
        'reportReason': '',
        'status': 'active',
        'sharedFrom': null,
        'sharedFromType': null,
      };

      final docRef = await _firestore.collection('community_posts').add(postData);
      
      // Increment post count in community
      await _firestore.collection('communities').doc(communityId).update({
        // Note: We'll need to add a postCount field to the Community model
      });

      print('✅ Community post created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating community post: $e');
      rethrow;
    }
  }

  // Get posts for a community
  Stream<List<CommunityPost>> getCommunityPosts(String communityId) {
    return _firestore
        .collection('community_posts')
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();
          // Sort by creation date in descending order (newest first)
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  // Like a post
  Future<void> likePost(String communityId, String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already liked this post
      final likeQuery = await _firestore
          .collection('post_likes')
          .where('userId', isEqualTo: user.uid)
          .where('postId', isEqualTo: postId)
          .get();

      if (likeQuery.docs.isNotEmpty) {
        // User already liked, remove like
        for (var doc in likeQuery.docs) {
          await doc.reference.delete();
        }
        // Decrement likes count
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Add like
        await _firestore.collection('post_likes').add({
          'userId': user.uid,
          'postId': postId,
          'communityId': communityId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Increment likes count
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('❌ Error liking post: $e');
      rethrow;
    }
  }

  // Get comments for a post
  Stream<List<CommunityComment>> getPostComments(String communityId, String postId) {
    return _firestore
        .collection('community_comments')
        .where('postId', isEqualTo: postId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommunityComment.fromFirestore(doc)).toList());
  }

  // Create a comment
  Future<String> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for author name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final authorName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

      final commentData = {
        'postId': postId,
        'content': content,
        'authorId': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'isReported': false,
        'status': 'active',
      };

      final docRef = await _firestore.collection('community_comments').add(commentData);
      
      // Increment comments count
      await _firestore.collection('community_posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      print('✅ Comment created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating comment: $e');
      rethrow;
    }
  }

  // Search communities
  Stream<List<Community>> searchCommunities(String query) {
    if (query.isEmpty) {
      return getCommunities();
    }

    return _firestore
        .collection('communities')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final communities = snapshot.docs.map((doc) => Community.fromFirestore(doc)).toList();
      return communities.where((community) {
        return community.name.toLowerCase().contains(query.toLowerCase()) ||
               community.description.toLowerCase().contains(query.toLowerCase()) ||
               community.categories.any((category) => 
                 category.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  // Share news to community (for the article detail screen)
  Future<String> shareNewsToCommunity({
    required String communityId,
    required String newsTitle,
    required String newsContent,
    String? newsImageUrl,
    required String sharedFrom,
    required String sharedFromType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for author name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final authorName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

      final postData = {
        'communityId': communityId,
        'title': 'Shared: $newsTitle',
        'content': newsContent,
        'authorId': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'images': newsImageUrl != null ? [newsImageUrl] : [],
        'tags': ['shared', 'news'],
        'isPinned': false,
        'isReported': false,
        'reportReason': '',
        'status': 'active',
        'sharedFrom': sharedFrom,
        'sharedFromType': sharedFromType,
      };

      final docRef = await _firestore.collection('community_posts').add(postData);
      
      print('✅ News shared to community successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error sharing news to community: $e');
      rethrow;
    }
  }

  // Get community categories
  List<String> getCategories() {
    return CommunityCategory.categories;
  }

  // Get category icons
  Map<String, String> getCategoryIcons() {
    return CommunityCategory.categoryIcons;
  }

  // Delete community (only for community leaders and anti-corruption officers)
  Future<void> deleteCommunity(String communityId, String userId) async {
    try {
      // First check if user has permission to delete
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final userRole = userData['roleId'] ?? '';
      final userType = userData['userType'] ?? '';

      // Only community leaders and anti-corruption officers can delete communities
      if (userRole != 'community_leader' && userRole != 'anticorruption_officer') {
        throw Exception('Insufficient permissions to delete community');
      }

      // Get community details to check if user is the creator
      final communityDoc = await _firestore.collection('communities').doc(communityId).get();
      if (!communityDoc.exists) {
        throw Exception('Community not found');
      }

      final communityData = communityDoc.data()!;
      final createdBy = communityData['createdBy'] ?? '';

      // Anti-corruption officers can delete any community, but community leaders can only delete their own
      if (userRole == 'community_leader' && createdBy != userId) {
        throw Exception('You can only delete communities you created');
      }

      // Delete all community posts first
      final postsQuery = await _firestore
          .collection('community_posts')
          .where('communityId', isEqualTo: communityId)
          .get();

      final batch = _firestore.batch();
      
      // Delete all posts
      for (final doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete all community members
      final membersQuery = await _firestore
          .collection('community_members')
          .where('communityId', isEqualTo: communityId)
          .get();

      for (final doc in membersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the community itself
      batch.delete(_firestore.collection('communities').doc(communityId));

      await batch.commit();
      
      print('✅ Community deleted successfully: $communityId');
    } catch (e) {
      print('❌ Error deleting community: $e');
      rethrow;
    }
  }

  // Check if user can delete a specific community
  Future<bool> canDeleteCommunity(String communityId, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final userRole = userData['roleId'] ?? '';
      final userType = userData['userType'] ?? '';

      // Anti-corruption officers can delete any community
      if (userRole == 'anticorruption_officer') return true;

      // Community leaders can only delete communities they created
      if (userRole == 'community_leader') {
        final communityDoc = await _firestore.collection('communities').doc(communityId).get();
        if (!communityDoc.exists) return false;
        
        final communityData = communityDoc.data()!;
        final createdBy = communityData['createdBy'] ?? '';
        return createdBy == userId;
      }

      return false;
    } catch (e) {
      print('❌ Error checking delete permissions: $e');
      return false;
    }
  }
}
