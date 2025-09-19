import 'package:cloud_firestore/cloud_firestore.dart';

/// Community model representing a community group
class Community {
  final String id;
  final String name;
  final String description;
  final String category;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final int memberCount;
  final bool isActive;
  final List<String> rules;
  final List<String> tags;
  final String? imageUrl;
  final String privacy; // public, private, restricted
  final String? coverImageUrl;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.memberCount,
    required this.isActive,
    required this.rules,
    required this.tags,
    this.imageUrl,
    required this.privacy,
    this.coverImageUrl,
  });

  factory Community.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Community(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      memberCount: data['memberCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      rules: List<String>.from(data['rules'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      privacy: data['privacy'] ?? 'public',
      coverImageUrl: data['coverImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberCount': memberCount,
      'isActive': isActive,
      'rules': rules,
      'tags': tags,
      'imageUrl': imageUrl,
      'privacy': privacy,
      'coverImageUrl': coverImageUrl,
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    int? memberCount,
    bool? isActive,
    List<String>? rules,
    List<String>? tags,
    String? imageUrl,
    String? privacy,
    String? coverImageUrl,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      isActive: isActive ?? this.isActive,
      rules: rules ?? this.rules,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      privacy: privacy ?? this.privacy,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  static DateTime _parseDateTime(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    } else if (data is String) {
      return DateTime.parse(data);
    } else if (data is DateTime) {
      return data;
    }
    return DateTime.now();
  }
}

/// Community post model
class CommunityPost {
  final String id;
  final String communityId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final List<String> images;
  final List<String> tags;
  final bool isPinned;
  final bool isReported;
  final String reportReason;
  final String status; // active, hidden, deleted
  final String? sharedFrom; // If shared from news, store the news article ID
  final String? sharedFromType; // 'news', 'tender', etc.

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.images,
    required this.tags,
    required this.isPinned,
    required this.isReported,
    required this.reportReason,
    required this.status,
    this.sharedFrom,
    this.sharedFromType,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityPost(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isPinned: data['isPinned'] ?? false,
      isReported: data['isReported'] ?? false,
      reportReason: data['reportReason'] ?? '',
      status: data['status'] ?? 'active',
      sharedFrom: data['sharedFrom'],
      sharedFromType: data['sharedFromType'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityId': communityId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'comments': comments,
      'images': images,
      'tags': tags,
      'isPinned': isPinned,
      'isReported': isReported,
      'reportReason': reportReason,
      'status': status,
      'sharedFrom': sharedFrom,
      'sharedFromType': sharedFromType,
    };
  }

  static DateTime _parseDateTime(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    } else if (data is String) {
      return DateTime.parse(data);
    } else if (data is DateTime) {
      return data;
    }
    return DateTime.now();
  }
}

/// Community comment model
class CommunityComment {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likes;
  final bool isReported;
  final String status; // active, hidden, deleted

  CommunityComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.likes,
    required this.isReported,
    required this.status,
  });

  factory CommunityComment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      likes: data['likes'] ?? 0,
      isReported: data['isReported'] ?? false,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'isReported': isReported,
      'status': status,
    };
  }

  static DateTime _parseDateTime(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    } else if (data is String) {
      return DateTime.parse(data);
    } else if (data is DateTime) {
      return data;
    }
    return DateTime.now();
  }
}

/// Community member model
class CommunityMember {
  final String userId;
  final String communityId;
  final String role; // member, moderator, admin
  final String status; // active, banned, pending
  final DateTime joinedAt;

  CommunityMember({
    required this.userId,
    required this.communityId,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  factory CommunityMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityMember(
      userId: data['userId'] ?? '',
      communityId: data['communityId'] ?? '',
      role: data['role'] ?? 'member',
      status: data['status'] ?? 'active',
      joinedAt: _parseDateTime(data['joinedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'communityId': communityId,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  static DateTime _parseDateTime(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    } else if (data is String) {
      return DateTime.parse(data);
    } else if (data is DateTime) {
      return data;
    }
    return DateTime.now();
  }
}

/// Community categories
class CommunityCategory {
  static const List<String> categories = [
    'General',
    'Environment',
    'Politics',
    'Health',
    'Education',
    'Infrastructure',
    'Economy',
    'Technology',
    'Social Issues',
    'Local News',
    'Business',
    'Sports',
    'Culture',
    'Science',
    'Other',
  ];

  static const Map<String, String> categoryIcons = {
    'General': '🌐',
    'Environment': '🌱',
    'Politics': '🏛️',
    'Health': '🏥',
    'Education': '📚',
    'Infrastructure': '🏗️',
    'Economy': '💰',
    'Technology': '💻',
    'Social Issues': '👥',
    'Local News': '📰',
    'Business': '💼',
    'Sports': '⚽',
    'Culture': '🎭',
    'Science': '🔬',
    'Other': '📋',
  };
}
