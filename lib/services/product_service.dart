import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/services/firebase_service.dart';
import 'dart:developer' as developer;

class ProductService {
  static const String _collection = 'products';

  // Ürün ekle
  static Future<String> addProduct(Product product) async {
    try {
      developer.log('ProductService: Ürün ekleme işlemi başlatıldı',
          name: 'ProductService');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('ProductService: Kullanıcı oturum açmamış',
            name: 'ProductService', level: 1000);
        throw Exception('Kullanıcı oturum açmamış');
      }

      final productData = product.toJson();
      productData['createdBy'] = user.uid;
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      developer.log('ProductService: Eklenecek veri: $productData',
          name: 'ProductService');

      final docRef =
          await FirebaseService.addDocument(_collection, productData);

      developer.log('ProductService: Ürün başarıyla eklendi, ID: ${docRef.id}',
          name: 'ProductService');

      return docRef.id;
    } catch (e, stackTrace) {
      developer.log('ProductService: Ürün eklenirken hata oluştu',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      throw Exception('Ürün eklenirken hata oluştu: $e');
    }
  }

  // Ürün güncelle
  static Future<void> updateProduct(String productId, Product product) async {
    try {
      developer.log(
          'ProductService: Ürün güncelleme işlemi başlatıldı, ID: $productId',
          name: 'ProductService');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('ProductService: Kullanıcı oturum açmamış',
            name: 'ProductService', level: 1000);
        throw Exception('Kullanıcı oturum açmamış');
      }

      final productData = product.toJson();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      developer.log('ProductService: Güncellenecek veri: $productData',
          name: 'ProductService');

      await FirebaseService.updateDocument(_collection, productId, productData);

      developer.log('ProductService: Ürün başarıyla güncellendi',
          name: 'ProductService');
    } catch (e, stackTrace) {
      developer.log('ProductService: Ürün güncellenirken hata oluştu',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Ürün sil
  static Future<void> deleteProduct(String productId) async {
    try {
      developer.log(
          'ProductService: Ürün silme işlemi başlatıldı, ID: $productId',
          name: 'ProductService');

      await FirebaseService.deleteDocument(_collection, productId);

      developer.log('ProductService: Ürün başarıyla silindi',
          name: 'ProductService');
    } catch (e, stackTrace) {
      developer.log('ProductService: Ürün silinirken hata oluştu',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Kullanıcının ürünlerini al - çalışan desteği ile
  static Future<List<Product>> getUserProducts({String? companyId}) async {
    try {
      developer.log('ProductService: Kullanıcı ürünleri getiriliyor',
          name: 'ProductService');

      String? ownerId;

      if (companyId != null) {
        // Çalışan girişi - company ID'si ile
        ownerId = companyId;
        developer.log('ProductService: Çalışan girişi - Company ID: $companyId',
            name: 'ProductService');
      } else {
        // Normal kullanıcı girişi
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          developer.log('ProductService: Kullanıcı oturum açmamış',
              name: 'ProductService', level: 1000);
          throw Exception('Kullanıcı oturum açmamış');
        }
        ownerId = user.uid;
        developer.log('ProductService: Normal giriş - User ID: ${user.uid}',
            name: 'ProductService');
      }

      developer.log('ProductService: Ürünler şu ID ile aranıyor: $ownerId',
          name: 'ProductService');

      final querySnapshot = await FirebaseService.queryCollection(
        _collection,
        field: 'createdBy',
        value: ownerId,
        orderBy: 'createdAt',
        descending: true,
      );

      developer.log('ProductService: ${querySnapshot.docs.length} ürün bulundu',
          name: 'ProductService');

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        developer.log('ProductService: Ürün verisi: $data',
            name: 'ProductService');
        return Product.fromJson(data);
      }).toList();

      developer.log('ProductService: Ürünler başarıyla dönüştürüldü',
          name: 'ProductService');
      return products;
    } catch (e, stackTrace) {
      developer.log('ProductService: Ürünler alınırken hata oluştu',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      throw Exception('Ürünler alınırken hata oluştu: $e');
    }
  }

  // Tüm aktif ürünleri al
  static Future<List<Product>> getAllActiveProducts() async {
    try {
      developer.log('ProductService: Tüm aktif ürünler getiriliyor',
          name: 'ProductService');

      final querySnapshot = await FirebaseService.queryCollection(
        _collection,
        field: 'isActive',
        value: true,
        orderBy: 'createdAt',
        descending: true,
      );

      developer.log(
          'ProductService: ${querySnapshot.docs.length} aktif ürün bulundu',
          name: 'ProductService');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e, stackTrace) {
      developer.log('ProductService: Aktif ürünler alınırken hata oluştu',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      throw Exception('Ürünler alınırken hata oluştu: $e');
    }
  }

  // Kategoriye göre ürünleri al
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      developer.log('ProductService: Kategori ürünleri getiriliyor: $category',
          name: 'ProductService');

      final querySnapshot = await FirebaseService.queryCollection(
        _collection,
        field: 'category',
        value: category,
        orderBy: 'createdAt',
        descending: true,
      );

      developer.log(
          'ProductService: $category kategorisinde ${querySnapshot.docs.length} ürün bulundu',
          name: 'ProductService');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e, stackTrace) {
      developer.log('ProductService: Kategori ürünleri alınırken hata oluştu',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      throw Exception('Ürünler alınırken hata oluştu: $e');
    }
  }

  // Ürünleri gerçek zamanlı dinle
  static Stream<List<Product>> listenToUserProducts() {
    try {
      developer.log('ProductService: Gerçek zamanlı ürün dinleme başlatıldı',
          name: 'ProductService');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log(
            'ProductService: Kullanıcı oturum açmamış, boş stream döndürülüyor',
            name: 'ProductService',
            level: 1000);
        return Stream.empty();
      }

      return FirebaseFirestore.instance
          .collection(_collection)
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        developer.log(
            'ProductService: Stream\'den ${snapshot.docs.length} ürün alındı',
            name: 'ProductService');
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Product.fromJson(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      developer.log('ProductService: Gerçek zamanlı dinleme hatası',
          name: 'ProductService',
          error: e,
          stackTrace: stackTrace,
          level: 1000);
      return Stream.empty();
    }
  }
}
