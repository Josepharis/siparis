import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/screens/order_detail_screen.dart';

class OrderListItem extends StatelessWidget {
  final Order order;
  final Function(OrderStatus) onStatusChanged;
  final VoidCallback? onTap;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onStatusChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = Order.getStatusText(order.status);
    final formatter = DateFormat('HH:mm');
    final deliveryTime = formatter.format(order.deliveryDate);

    // Teslimat tarihinden kalan gün hesabı - DÜZELTME
    final now = DateTime.now();
    final deliveryDate = order.deliveryDate;

    // Sadece tarih kısmını karşılaştır (saat bilgisini yok say)
    final today = DateTime(now.year, now.month, now.day);
    final orderDeliveryDate =
        DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);

    final int daysLeft = orderDeliveryDate.difference(today).inDays;
    final String timeIndicator = daysLeft > 0
        ? '$daysLeft gün'
        : daysLeft == 0
            ? 'Bugün'
            : '${daysLeft.abs()} gün geçti';
    final bool isUrgent =
        daysLeft <= 1 && order.status != OrderStatus.completed;

    // Ana kart rengi belirleme
    final Color statusColor = _getStatusColor(order.status);

    // Durum renk paleti
    final List<Color> statusColors = _getStatusGradientColors(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst kısım: Statü barı ve müşteri bilgisi
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: statusColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Müşteri baş harfi
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            order.customer.name.isNotEmpty
                                ? order.customer.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Müşteri bilgisi
                      Expanded(
                        flex: 2,
                        child: Text(
                          order.customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Durum ve fiyat
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Fiyat alanı
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getPaymentStatusColor(
                                      order.paymentStatus,
                                    ).withOpacity(0.7),
                                    _getPaymentStatusColor(order.paymentStatus),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getPaymentStatusColor(
                                      order.paymentStatus,
                                    ).withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₺${order.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _getPaymentStatusIcon(order.paymentStatus),
                                    size: 10,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 4),

                            // Durum etiketi
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(order.status),
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        statusText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik alanı
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // Üst bölüm - Teslimat bilgisi ve durum değişimi butonları
                      Row(
                        children: [
                          // Teslimat bilgisi
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(
                                  isUrgent
                                      ? Icons.timer
                                      : Icons.event_available,
                                  size: 14,
                                  color: isUrgent
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700,
                                ),
                                Text(
                                  DateFormat(
                                    'd MMM',
                                    'tr_TR',
                                  ).format(order.deliveryDate),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  deliveryTime,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUrgent
                                        ? Colors.red.shade50
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: isUrgent
                                          ? Colors.red.shade200
                                          : Colors.blue.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    timeIndicator,
                                    style: TextStyle(
                                      color: isUrgent
                                          ? Colors.red.shade800
                                          : Colors.blue.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Durum değiştirme butonları - burada olacak sadece durumu hazır değilse
                          if (order.status != OrderStatus.completed &&
                              order.status != OrderStatus.cancelled)
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // İptal butonu
                                  Flexible(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.shade600
                                                .withOpacity(0.2),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showCancelDialog(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          minimumSize: const Size(0, 36),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: const Text(
                                            'İptal',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // İlerleme butonu
                                  Flexible(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (order.status ==
                                                        OrderStatus.waiting
                                                    ? Colors.orange.shade600
                                                    : Colors.green.shade600)
                                                .withOpacity(0.2),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () => onStatusChanged(
                                          order.status == OrderStatus.waiting
                                              ? OrderStatus.processing
                                              : OrderStatus.completed,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: order.status ==
                                                  OrderStatus.waiting
                                              ? Colors.orange.shade600
                                              : Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          minimumSize: const Size(0, 36),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            order.status == OrderStatus.waiting
                                                ? 'Hazırla'
                                                : 'Tamamla',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Sipariş içeriği detaylı
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ürünler (${order.items.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: order.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade800,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${item.quantity}x ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                        TextSpan(text: item.product.name),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Colors.blue.shade700;
      case OrderStatus.processing:
        return Colors.orange.shade700;
      case OrderStatus.completed:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  List<Color> _getStatusGradientColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return [
          const Color(0xFF3B82F6), // Ana mavi
          const Color(0xFF60A5FA), // Açık mavi
        ];
      case OrderStatus.processing:
        return [
          const Color(0xFFF59E0B), // Ana turuncu
          const Color(0xFFFBBF24), // Açık turuncu
        ];
      case OrderStatus.completed:
        return [
          const Color(0xFF10B981), // Ana yeşil
          const Color(0xFF34D399), // Açık yeşil
        ];
      case OrderStatus.cancelled:
        return [
          const Color(0xFFEF4444), // Ana kırmızı
          const Color(0xFFF87171), // Açık kırmızı
        ];
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.processing:
        return Icons.sync_rounded;
      case OrderStatus.completed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return const Color(0xFFEF4444); // Kırmızı
      case PaymentStatus.partial:
        return const Color(0xFFF59E0B); // Turuncu
      case PaymentStatus.paid:
        return const Color(0xFF10B981); // Yeşil
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.money_off_rounded;
      case PaymentStatus.partial:
        return Icons.payments_outlined;
      case PaymentStatus.paid:
        return Icons.check_circle_outline_rounded;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange.shade600,
          size: 48,
        ),
        title: const Text(
          'Sipariş İptal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu siparişi iptal etmek istediğinize emin misiniz?',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bu işlem geri alınamaz.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Vazgeç',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onStatusChanged(OrderStatus.cancelled);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Evet, İptal Et',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
