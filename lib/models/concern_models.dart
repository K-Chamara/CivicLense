import 'package:cloud_firestore/cloud_firestore.dart';

enum ConcernCategory {
  budget,
  tender,
  community,
  system,
  corruption,
  transparency,
  other
}

enum ConcernPriority {
  low,
  medium,
  high,
  critical
}

enum ConcernStatus {
  pending,
  underReview,
  inProgress,
  resolved,
  dismissed,
  escalated
}

enum ConcernType {
  complaint,
  suggestion,
  report,
  question,
  feedback
}

class Concern {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final ConcernCategory category;
  final ConcernType type;
  final ConcernPriority priority;
  final ConcernStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? relatedBudgetId;
  final String? relatedTenderId;
  final String? relatedCommunityId;
  final List<String> tags;
  final List<String> attachments;
  final bool isAnonymous;
  final bool isPublic;
  final int upvotes;
  final int downvotes;
  final int supportCount;
  final int commentCount;
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final List<ConcernComment> comments;
  final List<ConcernUpdate> updates;
  final Map<String, dynamic> metadata;

  Concern({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.category,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.relatedBudgetId,
    this.relatedTenderId,
    this.relatedCommunityId,
    this.tags = const [],
    this.attachments = const [],
    this.isAnonymous = false,
    this.isPublic = true,
    this.upvotes = 0,
    this.downvotes = 0,
    this.supportCount = 0,
    this.commentCount = 0,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.comments = const [],
    this.updates = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'category': category.name,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'relatedBudgetId': relatedBudgetId,
      'relatedTenderId': relatedTenderId,
      'relatedCommunityId': relatedCommunityId,
      'tags': tags,
      'attachments': attachments,
      'isAnonymous': isAnonymous,
      'isPublic': isPublic,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'supportCount': supportCount,
      'commentCount': commentCount,
      'assignedOfficerId': assignedOfficerId,
      'assignedOfficerName': assignedOfficerName,
      'metadata': metadata,
    };
  }

  static Concern fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Concern(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorEmail: data['authorEmail'] ?? '',
      category: ConcernCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ConcernCategory.other,
      ),
      type: ConcernType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ConcernType.complaint,
      ),
      priority: ConcernPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => ConcernPriority.medium,
      ),
      status: ConcernStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ConcernStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
      relatedBudgetId: data['relatedBudgetId'],
      relatedTenderId: data['relatedTenderId'],
      relatedCommunityId: data['relatedCommunityId'],
      tags: List<String>.from(data['tags'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      isAnonymous: data['isAnonymous'] ?? false,
      isPublic: data['isPublic'] ?? true,
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      supportCount: data['supportCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      assignedOfficerId: data['assignedOfficerId'],
      assignedOfficerName: data['assignedOfficerName'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Concern copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? authorEmail,
    ConcernCategory? category,
    ConcernType? type,
    ConcernPriority? priority,
    ConcernStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? relatedBudgetId,
    String? relatedTenderId,
    String? relatedCommunityId,
    List<String>? tags,
    List<String>? attachments,
    bool? isAnonymous,
    bool? isPublic,
    int? upvotes,
    int? downvotes,
    int? supportCount,
    int? commentCount,
    String? assignedOfficerId,
    String? assignedOfficerName,
    List<ConcernComment>? comments,
    List<ConcernUpdate>? updates,
    Map<String, dynamic>? metadata,
  }) {
    return Concern(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      category: category ?? this.category,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      relatedBudgetId: relatedBudgetId ?? this.relatedBudgetId,
      relatedTenderId: relatedTenderId ?? this.relatedTenderId,
      relatedCommunityId: relatedCommunityId ?? this.relatedCommunityId,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPublic: isPublic ?? this.isPublic,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      supportCount: supportCount ?? this.supportCount,
      commentCount: commentCount ?? this.commentCount,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
      comments: comments ?? this.comments,
      updates: updates ?? this.updates,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ConcernComment {
  final String id;
  final String concernId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isOfficial;
  final bool isInternal;
  final List<String> attachments;

  ConcernComment({
    required this.id,
    required this.concernId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isOfficial = false,
    this.isInternal = false,
    this.attachments = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'concernId': concernId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOfficial': isOfficial,
      'isInternal': isInternal,
      'attachments': attachments,
    };
  }

  static ConcernComment fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConcernComment(
      id: doc.id,
      concernId: data['concernId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isOfficial: data['isOfficial'] ?? false,
      isInternal: data['isInternal'] ?? false,
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }
}

class ConcernUpdate {
  final String id;
  final String concernId;
  final String officerId;
  final String officerName;
  final String action;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic> changes;

  ConcernUpdate({
    required this.id,
    required this.concernId,
    required this.officerId,
    required this.officerName,
    required this.action,
    required this.description,
    required this.createdAt,
    this.changes = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'concernId': concernId,
      'officerId': officerId,
      'officerName': officerName,
      'action': action,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'changes': changes,
    };
  }

  static ConcernUpdate fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConcernUpdate(
      id: doc.id,
      concernId: data['concernId'] ?? '',
      officerId: data['officerId'] ?? '',
      officerName: data['officerName'] ?? '',
      action: data['action'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      changes: Map<String, dynamic>.from(data['changes'] ?? {}),
    );
  }
}

class ConcernFilter {
  final ConcernCategory? category;
  final ConcernType? type;
  final ConcernPriority? priority;
  final ConcernStatus? status;
  final String? assignedOfficerId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchQuery;
  final bool? isPublic;
  final bool? isAnonymous;

  ConcernFilter({
    this.category,
    this.type,
    this.priority,
    this.status,
    this.assignedOfficerId,
    this.dateFrom,
    this.dateTo,
    this.searchQuery,
    this.isPublic,
    this.isAnonymous,
  });
}

class ConcernSupport {
  final String id;
  final String concernId;
  final String userId;
  final String userName;
  final DateTime supportedAt;
  final bool isActive;

  ConcernSupport({
    required this.id,
    required this.concernId,
    required this.userId,
    required this.userName,
    required this.supportedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'concernId': concernId,
      'userId': userId,
      'userName': userName,
      'supportedAt': Timestamp.fromDate(supportedAt),
      'isActive': isActive,
    };
  }

  static ConcernSupport fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConcernSupport(
      id: doc.id,
      concernId: data['concernId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      supportedAt: (data['supportedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class ConcernStats {
  final int totalConcerns;
  final int pendingConcerns;
  final int inProgressConcerns;
  final int resolvedConcerns;
  final int criticalConcerns;
  final Map<ConcernCategory, int> concernsByCategory;
  final Map<ConcernPriority, int> concernsByPriority;
  final double averageResolutionTime;
  final int concernsThisMonth;
  final int concernsLastMonth;

  ConcernStats({
    required this.totalConcerns,
    required this.pendingConcerns,
    required this.inProgressConcerns,
    required this.resolvedConcerns,
    required this.criticalConcerns,
    required this.concernsByCategory,
    required this.concernsByPriority,
    required this.averageResolutionTime,
    required this.concernsThisMonth,
    required this.concernsLastMonth,
  });
}
