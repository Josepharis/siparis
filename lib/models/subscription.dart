class Subscription {
  final String id;
  final String userId;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? activatedBy;

  Subscription({
    required this.id,
    required this.userId,
    required this.isActive,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.activatedBy,
  });

  bool get isValid {
    if (!isActive) return false;
    if (endDate == null) return true;
    return endDate!.isAfter(DateTime.now());
  }

  int get remainingDays {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isActive': isActive,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'activatedBy': activatedBy,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map, String docId) {
    return Subscription(
      id: docId,
      userId: map['userId'] ?? '',
      isActive: map['isActive'] ?? false,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      activatedBy: map['activatedBy'],
    );
  }
}
