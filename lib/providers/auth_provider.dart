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

      // Eğer çalışan otomatik girişi başarılıysa Firebase listener'ını başlatma
      if (_isEmployeeLogin && _currentEmployee != null) {
        print('🔧 Çalışan girişi aktif, Firebase listener başlatılmayacak');
        return;
      }

      // Firebase auth state değişikliklerini dinle (sadece sahip girişi için)
      AuthService.authStateChanges.listen((User? user) async {
        if (!_isEmployeeLogin) {
          // Sadece çalışan girişi yapılmamışsa Firebase'i dinle
          if (user != null) {
            try {
              _currentUser = await AuthService.getUserData(user.uid);
            } catch (e) {
              _errorMessage = e.toString();
              _currentUser = null;
            }
          } else {
            _currentUser = null;
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

          // Auth başlatılmış olarak işaretle ve UI'ı bilgilendir
          _isInitialized = true;
          notifyListeners();

          print('🎯 Çalışan otomatik girişi tamamlandı, UI güncellenecek');
        } else {
          print('❌ Çalışan artık aktif değil, otomatik giriş temizleniyor');
          await _clearEmployeeLoginData();

          // Başarısız giriş durumunda da initialize olarak işaretle
          _isInitialized = true;
          notifyListeners();
        }
      } else {
        print('ℹ️ Kaydedilmiş çalışan girişi bulunamadı');

        // Çalışan girişi yoksa da initialize olarak işaretle
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Çalışan otomatik giriş kontrolü hatası: $e');
      await _clearEmployeeLoginData();

      // Hata durumunda da initialize olarak işaretle
      _isInitialized = true;
      notifyListeners();
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

      _isEmployeeLogin = false; // Normal kullanıcı girişi
      _currentEmployee = null;

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
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
        await _clearEmployeeLoginData();
        _currentEmployee = null;
        _isEmployeeLogin = false;
      } else {
        // Sahip çıkışı
        await AuthService.signOut();
        _currentUser = null;
      }
      _setLoading(false);
    } catch (e) {
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
