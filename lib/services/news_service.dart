import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';

class NewsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _articlesCol => _db.collection('articles');

  Future<String> publishArticle(ReportArticle article) async {
    final doc = await _articlesCol.add(article.toMap());
    return doc.id;
  }

  Stream<List<ReportArticle>> streamArticles({
    String? searchQuery,
    String? category,
    bool? breakingOnly,
    bool? verifiedOnly,
  }) {
    Query<Map<String, dynamic>> q = _articlesCol.orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (breakingOnly == true) {
      q = q.where('isBreakingNews', isEqualTo: true);
    }
    if (verifiedOnly == true) {
      q = q.where('isVerified', isEqualTo: true);
    }

    return q.snapshots().map((snap) {
      final items = snap.docs.map((d) => ReportArticle.fromDoc(d)).toList();
      if (searchQuery == null || searchQuery.trim().isEmpty) return items;
      final s = searchQuery.toLowerCase();
      return items.where((a) {
        return a.title.toLowerCase().contains(s) ||
            a.summary.toLowerCase().contains(s) ||
            a.content.toLowerCase().contains(s) ||
            a.hashtags.any((h) => h.toLowerCase().contains(s));
      }).toList();
    });
  }

  Future<ReportArticle?> getArticle(String id) async {
    final doc = await _articlesCol.doc(id).get();
    if (!doc.exists) return null;
    return ReportArticle.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  Stream<ReportArticle?> streamArticle(String id) {
    return _articlesCol.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ReportArticle.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
    });
  }

  /// Returns a stream indicating whether the current user has liked the article
  Stream<bool> streamUserLiked(String articleId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      // No user -> never liked
      return Stream<bool>.value(false);
    }
    return _articlesCol
        .doc(articleId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }

  /// Toggle like by current user; ensures only one like per user
  Future<void> toggleLike(String articleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('You must be signed in to like');
    }
    final likeRef = _articlesCol.doc(articleId).collection('likes').doc(uid);
    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(_articlesCol.doc(articleId), {
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        tx.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(_articlesCol.doc(articleId), {
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> updateComment({
    required String articleId,
    required String commentId,
    required String newText,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final ref = _articlesCol.doc(articleId).collection('comments').doc(commentId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Comment not found');
    if (snap.data()?['userUid'] != uid) throw Exception('You can only edit your own comment');
    await ref.update({'text': newText});
  }

  Future<void> deleteComment({
    required String articleId,
    required String commentId,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final ref = _articlesCol.doc(articleId).collection('comments').doc(commentId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }
      if ((snap.data() as Map<String, dynamic>)['userUid'] != uid) {
        throw Exception('You can only delete your own comment');
      }
      tx.delete(ref);
      tx.update(_articlesCol.doc(articleId), {
        'commentCount': FieldValue.increment(-1),
      });
    });
  }

  Future<void> likeArticle(String id) async {
    await _articlesCol.doc(id).update({'likeCount': FieldValue.increment(1)});
  }

  Stream<List<ArticleComment>> streamComments(String articleId) {
    return _articlesCol
        .doc(articleId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ArticleComment.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> addComment({
    required String articleId,
    required String text,
    String? userName,
  }) async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('You must be signed in to comment');
    }
    final derivedName = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : ((user?.email?.isNotEmpty == true)
                ? (user!.email!.split('@').first)
                : 'User'));

    final comment = ArticleComment(
      id: '',
      articleId: articleId,
      userUid: uid,
      userName: derivedName,
      text: text,
      createdAt: Timestamp.now(),
    );
    final ref = _articlesCol.doc(articleId).collection('comments');
    await _db.runTransaction((tx) async {
      tx.set(ref.doc(), comment.toMap());
      tx.update(_articlesCol.doc(articleId), {'commentCount': FieldValue.increment(1)});
    });
  }

  /// Update article (only by author)
  Future<void> updateArticle({
    required String articleId,
    required String title,
    required String summary,
    required String content,
    required String abstractText,
    required String references,
    required String category,
    required List<String> hashtags,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('You must be signed in to edit articles');
    }

    final articleDoc = await _articlesCol.doc(articleId).get();
    if (!articleDoc.exists) {
      throw Exception('Article not found');
    }

    final articleData = articleDoc.data() as Map<String, dynamic>;
    if (articleData['authorUid'] != uid) {
      throw Exception('You can only edit your own articles');
    }

    await _articlesCol.doc(articleId).update({
      'title': title,
      'summary': summary,
      'content': content,
      'abstractText': abstractText,
      'references': references,
      'category': category,
      'hashtags': hashtags,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle breaking news status (only by author)
  Future<void> toggleBreakingNews(String articleId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('You must be signed in');
    }

    final articleDoc = await _articlesCol.doc(articleId).get();
    if (!articleDoc.exists) {
      throw Exception('Article not found');
    }

    final articleData = articleDoc.data() as Map<String, dynamic>;
    if (articleData['authorUid'] != uid) {
      throw Exception('You can only edit your own articles');
    }

    final currentStatus = articleData['isBreakingNews'] ?? false;
    await _articlesCol.doc(articleId).update({
      'isBreakingNews': !currentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle verified status (only by author)
  Future<void> toggleVerified(String articleId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('You must be signed in');
    }

    final articleDoc = await _articlesCol.doc(articleId).get();
    if (!articleDoc.exists) {
      throw Exception('Article not found');
    }

    final articleData = articleDoc.data() as Map<String, dynamic>;
    if (articleData['authorUid'] != uid) {
      throw Exception('You can only edit your own articles');
    }

    final currentStatus = articleData['isVerified'] ?? false;
    await _articlesCol.doc(articleId).update({
      'isVerified': !currentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete article (only by author)
  Future<void> deleteArticle(String articleId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('You must be signed in');
    }

    final articleDoc = await _articlesCol.doc(articleId).get();
    if (!articleDoc.exists) {
      throw Exception('Article not found');
    }

    final articleData = articleDoc.data() as Map<String, dynamic>;
    if (articleData['authorUid'] != uid) {
      throw Exception('You can only delete your own articles');
    }

    // Delete the article and all its subcollections
    await _articlesCol.doc(articleId).delete();
    
    // Delete likes subcollection
    final likesSnapshot = await _articlesCol.doc(articleId).collection('likes').get();
    for (var doc in likesSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Delete comments subcollection
    final commentsSnapshot = await _articlesCol.doc(articleId).collection('comments').get();
    for (var doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }
  }
}


