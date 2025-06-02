import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

class SubscriptionProvider with ChangeNotifier {
  Subscription? _currentSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSubscription => _currentSubscription?.isValid ?? false;

  // Firebase collection reference
  final CollectionReference _subscriptionsRef =
      FirebaseFirestore.instance.collection('subscriptions');

  // Kullanıcının abonelik durumunu yükle
  Future<void> loadUserSubscription(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Kullanıcının aktif aboneliğini bul
      final QuerySnapshot querySnapshot = await _subscriptionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        _currentSubscription = Subscription.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      } else {
        _currentSubscription = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Abonelik yükleme hatası: $e');
    }
  }

  // Çalışanın firma abonelik durumunu yükle
  Future<void> loadCompanySubscription(String companyId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Firma sahibini bul
      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'producer')
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final companyOwnerUserId = userQuery.docs.first.id;

        // Firma sahibinin abonelik durumunu kontrol et
        final QuerySnapshot querySnapshot = await _subscriptionsRef
            .where('userId', isEqualTo: companyOwnerUserId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          _currentSubscription = Subscription.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        } else {
          _currentSubscription = null;
        }
      } else {
        _currentSubscription = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Firma abonelik yükleme hatası: $e');
    }
  }

  // Abonelik oluştur/güncelle (Admin kullanımı)
  Future<bool> createOrUpdateSubscription({
    required String userId,
    required bool isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? activatedBy,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Mevcut aboneliği kontrol et
      final QuerySnapshot existingQuery =
          await _subscriptionsRef.where('userId', isEqualTo: userId).get();

      final now = DateTime.now();

      if (existingQuery.docs.isNotEmpty) {
        // Mevcut aboneliği güncelle
        final docId = existingQuery.docs.first.id;
        final updateData = {
          'isActive': isActive,
          'startDate':
              startDate?.millisecondsSinceEpoch ?? now.millisecondsSinceEpoch,
          'endDate': endDate?.millisecondsSinceEpoch,
          'notes': notes,
          'updatedAt': now.millisecondsSinceEpoch,
          'activatedBy': activatedBy,
        };

        await _subscriptionsRef.doc(docId).update(updateData);
      } else {
        // Yeni abonelik oluştur
        final newSubscription = Subscription(
          id: '', // Firestore otomatik ID verecek
          userId: userId,
          isActive: isActive,
          startDate: startDate ?? now,
          endDate: endDate,
          notes: notes,
          createdAt: now,
          activatedBy: activatedBy,
        );

        await _subscriptionsRef.add(newSubscription.toMap());
      }

      // Güncel aboneliği yeniden yükle
      await loadUserSubscription(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Abonelik oluşturma/güncelleme hatası: $e');
      return false;
    }
  }

  // Aboneliği iptal et
  Future<bool> cancelSubscription(
      String userId, String cancelledBy, String? reason) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final QuerySnapshot querySnapshot =
          await _subscriptionsRef.where('userId', isEqualTo: userId).get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        final now = DateTime.now();

        await _subscriptionsRef.doc(docId).update({
          'isActive': false,
          'endDate': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
          'notes': reason ?? 'Abonelik iptal edildi',
          'activatedBy': cancelledBy,
        });

        // Güncel aboneliği yeniden yükle
        await loadUserSubscription(userId);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Abonelik iptal etme hatası: $e');
      return false;
    }
  }

  // Tüm abonelikleri getir (Admin paneli için)
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      final QuerySnapshot querySnapshot =
          await _subscriptionsRef.orderBy('createdAt', descending: true).get();

      List<Map<String, dynamic>> subscriptionsWithUsers = [];

      for (var doc in querySnapshot.docs) {
        final subscription = Subscription.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Kullanıcı bilgisini de getir
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(subscription.userId)
            .get();

        String userName = 'Bilinmeyen Kullanıcı';
        String userEmail = '';

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Bilinmeyen';
          userEmail = userData['email'] ?? '';
        }

        subscriptionsWithUsers.add({
          'subscription': subscription,
          'userName': userName,
          'userEmail': userEmail,
        });
      }

      return subscriptionsWithUsers;
    } catch (e) {
      print('❌ Tüm abonelikleri getirme hatası: $e');
      return [];
    }
  }

  // Abonelik durumunu temizle
  void clearSubscription() {
    _currentSubscription = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Erişim kontrolü - bu fonksiyon tüm uygulamada kullanılacak
  bool checkAccess() {
    return hasActiveSubscription;
  }
}
