class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String companyId;
  final String password;
  final Map<String, bool> permissions;
  final DateTime createdAt;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.companyId,
    required this.password,
    required this.permissions,
    required this.createdAt,
    this.isActive = true,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      position: map['position'] ?? '',
      companyId: map['companyId'] ?? '',
      password: map['password'] ?? '',
      permissions: Map<String, bool>.from(map['permissions'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'companyId': companyId,
      'password': password,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Yetki kontrol metodları
  bool hasPermission(String permission) {
    return permissions[permission] ?? false;
  }

  bool get canViewBudget => hasPermission('view_budget');
  bool get canApprovePartnerships => hasPermission('approve_partnerships');
  bool get canViewCompanies => hasPermission('view_companies');
  bool get canManageOrders => hasPermission('manage_orders');
  bool get canManageProducts => hasPermission('manage_products');

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? companyId,
    String? password,
    Map<String, bool>? permissions,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      companyId: companyId ?? this.companyId,
      password: password ?? this.password,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
