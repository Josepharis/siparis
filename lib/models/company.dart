import 'package:siparis/models/product.dart';

class Company {
  final String id;
  final String name;
  final String description;
  final List<String> services;
  final String address;
  final String phone;
  final String email;
  final String? website;
  final double rating;
  final int totalProjects;
  final List<Product> products;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    required this.description,
    required this.services,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
    required this.rating,
    required this.totalProjects,
    required this.products,
    this.isActive = true,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      services:
          (json['services'] as List<dynamic>).map((e) => e as String).toList(),
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String?,
      rating: (json['rating'] as num).toDouble(),
      totalProjects: json['totalProjects'] as int,
      products: (json['products'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'services': services,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'rating': rating,
      'totalProjects': totalProjects,
      'products': products.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }
}
