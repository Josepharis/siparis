import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';

class CustomerOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const CustomerOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Durum bilgileri
    final statusText = Order.getStatusText(order.status);

    // Firma adını çıkar
    String companyName = 'Bilinmeyen Firma';
    if (order.customer.name.contains('→')) {
      companyName = order.customer.name.split('→').last.trim();
    } else if (order.note != null && order.note!.contains('firmasından')) {
      // Note'tan firma adını çıkarmaya çalış
      final noteWords = order.note!.split(' ');
      final firmaIndex = noteWords.indexOf('firmasından');
      if (firmaIndex > 0) {
        companyName = noteWords[firmaIndex - 1];
      }
    }

    // Debug: Firma adı çıkarma işlemini kontrol et
    print('🔍 CustomerOrderCard Debug:');
    print('   Müşteri adı: ${order.customer.name}');
    print('   Çıkarılan firma: $companyName');
    print('   Not: ${order.note}');

    // Saat formatı ve bilgileri
    final timeFormat = DateFormat('HH:mm');
    final deliveryTime = timeFormat.format(order.deliveryDate);
    final dateFormat = DateFormat('d MMM', 'tr_TR');
    final deliveryDate = dateFormat.format(order.deliveryDate);

    // Teslimat tarihinden kalan gün hesabı
    final int daysLeft = order.deliveryDate.difference(DateTime.now()).inDays;
    final String timeIndicator = daysLeft > 0
        ? '$daysLeft gün kaldı'
        : daysLeft == 0
            ? 'Bugün teslim'
            : '${daysLeft.abs()} gün önce teslim edildi';
    final bool isUrgent =
        daysLeft <= 1 && order.status != OrderStatus.completed;

    // Durum renklerini belirle
    final mainColor = _getStatusColor(order.status);
    final gradientColors = _getGradientColors(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
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
                // Üst renk şeridi ve sipariş bilgisi
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sipariş ikonu
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(order.status),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sipariş ID ve durum
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sipariş #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    companyName,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Fiyat göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₺${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik alanı (beyaz kısım)
                Container(
                  padding: const EdgeInsets.all(14),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Teslimat bilgisi
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red.shade50
                                  : mainColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isUrgent
                                  ? Icons.schedule_rounded
                                  : Icons.event_rounded,
                              size: 20,
                              color: isUrgent ? Colors.red : mainColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Teslimat: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '$deliveryDate, $deliveryTime',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUrgent
                                        ? Colors.red.shade50
                                        : mainColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isUrgent ? Colors.red : mainColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Sipariş içeriği
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: mainColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sipariş İçeriği (${order.items.length} ürün)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...order.items.take(3).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: mainColor,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.product.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₺${item.total.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            if (order.items.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+${order.items.length - 3} ürün daha...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Ödeme durumu (sadece ödenmemişse göster)
                      if (order.paymentStatus != PaymentStatus.paid) ...[
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.shade50,
                                Colors.orange.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.orange.shade500,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.credit_card_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.paymentStatus ==
                                                PaymentStatus.pending
                                            ? 'Ödeme Bekleniyor'
                                            : 'Kısmi Ödeme Yapıldı',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                      if (order.paidAmount != null &&
                                          order.paidAmount! > 0) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '₺${order.paidAmount!.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade600,
                                              ),
                                            ),
                                            Text(
                                              ' / ₺${order.totalAmount.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: order.paidAmount! /
                                              order.totalAmount,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.green.shade500,
                                          ),
                                          minHeight: 3,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    order.paymentStatus == PaymentStatus.pending
                                        ? 'Bekliyor'
                                        : 'Kısmi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  List<Color> _getGradientColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return [
          Colors.orange.shade400,
          Colors.orange.shade500,
          Colors.orange.shade600,
        ];
      case OrderStatus.processing:
        return [
          Colors.blue.shade400,
          Colors.blue.shade500,
          Colors.blue.shade600,
        ];
      case OrderStatus.completed:
        return [
          Colors.green.shade400,
          Colors.green.shade500,
          Colors.green.shade600,
        ];
      case OrderStatus.cancelled:
        return [
          Colors.red.shade400,
          Colors.red.shade500,
          Colors.red.shade600,
        ];
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Icons.schedule_rounded;
      case OrderStatus.processing:
        return Icons.construction_rounded;
      case OrderStatus.completed:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}
