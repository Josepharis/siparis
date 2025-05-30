import 'package:flutter/foundation.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/services/order_service.dart';
import 'dart:async';

class OrderProvider extends ChangeNotifier {
  // Tüm siparişler
  List<Order> _orders = [];

  // Günlük ürün özetleri
  Map<String, DailyProductSummary> _dailyProductSummary = {};

  // Finansal özet
  FinancialSummary? _financialSummary;

  // Firma özetleri
  List<CompanySummary> _companySummaries = [];

  // Firebase stream subscription
  StreamSubscription<List<Order>>? _ordersStreamSubscription;

  // Getters
  List<Order> get orders => _orders;
  List<Order> get waitingOrders =>
      _orders.where((order) => order.status == OrderStatus.waiting).toList();
  List<Order> get processingOrders =>
      _orders.where((order) => order.status == OrderStatus.processing).toList();
  List<Order> get completedOrders =>
      _orders.where((order) => order.status == OrderStatus.completed).toList();
  Map<String, DailyProductSummary> get dailyProductSummary =>
      _dailyProductSummary;
  FinancialSummary? get financialSummary => _financialSummary;
  List<CompanySummary> get companySummaries => _companySummaries;

  // Real-time Firebase listener başlat
  void startListeningToOrders() {
    _ordersStreamSubscription?.cancel(); // Önceki listener'ı iptal et

    _ordersStreamSubscription = OrderService.getOrdersStream().listen(
      (firebaseOrders) {
        print('🔥 Firebase\'den ${firebaseOrders.length} siparis alindi');

        // Sadece Firebase verilerini kullan
        _orders = firebaseOrders;

        _updateSummaries();
        notifyListeners();

        print('✅ Toplam ${_orders.length} siparis guncellendi (Real-time)');
      },
      onError: (error) {
        print('❌ Firebase stream hatasi: $error');
        // Hata durumunda boş liste
        _orders = [];
        _updateSummaries();
        notifyListeners();
      },
    );
  }

  // Listener'ı durdur
  void stopListeningToOrders() {
    _ordersStreamSubscription?.cancel();
    _ordersStreamSubscription = null;
  }

  // Siparişleri yükle (Firebase'den) - Artık sadece ilk yükleme için
  Future<void> loadOrders() async {
    try {
      // Eğer listener aktif değilse başlat
      if (_ordersStreamSubscription == null) {
        startListeningToOrders();
      }

      // İlk yükleme için Firebase'den siparişleri çek
      List<Order> firebaseOrders = await OrderService.getAllOrders();

      // Sadece Firebase verilerini kullan
      _orders = firebaseOrders;

      _updateSummaries();
      notifyListeners();

      print('✅ Toplam ${_orders.length} siparis yuklendi (Firebase)');
    } catch (e) {
      print('❌ Siparisler yuklenirken hata: $e');
      // Hata durumunda boş liste
      _orders = [];
      _updateSummaries();
      notifyListeners();
    }
  }

  // Sipariş ekleme - Firebase'e de kaydet
  Future<void> addOrder(Order order) async {
    // Önce local'e ekle (hızlı UI güncellemesi için)
    _orders.add(order);
    _updateSummaries();
    notifyListeners();

    // Firebase'e kaydet (arka planda)
    try {
      await OrderService.saveOrder(order);
      print('✅ Siparis Firebase\'e kaydedildi: ${order.id}');
    } catch (e) {
      print('❌ Siparis Firebase\'e kaydedilemedi: $e');
    }
  }

