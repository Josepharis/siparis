import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(OrderStatus) onStatusChanged;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Durum bilgileri
    final statusText = Order.getStatusText(order.status);

    // Saat formatı ve bilgileri
    final timeFormat = DateFormat('HH:mm');
    final deliveryTime = timeFormat.format(order.deliveryDate);
    final dateFormat = DateFormat('d MMM', 'tr_TR');
    final deliveryDate = dateFormat.format(order.deliveryDate);

    // Teslimat tarihinden kalan gün hesabı
    final now = DateTime.now();
    final orderDeliveryDate = DateTime(order.deliveryDate.year,
        order.deliveryDate.month, order.deliveryDate.day);

    // Sadece tarih kısmını karşılaştır (saat bilgisini yok say)
    final today = DateTime(now.year, now.month, now.day);
    final int daysLeft = orderDeliveryDate.difference(today).inDays;
    final String timeIndicator = daysLeft > 0
        ? '$daysLeft gün'
        : daysLeft == 0
            ? 'Bugün'
            : '${daysLeft.abs()} gün geçti';
    final bool isUrgent =
        daysLeft <= 1 && order.status != OrderStatus.completed;

    // Durum renklerini belirle
    final mainColor = _getStatusColor(order.status);
    final secondaryColor = _getStatusSecondaryColor(order.status);

    // Arka plan gradyan renkleri
    final gradientColors = _getGradientColors(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst renk şeridi ve müşteri bilgisi
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Müşteri avatarı
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Text(
                          order.customer.name.isNotEmpty
                              ? order.customer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Müşteri adı
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            order.customer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Fiyat göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(
                            order.paymentStatus,
                          ).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
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
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Durum indikatörü
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(order.status),
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik alanı (beyaz kısım)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Durum değiştirme butonları
                      if (order.status != OrderStatus.completed &&
                          order.status != OrderStatus.cancelled)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // İptal butonu
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onStatusChanged(OrderStatus.cancelled),
                              icon: const Icon(Icons.cancel_outlined, size: 14),
                              label: const Text(
                                'İptal',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 26),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // İlerleme butonu
                            ElevatedButton.icon(
                              onPressed: () => onStatusChanged(
                                order.status == OrderStatus.waiting
                                    ? OrderStatus.processing
                                    : OrderStatus.completed,
                              ),
                              icon: Icon(
                                order.status == OrderStatus.waiting
                                    ? Icons.play_arrow_rounded
                                    : Icons.check_circle_outline,
                                size: 14,
                              ),
                              label: Text(
                                order.status == OrderStatus.waiting
                                    ? 'Hazırla'
                                    : 'Tamamla',
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    order.status == OrderStatus.waiting
                                        ? Colors.orange
                                        : Colors.green,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      // Teslimat bilgisi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red.shade50
                                  : mainColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isUrgent
                                  ? Icons.priority_high_rounded
                                  : Icons.event_rounded,
                              size: 18,
                              color: isUrgent ? Colors.redAccent : mainColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    deliveryDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    deliveryTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? Colors.red.shade50
                                      : mainColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isUrgent
                                        ? Colors.red.shade300
                                        : mainColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  timeIndicator,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUrgent ? Colors.red : mainColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Sipariş içeriği
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors.sublist(0, 2),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ürünler (${order.items.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: order.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mainColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: mainColor.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.quantity}x',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: mainColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.product.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '₺${(item.product.price * item.quantity).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
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
        return const Color(0xFF3B82F6); // Daha canlı mavi
      case OrderStatus.processing:
        return const Color(0xFFF59E0B); // Daha canlı turuncu
      case OrderStatus.completed:
        return const Color(0xFF10B981); // Daha canlı yeşil
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444); // Daha canlı kırmızı
    }
  }

  Color _getStatusSecondaryColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return const Color(0xFF60A5FA); // Mavi tonu
      case OrderStatus.processing:
        return const Color(0xFFFBBF24); // Turuncu tonu
      case OrderStatus.completed:
        return const Color(0xFF34D399); // Yeşil tonu
      case OrderStatus.cancelled:
        return const Color(0xFFF87171); // Kırmızı tonu
    }
  }

  List<Color> _getGradientColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return [
          const Color(0xFF3B82F6), // Ana mavi
          const Color(0xFF60A5FA), // Açık mavi
          const Color(0xFF93C5FD), // Daha açık mavi
        ];
      case OrderStatus.processing:
        return [
          const Color(0xFFF59E0B), // Ana turuncu
          const Color(0xFFFBBF24), // Açık turuncu
          const Color(0xFFFCD34D), // Daha açık turuncu/sarı
        ];
      case OrderStatus.completed:
        return [
          const Color(0xFF10B981), // Ana yeşil
          const Color(0xFF34D399), // Açık yeşil
          const Color(0xFF6EE7B7), // Daha açık yeşil
        ];
      case OrderStatus.cancelled:
        return [
          const Color(0xFFEF4444), // Ana kırmızı
          const Color(0xFFF87171), // Açık kırmızı
          const Color(0xFFFCA5A5), // Daha açık kırmızı
        ];
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Icons.hourglass_top_rounded;
      case OrderStatus.processing:
        return Icons.sync_rounded;
      case OrderStatus.completed:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
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

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ödenmedi';
      case PaymentStatus.partial:
        return 'Kısmi Ödeme';
      case PaymentStatus.paid:
        return 'Ödendi';
    }
  }
}
