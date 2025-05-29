import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/services/company_service.dart';

class PartnershipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _partnershipsCollection = 'partnerships';
  static const String _partnershipRequestsCollection = 'partnership_requests';

  // Partnerlik isteği gönder
  static Future<void> sendPartnershipRequest(PartnershipRequest request) async {
    try {
      await _firestore
          .collection(_partnershipRequestsCollection)
          .doc(request.id)
          .set(request.toJson());

      print('✅ Partnerlik isteği gönderildi: ${request.id}');
    } catch (e) {
      print('❌ Partnerlik isteği gönderilemedi: $e');
      throw Exception('Partnerlik isteği gönderilemedi: $e');
    }
  }

  // Müşterinin bir firmaya partnerlik isteği olup olmadığını kontrol et
  static Future<PartnershipRequest?> getPartnershipRequest(
      String customerId, String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_partnershipRequestsCollection)
          .where('customerId', isEqualTo: customerId)
          .where('companyId', isEqualTo: companyId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return PartnershipRequest.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Partnerlik isteği kontrol edilemedi: $e');
      return null;
    }
  }

  // Müşterinin bir firma ile partnership durumunu kontrol et
  static Future<PartnershipStatus> getPartnershipStatus(
      String customerId, String companyId) async {
    try {
      // Önce aktif partnership var mı kontrol et
      final partnershipSnapshot = await _firestore
          .collection(_partnershipsCollection)
          .where('customerId', isEqualTo: customerId)
          .where('companyId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (partnershipSnapshot.docs.isNotEmpty) {
        return PartnershipStatus.approved;
      }

      // Aktif partnership yoksa, bekleyen/reddedilen istek var mı kontrol et
      final requestSnapshot = await _firestore
          .collection(_partnershipRequestsCollection)
          .where('customerId', isEqualTo: customerId)
          .where('companyId', isEqualTo: companyId)
          .orderBy('requestDate', descending: true)
          .limit(1)
          .get();

      if (requestSnapshot.docs.isNotEmpty) {
        final request =
            PartnershipRequest.fromJson(requestSnapshot.docs.first.data());
        return request.status;
      }

      return PartnershipStatus.notPartner;
    } catch (e) {
      print('❌ Partnerlik durumu kontrol edilemedi: $e');
      return PartnershipStatus.notPartner;
    }
  }

  // Müşterinin tüm partnerlik isteklerini getir
  static Future<List<PartnershipRequest>> getCustomerPartnershipRequests(
      String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_partnershipRequestsCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PartnershipRequest.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Partnerlik istekleri getirilemedi: $e');
      return [];
    }
  }

  // Firmanın aldığı partnerlik isteklerini getir
  static Future<List<PartnershipRequest>> getCompanyPartnershipRequests(
      String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_partnershipRequestsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: PartnershipStatus.pending.index)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PartnershipRequest.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Firma partnerlik istekleri getirilemedi: $e');
      return [];
    }
  }

  // Partnerlik isteğini onayla (Admin/Firma tarafında kullanılacak)
  static Future<void> approvePartnershipRequest(
      String requestId,
      String companyId,
      String customerId,
      String customerName,
      String companyName) async {
    try {
      // İsteği güncelle
      await _firestore
          .collection(_partnershipRequestsCollection)
          .doc(requestId)
          .update({
        'status': PartnershipStatus.approved.index,
        'responseDate': DateTime.now().toIso8601String(),
        'responseMessage': 'Partnerlik isteğiniz onaylanmıştır.',
      });

      // Aktif partnership oluştur
      final partnership = Partnership(
        customerId: customerId,
        companyId: companyId,
        customerName: customerName,
        companyName: companyName,
        startDate: DateTime.now(),
      );

      await _firestore
          .collection(_partnershipsCollection)
          .doc(partnership.id)
          .set(partnership.toJson());

      print('✅ Partnerlik isteği onaylandı: $requestId');
    } catch (e) {
      print('❌ Partnerlik isteği onaylanamadı: $e');
      throw Exception('Partnerlik isteği onaylanamadı: $e');
    }
  }

  // Partnerlik isteğini reddet
  static Future<void> rejectPartnershipRequest(
      String requestId, String? message) async {
    try {
      await _firestore
          .collection(_partnershipRequestsCollection)
          .doc(requestId)
          .update({
        'status': PartnershipStatus.rejected.index,
        'responseDate': DateTime.now().toIso8601String(),
        'responseMessage': message ?? 'Partnerlik isteğiniz reddedilmiştir.',
      });

      print('✅ Partnerlik isteği reddedildi: $requestId');
    } catch (e) {
      print('❌ Partnerlik isteği reddedilemedi: $e');
      throw Exception('Partnerlik isteği reddedilemedi: $e');
    }
  }

  // Müşterinin partner olduğu firmaları getir
  static Future<List<Partnership>> getCustomerPartnerships(
      String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_partnershipsCollection)
          .where('customerId', isEqualTo: customerId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Partnership.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Müşteri partnerlikleri getirilemedi: $e');
      return [];
    }
  }

  // Partnership'i sonlandır
  static Future<void> endPartnership(String partnershipId) async {
    try {
      await _firestore
          .collection(_partnershipsCollection)
          .doc(partnershipId)
          .update({'isActive': false});

      print('✅ Partnership sonlandırıldı: $partnershipId');
    } catch (e) {
      print('❌ Partnership sonlandırılamadı: $e');
      throw Exception('Partnership sonlandırılamadı: $e');
    }
  }

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
      final partnership = Partnership(
        customerId: companyAId, // İlk firma müşteri olarak
        companyId: companyBId, // İkinci firma olarak
        customerName: companyAName,
        companyName: companyBName,
        startDate: DateTime.now(),
      );

      await _firestore
          .collection(_partnershipsCollection)
          .doc(partnership.id)
          .set(partnership.toJson());

      print('✅ İş ortaklığı oluşturuldu: ${partnership.id}');
      return partnership;
    } catch (e) {
      print('❌ İş ortaklığı oluşturulamadı: $e');
      return null;
    }
  }

  // Kullanıcının firma ortaklıklarını getir
  static Future<List<Partnership>> getUserCompanyPartnerships(
      String userId) async {
    try {
      print('DEBUG: getUserCompanyPartnerships çağrıldı, userId: $userId');

      // Önce kullanıcının sahip olduğu firmaları al
      final userCompanies = await CompanyService.getUserCompanies(userId);
      print('DEBUG: Kullanıcının ${userCompanies.length} firması var');

      if (userCompanies.isEmpty) {
        print('DEBUG: Kullanıcının firması bulunamadı');
        return [];
      }

      List<Partnership> allPartnerships = [];

      // Her firma için ortaklıkları ara
      for (var company in userCompanies) {
        print(
            'DEBUG: ${company.name} (${company.id}) firması için ortaklıklar kontrol ediliyor');

        // Bu firmanın customerId olarak bulunduğu ortaklıklar
        final customerPartnerships = await _firestore
            .collection(_partnershipsCollection)
            .where('customerId', isEqualTo: company.id)
            .where('isActive', isEqualTo: true)
            .get();

        // Bu firmanın companyId olarak bulunduğu ortaklıklar
        final companyPartnerships = await _firestore
            .collection(_partnershipsCollection)
            .where('companyId', isEqualTo: company.id)
            .where('isActive', isEqualTo: true)
            .get();

        // Sonuçları birleştir
        final companyPartnershipList = [
          ...customerPartnerships.docs
              .map((doc) => Partnership.fromJson(doc.data())),
          ...companyPartnerships.docs
              .map((doc) => Partnership.fromJson(doc.data())),
        ];

        print(
            'DEBUG: ${company.name} için ${companyPartnershipList.length} ortaklık bulundu');
        allPartnerships.addAll(companyPartnershipList);
      }

      print('DEBUG: Toplam ${allPartnerships.length} ortaklık bulundu');
      return allPartnerships;
    } catch (e) {
      print('❌ Kullanıcı firma ortaklıkları getirilemedi: $e');
      return [];
    }
  }
}
