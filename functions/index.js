/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest, onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {onDocumentUpdated, onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Firebase Admin SDK'yı initialize et
admin.initializeApp();

// Flutter OrderStatus enum mapping (int to string)
const orderStatusMapping = {
  0: 'waiting',
  1: 'processing', 
  2: 'completed',
  3: 'cancelled'
};

// Türkçe durum çevirileri (müşteriye gönderilen)
// NOT: 'waiting' durumu için bildirim gönderilmez (müşteri zaten sipariş vermiş)
const statusTranslations = {
  'processing': {
    title: '👨‍🍳 Hazırlanıyor',
    body: 'Siparişiniz hazırlanmaya başlanmıştır'
  },
  'completed': {
    title: '✅ Tamamlandı',
    body: 'Siparişiniz tamamlandı. Afiyet olsun!'
  },
  'cancelled': {
    title: '❌ Sipariş İptal Edildi',
    body: 'Siparişiniz iptal edildi. Detaylar için uygulamayı kontrol edin'
  }
};

// Yeni sipariş oluşturulduğunda üreticiye bildirim gönderen function
exports.sendNewOrderNotification = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    try {
      logger.info("🆕 Yeni sipariş oluşturuldu!");
      
      const orderData = event.data.data();
      logger.info("📋 Sipariş data:", orderData);
      
      const orderId = event.params.orderId;
      const producerCompanyId = orderData.producerCompanyId;
      const customerName = orderData.customer?.name || 'Bilinmeyen müşteri';
      
      logger.info(`OrderID: ${orderId}`);
      logger.info(`ProducerCompanyID: ${producerCompanyId}`);
      logger.info(`Customer: ${customerName}`);
      
      if (!producerCompanyId) {
        logger.warn("⚠️ ProducerCompanyId bulunamadı");
        return;
      }
      
      // Üretici firma kullanıcılarını bul
      const producerQuery = await admin.firestore()
        .collection('users')
        .where('companyId', '==', producerCompanyId)
        .where('role', '==', 'producer')
        .get();
        
      if (producerQuery.empty) {
        logger.warn(`⚠️ Üretici bulunamadı: ${producerCompanyId}`);
        return;
      }
      
      const producerTokens = [];
      producerQuery.forEach(doc => {
        const producerData = doc.data();
        if (producerData.fcmToken) {
          producerTokens.push(producerData.fcmToken);
        }
      });
      
      if (producerTokens.length === 0) {
        logger.warn("⚠️ Üretici FCM token bulunamadı");
        return;
      }
      
      logger.info(`👨‍🏭 ${producerTokens.length} üreticiye bildirim gönderiliyor`);
      
      const message = {
        tokens: producerTokens,
        notification: {
          title: '🆕 Yeni Sipariş!',
          body: `${customerName} tarafından sipariş alındı, hazırlanmayı bekliyor`
        },
        data: {
          orderId: orderId,
          type: 'new_order',
          customerName: customerName,
          companyId: producerCompanyId
        },
        android: {
          notification: {
            channelId: 'order_updates',
            priority: 'high',
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };
      
      // Bildirimi gönder
      logger.info("📤 Üreticilere bildirim gönderiliyor...");
      const result = await admin.messaging().sendEachForMulticast(message);
      logger.info(`✅ Üreticilere bildirim gönderildi - Success: ${result.successCount}, Failure: ${result.failureCount}`);
      
    } catch (error) {
      logger.error("Yeni sipariş bildirim hatası:", error);
    }
  }
);

// Sipariş durumu değiştiğinde tetiklenen function
exports.sendOrderStatusNotification = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    try {
      logger.info("🔥 Function tetiklendi!");
      
      const oldData = event.data.before.data();
      const newData = event.data.after.data();
      
      logger.info("📋 Eski data:", oldData);
      logger.info("📋 Yeni data:", newData);
      
      // Durum değişimi kontrolü
      if (oldData.status === newData.status) {
        logger.info("Sipariş durumu değişmedi, bildirim gönderilmeyecek");
        return;
      }

      logger.info(`Sipariş durumu değişti: ${oldData.status} -> ${newData.status}`);

      const orderId = event.params.orderId;
      const customerId = newData.customerId;
      const newStatusInt = newData.status;
      const newStatus = orderStatusMapping[newStatusInt];
      
      logger.info(`OrderID: ${orderId}`);
      logger.info(`CustomerID: ${customerId}`);
      logger.info(`NewStatus: ${newStatusInt} -> ${newStatus}`);
      
      if (!newStatus) {
        logger.warn(`Bilinmeyen durum kodu: ${newStatusInt}`);
        return;
      }
      
      // Waiting durumu için müşteriye bildirim gönderme (zaten sipariş vermiş)
      if (newStatus === 'waiting') {
        logger.info("Waiting durumu - müşteriye bildirim gönderilmeyecek");
        return;
      }

      // Müşteri bilgilerini al
      logger.info(`🔍 Müşteri aranıyor: ${customerId}`);
      
      const customerDoc = await admin.firestore()
        .collection('users')
        .doc(customerId)
        .get();

      if (!customerDoc.exists) {
        logger.error(`❌ Müşteri bulunamadı: ${customerId}`);
        return;
      }

      const customerData = customerDoc.data();
      logger.info("👤 Müşteri data:", customerData);
      
      const fcmToken = customerData.fcmToken;
      logger.info(`📱 FCM Token: ${fcmToken}`);

      if (!fcmToken) {
        logger.warn(`⚠️ Müşterinin FCM token'ı yok: ${customerId}`);
        return;
      }

      // Bildirim mesajını hazırla
      const statusInfo = statusTranslations[newStatus];
      if (!statusInfo) {
        logger.warn(`Bilinmeyen durum: ${newStatusInt} (${newStatus})`);
        return;
      }
      
      logger.info(`📝 Bildirim hazırlanıyor: ${statusInfo.title}`);

      const message = {
        token: fcmToken,
        notification: {
          title: statusInfo.title,
          body: `${statusInfo.body} (Sipariş #${orderId.substring(0, 8)})`
        },
        data: {
          orderId: orderId,
          status: newStatus,
          type: 'order_status_update',
          customerId: customerId
        },
        android: {
          notification: {
            channelId: 'order_updates',
            priority: 'high',
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      // Bildirimi gönder
      logger.info("📤 Müşteriye bildirim gönderiliyor...");
      const result = await admin.messaging().send(message);
      logger.info(`✅ Müşteriye bildirim başarıyla gönderildi: ${result}`);
      logger.info(`📊 Summary: ${customerId} - ${newStatus}`);

    } catch (error) {
      logger.error("Bildirim gönderme hatası:", error);
    }
  }
);



// Manuel bildirim gönderme endpoint'i (test için)
exports.sendTestNotification = onCall(async (request) => {
  try {
    const {userId, title, body} = request.data;

    if (!userId || !title || !body) {
      throw new Error("userId, title ve body gerekli");
    }

    // Kullanıcı FCM token'ını al
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new Error("Kullanıcı bulunamadı");
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new Error("Kullanıcının FCM token'ı yok");
    }

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body
      },
      data: {
        type: 'test_notification'
      }
    };

    await admin.messaging().send(message);
    
    return {
      success: true,
      message: "Test bildirimi başarıyla gönderildi"
    };

  } catch (error) {
    logger.error("Test bildirim hatası:", error);
    throw new Error(`Bildirim gönderilemedi: ${error.message}`);
  }
});

// Toplu bildirim gönderme (promosyonlar için)
exports.sendBulkNotification = onCall(async (request) => {
  try {
    const {title, body, userRole = 'customer'} = request.data;

    if (!title || !body) {
      throw new Error("title ve body gerekli");
    }

    // Belirtilen role sahip kullanıcıları al
    const usersQuery = await admin.firestore()
      .collection('users')
      .where('role', '==', userRole)
      .get();

    if (usersQuery.empty) {
      throw new Error(`${userRole} rolünde kullanıcı bulunamadı`);
    }

    const tokens = [];
    usersQuery.forEach(doc => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length === 0) {
      throw new Error("FCM token'ı olan kullanıcı bulunamadı");
    }

    // Batch halinde gönder (500'er token)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      
      const message = {
        tokens: batch,
        notification: {
          title: title,
          body: body
        },
        data: {
          type: 'bulk_notification'
        }
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;
    }

    return {
      success: true,
      message: `Toplu bildirim gönderildi`,
      successCount: successCount,
      failureCount: failureCount,
      totalTokens: tokens.length
    };

  } catch (error) {
    logger.error("Toplu bildirim hatası:", error);
    throw new Error(`Toplu bildirim gönderilemedi: ${error.message}`);
  }
});
