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

enum SentimentScore {
  veryNegative,
  negative,
  neutral,
  positive,
  veryPositive
}

enum CommunityType {
  budget,
  tender,
  corruption,
  transparency,
  general
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
  final String? authorRole;
  final String? authorPhone;
  final String? authorLocation;
  final ConcernCategory category;
  final ConcernType type;
  final ConcernPriority priority;
  final ConcernStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final SentimentScore? sentimentScore;
  final double? sentimentMagnitude;
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final List<String> tags;
  final List<String> relatedBudgetIds;
  final List<String> relatedTenderIds;
  final String? communityId;
  final int engagementScore;
  final bool isFlaggedByCitizens;
  final List<ConcernComment> comments;
  final List<ConcernAttachment> attachments;
  final String? relatedBudgetId;
  final String? relatedTenderId;
  final String? relatedCommunityId;
  final bool isAnonymous;
  final bool isPublic;
  final int upvotes;
  final int downvotes;
  final int supportCount;
  final int commentCount;
  final List<ConcernUpdate> updates;
  final Map<String, dynamic> metadata;

  Concern({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    this.authorRole,
    this.authorPhone,
    this.authorLocation,
    required this.category,
    required this.type,
    this.priority = ConcernPriority.medium,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.sentimentScore,
    this.sentimentMagnitude,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.tags = const [],
    this.relatedBudgetIds = const [],
    this.relatedTenderIds = const [],
    this.communityId,
    this.engagementScore = 0,
    this.isFlaggedByCitizens = false,
    this.comments = const [],
    this.attachments = const [],
    this.relatedBudgetId,
    this.relatedTenderId,
    this.relatedCommunityId,
    this.isAnonymous = false,
    this.isPublic = true,
    this.upvotes = 0,
    this.downvotes = 0,
    this.supportCount = 0,
    this.commentCount = 0,
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
      'authorRole': authorRole,
      'authorPhone': authorPhone,
      'authorLocation': authorLocation,
      'category': category.name,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'sentimentScore': sentimentScore?.name,
      'sentimentMagnitude': sentimentMagnitude,
      'assignedOfficerId': assignedOfficerId,
      'assignedOfficerName': assignedOfficerName,
      'tags': tags,
      'relatedBudgetIds': relatedBudgetIds,
      'relatedTenderIds': relatedTenderIds,
      'communityId': communityId,
      'engagementScore': engagementScore,
      'isFlaggedByCitizens': isFlaggedByCitizens,
      'comments': comments.map((c) => c.toFirestore()).toList(),
      'attachments': attachments.map((a) => a.toFirestore()).toList(),
      'relatedBudgetId': relatedBudgetId,
      'relatedTenderId': relatedTenderId,
      'relatedCommunityId': relatedCommunityId,
      'isAnonymous': isAnonymous,
      'isPublic': isPublic,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'supportCount': supportCount,
      'commentCount': commentCount,
      'updates': updates.map((u) => u.toFirestore()).toList(),
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
      authorRole: data['authorRole'],
      authorPhone: data['authorPhone'],
      authorLocation: data['authorLocation'],
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
      sentimentScore: data['sentimentScore'] != null 
          ? SentimentScore.values.firstWhere(
              (e) => e.name == data['sentimentScore'],
              orElse: () => SentimentScore.neutral,
            )
          : null,
      sentimentMagnitude: data['sentimentMagnitude']?.toDouble(),
      assignedOfficerId: data['assignedOfficerId'],
      assignedOfficerName: data['assignedOfficerName'],
      tags: List<String>.from(data['tags'] ?? []),
      relatedBudgetIds: List<String>.from(data['relatedBudgetIds'] ?? []),
      relatedTenderIds: List<String>.from(data['relatedTenderIds'] ?? []),
      communityId: data['communityId'],
      engagementScore: data['engagementScore'] ?? 0,
      isFlaggedByCitizens: data['isFlaggedByCitizens'] ?? false,
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((c) => ConcernComment.fromFirestore(c as DocumentSnapshot))
          .toList(),
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((a) => ConcernAttachment.fromFirestore(a as DocumentSnapshot))
          .toList(),
      relatedBudgetId: data['relatedBudgetId'],
      relatedTenderId: data['relatedTenderId'],
      relatedCommunityId: data['relatedCommunityId'],
      isAnonymous: data['isAnonymous'] ?? false,
      isPublic: data['isPublic'] ?? true,
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      supportCount: data['supportCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      updates: (data['updates'] as List<dynamic>? ?? [])
          .map((u) => ConcernUpdate.fromFirestore(u as DocumentSnapshot))
          .toList(),
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
    String? authorRole,
    String? authorPhone,
    String? authorLocation,
    ConcernCategory? category,
    ConcernType? type,
    ConcernPriority? priority,
    ConcernStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    SentimentScore? sentimentScore,
    double? sentimentMagnitude,
    String? assignedOfficerId,
    String? assignedOfficerName,
    List<String>? tags,
    List<String>? relatedBudgetIds,
    List<String>? relatedTenderIds,
    String? communityId,
    int? engagementScore,
    bool? isFlaggedByCitizens,
    List<ConcernComment>? comments,
    List<ConcernAttachment>? attachments,
    String? relatedBudgetId,
    String? relatedTenderId,
    String? relatedCommunityId,
    bool? isAnonymous,
    bool? isPublic,
    int? upvotes,
    int? downvotes,
    int? supportCount,
    int? commentCount,
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
      authorRole: authorRole ?? this.authorRole,
      authorPhone: authorPhone ?? this.authorPhone,
      authorLocation: authorLocation ?? this.authorLocation,
      category: category ?? this.category,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      sentimentMagnitude: sentimentMagnitude ?? this.sentimentMagnitude,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
      tags: tags ?? this.tags,
      relatedBudgetIds: relatedBudgetIds ?? this.relatedBudgetIds,
      relatedTenderIds: relatedTenderIds ?? this.relatedTenderIds,
      communityId: communityId ?? this.communityId,
      engagementScore: engagementScore ?? this.engagementScore,
      isFlaggedByCitizens: isFlaggedByCitizens ?? this.isFlaggedByCitizens,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      relatedBudgetId: relatedBudgetId ?? this.relatedBudgetId,
      relatedTenderId: relatedTenderId ?? this.relatedTenderId,
      relatedCommunityId: relatedCommunityId ?? this.relatedCommunityId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPublic: isPublic ?? this.isPublic,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      supportCount: supportCount ?? this.supportCount,
      commentCount: commentCount ?? this.commentCount,
      updates: updates ?? this.updates,
      metadata: metadata ?? this.metadata,
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

// New classes for enhanced concern management
class ConcernComment {
  final String id;
  final String concernId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isOfficial;
  final String? officerId;

  ConcernComment({
    required this.id,
    required this.concernId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isOfficial = false,
    this.officerId,
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
      'officerId': officerId,
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
      officerId: data['officerId'],
    );
  }
}

class ConcernAttachment {
  final String id;
  final String concernId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final String uploadedBy;

  ConcernAttachment({
    required this.id,
    required this.concernId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'concernId': concernId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }

  static ConcernAttachment fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConcernAttachment(
      id: doc.id,
      concernId: data['concernId'] ?? '',
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }
}

class ConcernCommunity {
  final String id;
  final String name;
  final String description;
  final CommunityType type;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  final List<String> moderators;
  final bool isActive;
  final Map<String, dynamic> settings;

  ConcernCommunity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
    this.moderators = const [],
    this.isActive = true,
    this.settings = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members,
      'moderators': moderators,
      'isActive': isActive,
      'settings': settings,
    };
  }

  static ConcernCommunity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConcernCommunity(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: CommunityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CommunityType.general,
      ),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      members: List<String>.from(data['members'] ?? []),
      moderators: List<String>.from(data['moderators'] ?? []),
      isActive: data['isActive'] ?? true,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }
}
