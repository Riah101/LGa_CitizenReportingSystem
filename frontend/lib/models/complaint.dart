
enum ComplaintStatus {
  pending,
  inProgress,
  escalated,
  resolved,
  closed,
}

enum GovernmentLevel {
  mtaa,      // Street/Village level
  ward,      // Ward level
  district,  // District level
  region,    // Regional level
  national,  // National level
}

enum ComplaintCategory {
  infrastructure,
  water,
  electricity,
  health,
  education,
  security,
  environment,
  socialServices,
  corruption,
  other,
}

class EscalationRule {
  final GovernmentLevel fromLevel;
  final GovernmentLevel toLevel;
  final int daysBeforeEscalation;

  const EscalationRule({
    required this.fromLevel,
    required this.toLevel,
    required this.daysBeforeEscalation,
  });
}

class EscalationHistory {
  final GovernmentLevel fromLevel;
  final GovernmentLevel toLevel;
  final DateTime escalatedAt;
  final String reason;

  EscalationHistory({
    required this.fromLevel,
    required this.toLevel,
    required this.escalatedAt,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'fromLevel': fromLevel.name,
        'toLevel': toLevel.name,
        'escalatedAt': escalatedAt.toIso8601String(),
        'reason': reason,
      };

  factory EscalationHistory.fromJson(Map<String, dynamic> json) =>
      EscalationHistory(
        fromLevel: GovernmentLevel.values.byName(json['fromLevel']),
        toLevel: GovernmentLevel.values.byName(json['toLevel']),
        escalatedAt: DateTime.parse(json['escalatedAt']),
        reason: json['reason'],
      );
}

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final DateTime createdAt;
  final bool isOfficial;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.createdAt,
    this.isOfficial = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isOfficial': isOfficial,
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        authorRole: json['authorRole'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        isOfficial: json['isOfficial'] ?? false,
      );
}

class Complaint {
  final String id;
  final String citizenId;
  final String citizenName;
  final String citizenPhone;
  final String title;
  final String description;
  final ComplaintCategory category;
  ComplaintStatus status;
  GovernmentLevel currentLevel;
  
  // Location hierarchy
  final String mtaa;      // Mtaa/Street name
  final String ward;      // Ward
  final String district;  // District
  final String region;    // Region
  
  final DateTime submittedAt;
  DateTime updatedAt;
  DateTime? resolvedAt;
  
  final List<String> attachments;
  final List<EscalationHistory> escalationHistory;
  final List<Comment> comments;
  
  // Tracking
  int viewCount;
  int upvotes;
  bool isAnonymous;
  String trackingCode;
  
  // Priority
  int priorityScore;
  bool isUrgent;

  Complaint({
    required this.id,
    required this.citizenId,
    required this.citizenName,
    required this.citizenPhone,
    required this.title,
    required this.description,
    required this.category,
    this.status = ComplaintStatus.pending,
    this.currentLevel = GovernmentLevel.mtaa,
    required this.mtaa,
    required this.ward,
    required this.district,
    required this.region,
    required this.submittedAt,
    DateTime? updatedAt,
    this.resolvedAt,
    List<String>? attachments,
    List<EscalationHistory>? escalationHistory,
    List<Comment>? comments,
    this.viewCount = 0,
    this.upvotes = 0,
    this.isAnonymous = false,
    required this.trackingCode,
    this.priorityScore = 0,
    this.isUrgent = false,
  })  : updatedAt = updatedAt ?? submittedAt,
        attachments = attachments ?? [],
        escalationHistory = escalationHistory ?? [],
        comments = comments ?? [];

  // Escalation rules: days at each level before escalating
  static const Map<GovernmentLevel, int> escalationDays = {
    GovernmentLevel.mtaa: 7,      // 7 days at Mtaa before escalating to Ward
    GovernmentLevel.ward: 14,     // 14 days at Ward before escalating to District
    GovernmentLevel.district: 21, // 21 days at District before escalating to Region
    GovernmentLevel.region: 30,   // 30 days at Region before escalating to National
  };

  bool shouldEscalate() {
    if (status == ComplaintStatus.resolved || status == ComplaintStatus.closed) {
      return false;
    }
    if (currentLevel == GovernmentLevel.national) return false;

    final daysAllowed = escalationDays[currentLevel]!;
    final daysSinceLastAction = DateTime.now().difference(updatedAt).inDays;
    return daysSinceLastAction >= daysAllowed;
  }

