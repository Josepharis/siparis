import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siparis/models/order.dart' as order_models;

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';

  /// Siparişi Firebase Firestore'a kaydet
  static Future<bool> saveOrder(order_models.Order order) async {
    try {
      // Siparişi Firestore'a kaydet
      await _firestore
          .collection(_ordersCollection)
          .doc(order.id)
          .set(order.toJson());

      print('✅ Sipariş  alındı: ${order.id}');
      return true;
    } catch (e) {
      print('❌ Sipariş kaydedilirken hata: $e');
      return false;
    }
  }

  /// Siparişi Firebase Firestore'da güncelle
  static Future<bool> updateOrder(order_models.Order order) async {
    try {
      print('🔥 OrderService: updateOrder başlatılıyor...');
      print('🔥 OrderService: Sipariş ID: ${order.id}');
      print(
          '🔥 OrderService: Yeni durum: ${order_models.Order.getStatusText(order.status)}');
      print('🔥 OrderService: Firebase bağlantısı kontrol ediliyor...');

      // Siparişi Firestore'da güncelle
      await _firestore
          .collection(_ordersCollection)
          .doc(order.id)
          .update(order.toJson());

      print('✅ OrderService: Sipariş başarıyla güncellendi: ${order.id}');
      return true;
    } catch (e) {
      print('❌ OrderService: Sipariş güncellenirken hata: $e');
      print('❌ OrderService: Hata türü: ${e.runtimeType}');
      return false;
    }
  }

  /// Birden fazla siparişi Firebase'e kaydet
  static Future<bool> saveMultipleOrders(
      List<order_models.Order> orders) async {
    try {
      // Batch işlemi için
      WriteBatch batch = _firestore.batch();

      for (final order in orders) {
        DocumentReference orderRef =
            _firestore.collection(_ordersCollection).doc(order.id);
        batch.set(orderRef, order.toJson());
      }

      // Tüm siparişleri tek seferde kaydet
      await batch.commit();

      print('✅ ${orders.length} adet sipariş Firebase\'e kaydedildi');
      return true;
    } catch (e) {
      print('❌ Siparişler kaydedilirken hata: $e');
      return false;
    }
  }

  /// Firebase'den tüm siparişleri çek
  static Future<List<order_models.Order>> getAllOrders() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_ordersCollection)
          .orderBy('orderDate', descending: true)
          .get();

      List<order_models.Order> orders = [];

      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          order_models.Order order = order_models.Order.fromJson(data);
          orders.add(order);
        } catch (e) {
          print('❌ Sipariş parse edilirken hata: $e');
        }
      }

      print('✅ ${orders.length} adet sipariş Firebase\'den çekildi');
      return orders;
    } catch (e) {
      print('❌ Siparişler çekilirken hata: $e');
      return [];
    }
  }

  /// Belirli bir müşterinin siparişlerini çek
  static Future<List<order_models.Order>> getOrdersByCustomer(
      String customerName) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('customer.name', isEqualTo: customerName)
          .orderBy('orderDate', descending: true)
          .get();

      List<order_models.Order> orders = [];

      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          order_models.Order order = order_models.Order.fromJson(data);
          orders.add(order);
        } catch (e) {
          print('❌ Müşteri siparişi parse edilirken hata: $e');
        }
      }

      print('✅ ${orders.length} adet müşteri siparişi çekildi');
      return orders;
    } catch (e) {
      print('❌ Müşteri siparişleri çekilirken hata: $e');
      return [];
    }
  }

  /// Gerçek zamanlı sipariş dinleme
  static Stream<List<order_models.Order>> getOrdersStream() {
    return _firestore
        .collection(_ordersCollection)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      List<order_models.Order> orders = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          order_models.Order order = order_models.Order.fromJson(data);
          orders.add(order);
        } catch (e) {
          print('❌ Stream sipariş parse edilirken hata: $e');
        }
      }

      return orders;
    });
  }
}
