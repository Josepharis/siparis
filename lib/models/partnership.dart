class Partnership {
  final String id;
  final String companyAId; // İlk firma ID'si
  final String companyBId; // İkinci firma ID'si
  final String companyAName; // İlk firma adı
  final String companyBName; // İkinci firma adı
  final String initiatedBy; // İsteği başlatan firma ID'si
  final DateTime createdAt; // İş ortaklığı başlangıç tarihi
  final bool isActive; // Aktif mi?
  final String? notes; // Ek notlar

  Partnership({
    required this.id,
    required this.companyAId,
    required this.companyBId,
    required this.companyAName,
    required this.companyBName,
    required this.initiatedBy,
    required this.createdAt,
    this.isActive = true,
    this.notes,
  });

  // Firebase'den gelen data'yı Partnership'e çevir
  factory Partnership.fromMap(Map<String, dynamic> map, String id) {
    return Partnership(
      id: id,
      companyAId: map['companyAId'] ?? '',
      companyBId: map['companyBId'] ?? '',
      companyAName: map['companyAName'] ?? '',
      companyBName: map['companyBName'] ?? '',
      initiatedBy: map['initiatedBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
    );
  }

  // Partnership'i Firebase'e kaydetmek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'companyAId': companyAId,
      'companyBId': companyBId,
      'companyAName': companyAName,
      'companyBName': companyBName,
      'initiatedBy': initiatedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'notes': notes,
    };
  }

  // İş ortaklığını güncelle
  Partnership copyWith({
    String? companyAName,
    String? companyBName,
    bool? isActive,
    String? notes,
  }) {
    return Partnership(
      id: id,
      companyAId: companyAId,
      companyBId: companyBId,
      companyAName: companyAName ?? this.companyAName,
      companyBName: companyBName ?? this.companyBName,
      initiatedBy: initiatedBy,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  // Belirli bir firma için partner firma ID'sini al
  String getPartnerCompanyId(String currentCompanyId) {
    return currentCompanyId == companyAId ? companyBId : companyAId;
  }

  // Belirli bir firma için partner firma adını al
  String getPartnerCompanyName(String currentCompanyId) {
    return currentCompanyId == companyAId ? companyBName : companyAName;
  }
}
