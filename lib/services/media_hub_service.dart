import 'package:cloud_firestore/cloud_firestore.dart';

class MediaHubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _hubCol => _db.collection('mediaHub');

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

  Stream<List<Map<String, dynamic>>> streamHubPosts() {
    return _hubCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> deleteHubPost(String id) async {
    await _hubCol.doc(id).delete();
  }
}


