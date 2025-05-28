class WorkRequest {
  final String id;
  final String fromUserId;
  final String toCompanyId;
  final String fromUserName;
  final String toCompanyName;
  final String message;
  final WorkRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  WorkRequest({
    required this.id,
    required this.fromUserId,
    required this.toCompanyId,
    required this.fromUserName,
    required this.toCompanyName,
    required this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory WorkRequest.fromMap(Map<String, dynamic> map, String id) {
    return WorkRequest(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      toCompanyId: map['toCompanyId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toCompanyName: map['toCompanyName'] ?? '',
      message: map['message'] ?? '',
      status: WorkRequestStatus.values.firstWhere(
        (e) => e.toString() == 'WorkRequestStatus.${map['status']}',
        orElse: () => WorkRequestStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      respondedAt: map['respondedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toCompanyId': toCompanyId,
      'fromUserName': fromUserName,
      'toCompanyName': toCompanyName,
      'message': message,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  WorkRequest copyWith({
    WorkRequestStatus? status,
    DateTime? respondedAt,
  }) {
    return WorkRequest(
      id: id,
      fromUserId: fromUserId,
      toCompanyId: toCompanyId,
      fromUserName: fromUserName,
      toCompanyName: toCompanyName,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

enum WorkRequestStatus {
  pending,
  accepted,
  rejected,
}
