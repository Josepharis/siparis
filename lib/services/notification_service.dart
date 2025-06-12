import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Bildirim kanalı ayarları
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel', // id
    'Yüksek Öncelikli Bildirimler', // name
    description: 'Sipariş ve stok bildirimleri için kanal',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Bildirim servisini başlat
  static Future<void> initialize() async {
    print('🔔 Bildirim servisi başlatılıyor...');

    try {
      // Bildirim izni iste
      await _requestPermissions();

      // Firebase Messaging başlat
      await _initializeFirebaseMessaging();

      // Local notifications başlat
      await _initializeLocalNotifications();

      // Bildirim dinleyicilerini kur
      await _setupListeners();

      // FCM token al
      await _getAndSaveToken();

      print('✅ Bildirim servisi başarıyla başlatıldı');
    } catch (e) {
      print('❌ Bildirim servisi başlatma hatası: $e');
    }
  }

  // Bildirim izinlerini iste
  static Future<void> _requestPermissions() async {
    print('📋 Bildirim izinleri isteniyor...');

    // Firebase Messaging izni
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 Firebase bildirim izni: ${settings.authorizationStatus}');
  }

  // Firebase Messaging'i başlat
  static Future<void> _initializeFirebaseMessaging() async {
    print('🔥 Firebase Messaging başlatılıyor...');

    // Background message handler'ı ayarla
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Local notifications'ı başlat
  static Future<void> _initializeLocalNotifications() async {
    print('📱 Local notifications başlatılıyor...');

    // Android ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // İOS ayarları
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Başlatma ayarları
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Local notifications'ı başlat
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android bildirim kanalını oluştur
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  // Bildirim dinleyicilerini kur
  static Future<void> _setupListeners() async {
    print('👂 Bildirim dinleyicileri kuruluyor...');

    // Uygulama ön plandayken gelen bildirimler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklayarak uygulama açıldığında
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Uygulama tamamen kapalıyken bildirime tıklandığında
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  // FCM token al ve kaydet
  static Future<String?> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      print('🔑 FCM Token: $token');

      // Token'ı Firestore'da kullanıcı kaydına kaydet
      await _saveTokenToFirestore(token);

      return token;
    } catch (e) {
      print('❌ FCM token alma hatası: $e');
      return null;
    }
  }

  // Token'ı Firestore'a kaydet
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    try {
      // Firebase Auth'dan current user'ı al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ Kullanıcı giriş yapmamış, token kaydedilemiyor');
        return;
      }

      // Firestore'da kullanıcı dokümanını güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token veritabanına kaydedildi');
    } catch (e) {
      print('❌ FCM token kaydetme hatası: $e');
    }
  }

  // Ön planda gelen bildirimi işle
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Ön planda bildirim alındı: ${message.messageId}');
    print('📋 Başlık: ${message.notification?.title}');
    print('📝 İçerik: ${message.notification?.body}');
    print('📊 Data: ${message.data}');

    // Local notification göster
    await _showLocalNotification(message);
  }

  // Bildirime tıklanma işlemi
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Bildirime tıklandı: ${message.messageId}');
    print('📊 Data: ${message.data}');

    // Bildirim data'sına göre sayfa yönlendirmesi yapılabilir
    if (message.data['type'] == 'order') {
      // Sipariş sayfasına git
      print('🛒 Sipariş sayfasına yönlendiriliyor...');
    } else if (message.data['type'] == 'stock') {
      // Stok sayfasına git
      print('📦 Stok sayfasına yönlendiriliyor...');
    }
  }

  // Local notification göster
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
            ),
          ),
        ),
        payload: jsonEncode(message.data),
      );

      print('✅ Local notification gösterildi');
    } catch (e) {
      print('❌ Local notification gösterme hatası: $e');
    }
  }

  // Local notification'a tıklanma
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tıklandı');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        print('📊 Payload data: $data');

        // Data'ya göre yönlendirme yapılabilir
      } catch (e) {
        print('❌ Payload parse hatası: $e');
      }
    }
  }

  // Belirli bir konuya abone ol
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ $topic konusuna abone olundu');
    } catch (e) {
      print('❌ $topic konusuna abone olma hatası: $e');
    }
  }

  // Konudan aboneliği kaldır
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ $topic konusundan abonelik kaldırıldı');
    } catch (e) {
      print('❌ $topic konusundan abonelik kaldırma hatası: $e');
    }
  }

  // FCM token'ı al
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Token alma hatası: $e');
      return null;
    }
  }

  // Token yenilenme dinleyicisi
  static void listenToTokenRefresh(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen(onTokenRefresh);
  }

  // Sipariş bildirimi gönder
  static Future<void> sendOrderNotification({
    required String targetUserId,
    required String orderId,
    required String title,
    required String body,
    required String orderStatus,
  }) async {
    try {
      // Hedef kullanıcının FCM token'ını al
      final tokenDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      final userData = tokenDoc.data();
      if (userData == null || userData['fcmToken'] == null) {
        print('⚠️ Kullanıcının FCM token\'ı bulunamadı: $targetUserId');
        return;
      }

      final fcmToken = userData['fcmToken'] as String;

      // Bildirim verilerini hazırla
      final data = {
        'type': 'order',
        'orderId': orderId,
        'status': orderStatus,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      print('📤 Sipariş bildirimi gönderiliyor:');
      print('  - Hedef: $targetUserId');
      print('  - Sipariş: $orderId');
      print('  - Durum: $orderStatus');
      print('  - Token: ${fcmToken.substring(0, 20)}...');

      // FCM ile bildirim gönder (Bu kısım backend'de yapılmalı)
      // Şimdilik sadece log olarak gösterelim
      print('✅ Sipariş bildirimi hazırlandı');
    } catch (e) {
      print('❌ Sipariş bildirimi gönderme hatası: $e');
    }
  }

  // Müşteriye sipariş durumu bildirimi
  static Future<void> notifyCustomerOrderUpdate({
    required String customerId,
    required String orderId,
    required String newStatus,
    required String companyName,
  }) async {
    String title, body;

    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        title = '✅ Sipariş Onaylandı';
        body =
            '$companyName siparişinizi onayladı. Hazırlık aşamasına geçiliyor.';
        break;
      case 'preparing':
        title = '👨‍🍳 Sipariş Hazırlanıyor';
        body =
            '$companyName siparişinizi hazırlıyor. Yakında teslime hazır olacak.';
        break;
      case 'ready':
        title = '🎉 Sipariş Hazır!';
        body = '$companyName siparişiniz hazır! Teslimat için bekliyor.';
        break;
      case 'completed':
        title = '✨ Sipariş Tamamlandı';
        body =
            '$companyName siparişiniz başarıyla teslim edildi. Teşekkür ederiz!';
        break;
      case 'cancelled':
        title = '❌ Sipariş İptal Edildi';
        body =
            '$companyName siparişiniz iptal edildi. Detaylar için uygulamayı kontrol edin.';
        break;
      default:
        title = '📋 Sipariş Güncellendi';
        body = '$companyName siparişinizde güncelleme var.';
    }

    await sendOrderNotification(
      targetUserId: customerId,
      orderId: orderId,
      title: title,
      body: body,
      orderStatus: newStatus,
    );
  }

  // Üreticiye yeni sipariş bildirimi
  static Future<void> notifyProducerNewOrder({
    required String producerId,
    required String orderId,
    required String customerName,
    required double totalAmount,
  }) async {
    await sendOrderNotification(
      targetUserId: producerId,
      orderId: orderId,
      title: '🛒 Yeni Sipariş!',
      body:
          '$customerName\'den ₺${totalAmount.toStringAsFixed(2)} tutarında yeni sipariş geldi.',
      orderStatus: 'pending',
    );
  }

  // Topic tabanlı bildirim gönder
  static Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      print('📢 Topic bildirimi gönderiliyor: $topic');
      print('  - Başlık: $title');
      print('  - İçerik: $body');

      // Bu kısım backend'de FCM Admin SDK ile yapılmalı
      // Şimdilik log olarak gösterelim
      print('✅ Topic bildirimi hazırlandı');
    } catch (e) {
      print('❌ Topic bildirimi gönderme hatası: $e');
    }
  }

  // Ödeme hatırlatması gönder (Firestore trigger ile - diğerleri gibi)
  static Future<Map<String, dynamic>?> sendPaymentReminder({
    required String companyId,
    required String title,
    required String body,
    double? pendingAmount,
  }) async {
    try {
      print('💳 Ödeme hatırlatması başlatılıyor: $companyId');
      print('  - Başlık: $title');
      print('  - İçerik: $body');
      print('  - Tutar: ₺${pendingAmount?.toStringAsFixed(2) ?? '0.00'}');

      // Firestore'a payment_reminder dokümanı ekle (diğer bildirimler gibi)
      final reminderDoc =
          await FirebaseFirestore.instance.collection('payment_reminders').add({
        'companyId': companyId,
        'title': title,
        'body': body,
        'pendingAmount': pendingAmount,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      print('✅ Ödeme hatırlatması kaydı oluşturuldu: ${reminderDoc.id}');
      print('🔄 Firebase Function otomatik olarak tetiklenecek...');

      // Başarılı sonuç döndür (gerçek sonuç Firebase Function'dan gelecek)
      return {
        'success': true,
        'message': 'Ödeme hatırlatması başlatıldı',
        'reminderId': reminderDoc.id,
        'successCount': 1, // UI için mock değer
        'failureCount': 0,
        'totalTokens': 1
      };
    } catch (e) {
      print('❌ Ödeme hatırlatması Firestore hatası: $e');
      rethrow;
    }
  }
}

// Background message handler (global function olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background bildirim alındı: ${message.messageId}');
  print('📋 Başlık: ${message.notification?.title}');
  print('📝 İçerik: ${message.notification?.body}');
  print('📊 Data: ${message.data}');
}
