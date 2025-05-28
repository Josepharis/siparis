import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partnership.dart';

class PartnershipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'partnerships';

  // İş ortaklığı oluştur
  static Future<Partnership?> createPartnership({
    required String companyAId,
    required String companyBId,
    required String companyAName,
    required String companyBName,
    required String initiatedBy,
    String? notes,
  }) async {
    try {
      // Önce aynı iş ortaklığının var olup olmadığını kontrol et
      final existingPartnership = await getPartnership(companyAId, companyBId);
      if (existingPartnership != null) {
        print('Bu firmalar arasında zaten iş ortaklığı var');
        return existingPartnership;
      }

      DocumentReference docRef = _firestore.collection(_collection).doc();

      Partnership partnership = Partnership(
        id: docRef.id,
        companyAId: companyAId,
        companyBId: companyBId,
        companyAName: companyAName,
        companyBName: companyBName,
        initiatedBy: initiatedBy,
        createdAt: DateTime.now(),
        notes: notes,
      );

      await docRef.set(partnership.toMap());
      print('İş ortaklığı oluşturuldu: ${partnership.id}');
      return partnership;
    } catch (e) {
      print('İş ortaklığı oluşturulurken hata: $e');
      return null;
    }
  }

  // İki firma arasında iş ortaklığı var mı kontrol et
  static Future<Partnership?> getPartnership(
      String companyAId, String companyBId) async {
    try {
      // Her iki yönde de arama yap (A-B veya B-A)
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final docCompanyAId = data['companyAId'];
        final docCompanyBId = data['companyBId'];

        // Her iki yönde de kontrol et
        if ((docCompanyAId == companyAId && docCompanyBId == companyBId) ||
            (docCompanyAId == companyBId && docCompanyBId == companyAId)) {
          return Partnership.fromMap(data, doc.id);
        }
      }

      return null;
    } catch (e) {
      print('İş ortaklığı kontrol edilirken hata: $e');
      return null;
    }
  }

  // Bir firmanın tüm iş ortaklarını getir
  static Future<List<Partnership>> getCompanyPartnerships(
      String companyId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      List<Partnership> partnerships = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final docCompanyAId = data['companyAId'];
        final docCompanyBId = data['companyBId'];

        // Bu firma bu iş ortaklığında var mı?
        if (docCompanyAId == companyId || docCompanyBId == companyId) {
          partnerships.add(Partnership.fromMap(data, doc.id));
        }
      }

      return partnerships;
    } catch (e) {
      print('Firma iş ortaklıkları alınırken hata: $e');
      return [];
    }
  }

  // Bir kullanıcının sahip olduğu tüm firmaların iş ortaklarını getir
  static Future<List<Partnership>> getUserCompanyPartnerships(
      String userId) async {
    try {
      // Önce kullanıcının sahip olduğu firmaları al
      final userCompanies = await _getUserCompanies(userId);

      List<Partnership> allPartnerships = [];

      for (var company in userCompanies) {
        final partnerships = await getCompanyPartnerships(company['id']);
        allPartnerships.addAll(partnerships);
      }

      return allPartnerships;
    } catch (e) {
      print('Kullanıcı firma iş ortaklıkları alınırken hata: $e');
      return [];
    }
  }

  // İş ortaklığını sonlandır
  static Future<bool> endPartnership(String partnershipId) async {
    try {
      await _firestore.collection(_collection).doc(partnershipId).update({
        'isActive': false,
        'endedAt': DateTime.now().millisecondsSinceEpoch,
      });

      print('İş ortaklığı sonlandırıldı: $partnershipId');
      return true;
    } catch (e) {
      print('İş ortaklığı sonlandırılırken hata: $e');
      return false;
    }
  }

  // İş ortaklığını sil
  static Future<bool> deletePartnership(String partnershipId) async {
    try {
      await _firestore.collection(_collection).doc(partnershipId).delete();
      print('İş ortaklığı silindi: $partnershipId');
      return true;
    } catch (e) {
      print('İş ortaklığı silinirken hata: $e');
      return false;
    }
  }

  // Yardımcı metod: Kullanıcının sahip olduğu firmaları al
  static Future<List<dynamic>> _getUserCompanies(String userId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': (doc.data() as Map<String, dynamic>)['name'] ?? '',
              })
          .toList();
    } catch (e) {
      print('Kullanıcı firmaları alınırken hata: $e');
      return [];
    }
  }
}
