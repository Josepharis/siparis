import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_request.dart';

class WorkRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'work_requests';

  // Çalışma isteği gönder
  static Future<WorkRequest?> sendWorkRequest({
    required String fromUserId,
    required String toCompanyId,
    required String fromUserName,
    required String toCompanyName,
    required String message,
  }) async {
    try {
      print('DEBUG: sendWorkRequest çağrıldı');
      print('DEBUG: fromUserId: $fromUserId');
      print('DEBUG: toCompanyId: $toCompanyId');
      print('DEBUG: fromUserName: $fromUserName');
      print('DEBUG: toCompanyName: $toCompanyName');

      // Aynı firmaya daha önce bekleyen istek var mı kontrol et
      QuerySnapshot existingRequests = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toCompanyId', isEqualTo: toCompanyId)
          .where('status', isEqualTo: 'pending')
          .get();

      print(
          'DEBUG: Mevcut bekleyen istek sayısı: ${existingRequests.docs.length}');

      if (existingRequests.docs.isNotEmpty) {
        print('DEBUG: Zaten bekleyen istek var, gönderim iptal edildi');
        throw Exception('Bu firmaya zaten bekleyen bir çalışma isteğiniz var');
      }

      DocumentReference docRef = _firestore.collection(_collection).doc();
      print('DEBUG: Yeni doküman ID: ${docRef.id}');

      WorkRequest workRequest = WorkRequest(
        id: docRef.id,
        fromUserId: fromUserId,
        toCompanyId: toCompanyId,
        fromUserName: fromUserName,
        toCompanyName: toCompanyName,
        message: message,
        status: WorkRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await docRef.set(workRequest.toMap());
      print('DEBUG: WorkRequest Firebase\'e kaydedildi');
      return workRequest;
    } catch (e) {
      print('DEBUG: sendWorkRequest hatası: $e');
      throw Exception('Çalışma isteği gönderilirken hata: $e');
    }
  }

  // Kullanıcının gönderdiği istekleri getir
  static Future<List<WorkRequest>> getSentRequests(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkRequest.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Gönderilen istekler alınırken hata: $e');
    }
  }

  // Firmaya gelen istekleri getir
  static Future<List<WorkRequest>> getReceivedRequests(String companyId) async {
    try {
      print('DEBUG: getReceivedRequests çağrıldı, companyId: $companyId');

      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('toCompanyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
          'DEBUG: Firebase\'den ${querySnapshot.docs.length} doküman bulundu');

      List<WorkRequest> requests = querySnapshot.docs.map((doc) {
        print('DEBUG: Doküman ID: ${doc.id}, Data: ${doc.data()}');
        return WorkRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      print('DEBUG: Toplam ${requests.length} WorkRequest oluşturuldu');
      for (var request in requests) {
        print(
            'DEBUG: Request - From: ${request.fromUserName}, To: ${request.toCompanyName}, Status: ${request.status}');
      }

      return requests;
    } catch (e) {
      print('DEBUG: getReceivedRequests hatası: $e');
      throw Exception('Alınan istekler alınırken hata: $e');
    }
  }

  // Bekleyen istekleri getir
  static Future<List<WorkRequest>> getPendingRequests(String companyId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('toCompanyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkRequest.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Bekleyen istekler alınırken hata: $e');
    }
  }

  // Çalışma isteğini kabul et
  static Future<bool> acceptWorkRequest(String requestId) async {
    try {
      DocumentReference docRef =
          _firestore.collection(_collection).doc(requestId);

      await docRef.update({
        'status': 'accepted',
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      throw Exception('İstek kabul edilirken hata: $e');
    }
  }

  // Çalışma isteğini reddet
  static Future<bool> rejectWorkRequest(String requestId) async {
    try {
      DocumentReference docRef =
          _firestore.collection(_collection).doc(requestId);

      await docRef.update({
        'status': 'rejected',
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      throw Exception('İstek reddedilirken hata: $e');
    }
  }

  // Kabul edilen istekleri getir (partnered companies için)
  static Future<List<WorkRequest>> getAcceptedRequests(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      return querySnapshot.docs
          .map((doc) => WorkRequest.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Kabul edilen istekler alınırken hata: $e');
    }
  }

  // İsteği sil
  static Future<bool> deleteWorkRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
      return true;
    } catch (e) {
      throw Exception('İstek silinirken hata: $e');
    }
  }
}
