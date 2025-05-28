import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:siparis/services/product_service.dart';
import 'package:siparis/services/image_service.dart';
import 'package:siparis/models/order.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _status = 'Başlatılıyor...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    developer.log(message, name: 'DebugScreen');
  }

  Future<void> _testFirebaseConnection() async {
    try {
      _addLog('Firebase bağlantısı test ediliyor...');

      // 1. Firebase Auth durumunu kontrol et
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _addLog('✅ Kullanıcı oturum açmış: ${user.uid}');
        _addLog('📧 Email: ${user.email}');
        _addLog('🔐 Email doğrulandı: ${user.emailVerified}');
      } else {
        _addLog('❌ Kullanıcı oturum açmamış');

        // Anonim giriş yapmayı dene
        try {
          _addLog('🔄 Anonim giriş deneniyor...');
          final userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          _addLog('✅ Anonim giriş başarılı: ${userCredential.user?.uid}');
        } catch (authError) {
          _addLog('❌ Anonim giriş başarısız: $authError');
          setState(() {
            _status = 'Auth hatası: $authError';
          });
          return;
        }
      }

      // 2. Firestore bağlantısını test et
      _addLog('Firestore bağlantısı test ediliyor...');
      final firestore = FirebaseFirestore.instance;

      // Önce okuma testi yap
      try {
        _addLog('🔄 Firestore okuma testi...');
        final testQuery = await firestore.collection('test').limit(1).get();
        _addLog(
            '✅ Firestore okuma testi başarılı (${testQuery.docs.length} belge)');
      } catch (readError) {
        _addLog('❌ Firestore okuma hatası: $readError');
      }

      // Sonra yazma testi yap
      try {
        _addLog('🔄 Firestore yazma testi...');
        await firestore.collection('test').doc('connection').set({
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Test bağlantısı',
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });
        _addLog('✅ Firestore yazma testi başarılı');
      } catch (writeError) {
        _addLog('❌ Firestore yazma hatası: $writeError');
      }

      // Test belgesini oku
      try {
        _addLog('🔄 Test belgesi okunuyor...');
        final doc = await firestore.collection('test').doc('connection').get();
        if (doc.exists) {
          _addLog('✅ Test belgesi başarıyla okundu');
          _addLog('📄 Belge verisi: ${doc.data()}');
        } else {
          _addLog('❌ Test belgesi bulunamadı');
        }
      } catch (docError) {
        _addLog('❌ Test belgesi okuma hatası: $docError');
      }

      // 3. Products koleksiyonunu test et
      try {
        _addLog('🔄 Products koleksiyonu test ediliyor...');
        final productsQuery =
            await firestore.collection('products').limit(1).get();
        _addLog(
            '✅ Products koleksiyonu erişilebilir (${productsQuery.docs.length} belge)');
      } catch (productsError) {
        _addLog('❌ Products koleksiyonu hatası: $productsError');
      }

      // 4. ProductService'i test et
      try {
        _addLog('🔄 ProductService test ediliyor...');
        final products = await ProductService.getUserProducts();
        _addLog(
            '✅ ProductService test başarılı: ${products.length} ürün bulundu');
      } catch (serviceError) {
        _addLog('❌ ProductService hatası: $serviceError');
      }

      // 5. Firebase Storage'ı test et
      try {
        _addLog('🔄 Firebase Storage test ediliyor...');
        final storage = FirebaseStorage.instance;

        // Storage referansı oluştur
        final testRef = storage.ref().child('test/connection_test.txt');

        // Test dosyası yükle
        await testRef.putString('Test bağlantısı ${DateTime.now()}');
        _addLog('✅ Firebase Storage yazma testi başarılı');

        // Test dosyasını oku
        final downloadUrl = await testRef.getDownloadURL();
        _addLog('✅ Firebase Storage okuma testi başarılı');
        _addLog('📄 Download URL: $downloadUrl');

        // Test dosyasını sil
        await testRef.delete();
        _addLog('✅ Firebase Storage silme testi başarılı');
      } catch (storageError) {
        _addLog('❌ Firebase Storage hatası: $storageError');
      }

      setState(() {
        _status = 'Testler tamamlandı!';
      });
    } catch (e, stackTrace) {
      _addLog('❌ Genel hata oluştu: $e');
      developer.log('DebugScreen: Test hatası',
          name: 'DebugScreen', error: e, stackTrace: stackTrace, level: 1000);
      setState(() {
        _status = 'Test başarısız: $e';
      });
    }
  }

  Future<void> _testProductAdd() async {
    try {
      _addLog('Test ürünü ekleniyor...');

      final testProduct = Product(
        name: 'Test Ürünü ${DateTime.now().millisecondsSinceEpoch}',
        price: 25.50,
        category: 'Tatlılar',
        description: 'Bu bir test ürünüdür',
        isActive: true,
      );

      final productId = await ProductService.addProduct(testProduct);
      _addLog('✅ Test ürünü başarıyla eklendi: $productId');

      // Ürünü hemen sil
      await ProductService.deleteProduct(productId);
      _addLog('✅ Test ürünü başarıyla silindi');
    } catch (e, stackTrace) {
      _addLog('❌ Test ürünü eklenirken hata: $e');
      developer.log('DebugScreen: Test ürünü hatası',
          name: 'DebugScreen', error: e, stackTrace: stackTrace, level: 1000);
    }
  }

  Future<void> _testImageUpload() async {
    try {
      _addLog('Resim yükleme testi başlatılıyor...');

      // Resim seç
      final XFile? image =
          await ImageService.pickImage(source: ImageSource.gallery);

      if (image == null) {
        _addLog('❌ Resim seçilmedi');
        return;
      }

      _addLog('✅ Resim seçildi: ${image.path}');
      _addLog('📱 Platform: ${kIsWeb ? "Web" : "Mobil"}');

      if (kIsWeb) {
        _addLog('🌐 Web MIME type: ${image.mimeType}');
        _addLog('📄 Web dosya adı: ${image.name}');
      }

      // Resim formatını kontrol et
      if (!ImageService.validateImageFormat(image)) {
        _addLog('❌ Geçersiz resim formatı');
        return;
      }

      _addLog('✅ Resim formatı geçerli');

      // Resim boyutunu kontrol et
      if (!await ImageService.validateImageSize(image)) {
        _addLog('❌ Resim boyutu çok büyük');
        return;
      }

      _addLog('✅ Resim boyutu uygun');

      // Test ürünü oluştur
      final testProduct = Product(
        name: 'Test Resim Ürünü ${DateTime.now().millisecondsSinceEpoch}',
        price: 99.99,
        category: 'Tatlılar',
        description: 'Resim yükleme testi için oluşturulan ürün',
        isActive: true,
      );

      // Ürünü ekle
      final productId = await ProductService.addProduct(testProduct);
      _addLog('✅ Test ürünü eklendi: $productId');

      // Resmi yükle
      final imageUrl = await ImageService.uploadProductImage(image, productId);
      _addLog('✅ Resim başarıyla yüklendi: $imageUrl');

      // Ürünü resim URL'i ile güncelle
      final updatedProduct = Product(
        id: productId,
        name: testProduct.name,
        price: testProduct.price,
        category: testProduct.category,
        description: testProduct.description,
        isActive: testProduct.isActive,
        imageUrl: imageUrl,
      );

      await ProductService.updateProduct(productId, updatedProduct);
      _addLog('✅ Ürün resim URL\'i ile güncellendi');

      // Test verilerini temizle
      await ProductService.deleteProduct(productId);
      _addLog('✅ Test ürünü silindi');

      await ImageService.deleteImage(imageUrl);
      _addLog('✅ Test resmi silindi');

      _addLog('🎉 Resim yükleme testi başarıyla tamamlandı!');
    } catch (e, stackTrace) {
      _addLog('❌ Resim yükleme testi hatası: $e');
      developer.log('DebugScreen: Resim yükleme test hatası',
          name: 'DebugScreen', error: e, stackTrace: stackTrace, level: 1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Bağlantı Durumu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _status.contains('başarılı')
                            ? Colors.green
                            : _status.contains('başarısız') ||
                                    _status.contains('Hata')
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testFirebaseConnection,
                    child: const Text('Bağlantıyı Yeniden Test Et'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testProductAdd,
                    child: const Text('Ürün Ekleme Testi'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Resim testi butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testImageUpload,
                icon: const Icon(Icons.image),
                label: const Text('Resim Yükleme Testi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log başlığı
            const Text(
              'Loglar:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Log listesi
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: log.contains('❌')
                              ? Colors.red
                              : log.contains('✅')
                                  ? Colors.green
                                  : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
