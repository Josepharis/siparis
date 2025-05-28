import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import 'company_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı al
  static User? get currentUser => _auth.currentUser;

  // Auth durumunu dinle
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kullanıcı kayıt ol
  static Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? companyName,
    String? companyAddress,
    required String role,
  }) async {
    try {
      // Firebase Auth'da kullanıcı oluştur
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        String? companyId;

        // Eğer firma bilgileri varsa, firma oluştur
        if (companyName != null &&
            companyName.isNotEmpty &&
            companyAddress != null &&
            companyAddress.isNotEmpty) {
          try {
            CompanyModel? company = await CompanyService.createCompany(
              name: companyName,
              address: companyAddress,
              phone: phone,
              email: email,
              ownerId: user.uid,
              type: role,
            );
            companyId = company?.id;
          } catch (e) {
            print('Firma oluşturulurken hata: $e');
            // Firma oluşturulamazsa devam et, sadece kullanıcıyı kaydet
          }
        }

        // Kullanıcı bilgilerini Firestore'a kaydet
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          phone: phone,
          companyName: companyName,
          companyAddress: companyAddress,
          companyId: companyId,
          role: role,
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        // Display name'i güncelle
        await user.updateDisplayName(name);

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Kayıt işlemi sırasında beklenmeyen bir hata oluştu: $e');
    }
  }

  // Kullanıcı giriş yap
  static Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Firestore'dan kullanıcı bilgilerini al
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          return UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
            user.uid,
          );
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Giriş işlemi sırasında beklenmeyen bir hata oluştu: $e');
    }
  }

  // Kullanıcı çıkış yap
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Çıkış işlemi sırasında hata oluştu: $e');
    }
  }

  // Şifre sıfırlama e-postası gönder
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception(
          'Şifre sıfırlama e-postası gönderilirken hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini Firestore'dan al
  static Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          uid,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınırken hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini güncelle
  static Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .update(userModel.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Kullanıcı bilgileri güncellenirken hata oluştu: $e');
    }
  }

  // Firebase Auth hatalarını işle
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-not-found':
        return 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}
