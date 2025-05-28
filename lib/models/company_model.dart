import 'package:siparis/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String ownerId; // Firma sahibinin user ID'si
  final List<String> employeeIds; // Firmada çalışan kullanıcıların ID'leri
  final String type; // 'producer' veya 'customer'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? logoUrl;
  final Map<String, dynamic>? businessHours; // Çalışma saatleri
  final List<String>? categories; // Faaliyet alanları
  List<Product> products = [];

  CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.website,
    this.description,
    required this.ownerId,
    this.employeeIds = const [],
    required this.type,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.logoUrl,
    this.businessHours,
    this.categories,
    List<Product>? products,
  }) {
    this.products = products ?? [];
  }

  // Ürünleri yükle
  Future<void> loadProducts() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('createdBy', isEqualTo: ownerId)
          .get();

      products = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
          companyId: id,
          companyName: name,
          isAvailable: data['isActive'] ?? true,
          rating: 0.0,
          reviewCount: 0,
        );
      }).toList();
    } catch (e) {
      print('DEBUG: Ürünler yüklenirken hata: $e');
      products = [];
    }
  }

  // Firebase'den gelen data'yı CompanyModel'e çevir
  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      description: map['description'],
      ownerId: map['ownerId'] ?? '',
      employeeIds: List<String>.from(map['employeeIds'] ?? []),
      type: map['type'] ?? 'customer',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      logoUrl: map['logoUrl'],
      businessHours: map['businessHours'],
      categories: map['categories'] != null
          ? List<String>.from(map['categories'])
          : null,
    );
  }

  // CompanyModel'i Firebase'e kaydetmek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'ownerId': ownerId,
      'employeeIds': employeeIds,
      'type': type,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'logoUrl': logoUrl,
      'businessHours': businessHours,
      'categories': categories,
    };
  }

  // Firma bilgilerini güncelle
  CompanyModel copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? description,
    String? ownerId,
    List<String>? employeeIds,
    String? type,
    bool? isActive,
    DateTime? updatedAt,
    String? logoUrl,
    Map<String, dynamic>? businessHours,
    List<String>? categories,
    List<Product>? products,
  }) {
    return CompanyModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      employeeIds: employeeIds ?? this.employeeIds,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      businessHours: businessHours ?? this.businessHours,
      categories: categories ?? this.categories,
      products: products ?? this.products,
    );
  }

  // Firmanın üretici olup olmadığını kontrol et
  bool get isProducer => type == 'producer';

  // Firmanın müşteri olup olmadığını kontrol et
  bool get isCustomer => type == 'customer';

  // Kullanıcının bu firmada çalışıp çalışmadığını kontrol et
  bool hasEmployee(String userId) {
    return ownerId == userId || employeeIds.contains(userId);
  }

  // Çalışan ekle
  CompanyModel addEmployee(String userId) {
    if (!employeeIds.contains(userId)) {
      return copyWith(
        employeeIds: [...employeeIds, userId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Çalışan çıkar
  CompanyModel removeEmployee(String userId) {
    return copyWith(
      employeeIds: employeeIds.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }
}
