import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst başlık bölümü
            _buildHeader(context, statusColor, statusText, statusIcon),

            // İçerik
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  // Sipariş Zaman Çizelgesi
                  _buildOrderTimeline(context, statusColor),

                  // Sipariş İçeriği (Üstte)
                  _buildOrderItems(context),

                  // Müşteri Bilgileri (Altta)
                  _buildCustomerCard(context, statusColor),

                  // Teslimat Detayları (Altta)
                  _buildDeliveryInfoCard(context, statusColor),

                  const SizedBox(height: 100), // Alt boşluk
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(context, statusColor),
    );
  }

  // Üst başlık bölümü
  Widget _buildHeader(
    BuildContext context,
    Color statusColor,
    String statusText,
    IconData statusIcon,
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

          // Sipariş ve müşteri bilgileri
          Row(
            children: [
              // Müşteri avatarı
              Hero(
                tag: 'order_card_avatar_${order.id}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    order.customer.name.isNotEmpty
                        ? order.customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Müşteri ve sipariş bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Müşteri adı
                    Hero(
                      tag: 'order_card_name_${order.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          order.customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
              date:
                  isCompleted
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
            boxShadow:
                isCompleted
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

          // İletişim Bilgileri
          if (order.customer.phoneNumber != null)
            _buildInfoRow(
              icon: Icons.phone_rounded,
              title: 'Telefon',
              value: order.customer.phoneNumber!,
              color: Colors.blue,
            ),

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

          // Teslimat tarihi ve tutarı (iki yan yana)
          Row(
            children: [
              // Teslimat tarihi
              Expanded(
                child: _buildDeliveryInfoItem(
                  icon: Icons.calendar_today_rounded,
                  title: 'Teslimat Tarihi',
                  value: DateFormat(
                    'd MMMM yyyy',
                    'tr_TR',
                  ).format(order.deliveryDate),
                  color: Colors.indigo,
                ),
              ),

              const SizedBox(width: 16),

              // Sipariş tutarı
              Expanded(
                child: _buildDeliveryInfoItem(
                  icon: Icons.attach_money_rounded,
                  title: 'Toplam Tutar',
                  value: '₺${order.totalAmount.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
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
            separatorBuilder:
                (context, index) => Divider(
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
      builder:
          (context) => AlertDialog(
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
}
