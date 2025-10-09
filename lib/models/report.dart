import 'package:cloud_firestore/cloud_firestore.dart';

class ReportArticle {
  final String id;
  final String title;
  final String authorName;
  final String authorEmail;
  final String organization;
  final String abstractText;
  final String summary;
  final String content;
  final String references;
  final String category;
  final List<String> hashtags;
  final bool isBreakingNews;
  final bool isVerified;
  final String authorUid;
  final int likeCount;
  final int commentCount;
  final Timestamp createdAt;
  final String? bannerImageUrl;

  ReportArticle({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorEmail,
    required this.organization,
    required this.abstractText,
    required this.summary,
    required this.content,
    required this.references,
    required this.category,
    required this.hashtags,
    required this.isBreakingNews,
    required this.isVerified,
    required this.authorUid,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.bannerImageUrl,
  });

  factory ReportArticle.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReportArticle(
      id: doc.id,
      title: data['title'] ?? '',
      authorName: data['authorName'] ?? '',
      authorEmail: data['authorEmail'] ?? '',
      organization: data['organization'] ?? '',
      abstractText: data['abstract'] ?? '',
      summary: data['summary'] ?? '',
      content: data['content'] ?? '',
      references: data['references'] ?? '',
      category: data['category'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? <String>[]),
      isBreakingNews: data['isBreakingNews'] ?? false,
      isVerified: data['isVerified'] ?? false,
      authorUid: data['authorUid'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      bannerImageUrl: data['bannerImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'organization': organization,
      'abstract': abstractText,
      'summary': summary,
      'content': content,
      'references': references,
      'category': category,
      'hashtags': hashtags,
      'isBreakingNews': isBreakingNews,
      'isVerified': isVerified,
      'authorUid': authorUid,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt,
      'bannerImageUrl': bannerImageUrl,
    };
  }
}

class ArticleComment {
  final String id;
  final String articleId;
  final String userUid;
  final String userName;
  final String text;
  final Timestamp createdAt;

  ArticleComment({
    required this.id,
    required this.articleId,
    required this.userUid,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory ArticleComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ArticleComment(
      id: doc.id,
      articleId: data['articleId'] ?? '',
      userUid: data['userUid'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'articleId': articleId,
      'userUid': userUid,
      'userName': userName,
      'text': text,
      'createdAt': createdAt,
    };
  }
}


