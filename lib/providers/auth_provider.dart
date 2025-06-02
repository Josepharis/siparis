import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/employee.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  Employee? _currentEmployee; // Çalışan bilgisi
  bool _isLoading = false;
  bool _isInitialized =
      false; // Auth durumunun başlatılıp başlatılmadığını kontrol eder
  String? _errorMessage;
  bool _isEmployeeLogin = false; // Çalışan girişi mi?

  // SharedPreferences keys
  static const String _employeeDataKey = 'employee_data';
  static const String _isEmployeeLoginKey = 'is_employee_login';

  // Şifre hash fonksiyonu
  String _hashPassword(String password) {
    var bytes = utf8.encode(password + 'siparis_salt_2024'); // Salt ekle
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      (_currentUser != null || _currentEmployee != null) && _isInitialized;
  bool get isEmployeeLogin => _isEmployeeLogin;
  bool get isOwnerLogin => !_isEmployeeLogin && _currentUser != null;

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  // Auth durumunu başlat ve dinle
  void _initializeAuth() async {
    try {
      // Önce çalışan otomatik girişini kontrol et
      await _checkAutoEmployeeLogin();

      // Firebase auth state değişikliklerini her zaman dinle
      AuthService.authStateChanges.listen((User? user) async {
        // Eğer çalışan girişi aktifse Firebase user değişikliklerini görmezden gel
        if (_isEmployeeLogin && _currentEmployee != null) {
          print(
              '🔧 Çalışan girişi aktif, Firebase user değişiklikleri görmezden geliniyor');
          if (!_isInitialized) {
            _isInitialized = true;
            notifyListeners();
          }
          return;
        }

        // Sahip kullanıcı Firebase işlemleri
        if (user != null) {
          try {
            _currentUser = await AuthService.getUserData(user.uid);
            _isEmployeeLogin = false;
            _currentEmployee = null;

            // Demo çalışan verisi kontrolü (email bazlı)
            if (user.email == 'calisan@test.com') {
              _currentEmployee = Employee(
                id: 'demo_emp_1',
                name: 'Demo Çalışan',
                email: 'calisan@test.com',
                phone: '0555 123 45 67',
                position: 'Satış Uzmanı',
                companyId: 'demo_company',
                permissions: {
                  'manage_orders': true,
                  'manage_products': true,
                  'view_partial_budget': true,
                  'view_budget': false,
                  'approve_partnerships': false,
                  'view_companies': false,
                },
                createdAt: DateTime.now(),
                isActive: true,
                password: 'hashed_password',
              );
              _isEmployeeLogin = true;
              _currentUser = null; // Demo çalışan için sahip bilgisini temizle
            }

            print('✅ Sahip otomatik girişi başarılı: ${_currentUser?.name}');
          } catch (e) {
            _errorMessage = e.toString();
            _currentUser = null;
            _currentEmployee = null;
            _isEmployeeLogin = false;
            print('❌ Sahip otomatik giriş hatası: $e');
          }
        } else {
          // User null ise ve çalışan girişi de yoksa tüm bilgileri temizle
          if (!_isEmployeeLogin) {
            _currentUser = null;
            _currentEmployee = null;
            print('ℹ️ Firebase user null, otomatik giriş yok');
          }
        }

        if (!_isInitialized) {
          _isInitialized = true;
        }

        notifyListeners();
      });
    } catch (e) {
      print('❌ Auth initialization hatası: $e');
      _isInitialized = true;
      _currentUser = null;
      _currentEmployee = null;
      _isEmployeeLogin = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Çalışan otomatik giriş kontrolü
  Future<void> _checkAutoEmployeeLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEmployeeLogin = prefs.getBool(_isEmployeeLoginKey) ?? false;
      final employeeDataString = prefs.getString(_employeeDataKey);

      if (isEmployeeLogin && employeeDataString != null) {
        print('🔄 Çalışan otomatik girişi kontrol ediliyor...');

        final employeeData =
            jsonDecode(employeeDataString) as Map<String, dynamic>;
        final savedEmployee = Employee.fromMap(employeeData);

        // Firebase'den güncel çalışan bilgisini kontrol et
        final QuerySnapshot employeeQuery = await FirebaseFirestore.instance
            .collection('employees')
            .where('email', isEqualTo: savedEmployee.email.toLowerCase())
            .where('isActive', isEqualTo: true)
            .get();

        if (employeeQuery.docs.isNotEmpty) {
          print('✅ Çalışan otomatik girişi başarılı: ${savedEmployee.name}');

          // Güncel çalışan verisini al
          final currentEmployeeData =
              employeeQuery.docs.first.data() as Map<String, dynamic>;
          _currentEmployee = Employee.fromMap(currentEmployeeData);
          _isEmployeeLogin = true;
          _currentUser = null; // Sahip girişini temizle

          print('🎯 Çalışan otomatik girişi tamamlandı');
        } else {
          print('❌ Çalışan artık aktif değil, otomatik giriş temizleniyor');
          await _clearEmployeeLoginData();
          _isEmployeeLogin = false;
          _currentEmployee = null;
        }
      } else {
        print('ℹ️ Kaydedilmiş çalışan girişi bulunamadı');
        _isEmployeeLogin = false;
        _currentEmployee = null;
      }
    } catch (e) {
      print('❌ Çalışan otomatik giriş kontrolü hatası: $e');
      await _clearEmployeeLoginData();
      _isEmployeeLogin = false;
      _currentEmployee = null;
    }
  }

  // Çalışan giriş bilgilerini kaydet
  Future<void> _saveEmployeeLoginData(Employee employee) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isEmployeeLoginKey, true);
      await prefs.setString(_employeeDataKey, jsonEncode(employee.toMap()));
      print('💾 Çalışan giriş bilgileri kaydedildi');
    } catch (e) {
      print('❌ Çalışan giriş bilgileri kaydedilemedi: $e');
    }
  }

  // Çalışan giriş bilgilerini temizle
  Future<void> _clearEmployeeLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isEmployeeLoginKey);
      await prefs.remove(_employeeDataKey);
      print('🗑️ Çalışan giriş bilgileri temizlendi');
    } catch (e) {
      print('❌ Çalışan giriş bilgileri temizlenemedi: $e');
    }
  }

  // Kayıt ol
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? companyName,
    String? companyAddress,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        companyName: companyName,
        companyAddress: companyAddress,
        role: role,
      );

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Giriş yap
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Önce çalışan kontrolü yap
      if (await _checkAndSignInAsEmployee(email, password)) {
        _setLoading(false);
        return true;
      }

      // Çalışan değilse normal Firebase girişi dene
      _currentUser = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_currentUser != null) {
        print(
            '✅ Kullanıcı girişi başarılı: ${_currentUser?.name} (${_currentUser?.role})');
        _isEmployeeLogin = false;
        _currentEmployee = null;
      } else {
        print('❌ Kullanıcı girişi başarısız: Kullanıcı bilgileri alınamadı');
        _setError('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.');
        return false;
      }

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      print('❌ Giriş hatası: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Çalışan kontrolü ve girişi
  Future<bool> _checkAndSignInAsEmployee(String email, String password) async {
    try {
      print('🔍 Çalışan kontrolü yapılıyor: $email');

      // Firebase'den employees collection'ından bu email ile çalışan ara
      final QuerySnapshot employeeQuery = await FirebaseFirestore.instance
          .collection('employees')
          .where('email', isEqualTo: email.toLowerCase())
          .where('isActive', isEqualTo: true)
          .get();

      if (employeeQuery.docs.isNotEmpty) {
        print('✅ Çalışan bulundu!');

        // Çalışan verisini al
        final employeeData =
            employeeQuery.docs.first.data() as Map<String, dynamic>;

        // Employee nesnesini oluştur
        final employee = Employee.fromMap(employeeData);

        // Gerçek şifre kontrolü
        final hashedPassword = _hashPassword(password);
        if (hashedPassword == employee.password) {
          _currentEmployee = employee;
          _isEmployeeLogin = true;
          _currentUser = null; // Sahip girişini temizle

          // Çalışan giriş bilgilerini lokal olarak kaydet
          await _saveEmployeeLoginData(employee);

          print('✅ Çalışan girişi başarılı: ${_currentEmployee!.name}');
          return true;
        } else {
          print('❌ Çalışan şifresi yanlış');
          throw Exception('Şifre hatalı');
        }
      }

      print('ℹ️ Bu email ile aktif çalışan bulunamadı');
      return false;
    } catch (e) {
      print('❌ Çalışan kontrolü hatası: $e');
      if (e.toString().contains('Şifre hatalı')) {
        throw e; // Şifre hatasını yukarı aktar
      }
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      if (_isEmployeeLogin) {
        // Çalışan çıkışı - lokal verileri temizle
        print('🚪 Çalışan çıkışı yapılıyor...');
        await _clearEmployeeLoginData();
        _currentEmployee = null;
        _isEmployeeLogin = false;
        print('✅ Çalışan çıkışı tamamlandı');
      } else {
        // Sahip çıkışı - Firebase'den çıkış yap
        print('🚪 Sahip çıkışı yapılıyor...');
        await AuthService.signOut();
        _currentUser = null;
        print('✅ Sahip çıkışı tamamlandı');
      }

      // Her durumda tüm verileri temizle
      _currentUser = null;
      _currentEmployee = null;
      _isEmployeeLogin = false;

      _setLoading(false);
      print('🎯 Çıkış işlemi tamamlandı');
    } catch (e) {
      print('❌ Çıkış hatası: $e');
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<bool> updateUserData(UserModel updatedUser) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.updateUserData(updatedUser);
      _currentUser = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Çalışan yetki kontrolü
  bool hasPermission(String permission) {
    if (_isEmployeeLogin && _currentEmployee != null) {
      return _currentEmployee!.hasPermission(permission);
    }
    // Sahip her şeye erişebilir
    return !_isEmployeeLogin && _currentUser != null;
  }

  // Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Hata mesajını ayarla
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Hata mesajını temizle
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Hata mesajını temizle (manuel)
  void clearError() {
    _clearError();
  }
}
