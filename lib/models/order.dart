import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:siparis/config/theme.dart';

// Sipariş durumları
enum OrderStatus { waiting, processing, completed, cancelled }

// Ödeme durumu
enum PaymentStatus { pending, paid, partial }

// Ürün sınıfı
class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String category;
  final String? description;
  final bool isActive;

  Product({
    String? id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.category,
    this.description,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      category: json['category'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'description': description,
      'isActive': isActive,
    };
  }
}

// Sipariş Öğesi
class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final String? note;
  final double total;

  OrderItem({
    String? id,
    required this.product,
    required this.quantity,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        total = product.price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'note': note,
      'total': total,
    };
  }
}

// Müşteri/İşletme
class Customer {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? imageUrl;

  Customer({
    String? id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.imageUrl,
  }) : id = id ?? const Uuid().v4();

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      address: json['address'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'imageUrl': imageUrl,
    };
  }
}

// Ana Sipariş Sınıfı
class Order {
  final String id;
  final Customer customer;
  final List<OrderItem> items;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final DateTime? requestedDate; // Müşterinin istediği tarih
  final TimeOfDay? requestedTime; // Müşterinin istediği saat
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final double totalAmount;
  final double? paidAmount;
  final String? note;
  final String? producerCompanyName; // ✅ Üretici firma adı
  final String? producerCompanyId; // ✅ Üretici firma ID'si
  final String? customerId; // ✅ Müşteri ID'si (Cloud Functions için)

  Order({
    String? id,
    required this.customer,
    required this.items,
    required this.orderDate,
    required this.deliveryDate,
    this.requestedDate,
    this.requestedTime,
    this.status = OrderStatus.waiting,
    this.paymentStatus = PaymentStatus.pending,
    this.paidAmount,
    this.note,
    this.producerCompanyName, // ✅ Üretici firma adı
    this.producerCompanyId, // ✅ Üretici firma ID'si
    this.customerId, // ✅ Müşteri ID'si (Cloud Functions için)
  })  : id = id ?? const Uuid().v4(),
        totalAmount = items.fold(0, (sum, item) => sum + item.total);

  double get remainingAmount => totalAmount - (paidAmount ?? 0);

  bool get isPaid => paymentStatus == PaymentStatus.paid;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customer: Customer.fromJson(json['customer']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      orderDate: DateTime.parse(json['orderDate']),
      deliveryDate: DateTime.parse(json['deliveryDate']),
      requestedDate: json['requestedDate'] != null
          ? DateTime.parse(json['requestedDate'])
          : null,
      requestedTime: json['requestedTime'] != null
          ? TimeOfDay(
              hour: json['requestedTime']['hour'],
              minute: json['requestedTime']['minute'],
            )
          : null,
      status: OrderStatus.values[json['status']],
      paymentStatus: PaymentStatus.values[json['paymentStatus']],
      paidAmount: json['paidAmount']?.toDouble(),
      note: json['note'],
      producerCompanyName: json['producerCompanyName'], // ✅ Üretici firma adı
      producerCompanyId: json['producerCompanyId'], // ✅ Üretici firma ID'si
      customerId: json['customerId'], // ✅ Müşteri ID'si
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate.toIso8601String(),
      'requestedDate': requestedDate?.toIso8601String(),
      'requestedTime': requestedTime != null
          ? {
              'hour': requestedTime!.hour,
              'minute': requestedTime!.minute,
            }
          : null,
      'status': status.index,
      'paymentStatus': paymentStatus.index,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'note': note,
      'producerCompanyName': producerCompanyName, // ✅ Üretici firma adı
      'producerCompanyId': producerCompanyId, // ✅ Üretici firma ID'si
      'customerId': customerId, // ✅ Müşteri ID'si
    };
  }

  // Duruma göre sipariş rengi
  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return AppTheme.waitingColor;
      case OrderStatus.processing:
        return AppTheme.processingColor;
      case OrderStatus.completed:
        return AppTheme.completedColor;
      case OrderStatus.cancelled:
        return AppTheme.errorColor.withOpacity(0.1);
    }
  }

  // Duruma göre sipariş metni
  static String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return 'Bekliyor';
      case OrderStatus.processing:
        return 'Hazırlanıyor';
      case OrderStatus.completed:
        return 'Tamamlandı';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}

// Günlük Ürün Özeti
class DailyProductSummary {
  final String productName;
  final int totalQuantity;
  final String category;
  final String? imageUrl;
  final Map<String, int>? firmaCounts; // Her firma için miktar bilgisi
  final DateTime? productionDate; // Üretim tarihi
  final bool isPopular; // Popüler ürün mü
  final List<FirmaSiparis>? firmaDetaylari; // Firma detayları

  DailyProductSummary({
    required this.productName,
    required this.totalQuantity,
    required this.category,
    this.imageUrl,
    this.firmaCounts,
    this.productionDate,
    this.isPopular = false,
    this.firmaDetaylari,
  });

  // Bu ürün için firma sayısını döndür
  int get firmaCount => firmaDetaylari?.length ?? firmaCounts?.length ?? 0;

  // Firma başına ortalama siparişi hesapla
  double get averagePerFirma {
    if (firmaCount == 0) return 0;
    return totalQuantity / firmaCount;
  }

