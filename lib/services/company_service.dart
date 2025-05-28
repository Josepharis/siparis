import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';

class CompanyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'companies';

  // Firma oluştur
  static Future<CompanyModel?> createCompany({
    required String name,
    required String address,
    String? phone,
    String? email,
    String? website,
    String? description,
    required String ownerId,
    required String type,
    List<String>? categories,
  }) async {
    try {
      DocumentReference docRef = _firestore.collection(_collection).doc();

      CompanyModel company = CompanyModel(
        id: docRef.id,
        name: name,
        address: address,
        phone: phone,
        email: email,
        website: website,
        description: description,
        ownerId: ownerId,
        type: type,
        createdAt: DateTime.now(),
        categories: categories,
      );

      await docRef.set(company.toMap());
      return company;
    } catch (e) {
      throw Exception('Firma oluşturulurken hata: $e');
    }
  }

  // Firma bilgilerini getir
  static Future<CompanyModel?> getCompany(String companyId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(companyId).get();

      if (doc.exists) {
        return CompanyModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Firma bilgileri alınırken hata: $e');
    }
  }

  // Kullanıcının sahip olduğu firmaları getir
  static Future<List<CompanyModel>> getUserCompanies(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CompanyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı firmaları alınırken hata: $e');
    }
  }

  // Kullanıcının çalıştığı firmaları getir
  static Future<List<CompanyModel>> getUserEmployeeCompanies(
      String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('employeeIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CompanyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Çalışılan firmalar alınırken hata: $e');
    }
  }

  // Tüm aktif firmaları getir (belirli tipte)
  static Future<List<CompanyModel>> getCompaniesByType(String type) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => CompanyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Firmalar alınırken hata: $e');
    }
  }

  // Firma bilgilerini güncelle
  static Future<bool> updateCompany(CompanyModel company) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(company.id)
          .update(company.copyWith(updatedAt: DateTime.now()).toMap());
      return true;
    } catch (e) {
      throw Exception('Firma güncellenirken hata: $e');
    }
  }

  // Firmaya çalışan ekle
  static Future<bool> addEmployee(String companyId, String userId) async {
    try {
      DocumentReference docRef =
          _firestore.collection(_collection).doc(companyId);

      await docRef.update({
        'employeeIds': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      throw Exception('Çalışan eklenirken hata: $e');
    }
  }

  // Firmadan çalışan çıkar
  static Future<bool> removeEmployee(String companyId, String userId) async {
    try {
      DocumentReference docRef =
          _firestore.collection(_collection).doc(companyId);

      await docRef.update({
        'employeeIds': FieldValue.arrayRemove([userId]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      throw Exception('Çalışan çıkarılırken hata: $e');
    }
  }

  // Firmayı sil (soft delete)
  static Future<bool> deleteCompany(String companyId) async {
    try {
      await _firestore.collection(_collection).doc(companyId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      throw Exception('Firma silinirken hata: $e');
    }
  }

  // Firma arama
  static Future<List<CompanyModel>> searchCompanies(String searchTerm) async {
    try {
      // Firestore'da case-insensitive arama için name field'ını lowercase olarak tutmak gerekir
      // Şimdilik basit bir çözüm kullanıyoruz
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      List<CompanyModel> allCompanies = querySnapshot.docs
          .map((doc) => CompanyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Client-side filtering
      return allCompanies
          .where((company) =>
              company.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              company.address.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Firma aranırken hata: $e');
    }
  }
}
