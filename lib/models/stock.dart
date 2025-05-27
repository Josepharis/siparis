import 'package:flutter/material.dart';
import 'package:siparis/theme/app_theme.dart';

enum StockStatus {
  normal,
  critical,
  outOfStock,
  excess // Fazla stok durumu eklendi
}

enum MovementType {
  incoming,
  outgoing,
  adjustment,
  returned, // 'return' anahtar kelime olduğu için 'returned' olarak değiştirildi
  damage // Hasar durumu eklendi
}

class Stock {
  final String id;
  final String productName;
  final String category;
  final String subCategory; // Eklendi
  final String barcode; // Eklendi
  final String supplier; // Eklendi
  final double currentQuantity; // int yerine double
  final double minQuantity; // int yerine double
  final double maxQuantity; // Eklendi
  final double unitPrice;
  final double purchasePrice; // Eklendi
  final String unit;
  final String location; // Depo lokasyonu - Eklendi
  final DateTime lastUpdated;
  final List<StockMovement> movements;
  final String? imageUrl; // Opsiyonel yapıldı
  final String? description; // Opsiyonel yapıldı
  final List<String> tags; // Eklendi
  final bool isActive; // Eklendi
  final DateTime? expiryDate; // Son kullanma tarihi - Opsiyonel yapıldı
  final String? batchNumber; // Parti numarası - Opsiyonel yapıldı

  Stock({
    required this.id,
    required this.productName,
    required this.category,
    this.subCategory = '',
    this.barcode = '',
    this.supplier = '',
    required this.currentQuantity,
    required this.minQuantity,
    this.maxQuantity = double.infinity, // Varsayılan değer eklendi
    required this.unitPrice,
    this.purchasePrice = 0.0, // Varsayılan değer eklendi
    required this.unit,
    this.location = '',
    required this.lastUpdated,
    this.movements = const [], // Varsayılan değer eklendi
    this.imageUrl,
    this.description,
    this.tags = const [],
    this.isActive = true,
    this.expiryDate,
    this.batchNumber,
  });

  StockStatus get status {
    if (!isActive)
      return StockStatus.outOfStock; // Aktif değilse tükendi sayılabilir
    if (currentQuantity <= 0) return StockStatus.outOfStock;
    if (currentQuantity <= minQuantity) return StockStatus.critical;
    if (maxQuantity != double.infinity && currentQuantity >= maxQuantity)
      return StockStatus.excess;
    return StockStatus.normal;
  }

  Color get statusColor {
    // AppTheme renklerini kullanacak şekilde güncellendi
    switch (status) {
      case StockStatus.normal:
        return AppTheme.success;
      case StockStatus.critical:
        return AppTheme.warning;
      case StockStatus.outOfStock:
        return AppTheme.error;
      case StockStatus.excess:
        return AppTheme.info; // Fazla stok için info rengi
    }
  }

  String get statusText {
    switch (status) {
      case StockStatus.normal:
        return 'Normal';
      case StockStatus.critical:
        return 'Kritik';
      case StockStatus.outOfStock:
        return 'Tükendi';
      case StockStatus.excess:
        return 'Fazla';
    }
  }

  // copyWith metodu, tüm yeni alanları içerecek şekilde güncellenmeli
  Stock copyWith({
    String? id,
    String? productName,
    String? category,
    String? subCategory,
    String? barcode,
    String? supplier,
    double? currentQuantity,
    double? minQuantity,
    double? maxQuantity,
    double? unitPrice,
    double? purchasePrice,
    String? unit,
    String? location,
    DateTime? lastUpdated,
    List<StockMovement>? movements,
    String? imageUrl,
    String? description,
    List<String>? tags,
    bool? isActive,
    DateTime? expiryDate,
    String? batchNumber,
  }) {
    return Stock(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      barcode: barcode ?? this.barcode,
      supplier: supplier ?? this.supplier,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      movements: movements ?? this.movements,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
    );
  }
}

class StockMovement {
  final String id;
  final DateTime date;
  final MovementType type;
  final double quantity; // int yerine double
  final double unitPrice;
  final String reference; // Fatura no, sipariş no vb.
  final String notes;
  final String operatorId; // İşlemi yapan kişi

  StockMovement({
    required this.id,
    required this.date,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.reference,
    this.notes = '',
    required this.operatorId,
  });

  Color get typeColor {
    switch (type) {
      case MovementType.incoming:
        return AppTheme.success; // AppTheme renkleri kullanıldı
      case MovementType.outgoing:
        return AppTheme.error;
      case MovementType.adjustment:
        return AppTheme.info;
      case MovementType.returned:
        return AppTheme.warning;
      case MovementType.damage:
        return Colors.brown; // AppTheme'e eklenebilir veya mevcut kalabilir
    }
  }

  String get typeText {
    switch (type) {
      case MovementType.incoming:
        return 'Giriş';
      case MovementType.outgoing:
        return 'Çıkış';
      case MovementType.adjustment:
        return 'Düzeltme';
      case MovementType.returned:
        return 'İade';
      case MovementType.damage:
        return 'Hasar';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case MovementType.incoming:
        return Icons.add_circle_outline;
      case MovementType.outgoing:
        return Icons.remove_circle_outline;
      case MovementType.adjustment:
        return Icons.sync_alt_outlined; // Daha uygun bir ikon
      case MovementType.returned:
        return Icons.undo_outlined;
      case MovementType.damage:
        return Icons.warning_amber_outlined;
    }
  }
}