  // Toplam ürün adedini gerçek verilerden hesapla
  int get gercekToplam {
    if (firmaDetaylari != null && firmaDetaylari!.isNotEmpty) {
      return firmaDetaylari!.fold(0, (sum, firma) => sum + firma.adet);
    } else if (firmaCounts != null && firmaCounts!.isNotEmpty) {
      return firmaCounts!.values.fold(0, (sum, count) => sum + count);
    }
    return totalQuantity;
  }
}

// Firma sipariş detayları
class FirmaSiparis {
  final String firmaAdi; // Firma adı
  final int adet; // Sipariş adedi
  final String? telefon; // İletişim telefonu
  final String? aciklama; // Sipariş açıklaması
  final DateTime? siparisTarihi; // Sipariş tarihi

  FirmaSiparis({
    required this.firmaAdi,
    required this.adet,
    this.telefon,
    this.aciklama,
    this.siparisTarihi,
  });

  factory FirmaSiparis.fromJson(Map<String, dynamic> json) {
    return FirmaSiparis(
      firmaAdi: json['firmaAdi'],
      adet: json['adet'],
      telefon: json['telefon'],
      aciklama: json['aciklama'],
      siparisTarihi: json['siparisTarihi'] != null
          ? DateTime.parse(json['siparisTarihi'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firmaAdi': firmaAdi,
      'adet': adet,
      'telefon': telefon,
      'aciklama': aciklama,
      'siparisTarihi': siparisTarihi?.toIso8601String(),
    };
  }
}

// Finansal Özet
class FinancialSummary {
  final double totalAmount;
  final double collectedAmount;
  final double pendingAmount;
  final double collectionRate;
  final int totalOrders;
  final int paidOrders;
  final int pendingOrders;

  FinancialSummary({
    required this.totalAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.collectionRate,
    required this.totalOrders,
    required this.paidOrders,
    required this.pendingOrders,
  });
}

// Firma Özeti
class CompanySummary {
  final Customer company;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final int totalOrders;
  final double collectionRate;

  CompanySummary({
    required this.company,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.totalOrders,
    required this.collectionRate,
  });
}

// Partnerlik Durumları
enum PartnershipStatus {
  notPartner, // Partner değil
  pending, // İstek bekliyor
  approved, // Onaylandı (Partner)
  rejected, // Reddedildi
}

// Partnerlik İsteği
class PartnershipRequest {
  final String id;
  final String customerId; // İstek gönderen müşteri
  final String companyId; // İstek gönderilen firma
  final String customerName; // Müşteri adı
  final String companyName; // Firma adı
  final String? message; // İstek mesajı
  final DateTime requestDate; // İstek tarihi
  final PartnershipStatus status;
  final String? responseMessage; // Yanıt mesajı
  final DateTime? responseDate; // Yanıt tarihi

  PartnershipRequest({
    String? id,
    required this.customerId,
    required this.companyId,
    required this.customerName,
    required this.companyName,
    this.message,
    required this.requestDate,
    this.status = PartnershipStatus.pending,
    this.responseMessage,
    this.responseDate,
  }) : id = id ?? const Uuid().v4();

  factory PartnershipRequest.fromJson(Map<String, dynamic> json) {
    return PartnershipRequest(
      id: json['id'],
      customerId: json['customerId'],
      companyId: json['companyId'],
      customerName: json['customerName'],
      companyName: json['companyName'],
      message: json['message'],
      requestDate: DateTime.parse(json['requestDate']),
      status: PartnershipStatus.values[json['status']],
      responseMessage: json['responseMessage'],
      responseDate: json['responseDate'] != null
          ? DateTime.parse(json['responseDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'companyId': companyId,
      'customerName': customerName,
      'companyName': companyName,
      'message': message,
      'requestDate': requestDate.toIso8601String(),
      'status': status.index,
      'responseMessage': responseMessage,
      'responseDate': responseDate?.toIso8601String(),
    };
  }

  // Durum rengini al
  static Color getStatusColor(PartnershipStatus status) {
    switch (status) {
      case PartnershipStatus.notPartner:
        return Colors.grey;
      case PartnershipStatus.pending:
        return Colors.orange;
      case PartnershipStatus.approved:
        return Colors.green;
      case PartnershipStatus.rejected:
        return Colors.red;
    }
  }

  // Durum metnini al
  static String getStatusText(PartnershipStatus status) {
    switch (status) {
      case PartnershipStatus.notPartner:
        return 'Partner Değil';
      case PartnershipStatus.pending:
        return 'İstek Bekliyor';
      case PartnershipStatus.approved:
        return 'Partner';
      case PartnershipStatus.rejected:
        return 'Reddedildi';
    }
  }
}

// Partnerlik İlişkisi
class Partnership {
  final String id;
  final String customerId; // Müşteri ID
  final String companyId; // Firma ID
  final String customerName; // Müşteri adı
  final String companyName; // Firma adı
  final DateTime startDate; // Ortaklık başlangıç tarihi
  final bool isActive; // Aktif mi?

  Partnership({
    String? id,
    required this.customerId,
    required this.companyId,
    required this.customerName,
    required this.companyName,
    required this.startDate,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      id: json['id'],
      customerId: json['customerId'],
      companyId: json['companyId'],
      customerName: json['customerName'],
      companyName: json['companyName'],
      startDate: DateTime.parse(json['startDate']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'companyId': companyId,
      'customerName': customerName,
      'companyName': companyName,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
