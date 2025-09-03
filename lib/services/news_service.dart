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

  Future<void> addComment({required String articleId, required String text, required String userName}) async {
    final uid = _auth.currentUser?.uid ?? '';
    final comment = ArticleComment(
      id: '',
      articleId: articleId,
      userUid: uid,
      userName: userName,
      text: text,
      createdAt: Timestamp.now(),
    );
    final ref = _articlesCol.doc(articleId).collection('comments');
    await _db.runTransaction((tx) async {
      tx.set(ref.doc(), comment.toMap());
      tx.update(_articlesCol.doc(articleId), {'commentCount': FieldValue.increment(1)});
    });
  }
}


