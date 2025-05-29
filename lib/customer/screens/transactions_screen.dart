import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/models/order.dart';
import 'package:intl/intl.dart';

// Firma borç bilgisi sınıfı
class CompanyDebtInfo {
  final String companyName;
  final double totalDebt;
  final double paidAmount;
  final DateTime lastPaymentDate;
  final int orderCount;

  CompanyDebtInfo({
    required this.companyName,
    required this.totalDebt,
    required this.paidAmount,
    required this.lastPaymentDate,
    required this.orderCount,
  });
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Firebase verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.startListeningToOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'İşlemlerim',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(85),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text('Siparişler'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text('Ödemeler'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Müşteri siparişlerini filtrele (Müşteri → ile başlayanlar)
        final customerOrders = orderProvider.orders
            .where((order) => order.customer.name.startsWith('Müşteri →'))
            .toList();

        // Tarihe göre sırala (en yeni önce)
        customerOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Gerçek Firebase siparişleri
            ...customerOrders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRealOrderCard(order),
                )),

            // Taslak veriler (örnek gösterim için)
            if (customerOrders.isEmpty) ...[
              _buildSectionHeader('Örnek Siparişler'),
              const SizedBox(height: 8),
            ],

            _buildOrderCard(
              orderNo: 'SP123456',
              date: '12 Mart 2024',
              status: 'Tamamlandı',
              statusColor: Colors.green,
              companyName: 'Anadolu Gıda',
              amount: 450.90,
              items: [
                'Organik Tam Yağlı Süt x2',
                'Taze Kaşar Peyniri x1',
                'Dana Antrikot x1',
              ],
              paymentStatus: 'Kısmi Ödeme',
              paymentColor: Colors.orange,
              paidAmount: 200.00,
            ),
            const SizedBox(height: 12),
            _buildOrderCard(
              orderNo: 'SP123455',
              date: '10 Mart 2024',
              status: 'Tamamlandı',
              statusColor: Colors.green,
              companyName: 'Doğal Tarım',
              amount: 234.50,
              items: [
                'Organik Çeri Domates x3',
                'Yerli Muz x2',
              ],
              paymentStatus: 'Ödendi',
              paymentColor: Colors.green,
              paidAmount: 234.50,
            ),
          ],
        );
      },
    );
  }

  // Gerçek Firebase siparişi için kart
  Widget _buildRealOrderCard(Order order) {
    final formatter = DateFormat('d MMMM yyyy', 'tr_TR');
    final statusText = _getStatusText(order.status);
    final statusColor = _getStatusColor(order.status);
    final paymentStatusText = _getPaymentStatusText(order.paymentStatus);
    final paymentColor = _getPaymentStatusColor(order.paymentStatus);

    // Firma adından "Müşteri → " kısmını çıkar
    final companyName = order.customer.name.replaceFirst('Müşteri → ', '');

    // Ürün listesi oluştur
    final items = order.items
        .map((item) => '${item.product.name} x${item.quantity}')
        .toList();

    return InkWell(
      onTap: () => _showRealOrderDetails(order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.grey[100]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Üst Kısım - Firma ve Sipariş Bilgileri
              Row(
                children: [
                  // Firma Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        companyName.length >= 2
                            ? companyName.substring(0, 2).toUpperCase()
                            : companyName.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sipariş Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.id.substring(0, 8).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatter.format(order.orderDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Fiyat ve Ödeme Durumu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: paymentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentStatusText,
                          style: TextStyle(
                            color: paymentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ürün Listesi - Kompakt
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // İlk 2 ürünü göster
                    ...items.take(2).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    // Eğer daha fazla ürün varsa göster
                    if (items.length > 2)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${items.length - 2} ürün daha',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Alt Kısım - Ödeme Özeti
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentSummaryItem(
                      'Ödenen',
                      order.paidAmount ?? 0.0,
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: _buildPaymentSummaryItem(
                      'Kalan',
                      order.totalAmount - (order.paidAmount ?? 0.0),
                      (order.totalAmount - (order.paidAmount ?? 0.0)) > 0
                          ? Colors.orange
                          : Colors.green,
                      (order.totalAmount - (order.paidAmount ?? 0.0)) > 0
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bölüm başlığı
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Durum metni
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return 'Bekliyor';
      case OrderStatus.processing:
        return 'Hazırlanıyor';
      case OrderStatus.completed:
        return 'Tamamlandı';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  // Durum rengi
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

  // Ödeme durumu metni
  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Bekliyor';
      case PaymentStatus.partial:
        return 'Kısmi Ödeme';
      case PaymentStatus.paid:
        return 'Ödendi';
    }
  }

  // Ödeme durumu rengi
  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.red;
      case PaymentStatus.partial:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
    }
  }

  Widget _buildOrderCard({
    required String orderNo,
    required String date,
    required String status,
    required Color statusColor,
    required String companyName,
    required double amount,
    required List<String> items,
    required String paymentStatus,
    required Color paymentColor,
    required double paidAmount,
  }) {
    return InkWell(
      onTap: () => _showOrderDetails(
        orderNo: orderNo,
        companyName: companyName,
        items: items,
        amount: amount,
        paidAmount: paidAmount,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.grey[100]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Üst Kısım - Firma ve Sipariş Bilgileri
              Row(
                children: [
                  // Firma Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        companyName.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sipariş Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              orderNo,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Fiyat ve Ödeme Durumu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: paymentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentStatus,
                          style: TextStyle(
                            color: paymentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ürün Listesi - Kompakt
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // İlk 2 ürünü göster
                    ...items.take(2).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    // Eğer daha fazla ürün varsa göster
                    if (items.length > 2)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${items.length - 2} ürün daha',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Alt Kısım - Ödeme Özeti
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentSummaryItem(
                      'Ödenen',
                      paidAmount,
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: _buildPaymentSummaryItem(
                      'Kalan',
                      amount - paidAmount,
                      amount - paidAmount > 0 ? Colors.orange : Colors.green,
                      amount - paidAmount > 0
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '₺${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showOrderDetails({
    required String orderNo,
    required String companyName,
    required List<String> items,
    required double amount,
    required double paidAmount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Sipariş Detayı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sipariş Özeti
                    _buildDetailSection(
                      title: 'Sipariş Bilgileri',
                      content: [
                        _buildDetailRow('Sipariş No', orderNo),
                        _buildDetailRow('Firma', companyName),
                        _buildDetailRow(
                          'Tutar',
                          '₺${amount.toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Ödenen',
                          '₺${paidAmount.toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Kalan',
                          '₺${(amount - paidAmount).toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Ürün Listesi
                    _buildDetailSection(
                      title: 'Ürünler',
                      content: items
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    // Ödeme Geçmişi
                    _buildDetailSection(
                      title: 'Ödeme Geçmişi',
                      content: [
                        _buildPaymentHistoryItem(
                          date: '12 Mart 2024',
                          amount: 200.00,
                          type: 'Nakit',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: isHighlighted
                  ? AppTheme.primaryColor
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem({
    required String date,
    required double amount,
    required String type,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Müşteri siparişlerini filtrele
        final customerOrders = orderProvider.orders
            .where((order) => order.customer.name.startsWith('Müşteri →'))
            .toList();

        // Firma bazında borç hesaplamaları
        final Map<String, CompanyDebtInfo> companyDebts = {};
        double totalOrderAmount = 0;
        double totalPaidAmount = 0;

        for (final order in customerOrders) {
          final companyName =
              order.customer.name.replaceFirst('Müşteri → ', '');
          final orderAmount = order.totalAmount;
          final paidAmount = order.paidAmount ?? 0.0;

          totalOrderAmount += orderAmount;
          totalPaidAmount += paidAmount;

          if (!companyDebts.containsKey(companyName)) {
            companyDebts[companyName] = CompanyDebtInfo(
              companyName: companyName,
              totalDebt: 0,
              paidAmount: 0,
              lastPaymentDate: order.orderDate,
              orderCount: 0,
            );
          }

          final companyInfo = companyDebts[companyName]!;
          companyDebts[companyName] = CompanyDebtInfo(
            companyName: companyName,
            totalDebt: companyInfo.totalDebt + orderAmount,
            paidAmount: companyInfo.paidAmount + paidAmount,
            lastPaymentDate:
                order.orderDate.isAfter(companyInfo.lastPaymentDate)
                    ? order.orderDate
                    : companyInfo.lastPaymentDate,
            orderCount: companyInfo.orderCount + 1,
          );
        }

        final totalRemainingDebt = totalOrderAmount - totalPaidAmount;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Özet Kartı
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.9),
                    const Color(0xFF1E40AF),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ödeme Özeti',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Toplam Finansal Durum',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // İstatistikler
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPaymentStat(
                          'Toplam Sipariş',
                          customerOrders.length.toString(),
                          Icons.shopping_bag_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildPaymentStat(
                          'Ödenen',
                          '₺${totalPaidAmount.toStringAsFixed(2)}',
                          Icons.check_circle_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildPaymentStat(
                          'Kalan',
                          '₺${totalRemainingDebt.toStringAsFixed(2)}',
                          Icons.pending_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Gerçek firma borç kartları
            ...companyDebts.values.map((companyInfo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRealCompanyDebtCard(companyInfo),
                )),

            // Taslak veriler (eğer gerçek veri yoksa)
            if (companyDebts.isEmpty) ...[
              _buildSectionHeader('Örnek Ödemeler'),
              const SizedBox(height: 8),
              _buildCompanyDebtCard(
                companyName: 'Anadolu Gıda',
                totalDebt: 450.90,
                paidAmount: 200.00,
                lastPaymentDate: '12 Mart 2024',
              ),
              const SizedBox(height: 12),
              _buildCompanyDebtCard(
                companyName: 'Doğal Tarım',
                totalDebt: 234.50,
                paidAmount: 234.50,
                lastPaymentDate: '10 Mart 2024',
                isPaid: true,
              ),
            ],
          ],
        );
      },
    );
  }

  // Gerçek firma borç kartı
  Widget _buildRealCompanyDebtCard(CompanyDebtInfo companyInfo) {
    final remainingDebt = companyInfo.totalDebt - companyInfo.paidAmount;
    final isPaid = remainingDebt <= 0;
    final formatter = DateFormat('d MMMM yyyy', 'tr_TR');

    return InkWell(
      onTap: () => _showRealCompanyDebtDetails(companyInfo),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isPaid ? Colors.green[100]! : Colors.orange[100]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Üst Kısım
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Firma Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isPaid ? Colors.green[100]! : Colors.orange[100]!,
                              isPaid ? Colors.green[50]! : Colors.orange[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            companyInfo.companyName.length >= 2
                                ? companyInfo.companyName
                                    .substring(0, 2)
                                    .toUpperCase()
                                : companyInfo.companyName.toUpperCase(),
                            style: TextStyle(
                              color: isPaid
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Firma Bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyInfo.companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPaid
                                            ? Icons.check_circle_rounded
                                            : Icons.pending_rounded,
                                        color: isPaid
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPaid ? 'Ödendi' : 'Bekliyor',
                                        style: TextStyle(
                                          color: isPaid
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Son Ödeme: ${formatter.format(companyInfo.lastPaymentDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Toplam Borç
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${companyInfo.totalDebt.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${companyInfo.orderCount} sipariş',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Alt Kısım - Ödeme Detayları
            if (!isPaid) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDebtStat(
                          'Toplam',
                          '₺${companyInfo.totalDebt.toStringAsFixed(2)}',
                          Icons.account_balance_wallet_rounded,
                        ),
                        _buildDebtStat(
                          'Ödenen',
                          '₺${companyInfo.paidAmount.toStringAsFixed(2)}',
                          Icons.check_circle_rounded,
                        ),
                        _buildDebtStat(
                          'Kalan',
                          '₺${remainingDebt.toStringAsFixed(2)}',
                          Icons.pending_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Gerçek firma borç detayları
  void _showRealCompanyDebtDetails(CompanyDebtInfo companyInfo) {
    final formatter = DateFormat('d MMMM yyyy', 'tr_TR');
    final remainingDebt = companyInfo.totalDebt - companyInfo.paidAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Borç Detayı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Firma Bilgileri
                    _buildDetailSection(
                      title: 'Firma Bilgileri',
                      content: [
                        _buildDetailRow('Firma', companyInfo.companyName),
                        _buildDetailRow(
                            'Toplam Sipariş', '${companyInfo.orderCount} adet'),
                        _buildDetailRow(
                          'Toplam Borç',
                          '₺${companyInfo.totalDebt.toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Ödenen',
                          '₺${companyInfo.paidAmount.toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Kalan',
                          '₺${remainingDebt.toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Son Ödeme Bilgisi
                    _buildDetailSection(
                      title: 'Son Ödeme',
                      content: [
                        _buildPaymentHistoryItem(
                          date: formatter.format(companyInfo.lastPaymentDate),
                          amount: companyInfo.paidAmount,
                          type: 'Toplam Ödenen',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Gerçek sipariş detayları göster
  void _showRealOrderDetails(Order order) {
    final formatter = DateFormat('d MMMM yyyy', 'tr_TR');
    final companyName = order.customer.name.replaceFirst('Müşteri → ', '');
    final items = order.items
        .map((item) => '${item.product.name} x${item.quantity}')
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Sipariş Detayı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sipariş Özeti
                    _buildDetailSection(
                      title: 'Sipariş Bilgileri',
                      content: [
                        _buildDetailRow('Sipariş No',
                            order.id.substring(0, 8).toUpperCase()),
                        _buildDetailRow('Firma', companyName),
                        _buildDetailRow('Sipariş Tarihi',
                            formatter.format(order.orderDate)),
                        _buildDetailRow('Teslimat Tarihi',
                            formatter.format(order.deliveryDate)),
                        _buildDetailRow(
                          'Tutar',
                          '₺${order.totalAmount.toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Ödenen',
                          '₺${(order.paidAmount ?? 0.0).toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Kalan',
                          '₺${(order.totalAmount - (order.paidAmount ?? 0.0)).toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Ürün Listesi
                    _buildDetailSection(
                      title: 'Ürünler',
                      content: items
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    if (order.note != null && order.note!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildDetailSection(
                        title: 'Sipariş Notu',
                        content: [
                          Text(
                            order.note!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Taslak firma borç kartı (eski veriler için)
  Widget _buildCompanyDebtCard({
    required String companyName,
    required double totalDebt,
    required double paidAmount,
    required String lastPaymentDate,
    bool isPaid = false,
  }) {
    final remainingDebt = totalDebt - paidAmount;

    return InkWell(
      onTap: () => _showOrderDetails(
        orderNo: 'SP123456',
        companyName: companyName,
        items: ['Örnek Ürün x1'],
        amount: totalDebt,
        paidAmount: paidAmount,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isPaid ? Colors.green[100]! : Colors.orange[100]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Üst Kısım
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Firma Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isPaid ? Colors.green[100]! : Colors.orange[100]!,
                              isPaid ? Colors.green[50]! : Colors.orange[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            companyName.length >= 2
                                ? companyName.substring(0, 2).toUpperCase()
                                : companyName.toUpperCase(),
                            style: TextStyle(
                              color: isPaid
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Firma Bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPaid
                                            ? Icons.check_circle_rounded
                                            : Icons.pending_rounded,
                                        color: isPaid
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPaid ? 'Ödendi' : 'Bekliyor',
                                        style: TextStyle(
                                          color: isPaid
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Son Ödeme: $lastPaymentDate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Toplam Borç
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${totalDebt.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Toplam',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Alt Kısım - Ödeme Detayları
            if (!isPaid) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDebtStat(
                          'Toplam',
                          '₺${totalDebt.toStringAsFixed(2)}',
                          Icons.account_balance_wallet_rounded,
                        ),
                        _buildDebtStat(
                          'Ödenen',
                          '₺${paidAmount.toStringAsFixed(2)}',
                          Icons.check_circle_rounded,
                        ),
                        _buildDebtStat(
                          'Kalan',
                          '₺${remainingDebt.toStringAsFixed(2)}',
                          Icons.pending_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Borç istatistik widget'ı
  Widget _buildDebtStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
