class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? companyName;
  final String? companyAddress;
  final String role; // 'producer' veya 'customer'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.companyName,
    this.companyAddress,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.profileImageUrl,
  });

  // Firebase'den gelen data'yı UserModel'e çevir
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      companyName: map['companyName'],
      companyAddress: map['companyAddress'],
      role: map['role'] ?? 'customer',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // UserModel'i Firebase'e kaydetmek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Kullanıcı bilgilerini güncelle
  UserModel copyWith({
    String? email,
    String? name,
    String? phone,
    String? companyName,
    String? companyAddress,
    String? role,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Kullanıcının üretici olup olmadığını kontrol et
  bool get isProducer => role == 'producer';

  // Kullanıcının müşteri olup olmadığını kontrol et
  bool get isCustomer => role == 'customer';

  // Kullanıcının admin olup olmadığını kontrol et
  bool get isAdmin => role == 'admin';
}
