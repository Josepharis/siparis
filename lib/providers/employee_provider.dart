import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siparis/models/employee.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  List<Employee> _employees = [];
  bool _isLoading = false;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;

  // Aktif çalışanları getir
  List<Employee> get activeEmployees =>
      _employees.where((emp) => emp.isActive).toList();

  // Şirket çalışanlarını getir
  List<Employee> getCompanyEmployees(String companyId) =>
      _employees.where((emp) => emp.companyId == companyId).toList();

  // Çalışan ekle
  Future<bool> addEmployee({
    required String name,
    required String email,
    required String phone,
    required String position,
    required String password,
    required String companyId,
    required Map<String, bool> permissions,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔥 Firebase auth durumu kontrol ediliyor...');

      // Firebase auth kontrol
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Firebase kullanıcısı giriş yapmamış!');
        throw Exception(
            'Firebase kullanıcısı giriş yapmamış. Lütfen tekrar giriş yapın.');
      }

      print('✅ Firebase kullanıcı: ${currentUser.uid}');
      print('✅ Çalışan bilgileri: $name, $email, $phone, $position');

      final employeeId = _uuid.v4();
      final employee = Employee(
        id: employeeId,
        name: name,
        email: email,
        phone: phone,
        position: position,
        companyId: companyId,
        password: password,
        permissions: permissions,
        createdAt: DateTime.now(),
      );

      print('🔥 Firebase\'e kaydediliyor...');
      print('📄 Veri: ${employee.toMap()}');

      // Firebase'e kaydet
      await _firestore
          .collection('employees')
          .doc(employeeId)
          .set(employee.toMap());

      // Local listeye ekle
      _employees.add(employee);

      print('✅ Çalışan başarıyla eklendi: ${employee.name}');
      return true;
    } catch (e) {
      print('❌ Çalışan ekleme hatası: $e');
      print('❌ Hata tipi: ${e.runtimeType}');
      if (e.toString().contains('auth')) {
        throw Exception(
            'Yetkilendirme hatası. Lütfen çıkış yapıp tekrar giriş yapın.');
      } else if (e.toString().contains('permission')) {
        throw Exception('İzin hatası. Firebase kuralları kontrol edilmeli.');
      } else {
        throw Exception('Beklenmeyen hata: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Çalışanları yükle
  Future<void> loadEmployees(String companyId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('employees')
          .where('companyId', isEqualTo: companyId)
          .get();

      _employees = querySnapshot.docs
          .map((doc) => Employee.fromMap(doc.data()))
          .toList();

      print('✅ ${_employees.length} çalışan yüklendi');
    } catch (e) {
      print('❌ Çalışan yükleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Çalışan güncelle
  Future<bool> updateEmployee(Employee employee) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employee.id)
          .update(employee.toMap());

      final index = _employees.indexWhere((emp) => emp.id == employee.id);
      if (index != -1) {
        _employees[index] = employee;
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('❌ Çalışan güncelleme hatası: $e');
      return false;
    }
  }

  // Çalışan sil (deaktive et)
  Future<bool> deactivateEmployee(String employeeId) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employeeId)
          .update({'isActive': false});

      final index = _employees.indexWhere((emp) => emp.id == employeeId);
      if (index != -1) {
        _employees[index] = _employees[index].copyWith(isActive: false);
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('❌ Çalışan deaktive etme hatası: $e');
      return false;
    }
  }

  // E-posta ile çalışan bul
  Employee? findEmployeeByEmail(String email) {
    try {
      return _employees.firstWhere(
        (emp) => emp.email.toLowerCase() == email.toLowerCase() && emp.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  // ID ile çalışan bul
  Employee? findEmployeeById(String id) {
    try {
      return _employees.firstWhere((emp) => emp.id == id);
    } catch (e) {
      return null;
    }
  }

  // Çalışan yetki kontrolü
  bool hasPermission(String employeeId, String permission) {
    final employee = findEmployeeById(employeeId);
    return employee?.hasPermission(permission) ?? false;
  }
}
