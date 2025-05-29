import 'package:flutter/material.dart';
import 'package:siparis/models/work_request.dart';
import 'package:siparis/services/work_request_service.dart';
import 'package:siparis/services/company_service.dart';
import 'package:siparis/services/partnership_service.dart';

class WorkRequestProvider with ChangeNotifier {
  List<WorkRequest> _workRequests = [];
  List<String> _partneredCompanies = [];
  bool _isLoading = false;

  List<WorkRequest> get workRequests => _workRequests;
  List<String> get partneredCompanies => _partneredCompanies;
  bool get isLoading => _isLoading;

  WorkRequestProvider() {
    _loadSampleData();
  }

  void _loadSampleData() {
    // Örnek olarak bazı firmalarla çalışıyor olalım
    _partneredCompanies = ['1', '3']; // Anadolu Gıda ve Deniz Ürünleri A.Ş.

    // Örnek çalışma istekleri - sadece kabul edilmiş olanlar
    _workRequests = [
      WorkRequest(
        id: '1',
        fromUserId: 'current_user_id',
        toCompanyId: '1',
        fromUserName: 'Kullanıcı Adı',
        toCompanyName: 'Anadolu Gıda',
        message: 'Merhaba, sizinle çalışmak istiyorum.',
        status: WorkRequestStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        respondedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      WorkRequest(
        id: '2',
        fromUserId: 'current_user_id',
        toCompanyId: '3',
        fromUserName: 'Kullanıcı Adı',
        toCompanyName: 'Deniz Ürünleri A.Ş.',
        message: 'Deniz ürünleri konusunda işbirliği yapmak istiyorum.',
        status: WorkRequestStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        respondedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  // Çalışma isteklerini kontrol et ve callback çağır
  void checkWorkRequests() {
    // Firebase'den yüklenen gerçek istekleri kontrol et
    final pendingRequests = _workRequests
        .where((request) => request.status == WorkRequestStatus.pending)
        .toList();

    print(
        'DEBUG: checkWorkRequests - Toplam istek: ${_workRequests.length}, Bekleyen: ${pendingRequests.length}');
    for (var request in pendingRequests) {
      print(
          'DEBUG: Bekleyen istek - ${request.fromUserName}: ${request.message}');
    }

    if (pendingRequests.isNotEmpty && onWorkRequestsFound != null) {
      onWorkRequestsFound!(pendingRequests);
    }
  }

  // Callback fonksiyonu
  Function(List<WorkRequest>)? onWorkRequestsFound;

  // Firebase'den kullanıcının isteklerini yükle
  Future<void> loadUserRequests(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _workRequests = await WorkRequestService.getSentRequests(userId);

      // Kabul edilen isteklerden partnered companies listesini oluştur
      _partneredCompanies = _workRequests
          .where((request) => request.status == WorkRequestStatus.accepted)
          .map((request) => request.toCompanyId)
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Kullanıcı istekleri yüklenirken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Firebase'den firma isteklerini yükle
  Future<void> loadCompanyRequests(String companyId) async {
    try {
      print('DEBUG: loadCompanyRequests çağrıldı, companyId: $companyId');
      _isLoading = true;
      notifyListeners();

      final requests = await WorkRequestService.getReceivedRequests(companyId);
      print('DEBUG: Firebase\'den ${requests.length} istek alındı');

      // Mevcut isteklere ekle (duplicate kontrolü yaparak)
      for (var request in requests) {
        print(
            'DEBUG: İstek - ID: ${request.id}, From: ${request.fromUserName}, Status: ${request.status}');
        if (!_workRequests.any((existing) => existing.id == request.id)) {
          _workRequests.add(request);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Firma istekleri yüklenirken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kullanıcının gönderdiği istekler
  List<WorkRequest> getSentRequests(String userId) {
    return _workRequests
        .where((request) => request.fromUserId == userId)
        .toList();
  }

  // Kullanıcının aldığı istekler (firma sahibi ise)
  List<WorkRequest> getReceivedRequests(String companyId) {
    return _workRequests
        .where((request) => request.toCompanyId == companyId)
        .toList();
  }

  // Bekleyen istekler
  List<WorkRequest> getPendingRequests(String companyId) {
    return _workRequests
        .where((request) =>
            request.toCompanyId == companyId &&
            request.status == WorkRequestStatus.pending)
        .toList();
  }

  // Çalışma isteği gönder (Firebase)
  Future<bool> sendWorkRequest({
    required String fromUserId,
    required String toCompanyId,
    required String fromUserName,
    required String toCompanyName,
    required String message,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final workRequest = await WorkRequestService.sendWorkRequest(
        fromUserId: fromUserId,
        toCompanyId: toCompanyId,
        fromUserName: fromUserName,
        toCompanyName: toCompanyName,
        message: message,
      );

      if (workRequest != null) {
        _workRequests.add(workRequest);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Çalışma isteği gönderilirken hata: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Çalışma isteğini kabul et (Firebase)
  Future<bool> acceptWorkRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await WorkRequestService.acceptWorkRequest(requestId);

      if (success) {
        final requestIndex =
            _workRequests.indexWhere((request) => request.id == requestId);
        if (requestIndex != -1) {
          final request = _workRequests[requestIndex];

          // İsteğin durumunu güncelle
          _workRequests[requestIndex] = request.copyWith(
            status: WorkRequestStatus.accepted,
            respondedAt: DateTime.now(),
          );

          // İş ortaklığı oluştur
          print('DEBUG: İş ortaklığı oluşturuluyor...');
          print('DEBUG: From User ID: ${request.fromUserId}');
          print('DEBUG: To Company ID: ${request.toCompanyId}');

          // Gönderen kullanıcının firma bilgilerini al
          final senderCompanies =
              await CompanyService.getUserCompanies(request.fromUserId);

          if (senderCompanies.isNotEmpty) {
            final senderCompany = senderCompanies.first; // İlk firmayı al

            // Alıcı firma bilgilerini al
            final receiverCompany =
                await CompanyService.getCompany(request.toCompanyId);

            if (receiverCompany != null) {
              // İş ortaklığı oluştur
              final partnership = await PartnershipService.createPartnership(
                companyAId: senderCompany.id,
                companyBId: receiverCompany.id,
                companyAName: senderCompany.name,
                companyBName: receiverCompany.name,
                initiatedBy: senderCompany.id,
                notes: 'Çalışma isteği kabul edilerek oluşturuldu',
              );

              if (partnership != null) {
                print(
                    'DEBUG: İş ortaklığı başarıyla oluşturuldu: ${partnership.id}');

                // 🔄 Firebase'den partnership verilerini yeniden yükle
                print(
                    'DEBUG: Partnership verileri Firebase\'den yeniden yükleniyor...');
                await loadUserPartnerships(request.fromUserId);
                print('DEBUG: Partnership verileri güncellendi');
              } else {
                print('DEBUG: İş ortaklığı oluşturulamadı');
              }
            } else {
              print('DEBUG: Alıcı firma bulunamadı: ${request.toCompanyId}');
            }
          } else {
            print(
                'DEBUG: Gönderen kullanıcının firması bulunamadı: ${request.fromUserId}');
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('İstek kabul edilirken hata: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Çalışma isteğini reddet (Firebase)
  Future<bool> rejectWorkRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await WorkRequestService.rejectWorkRequest(requestId);

      if (success) {
        final requestIndex =
            _workRequests.indexWhere((request) => request.id == requestId);
        if (requestIndex != -1) {
          _workRequests[requestIndex] = _workRequests[requestIndex].copyWith(
            status: WorkRequestStatus.rejected,
            respondedAt: DateTime.now(),
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('İstek reddedilirken hata: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Partnered company olup olmadığını kontrol et
  bool isPartneredCompany(String companyId) {
    return _partneredCompanies.contains(companyId);
  }

  // Partnered company ekle (manuel olarak)
  void addPartneredCompany(String companyId) {
    if (!_partneredCompanies.contains(companyId)) {
      _partneredCompanies.add(companyId);
      notifyListeners();
    }
  }

  // Partnered company çıkar
  void removePartneredCompany(String companyId) {
    _partneredCompanies.remove(companyId);
    notifyListeners();
  }

  // İsteği sil (Firebase)
  Future<bool> deleteWorkRequest(String requestId) async {
    try {
      final success = await WorkRequestService.deleteWorkRequest(requestId);

      if (success) {
        _workRequests.removeWhere((request) => request.id == requestId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('İstek silinirken hata: $e');
      return false;
    }
  }

  // Kullanıcının sahip olduğu tüm firmalara gelen istekleri yükle
  Future<void> loadUserCompanyRequests(String userId) async {
    try {
      print('DEBUG: loadUserCompanyRequests çağrıldı, userId: $userId');
      _isLoading = true;
      notifyListeners();

      // Önce kullanıcının sahip olduğu firmaları al
      final userCompanies = await CompanyService.getUserCompanies(userId);
      print('DEBUG: Kullanıcının ${userCompanies.length} firması bulundu');

      // Kullanıcının firma ID'lerini yazdır
      for (var company in userCompanies) {
        print(
            'DEBUG: Kullanıcının firması - ID: ${company.id}, Name: ${company.name}');
      }

      // Mevcut istekleri temizle (yeniden yükleme için)
      _workRequests.clear();

      // Her firma için gelen istekleri yükle
      for (var company in userCompanies) {
        print(
            'DEBUG: ${company.name} (ID: ${company.id}) firması için istekler kontrol ediliyor...');
        final requests =
            await WorkRequestService.getReceivedRequests(company.id);
        print('DEBUG: ${company.name} için ${requests.length} istek bulundu');

        // Mevcut isteklere ekle (duplicate kontrolü yaparak)
        for (var request in requests) {
          print(
              'DEBUG: İstek - ID: ${request.id}, From: ${request.fromUserName}, To: ${request.toCompanyName}, Status: ${request.status}');
          if (!_workRequests.any((existing) => existing.id == request.id)) {
            _workRequests.add(request);
          }
        }
      }

      print('DEBUG: Toplam ${_workRequests.length} istek yüklendi');

      // İş ortaklıklarını da yükle
      await loadUserPartnerships(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Kullanıcı firma istekleri yüklenirken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kullanıcının iş ortaklıklarını yükle
  Future<void> loadUserPartnerships(String userId) async {
    try {
      print('DEBUG: Kullanıcının iş ortaklıkları yükleniyor...');

      // Kullanıcının sahip olduğu firmaların iş ortaklıklarını al
      final partnerships =
          await PartnershipService.getUserCompanyPartnerships(userId);
      print('DEBUG: ${partnerships.length} iş ortaklığı bulundu');

      // Partnered companies listesini güncelle
      _partneredCompanies.clear();

      for (var partnership in partnerships) {
        // Kullanıcının sahip olduğu firmaları al
        final userCompanies = await CompanyService.getUserCompanies(userId);

        for (var userCompany in userCompanies) {
          // Bu kullanıcının firması bu iş ortaklığında var mı?
          if (partnership.customerId == userCompany.id) {
            // Partner firma companyId'dir
            if (!_partneredCompanies.contains(partnership.companyId)) {
              _partneredCompanies.add(partnership.companyId);
              print(
                  'DEBUG: Partner firma eklendi: ${partnership.companyName} (${partnership.companyId})');
            }
          } else if (partnership.companyId == userCompany.id) {
            // Partner firma customerId'dir
            if (!_partneredCompanies.contains(partnership.customerId)) {
              _partneredCompanies.add(partnership.customerId);
              print(
                  'DEBUG: Partner firma eklendi: ${partnership.customerName} (${partnership.customerId})');
            }
          }
        }
      }

      print(
          'DEBUG: Toplam ${_partneredCompanies.length} partner firma yüklendi');
    } catch (e) {
      print('DEBUG: İş ortaklıkları yüklenirken hata: $e');
    }
  }
}
