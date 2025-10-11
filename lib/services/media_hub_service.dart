import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';

class MediaHubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _savedArticlesCol => _db.collection('savedArticles');

  /// Save a complete article to the Media Hub (Article Saving Module)
  Future<String> saveArticleToHub({
    required String originalArticleId,
    required String title,
    required String authorName,
    required String authorEmail,
    required String organization,
    required String abstractText,
    required String summary,
    required String content,
    required String references,
    required String category,
    required List<String> hashtags,
    required bool isBreakingNews,
    required bool isVerified,
    required String authorUid,
    String? bannerImageUrl,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to save articles');
    }

    // Check if article is already saved by this user
    final existingQuery = await _savedArticlesCol
        .where('originalArticleId', isEqualTo: originalArticleId)
        .where('savedByUid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception('Article is already saved in your Media Hub');
    }

    final doc = await _savedArticlesCol.add({
      'originalArticleId': originalArticleId,
      'title': title,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'organization': organization,
      'abstractText': abstractText,
      'summary': summary,
      'content': content,
      'references': references,
      'category': category,
      'hashtags': hashtags,
      'isBreakingNews': isBreakingNews,
      'isVerified': isVerified,
      'authorUid': authorUid,
      'bannerImageUrl': bannerImageUrl,
      'imageUrl': imageUrl,
      'savedByUid': user.uid,
      'savedByEmail': user.email,
      'savedAt': FieldValue.serverTimestamp(),
      'originalCreatedAt': FieldValue.serverTimestamp(), // Preserve original creation time
    });
    return doc.id;
  }

  /// Save a complete article from ReportArticle object
  Future<String> saveArticleFromReport(ReportArticle article) async {
    return await saveArticleToHub(
      originalArticleId: article.id,
      title: article.title,
      authorName: article.authorName,
      authorEmail: article.authorEmail,
      organization: article.organization,
      abstractText: article.abstractText,
      summary: article.summary,
      content: article.content,
      references: article.references,
      category: article.category,
      hashtags: article.hashtags,
      isBreakingNews: article.isBreakingNews,
      isVerified: article.isVerified,
      authorUid: article.authorUid,
      bannerImageUrl: article.bannerImageUrl,
      imageUrl: article.imageUrl,
    );
  }

  /// Stream saved articles for the current user
  Stream<List<Map<String, dynamic>>> streamSavedArticles() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _savedArticlesCol
        .where('savedByUid', isEqualTo: user.uid)
        .snapshots()
        .map((s) {
          final articles = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          
          // Sort locally by savedAt (most recent first)
          articles.sort((a, b) {
            final savedAtA = a['savedAt'] as Timestamp?;
            final savedAtB = b['savedAt'] as Timestamp?;
            
            if (savedAtA == null && savedAtB == null) return 0;
            if (savedAtA == null) return 1;
            if (savedAtB == null) return -1;
            
            return savedAtB.compareTo(savedAtA); // Descending order
          });
          
          return articles;
        });
  }

  /// Get a specific saved article
  Future<Map<String, dynamic>?> getSavedArticle(String savedArticleId) async {
    final doc = await _savedArticlesCol.doc(savedArticleId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Remove a saved article
  Future<void> removeSavedArticle(String savedArticleId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in');
    }

    final doc = await _savedArticlesCol.doc(savedArticleId).get();
    if (!doc.exists) {
      throw Exception('Saved article not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['savedByUid'] != user.uid) {
      throw Exception('You can only remove your own saved articles');
    }

    await _savedArticlesCol.doc(savedArticleId).delete();
  }

  /// Check if an article is saved by the current user
  Future<bool> isArticleSaved(String originalArticleId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final query = await _savedArticlesCol
        .where('originalArticleId', isEqualTo: originalArticleId)
        .where('savedByUid', isEqualTo: user.uid)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Stream to check if an article is saved by the current user
  Stream<bool> streamIsArticleSaved(String originalArticleId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _savedArticlesCol
        .where('originalArticleId', isEqualTo: originalArticleId)
        .where('savedByUid', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Search saved articles
  Future<List<Map<String, dynamic>>> searchSavedArticles(String query) async {
    final user = _auth.currentUser;
    if (user == null || query.trim().isEmpty) return [];
    
    final snapshot = await _savedArticlesCol
        .where('savedByUid', isEqualTo: user.uid)
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

  /// Get count of saved articles for the current user
  Stream<int> streamSavedArticlesCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _savedArticlesCol
        .where('savedByUid', isEqualTo: user.uid)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Get recent saved articles for the current user (limit 3)
  Stream<List<Map<String, dynamic>>> streamRecentSavedArticles() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _savedArticlesCol
        .where('savedByUid', isEqualTo: user.uid)
        .snapshots()
        .map((s) {
          final articles = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          
          // Sort locally by savedAt (most recent first)
          articles.sort((a, b) {
            final savedAtA = a['savedAt'] as Timestamp?;
            final savedAtB = b['savedAt'] as Timestamp?;
            
            if (savedAtA == null && savedAtB == null) return 0;
            if (savedAtA == null) return 1;
            if (savedAtB == null) return -1;
            
            return savedAtB.compareTo(savedAtA); // Descending order
          });
          
          return articles.take(3).toList();
        });
  }
}