  int daysUntilEscalation() {
    if (currentLevel == GovernmentLevel.national) return -1;
    final daysAllowed = escalationDays[currentLevel]!;
    final daysSinceLastAction = DateTime.now().difference(updatedAt).inDays;
    return (daysAllowed - daysSinceLastAction).clamp(0, daysAllowed);
  }

  GovernmentLevel? nextLevel() {
    switch (currentLevel) {
      case GovernmentLevel.mtaa:
        return GovernmentLevel.ward;
      case GovernmentLevel.ward:
        return GovernmentLevel.district;
      case GovernmentLevel.district:
        return GovernmentLevel.region;
      case GovernmentLevel.region:
        return GovernmentLevel.national;
      case GovernmentLevel.national:
        return null;
    }
  }

  void escalate(String reason) {
    final next = nextLevel();
    if (next == null) return;

    escalationHistory.add(EscalationHistory(
      fromLevel: currentLevel,
      toLevel: next,
      escalatedAt: DateTime.now(),
      reason: reason,
    ));

    currentLevel = next;
    status = ComplaintStatus.escalated;
    updatedAt = DateTime.now();
  }

  String get statusLabel {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.escalated:
        return 'Escalated';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  String get statusLabelSw {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Inasubiri';
      case ComplaintStatus.inProgress:
        return 'Inashughulikiwa';
      case ComplaintStatus.escalated:
        return 'Imepandishwa';
      case ComplaintStatus.resolved:
        return 'Imesuluhiwa';
      case ComplaintStatus.closed:
        return 'Imefungwa';
    }
  }

  String get levelLabel {
    switch (currentLevel) {
      case GovernmentLevel.mtaa:
        return 'Mtaa';
      case GovernmentLevel.ward:
        return 'Kata';
      case GovernmentLevel.district:
        return 'Wilaya';
      case GovernmentLevel.region:
        return 'Mkoa';
      case GovernmentLevel.national:
        return 'Kitaifa';
    }
  }

  String get categoryLabel {
    switch (category) {
      case ComplaintCategory.infrastructure:
        return 'Infrastructure / Miundombinu';
      case ComplaintCategory.water:
        return 'Water / Maji';
      case ComplaintCategory.electricity:
        return 'Electricity / Umeme';
      case ComplaintCategory.health:
        return 'Health / Afya';
      case ComplaintCategory.education:
        return 'Education / Elimu';
      case ComplaintCategory.security:
        return 'Security / Usalama';
      case ComplaintCategory.environment:
        return 'Environment / Mazingira';
      case ComplaintCategory.socialServices:
        return 'Social Services / Huduma za Jamii';
      case ComplaintCategory.corruption:
        return 'Corruption / Rushwa';
      case ComplaintCategory.other:
        return 'Other / Nyingine';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'citizenId': citizenId,
        'citizenName': citizenName,
        'citizenPhone': citizenPhone,
        'title': title,
        'description': description,
        'category': category.name,
        'status': status.name,
        'currentLevel': currentLevel.name,
        'mtaa': mtaa,
        'ward': ward,
        'district': district,
        'region': region,
        'submittedAt': submittedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'attachments': attachments,
        'escalationHistory': escalationHistory.map((e) => e.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'viewCount': viewCount,
        'upvotes': upvotes,
        'isAnonymous': isAnonymous,
        'trackingCode': trackingCode,
        'priorityScore': priorityScore,
        'isUrgent': isUrgent,
      };

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'],
        citizenId: json['citizenId'],
        citizenName: json['citizenName'],
        citizenPhone: json['citizenPhone'],
        title: json['title'],
        description: json['description'],
        category: ComplaintCategory.values.byName(json['category']),
        status: ComplaintStatus.values.byName(json['status']),
        currentLevel: GovernmentLevel.values.byName(json['currentLevel']),
        mtaa: json['mtaa'],
        ward: json['ward'],
        district: json['district'],
        region: json['region'],
        submittedAt: DateTime.parse(json['submittedAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'])
            : null,
        attachments: List<String>.from(json['attachments'] ?? []),
        escalationHistory: (json['escalationHistory'] as List?)
                ?.map((e) => EscalationHistory.fromJson(e))
                .toList() ??
            [],
        comments: (json['comments'] as List?)
                ?.map((c) => Comment.fromJson(c))
                .toList() ??
            [],
        viewCount: json['viewCount'] ?? 0,
        upvotes: json['upvotes'] ?? 0,
        isAnonymous: json['isAnonymous'] ?? false,
        trackingCode: json['trackingCode'],
        priorityScore: json['priorityScore'] ?? 0,
        isUrgent: json['isUrgent'] ?? false,
      );
}
