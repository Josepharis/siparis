import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore instance'ını al
  static FirebaseFirestore get firestore => _firestore;

  // Auth instance'ını al
  static FirebaseAuth get auth => _auth;

  // Koleksiyon referansı al
  static CollectionReference collection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  // Belge ekle
  static Future<DocumentReference> addDocument(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _firestore.collection(collectionName).add(data);
    } catch (e) {
      throw Exception('Belge eklenirken hata oluştu: $e');
    }
  }

  // Belge güncelle
  static Future<void> updateDocument(
    String collectionName,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Belge güncellenirken hata oluştu: $e');
    }
  }

  // Belge sil
  static Future<void> deleteDocument(
    String collectionName,
    String documentId,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).delete();
    } catch (e) {
      throw Exception('Belge silinirken hata oluştu: $e');
    }
  }

  // Belge al
  static Future<DocumentSnapshot> getDocument(
    String collectionName,
    String documentId,
  ) async {
    try {
      return await _firestore.collection(collectionName).doc(documentId).get();
    } catch (e) {
      throw Exception('Belge alınırken hata oluştu: $e');
    }
  }

  // Koleksiyondaki tüm belgeleri al
  static Future<QuerySnapshot> getCollection(String collectionName) async {
    try {
      return await _firestore.collection(collectionName).get();
    } catch (e) {
      throw Exception('Koleksiyon alınırken hata oluştu: $e');
    }
  }

  // Koleksiyonu dinle (gerçek zamanlı)
  static Stream<QuerySnapshot> listenToCollection(String collectionName) {
    return _firestore.collection(collectionName).snapshots();
  }

  // Sorgu ile belgeleri al
  static Future<QuerySnapshot> queryCollection(
    String collectionName, {
    String? field,
    dynamic value,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collectionName);

      if (field != null && value != null) {
        query = query.where(field, isEqualTo: value);
      }

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      throw Exception('Sorgu çalıştırılırken hata oluştu: $e');
    }
  }
}
