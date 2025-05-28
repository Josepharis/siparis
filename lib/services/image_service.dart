import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Resim seç (galeri veya kamera)
  static Future<XFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      developer.log(
          'ImageService: Resim seçme işlemi başlatıldı, kaynak: $source',
          name: 'ImageService');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        developer.log('ImageService: Resim başarıyla seçildi: ${image.path}',
            name: 'ImageService');
        developer.log(
            'ImageService: Resim boyutu: ${await image.length()} bytes',
            name: 'ImageService');
      } else {
        developer.log('ImageService: Resim seçilmedi', name: 'ImageService');
      }

      return image;
    } catch (e, stackTrace) {
      developer.log('ImageService: Resim seçilirken hata oluştu',
          name: 'ImageService', error: e, stackTrace: stackTrace, level: 1000);
      throw Exception('Resim seçilirken hata oluştu: $e');
    }
  }

  // Ürün resmi yükle
  static Future<String> uploadProductImage(
      XFile imageFile, String productId) async {
    try {
      developer.log('ImageService: Ürün resmi yükleme başlatıldı',
          name: 'ImageService');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Dosya yolu oluştur
      final String fileName =
          'product_${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'products/${user.uid}/$fileName';

      developer.log('ImageService: Dosya yolu: $filePath',
          name: 'ImageService');

      // Storage referansı oluştur
      final Reference ref = _storage.ref().child(filePath);

      // Dosyayı yükle
      UploadTask uploadTask;

      if (kIsWeb) {
        // Web için
        final Uint8List imageData = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          imageData,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'productId': productId,
              'uploadedBy': user.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        // Mobil için
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'productId': productId,
              'uploadedBy': user.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      }

      // Yükleme ilerlemesini takip et
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        developer.log(
            'ImageService: Yükleme ilerlemesi: ${progress.toStringAsFixed(2)}%',
            name: 'ImageService');
      });

      // Yükleme tamamlanmasını bekle
      final TaskSnapshot snapshot = await uploadTask;

      // Download URL'i al
      final String downloadURL = await snapshot.ref.getDownloadURL();

      developer.log('ImageService: Resim başarıyla yüklendi: $downloadURL',
          name: 'ImageService');
      return downloadURL;
    } catch (e, stackTrace) {
      developer.log('ImageService: Resim yüklenirken hata oluştu',
          name: 'ImageService', error: e, stackTrace: stackTrace, level: 1000);
      throw Exception('Resim yüklenirken hata oluştu: $e');
    }
  }

  // Resmi sil
  static Future<void> deleteImage(String imageUrl) async {
    try {
      developer.log('ImageService: Resim silme işlemi başlatıldı: $imageUrl',
          name: 'ImageService');

      // URL'den storage referansını al
      final Reference ref = _storage.refFromURL(imageUrl);

      // Resmi sil
      await ref.delete();

      developer.log('ImageService: Resim başarıyla silindi',
          name: 'ImageService');
    } catch (e, stackTrace) {
      developer.log('ImageService: Resim silinirken hata oluştu',
          name: 'ImageService', error: e, stackTrace: stackTrace, level: 1000);
      throw Exception('Resim silinirken hata oluştu: $e');
    }
  }

  // Kullanıcının tüm ürün resimlerini sil
  static Future<void> deleteUserProductImages() async {
    try {
      developer.log('ImageService: Kullanıcı ürün resimleri siliniyor',
          name: 'ImageService');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Kullanıcının products klasörünü al
      final Reference userProductsRef =
          _storage.ref().child('products/${user.uid}');

      // Tüm dosyaları listele
      final ListResult result = await userProductsRef.listAll();

      // Her dosyayı sil
      for (Reference fileRef in result.items) {
        await fileRef.delete();
        developer.log('ImageService: Dosya silindi: ${fileRef.fullPath}',
            name: 'ImageService');
      }

      developer.log('ImageService: Tüm kullanıcı ürün resimleri silindi',
          name: 'ImageService');
    } catch (e, stackTrace) {
      developer.log('ImageService: Kullanıcı resimleri silinirken hata oluştu',
          name: 'ImageService', error: e, stackTrace: stackTrace, level: 1000);
      throw Exception('Resimler silinirken hata oluştu: $e');
    }
  }

  // Resim boyutunu kontrol et
  static Future<bool> validateImageSize(XFile imageFile,
      {int maxSizeInMB = 5}) async {
    try {
      final int fileSizeInBytes = await imageFile.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      developer.log(
          'ImageService: Resim boyutu: ${fileSizeInMB.toStringAsFixed(2)} MB',
          name: 'ImageService');

      return fileSizeInMB <= maxSizeInMB;
    } catch (e) {
      developer.log('ImageService: Resim boyutu kontrol edilirken hata: $e',
          name: 'ImageService', level: 1000);
      return false;
    }
  }

  // Resim formatını kontrol et
  static bool validateImageFormat(XFile imageFile) {
    if (kIsWeb) {
      // Web platformunda MIME type kontrolü yap
      final String? mimeType = imageFile.mimeType;
      developer.log('ImageService: Web MIME type: $mimeType',
          name: 'ImageService');

      if (mimeType != null) {
        final List<String> allowedMimeTypes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/webp'
        ];

        final bool isValid = allowedMimeTypes.contains(mimeType.toLowerCase());
        developer.log(
            'ImageService: Web MIME type ($mimeType) geçerli: $isValid',
            name: 'ImageService');
        return isValid;
      }

      // MIME type yoksa dosya adından kontrol et (fallback)
      final String fileName = imageFile.name.toLowerCase();
      developer.log('ImageService: Web dosya adı: $fileName',
          name: 'ImageService');

      final List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      for (String ext in allowedExtensions) {
        if (fileName.endsWith('.$ext')) {
          developer.log('ImageService: Web dosya uzantısı ($ext) geçerli: true',
              name: 'ImageService');
          return true;
        }
      }

      developer.log('ImageService: Web dosya formatı geçersiz',
          name: 'ImageService');
      return false;
    } else {
      // Mobil platformlar için mevcut kod
      final String extension = imageFile.path.toLowerCase().split('.').last;
      final List<String> allowedFormats = ['jpg', 'jpeg', 'png', 'webp'];

      final bool isValid = allowedFormats.contains(extension);
      developer.log(
          'ImageService: Mobil resim formatı ($extension) geçerli: $isValid',
          name: 'ImageService');

      return isValid;
    }
  }

  // Resim önizlemesi için geçici URL oluştur
  static Future<String> getImagePreviewUrl(XFile imageFile) async {
    try {
      if (kIsWeb) {
        // Web için blob URL oluştur
        final Uint8List bytes = await imageFile.readAsBytes();
        // Web'de blob URL oluşturmak için platform-specific kod gerekir
        // Şimdilik dosya path'ini döndür
        return imageFile.path;
      } else {
        // Mobil için dosya path'ini döndür
        return imageFile.path;
      }
    } catch (e) {
      developer.log('ImageService: Önizleme URL oluşturulurken hata: $e',
          name: 'ImageService', level: 1000);
      return '';
    }
  }
}