  // Sipariş güncelleme
  void updateOrder(Order updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
      _updateSummaries();
      notifyListeners();
    }
  }

  // Sipariş durumunu güncelleme - Firebase ile senkronize
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    print(
        '🔄 Sipariş durumu güncelleniyor: $orderId -> ${Order.getStatusText(newStatus)}');
    print('📍 Başlangıç zamanı: ${DateTime.now()}');

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      print('❌ Sipariş bulunamadı: $orderId');
      throw Exception('Sipariş bulunamadı');
    }

    final currentOrder = _orders[index];
    print(
        '📋 Mevcut sipariş durumu: ${Order.getStatusText(currentOrder.status)}');

    try {
      print('🏗️ Yeni sipariş objesi oluşturuluyor...');

      // Yeni sipariş oluştur, final değişkenleri güncellemek için
      final updatedOrder = Order(
        id: currentOrder.id,
        customer: currentOrder.customer,
        items: currentOrder.items,
        orderDate: currentOrder.orderDate,
        deliveryDate: currentOrder.deliveryDate,
        requestedDate: currentOrder.requestedDate,
        requestedTime: currentOrder.requestedTime,
        status: newStatus,
        paymentStatus: currentOrder.paymentStatus,
        paidAmount: currentOrder.paidAmount,
        note: currentOrder.note,
        producerCompanyName: currentOrder.producerCompanyName,
        producerCompanyId: currentOrder.producerCompanyId,
      );

      print('🔥 Firebase\'e kaydediliyor...');
      print('📍 Firebase başlangıç: ${DateTime.now()}');

      // Önce Firebase'e kaydet
      final success = await OrderService.updateOrder(updatedOrder);

      print('📍 Firebase bitiş: ${DateTime.now()}');
      print('🔥 Firebase sonucu: $success');

      if (!success) {
        print('❌ Firebase güncelleme başarısız oldu');
        throw Exception('Firebase güncelleme başarısız');
      }

      print('✅ Firebase güncelleme başarılı');

      // Başarılı olursa local'i güncelle
      print('🔄 Local liste güncelleniyor...');
      _orders[index] = updatedOrder;

      print('📊 Özetler güncelleniyor...');
      _updateSummaries();

      print('🔔 Listener\'lara bildirim gönderiliyor...');
      notifyListeners();

      print(
          '✅ Sipariş durumu başarıyla güncellendi: ${updatedOrder.id} -> ${Order.getStatusText(newStatus)}');
      print('📍 Toplam süre: ${DateTime.now()}');
    } catch (e) {
      print('❌ Sipariş durumu güncellenirken hata: $e');
      print('📍 Hata zamanı: ${DateTime.now()}');
      // Hata durumunda exception'ı yukarıya ilet
      rethrow;
    }
  }

  // Müşteri ödemelerini güncelleme - Firma adına göre (Sadece tamamlanan siparişler)
  Future<void> processCustomerPayment(
      String companyName, double paymentAmount) async {
    print('🔄 Ödeme işlemi başlatıldı: $companyName, Tutar: $paymentAmount');

    // Firmanın tamamlanan ve ödenmemiş siparişlerini bul
    final customerOrders = _orders
        .where((order) =>
            order.customer.name == companyName &&
            order.status == OrderStatus.completed &&
            order.paymentStatus != PaymentStatus.paid)
        .toList();

    if (customerOrders.isEmpty) {
      print(
          '❌ Firma için tamamlanan ödenmemiş sipariş bulunamadı: $companyName');
      return;
    }

    // Ödeme tutarını dağıt
    double remainingPayment = paymentAmount;
    List<Order> ordersToUpdate = [];

    for (final order in customerOrders) {
      if (remainingPayment <= 0) break;

      final remainingOrderAmount = order.totalAmount - (order.paidAmount ?? 0);

      if (remainingOrderAmount > 0) {
        final paymentForThisOrder = remainingPayment >= remainingOrderAmount
            ? remainingOrderAmount
            : remainingPayment;

        final newPaidAmount = (order.paidAmount ?? 0) + paymentForThisOrder;
        PaymentStatus newPaymentStatus;

        if (newPaidAmount >= order.totalAmount) {
          newPaymentStatus = PaymentStatus.paid;
        } else if (newPaidAmount > 0) {
          newPaymentStatus = PaymentStatus.partial;
        } else {
          newPaymentStatus = PaymentStatus.pending;
        }

        // Güncellenmiş sipariş oluştur
        final updatedOrder = Order(
          id: order.id,
          customer: order.customer,
          items: order.items,
          orderDate: order.orderDate,
          deliveryDate: order.deliveryDate,
          requestedDate: order.requestedDate,
          requestedTime: order.requestedTime,
          status: order.status,
          paymentStatus: newPaymentStatus,
          paidAmount: newPaidAmount,
          note: order.note,
        );

        ordersToUpdate.add(updatedOrder);
        remainingPayment -= paymentForThisOrder;

        print(
            '📝 Sipariş güncellenecek: ${order.id}, Yeni ödenen: $newPaidAmount, Durum: $newPaymentStatus');
      }
    }

    // Sadece Firebase'e kaydet - Firebase listener UI'ı otomatik güncelleyecek
    try {
      for (final order in ordersToUpdate) {
        await OrderService.updateOrder(order);
      }
      print('✅ Tüm ödeme güncellemeleri Firebase\'e kaydedildi');
    } catch (e) {
      print('❌ Ödeme Firebase\'e kaydedilemedi: $e');
      throw Exception('Ödeme kaydedilemedi: $e');
    }
  }

  // Sipariş silme
  void deleteOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    _updateSummaries();
    notifyListeners();
  }

  // Provider dispose edildiğinde listener'ı temizle
  @override
  void dispose() {
    stopListeningToOrders();
    super.dispose();
  }

  // Özetleri güncelleme
  void _updateSummaries() {
    _updateDailyProductSummary();
    _updateFinancialSummary();
    _updateCompanySummaries();
  }

  // Günlük ürün özetini güncelleme
  void _updateDailyProductSummary() {
    final Map<String, DailyProductSummary> summaryMap = {};
    // Ürün adına göre firma miktarlarını tutan harita
    final Map<String, Map<String, int>> productFirmaCounts = {};

    // Bugün için olan siparişleri filtrele
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayOrders = _orders.where(
      (order) {
        final orderDeliveryDate = DateTime(order.deliveryDate.year,
            order.deliveryDate.month, order.deliveryDate.day);
        return orderDeliveryDate.isAtSameMomentAs(today);
      },
    ).toList();

    // Her bir sipariş öğesi için özet oluştur
    for (final order in todayOrders) {
      for (final item in order.items) {
        final productName = item.product.name;
        final firmaName = order.customer.name;

        // Ürün için firma miktarlarını güncelle
        if (!productFirmaCounts.containsKey(productName)) {
          productFirmaCounts[productName] = {};
        }

        // Firma miktarını güncelle
        productFirmaCounts[productName]![firmaName] =
            (productFirmaCounts[productName]![firmaName] ?? 0) + item.quantity;

        if (summaryMap.containsKey(productName)) {
          // Mevcut özeti güncelle
          final existingSummary = summaryMap[productName]!;
          final newTotalQuantity =
              existingSummary.totalQuantity + item.quantity;

          summaryMap[productName] = DailyProductSummary(
            productName: productName,
            totalQuantity: newTotalQuantity,
            category: item.product.category,
            imageUrl: item.product.imageUrl,
            firmaCounts: productFirmaCounts[productName],
          );
        } else {
          // Yeni özet oluştur
          summaryMap[productName] = DailyProductSummary(
            productName: productName,
            totalQuantity: item.quantity,
            category: item.product.category,
            imageUrl: item.product.imageUrl,
            firmaCounts: productFirmaCounts[productName],
          );
        }
      }
    }

    _dailyProductSummary = summaryMap;
  }

  // Finansal özeti güncelleme - Sadece tamamlanan siparişler
  void _updateFinancialSummary() {
    // Sadece tamamlanan siparişleri finansal özete dahil et
    final completedOrders = _orders
        .where((order) => order.status == OrderStatus.completed)
        .toList();

    double totalAmount = 0;
    double collectedAmount = 0;
    int totalOrders = completedOrders.length;
    int paidOrders = 0;
    int pendingOrders = 0;

    for (final order in completedOrders) {
      totalAmount += order.totalAmount;
      collectedAmount += order.paidAmount ?? 0;

      if (order.paymentStatus == PaymentStatus.paid) {
        paidOrders++;
      } else {
        pendingOrders++;
      }
    }

    final pendingAmount = totalAmount - collectedAmount;
    final collectionRate =
        totalAmount > 0 ? (collectedAmount / totalAmount) * 100 : 0.0;

    _financialSummary = FinancialSummary(
      totalAmount: totalAmount,
      collectedAmount: collectedAmount,
      pendingAmount: pendingAmount,
      collectionRate: collectionRate,
      totalOrders: totalOrders,
      paidOrders: paidOrders,
      pendingOrders: pendingOrders,
    );

    print(
        '✅ Finansal özet güncellendi: ${completedOrders.length} tamamlanan sipariş, ₺${totalAmount.toStringAsFixed(2)} toplam tutar');
  }

  // Firma özetlerini güncelleme
  void _updateCompanySummaries() {
    final Map<String, CompanySummary> summaryMap = {};

    // Sadece tamamlanan siparişleri ödeme sistemine dahil et
    final completedOrders = _orders
        .where((order) => order.status == OrderStatus.completed)
        .toList();

    // Her bir firma için sipariş ve ödeme özetlerini hazırla - Firma adına göre grupla
    for (final order in completedOrders) {
      final companyName = order.customer.name; // Firma adını kullan

      if (summaryMap.containsKey(companyName)) {
        // Mevcut özeti güncelle
        final existingSummary = summaryMap[companyName]!;

        summaryMap[companyName] = CompanySummary(
          company: order.customer,
          totalAmount: existingSummary.totalAmount + order.totalAmount,
          paidAmount: existingSummary.paidAmount + (order.paidAmount ?? 0),
          pendingAmount: existingSummary.pendingAmount + order.remainingAmount,
          totalOrders: existingSummary.totalOrders + 1,
          collectionRate: 0, // Şimdilik 0 olarak ayarla, sonra hesapla
        );
      } else {
        // Yeni özet oluştur
        summaryMap[companyName] = CompanySummary(
          company: order.customer,
          totalAmount: order.totalAmount,
          paidAmount: order.paidAmount ?? 0,
          pendingAmount: order.remainingAmount,
          totalOrders: 1,
          collectionRate: 0, // Şimdilik 0 olarak ayarla, sonra hesapla
        );
      }
    }

    // Koleksiyon oranlarını hesapla ve ödemesi tamamlanan firmaları filtrele
    final List<CompanySummary> summaries = summaryMap.values
        .map((summary) {
          final collectionRate = summary.totalAmount > 0
              ? (summary.paidAmount / summary.totalAmount) * 100
              : 0.0;

          return CompanySummary(
            company: summary.company,
            totalAmount: summary.totalAmount,
            paidAmount: summary.paidAmount,
            pendingAmount: summary.pendingAmount,
            totalOrders: summary.totalOrders,
            collectionRate: collectionRate,
          );
        })
        .where((summary) => summary.pendingAmount > 0)
        .toList(); // Sadece bekleyen ödemesi olan firmalar

    // Toplam tutara göre sırala
    summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    _companySummaries = summaries;

    print(
        '✅ Firma özetleri güncellendi: ${completedOrders.length} tamamlanan sipariş, ${summaries.length} firma (ödemesi bekleyen)');
  }
}
