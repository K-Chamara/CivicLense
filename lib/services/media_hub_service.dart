import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MediaHubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _hubCol => _db.collection('mediaHub');
  CollectionReference<Map<String, dynamic>> get _discussionsCol => _db.collection('mediaHubDiscussions');

  Future<String> shareArticleToHub({
    required String articleId,
    required String title,
    required String summary,
    required String authorName,
  }) async {
    final doc = await _hubCol.add({
      'articleId': articleId,
      'title': title,
      'summary': summary,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> createDiscussion({
    required String title,
    required String content,
    String? articleId,
    String? articleTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to create discussions');
    }

    String userName = 'User'; // Default fallback
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      userName = user.displayName!;
    } else if (user.email != null && user.email!.isNotEmpty) {
      userName = user.email!.split('@').first;
    }

    final doc = await _discussionsCol.add({
      'title': title,
      'content': content,
      'authorUid': user.uid,
      'authorName': userName,
      'createdAt': FieldValue.serverTimestamp(),
      'commentCount': 0,
      'likeCount': 0,
      if (articleId != null) 'articleId': articleId,
      if (articleTitle != null) 'articleTitle': articleTitle,
    });
    return doc.id;
  }

  /// Search articles for tagging in discussions
  Future<List<Map<String, dynamic>>> searchArticles(String query) async {
    if (query.trim().isEmpty) return [];
    
    final snapshot = await _db
        .collection('articles')
        .where('title', isGreaterThanOrEqualTo: query.trim())
        .where('title', isLessThanOrEqualTo: query.trim() + '\uf8ff')
        .limit(10)
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'title': doc.data()['title'] ?? '',
      'summary': doc.data()['summary'] ?? '',
      'authorName': doc.data()['authorName'] ?? '',
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> streamHubPosts() {
    return _hubCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> streamDiscussions() {
    return _discussionsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> deleteHubPost(String id) async {
    await _hubCol.doc(id).delete();
  }

  Future<void> deleteDiscussion(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in');
    }

    final doc = await _discussionsCol.doc(id).get();
    if (!doc.exists) {
      throw Exception('Discussion not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['authorUid'] != user.uid) {
      throw Exception('You can only delete your own discussions');
    }

    await _discussionsCol.doc(id).delete();
  }

  Future<void> addComment({
    required String discussionId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to comment');
    }

    String userName = 'User'; // Default fallback
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      userName = user.displayName!;
    } else if (user.email != null && user.email!.isNotEmpty) {
      userName = user.email!.split('@').first;
    }

    final comment = {
      'discussionId': discussionId,
      'text': text,
      'authorUid': user.uid,
      'authorName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.runTransaction((tx) async {
      tx.set(_discussionsCol.doc(discussionId).collection('comments').doc(), comment);
      tx.update(_discussionsCol.doc(discussionId), {
        'commentCount': FieldValue.increment(1),
      });
    });
  }

  Stream<List<Map<String, dynamic>>> streamComments(String discussionId) {
    return _discussionsCol
        .doc(discussionId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> toggleLikeDiscussion(String discussionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to like');
    }

    final likeRef = _discussionsCol.doc(discussionId).collection('likes').doc(user.uid);
    
    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(_discussionsCol.doc(discussionId), {
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        tx.set(likeRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(_discussionsCol.doc(discussionId), {
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  Stream<bool> streamUserLikedDiscussion(String discussionId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream<bool>.value(false);
    }
    return _discussionsCol
        .doc(discussionId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }
}


