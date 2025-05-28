import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/customer/customer_order.dart';

class CustomerOrderCard extends StatelessWidget {
  final CustomerOrder order;
  final VoidCallback? onTap;

  const CustomerOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Firma avatarı
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCompanyColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          order.company.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Firma adı ve sipariş numarası
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.company.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D1D35),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${order.id.substring(0, 4).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8EA9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Durum etiketi
                    _buildStatusChip(),
                  ],
                ),
                const SizedBox(height: 16),
                // Sipariş detayları
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF8E8EA9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(order.orderDate)} ${_formatTime(order.orderDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8EA9),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Ürün bilgileri
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: Color(0xFF8E8EA9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ürünler (${order.items.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666687),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ürün listesi
                ...order.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B61FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666687),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 2)
                  Text(
                    '... ve ${order.items.length - 2} ürün daha',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8EA9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 16),
                // Alt kısım - Tutar ve buton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toplam Tutar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8EA9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₺${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D35),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getActionButtonColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getActionButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (order.status) {
      case CustomerOrderStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        statusText = 'Bekliyor';
        break;
      case CustomerOrderStatus.confirmed:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        statusText = 'Onaylandı';
        break;
      case CustomerOrderStatus.preparing:
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        statusText = 'Hazırlanıyor';
        break;
      case CustomerOrderStatus.ready:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        statusText = 'Hazır';
        break;
      case CustomerOrderStatus.delivered:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        statusText = 'Teslim Edildi';
        break;
      case CustomerOrderStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        statusText = 'İptal Edildi';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getCompanyColor() {
    // Firma adının ilk harfine göre renk belirleme
    final firstChar = order.company.name[0].toUpperCase();
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];
    return colors[firstChar.codeUnitAt(0) % colors.length];
  }

  String _getStatusText() {
    switch (order.status) {
      case CustomerOrderStatus.pending:
        return 'Bekliyor';
      case CustomerOrderStatus.confirmed:
        return 'Onaylandı';
      case CustomerOrderStatus.preparing:
        return 'Hazırlanıyor';
      case CustomerOrderStatus.ready:
        return 'Hazır';
      case CustomerOrderStatus.delivered:
        return 'Teslim Edildi';
      case CustomerOrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  Color _getStatusColor() {
    switch (order.status) {
      case CustomerOrderStatus.pending:
        return const Color(0xFFFFB74D);
      case CustomerOrderStatus.confirmed:
        return const Color(0xFF64B5F6);
      case CustomerOrderStatus.preparing:
        return const Color(0xFF9C88FF);
      case CustomerOrderStatus.ready:
        return const Color(0xFF81C784);
      case CustomerOrderStatus.delivered:
        return const Color(0xFF4CAF50);
      case CustomerOrderStatus.cancelled:
        return const Color(0xFFE57373);
    }
  }

  Color _getActionButtonColor() {
    switch (order.status) {
      case CustomerOrderStatus.pending:
        return const Color(0xFFFFB74D);
      case CustomerOrderStatus.confirmed:
      case CustomerOrderStatus.preparing:
        return const Color(0xFF7B61FF);
      case CustomerOrderStatus.ready:
        return const Color(0xFF4CAF50);
      case CustomerOrderStatus.delivered:
        return const Color(0xFF81C784);
      case CustomerOrderStatus.cancelled:
        return const Color(0xFF8E8EA9);
    }
  }

  String _getActionButtonText() {
    switch (order.status) {
      case CustomerOrderStatus.pending:
        return 'Bekliyor';
      case CustomerOrderStatus.confirmed:
        return 'Hazırla';
      case CustomerOrderStatus.preparing:
        return 'Hazırlanıyor';
      case CustomerOrderStatus.ready:
        return 'Teslim Al';
      case CustomerOrderStatus.delivered:
        return 'Teslim Edildi';
      case CustomerOrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}
