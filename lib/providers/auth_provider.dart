import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized =
      false; // Auth durumunun başlatılıp başlatılmadığını kontrol eder
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _isInitialized;

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  // Auth durumunu başlat ve dinle
  void _initializeAuth() {
    AuthService.authStateChanges.listen((User? user) async {
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

      if (!_isInitialized) {
        _isInitialized = true;
      }

      notifyListeners();
    });
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
      _currentUser = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.signOut();
      _currentUser = null;
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
