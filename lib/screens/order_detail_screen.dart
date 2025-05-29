import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:siparis/providers/company_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Sipariş durumuna göre renk ve ikon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (order.status) {
      case OrderStatus.waiting:
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = 'Bekliyor';
        break;
      case OrderStatus.processing:
        statusColor = Colors.orange;
        statusIcon = Icons.sync_rounded;
        statusText = 'Hazırlanıyor';
        break;
      case OrderStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        statusText = 'Tamamlandı';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = 'Bilinmiyor';
    }

    // Kullanıcının rolünü kontrol et
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isCustomer = currentUser?.role == 'customer';

    // ✅ Üretici firma adını çıkar (ana sayfadaki mantık)
    String producerCompanyName = 'Bilinmeyen Firma';

    // Önce yeni producerCompanyName alanını kontrol et
    if (order.producerCompanyName != null &&
        order.producerCompanyName!.isNotEmpty) {
      producerCompanyName = order.producerCompanyName!;
    } else if (order.customer.name.contains('→')) {
      producerCompanyName = order.customer.name.split('→').last.trim();
    } else if (order.note != null &&
        order.note!.contains('🏭 Üretici Firma:')) {
      // Note'tan üretici firma adını çıkarmaya çalış
      final noteLines = order.note!.split('\n');
      for (final line in noteLines) {
        if (line.contains('🏭 Üretici Firma:')) {
          producerCompanyName = line.split('🏭 Üretici Firma:').last.trim();
          break;
        }
      }
    }

    // Debug: Firma adı çıkarma işlemini kontrol et
    print('🔍 OrderDetailScreen Debug:');
    print('   Üretici firma adı (model): ${order.producerCompanyName}');
    print('   Çıkarılan firma: $producerCompanyName');
    print('   Not: ${order.note}');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst başlık bölümü
            _buildHeader(context, statusColor, statusText, statusIcon,
                isCustomer, producerCompanyName),

            // İçerik
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  // Sipariş Zaman Çizelgesi
                  _buildOrderTimeline(context, statusColor),

                  // Sipariş İçeriği (Üstte)
                  _buildOrderItems(context),

                  // ✅ Müşteri ise üretici bilgilerini, üretici ise müşteri bilgilerini göster
                  if (isCustomer)
                    _buildProducerCard(
                        context, statusColor, producerCompanyName)
                  else
                    _buildCustomerCard(context, statusColor),

                  // Teslimat Detayları (müşteri tercihi dahil)
                  _buildDeliveryInfoCard(context, statusColor),

                  const SizedBox(height: 100), // Alt boşluk
                ],
              ),
            ),
          ],
        ),
      ),
      // ✅ Müşteri ise bottom bar gösterme
      bottomSheet: !isCustomer ? _buildBottomBar(context, statusColor) : null,
    );
  }

  // Üst başlık bölümü
  Widget _buildHeader(
    BuildContext context,
    Color statusColor,
    String statusText,
    IconData statusIcon,
    bool isCustomer,
    String producerCompanyName,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık ve Geri Butonu
          Row(
            children: [
              // Geri butonu
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Başlık
              const Expanded(
                child: Text(
                  'Sipariş Detayı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Durum etiketi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sipariş ve firma bilgileri (müşteri/üretici göre farklı)
          Row(
            children: [
              // ✅ Avatar - müşteri ise üreticiyi, üretici ise müşteriyi göster
              Hero(
                tag: 'order_card_avatar_${order.id}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    isCustomer
                        ? (producerCompanyName.isNotEmpty
                            ? producerCompanyName[0].toUpperCase()
                            : 'Ü')
                        : (order.customer.name
                                .replaceFirst('Müşteri → ', '')
                                .isNotEmpty
                            ? order.customer.name
                                .replaceFirst('Müşteri → ', '')[0]
                                .toUpperCase()
                            : '?'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Firma bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Firma adı - müşteri ise üreticiyi, üretici ise müşteriyi göster
                    Hero(
                      tag: 'order_card_name_${order.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCustomer
                                  ? producerCompanyName
                                  : order.customer.name
                                      .replaceFirst('Müşteri → ', ''),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // ✅ Alt bilgi - müşteri ise üretici, üretici ise müşteri telefonu
                            const SizedBox(height: 2),
                            Text(
                              isCustomer
                                  ? 'Üretici Firma'
                                  : (order.customer.phoneNumber ??
                                      'Telefon bilgisi yok'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Sipariş tarihi
                    Row(
                      children: [
                        Icon(
                          Icons.event_note_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sipariş: ${DateFormat('d MMM yyyy', 'tr_TR').format(order.orderDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('HH:mm', 'tr_TR').format(order.orderDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sipariş zaman çizelgesi
  Widget _buildOrderTimeline(BuildContext context, Color statusColor) {
    final isCompleted = order.status == OrderStatus.completed;
    final isProcessing = order.status == OrderStatus.processing || isCompleted;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sipariş alındı
          Expanded(
            child: _buildTimelineItem(
              title: 'Sipariş Alındı',
              date: DateFormat('d MMM', 'tr_TR').format(order.orderDate),
              time: DateFormat('HH:mm', 'tr_TR').format(order.orderDate),
              isCompleted: true,
              color: Colors.amber,
              icon: Icons.receipt_rounded,
            ),
          ),

          // Çizgi
          _buildConnector(isActive: isProcessing),

          // Hazırlanıyor
          Expanded(
            child: _buildTimelineItem(
              title: 'Hazırlanıyor',
              date: isProcessing ? 'Üretimde' : '-',
              time: isProcessing ? 'Aktif' : '-',
              isCompleted: isProcessing,
              color: Colors.orange,
              icon: Icons.sync_rounded,
            ),
          ),

          // Çizgi
          _buildConnector(isActive: isCompleted),

          // Teslim edildi
          Expanded(
            child: _buildTimelineItem(
              title: 'Teslim Edildi',
              date: isCompleted
                  ? DateFormat('d MMM', 'tr_TR').format(order.deliveryDate)
                  : '-',
              time: isCompleted ? 'Tamamlandı' : '-',
              isCompleted: isCompleted,
              color: Colors.green,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // Zaman çizelgesi bağlantı çizgisi
  Widget _buildConnector({required bool isActive}) {
    return SizedBox(
      width: 20,
      child: Column(
        children: [
          Container(
            height: 3,
            color: isActive ? Colors.green : Colors.grey[300],
          ),
        ],
      ),
    );
  }

  // Zaman çizelgesi öğesi
  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String time,
    required bool isCompleted,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        // İkon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? color : Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey[400],
            size: 18,
          ),
        ),

        const SizedBox(height: 8),

        // Başlık
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isCompleted ? Colors.black87 : Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 4),

        // Tarih/saat
        if (date != '-')
          Text(
            date,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCompleted ? Colors.grey[700] : Colors.grey[400],
              fontSize: 12,
            ),
          ),

        if (time != '-')
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCompleted ? Colors.grey[700] : Colors.grey[400],
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  // Müşteri bilgi kartı
  Widget _buildCustomerCard(BuildContext context, Color statusColor) {
    // Müşteri telefon numarasını al ve temizle
    String? customerPhone = order.customer.phoneNumber;
    if (customerPhone != null && customerPhone.isNotEmpty) {
      customerPhone = _formatPhoneNumber(customerPhone);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.person_rounded, size: 18, color: statusColor),
              const SizedBox(width: 8),
              const Text(
                'Müşteri Bilgileri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const Divider(height: 24),

          // Müşteri Adı
          _buildInfoRow(
            icon: Icons.business_rounded,
            title: 'Firma Adı',
            value: order.customer.name,
            color: statusColor,
          ),

          // İletişim Bilgileri
          if (customerPhone != null && customerPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.phone_rounded,
              title: 'Telefon',
              value: customerPhone,
              color: Colors.blue,
            ),
          ],

          if (order.customer.email != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.email_rounded,
              title: 'E-posta',
              value: order.customer.email!,
              color: Colors.purple,
            ),
          ],

          if (order.customer.address != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              title: 'Adres',
              value: order.customer.address!,
              color: Colors.orange,
            ),
          ],

          // ✅ Arama ve WhatsApp butonları (telefon varsa)
          if (customerPhone != null && customerPhone.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Arama butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(customerPhone!),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text(
                      'WP Ara',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Mesaj butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendWhatsAppMessage(customerPhone!),
                    icon: const Icon(Icons.message_rounded, size: 18),
                    label: const Text(
                      'Mesaj',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Teslimat bilgileri kartı
  Widget _buildDeliveryInfoCard(BuildContext context, Color statusColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, size: 18, color: statusColor),
              const SizedBox(width: 8),
              const Text(
                'Teslimat Bilgileri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const Divider(height: 24),

          // ✅ Sadece Müşteri Tercihi
          if (order.requestedDate != null || order.requestedTime != null) ...[
            // Müşteri tercihi detayları
            Row(
              children: [
                // Tercih edilen tarih
                if (order.requestedDate != null)
                  Expanded(
                    child: _buildDeliveryInfoItem(
                      icon: Icons.calendar_today_rounded,
                      title: 'Tercih Edilen Tarih',
                      value: DateFormat('d MMMM yyyy', 'tr_TR')
                          .format(order.requestedDate!),
                      color: Colors.indigo,
                    ),
                  ),

                if (order.requestedDate != null && order.requestedTime != null)
                  const SizedBox(width: 16),

                // Tercih edilen saat
                if (order.requestedTime != null)
                  Expanded(
                    child: _buildDeliveryInfoItem(
                      icon: Icons.access_time_rounded,
                      title: 'Tercih Edilen Saat',
                      value:
                          '${order.requestedTime!.hour.toString().padLeft(2, '0')}:${order.requestedTime!.minute.toString().padLeft(2, '0')}',
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),

            // Bilgi notu
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu bilgiler müşterinin tercihi olup, kesin teslimat zamanı değildir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Müşteri tercihi yoksa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Müşteri herhangi bir teslimat tercihi belirtmemiştir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Bilgi satırı
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Teslimat bilgi öğesi
  Widget _buildDeliveryInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // Sipariş içerik listesi - Modernize edilmiş
  Widget _buildOrderItems(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sipariş İçeriği',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${order.items.length} Ürün',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ürün listesi
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: order.items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final item = order.items[index];
              final categoryColor = _getCategoryColor(item.product.category);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün ikonu
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.product.category),
                        color: categoryColor,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Ürün bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.quantity} adet',
                                style: TextStyle(
                                  color: categoryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Alt bilgiler: Kategori ve not
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item.product.category,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (item.note != null &&
                                  item.note!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Not: ${item.note!}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Fiyat ve toplam
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Birim: ₺${item.product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Toplam: ₺${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Toplam tutar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Ara toplam
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ara toplam:',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    Text(
                      '₺${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // İndirim (varsayılan olarak 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İndirim:',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    Text(
                      '₺0.00',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Genel toplam
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Toplam Tutar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₺${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Alt eylem çubuğu
  Widget _buildBottomBar(BuildContext context, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Geri düğmesi
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Durum güncelleme düğmesi
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showStatusDialog(context, statusColor);
                },
                icon: const Icon(Icons.update),
                label: const Text('Durumu Güncelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Durum güncelleme dialotu
  void _showStatusDialog(BuildContext context, Color statusColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sipariş Durumunu Güncelle'),
        content: const Text('Bu işlev yakında eklenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Kategori rengini döndürme
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Colors.pink[400]!;
      case 'hamur işleri':
        return Colors.amber[600]!;
      case 'kurabiyeler':
        return Colors.orange[400]!;
      case 'pastalar':
        return Colors.purple[400]!;
      default:
        return Colors.blue[400]!;
    }
  }

  // Kategori ikonunu döndürme
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.cake;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'kurabiyeler':
        return Icons.cookie;
      case 'pastalar':
        return Icons.cake_rounded;
      default:
        return Icons.fastfood;
    }
  }

  // Üretici bilgi kartı
  Widget _buildProducerCard(
      BuildContext context, Color statusColor, String producerCompanyName) {
    return Consumer<CompanyProvider>(
      builder: (context, companyProvider, child) {
        // Üretici firma telefon numarasını bul
        String? producerPhone;

        // Önce Firestore companies'den ara
        final firestoreCompany = companyProvider.firestoreCompanies
            .where((company) => company.name == producerCompanyName)
            .firstOrNull;

        if (firestoreCompany != null) {
          producerPhone = firestoreCompany.phone;
        } else {
          // Firestore'da bulunamazsa sample companies'den ara
          final sampleCompany = companyProvider.companies
              .where((company) => company.name == producerCompanyName)
              .firstOrNull;
          producerPhone = sampleCompany?.phone;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Icon(Icons.factory_rounded, size: 18, color: statusColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Üretici Bilgileri',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Üretici firma adı
              _buildInfoRow(
                icon: Icons.business_rounded,
                title: 'Firma Adı',
                value: producerCompanyName,
                color: Colors.blue,
              ),

              // Telefon numarası (varsa)
              if (producerPhone != null && producerPhone.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.phone_rounded,
                  title: 'Telefon',
                  value: producerPhone,
                  color: Colors.green,
                ),
              ],

              // Üretici ID (varsa)
              if (order.producerCompanyId != null &&
                  order.producerCompanyId!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.tag_rounded,
                  title: 'Firma ID',
                  value: order.producerCompanyId!,
                  color: Colors.purple,
                ),
              ],

              // ✅ Arama ve WhatsApp butonları (telefon varsa)
              if (producerPhone != null && producerPhone.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Arama butonu
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(producerPhone!),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text(
                          'WP Ara',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // WhatsApp butonu
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(context, producerPhone!),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text(
                          'Mesaj',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ✅ WhatsApp sesli arama metodu
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Telefon numarasını temizle (+90 gibi prefix'leri kaldır)
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Türkiye için +90 ekleme kontrolü
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '90${cleanedNumber.substring(1)}';
    } else if (!cleanedNumber.startsWith('90')) {
      cleanedNumber = '90$cleanedNumber';
    }

    // WhatsApp sesli arama URL'si
    final Uri whatsappCallUri = Uri.parse('https://wa.me/$cleanedNumber?call');

    try {
      if (await canLaunchUrl(whatsappCallUri)) {
        await launchUrl(whatsappCallUri, mode: LaunchMode.externalApplication);
      } else {
        // WhatsApp yüklü değilse tarayıcıda açmaya çalış
        await launchUrl(whatsappCallUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('WhatsApp sesli arama hatası: $e');
    }
  }

  // ✅ WhatsApp açma metodu
  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    // Telefon numarasını temizle (+90 gibi prefix'leri kaldır)
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Türkiye için +90 ekleme kontrolü
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '90${cleanedNumber.substring(1)}';
    } else if (!cleanedNumber.startsWith('90')) {
      cleanedNumber = '90$cleanedNumber';
    }

    final String message = 'Merhaba, sipariş konusunda bilgi almak istiyorum.';
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // WhatsApp yüklü değilse tarayıcıda açmaya çalış
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp açılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Müşteri telefon numarasını temizleme metodu
  String? _formatPhoneNumber(String phoneNumber) {
    // Telefon numarasını temizleme işlemleri
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Türkiye için +90 ekleme kontrolü
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '90${cleanedNumber.substring(1)}';
    } else if (!cleanedNumber.startsWith('90')) {
      cleanedNumber = '90$cleanedNumber';
    }

    return cleanedNumber;
  }

  // Müşteriye WhatsApp mesajı gönderme metodu
  Future<void> _sendWhatsAppMessage(String phoneNumber) async {
    // Telefon numarasını temizleme işlemleri
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Türkiye için +90 ekleme kontrolü
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '90${cleanedNumber.substring(1)}';
    } else if (!cleanedNumber.startsWith('90')) {
      cleanedNumber = '90$cleanedNumber';
    }

    final String message = 'Merhaba, sipariş konusunda bilgi almak istiyorum.';
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // WhatsApp yüklü değilse tarayıcıda açmaya çalış
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Context hatası için genel bir mesaj
      print('WhatsApp mesajı gönderilemedi: $e');
    }
  }
}
