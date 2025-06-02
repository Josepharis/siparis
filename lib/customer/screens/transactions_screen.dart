import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/models/order.dart';
import 'package:intl/intl.dart';
import 'package:siparis/providers/auth_provider.dart';

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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'İşlemlerim',
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSmallScreen ? 75 : 85),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 6 : 8,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 16 : 20),
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
              height: isSmallScreen ? 40 : 45,
              padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
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
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: isSmallScreen ? 6 : 8,
                      offset: Offset(0, isSmallScreen ? 1 : 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: isSmallScreen ? 16 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(isSmallScreen ? 'Sipariş' : 'Siparişler'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: isSmallScreen ? 16 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(isSmallScreen ? 'Ödeme' : 'Ödemeler'),
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
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
        // Oturum açmış kullanıcının firma adını al
        final currentUser = authProvider.currentUser;
        final currentUserCompanyName = currentUser?.companyName ?? '';

        // Müşteri siparişlerini filtrele - oturum açmış kullanıcının firma adıyla eşleşenler
        List<Order> customerOrders = [];

        if (currentUserCompanyName.isNotEmpty) {
          customerOrders = orderProvider.orders
              .where((order) => order.customer.name == currentUserCompanyName)
              .toList();
        } else {
          // Fallback: Eski sistem için "Müşteri →" ile başlayanları göster
          customerOrders = orderProvider.orders
              .where((order) => order.customer.name.startsWith('Müşteri →'))
              .toList();
        }

        // Tarihe göre sırala (en yeni önce)
        customerOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        print('🔍 Transactions Debug:');
        print('   Kullanıcı firma adı: $currentUserCompanyName');
        print('   Filtrelenmiş sipariş sayısı: ${customerOrders.length}');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Gerçek Firebase siparişleri
            ...customerOrders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOrderCard(order),
                )),

            // Eğer hiç sipariş yoksa boş durum mesajı
            if (customerOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz sipariş bulunmuyor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İlk siparişinizi verin ve burada görün',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final formatter = DateFormat('d MMM', 'tr_TR');
    final remainingAmount = order.totalAmount - (order.paidAmount ?? 0.0);
    final isPaid = remainingAmount <= 0;
    final companyName = order.customer.name.replaceFirst('Müşteri → ', '');
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final companyInitials = companyName.length >= 2
        ? companyName.substring(0, 2).toUpperCase()
        : companyName.toUpperCase();

    // Durum rengini belirle
    Color statusColor = isPaid ? Colors.green : Colors.orange;
    if (order.status == OrderStatus.waiting) statusColor = Colors.blue;
    if (order.status == OrderStatus.processing) statusColor = Colors.purple;
    if (order.status == OrderStatus.cancelled) statusColor = Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: isSmallScreen ? 4 : 10,
            offset: Offset(0, isSmallScreen ? 1 : 4),
          ),
        ],
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRealOrderDetails(order),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
          child: Column(
            children: [
              // Üst kısım - Şirket bilgileri ve tutar
              Row(
                children: [
                  // Avatar - Daha kompakt
                  Container(
                    width: isSmallScreen ? 24 : 32,
                    height: isSmallScreen ? 24 : 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 6 : 8),
                    ),
                    child: Center(
                      child: Text(
                        companyInitials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 8 : 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),

                  // Şirket ve sipariş bilgileri - Kompakt
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 1 : 2),
                        Row(
                          children: [
                            Text(
                              formatter.format(order.orderDate),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 2 : 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 2 : 4,
                                vertical: isSmallScreen ? 0 : 1,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 4 : 6),
                              ),
                              child: Text(
                                isPaid ? 'Ödendi' : 'Bekliyor',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 7 : 8,
                                  color: isPaid ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tutar kısmı - Kompakt
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.totalAmount >= 1000
                              ? '₺${(order.totalAmount / 1000).toStringAsFixed(order.totalAmount % 1000 == 0 ? 0 : 1)}K'
                              : '₺${order.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isPaid) ...[
                          SizedBox(height: isSmallScreen ? 1 : 2),
                          Text(
                            'Kalan: ${remainingAmount >= 1000 ? '₺${(remainingAmount / 1000).toStringAsFixed(remainingAmount % 1000 == 0 ? 0 : 1)}K' : '₺${remainingAmount.toStringAsFixed(0)}'}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 7 : 9,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 4 : 6),

              // Ürünler - Çok kompakt gösterim
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ürünler:',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 7 : 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 1 : 2),
                    Wrap(
                      spacing: isSmallScreen ? 2 : 4,
                      runSpacing: isSmallScreen ? 1 : 2,
                      children: [
                        // Telefonda sadece 1 ürün göster
                        ...order.items.take(isSmallScreen ? 1 : 2).map(
                              (item) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 2 : 4,
                                  vertical: isSmallScreen ? 0 : 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 4 : 6),
                                ),
                                child: Text(
                                  '${item.product.name} x${item.quantity}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 7 : 8,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        // Eğer daha fazla ürün varsa göster
                        if (order.items.length > (isSmallScreen ? 1 : 2))
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 2 : 4,
                              vertical: isSmallScreen ? 0 : 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius:
                                  BorderRadius.circular(isSmallScreen ? 4 : 6),
                            ),
                            child: Text(
                              '+${order.items.length - (isSmallScreen ? 1 : 2)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 7 : 8,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ödeme özeti - Daha kompakt
              if (!isPaid) ...[
                SizedBox(height: isSmallScreen ? 4 : 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentSummaryItem(
                        'Ödenen',
                        order.paidAmount ?? 0.0,
                        Colors.green,
                        Icons.check_circle_rounded,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 8),
                    Expanded(
                      child: _buildPaymentSummaryItem(
                        'Kalan',
                        remainingAmount,
                        Colors.orange,
                        Icons.pending_rounded,
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildPaymentSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 12 : 16,
          color: color,
        ),
        SizedBox(width: isSmallScreen ? 3 : 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                amount >= 1000
                    ? '₺${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K'
                    : '₺${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
        // Oturum açmış kullanıcının firma adını al
        final currentUser = authProvider.currentUser;
        final currentUserCompanyName = currentUser?.companyName ?? '';

        // Müşteri siparişlerini filtrele
        List<Order> customerOrders = [];

        if (currentUserCompanyName.isNotEmpty) {
          customerOrders = orderProvider.orders
              .where((order) => order.customer.name == currentUserCompanyName)
              .toList();
        } else {
          // Fallback: Eski sistem için "Müşteri →" ile başlayanları göster
          customerOrders = orderProvider.orders
              .where((order) => order.customer.name.startsWith('Müşteri →'))
              .toList();
        }

        // Firma bazında borç hesaplamaları
        final Map<String, CompanyDebtInfo> companyDebts = {};
        double totalOrderAmount = 0;
        double totalPaidAmount = 0;

        for (final order in customerOrders) {
          final companyName = currentUserCompanyName.isNotEmpty
              ? currentUserCompanyName
              : order.customer.name.replaceFirst('Müşteri → ', '');
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
        final isSmallScreen = MediaQuery.of(context).size.width < 600;

        return ListView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          children: [
            // Özet Kartı
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
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
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: isSmallScreen ? 8 : 12,
                    offset: Offset(0, isSmallScreen ? 4 : 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 6 : 8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ödeme Özeti',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                isSmallScreen
                                    ? 'Finansal Durum'
                                    : 'Toplam Finansal Durum',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 12 : 14,
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
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 10 : 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCompactPaymentStat(
                          'Sipariş',
                          customerOrders.length.toString(),
                          Icons.shopping_bag_rounded,
                          isSmallScreen,
                        ),
                        Container(
                          width: 1,
                          height: isSmallScreen ? 24 : 30,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildCompactPaymentStat(
                          'Ödenen',
                          totalPaidAmount >= 1000
                              ? '₺${(totalPaidAmount / 1000).toStringAsFixed(totalPaidAmount % 1000 == 0 ? 0 : 1)}K'
                              : '₺${totalPaidAmount.toStringAsFixed(0)}',
                          Icons.check_circle_rounded,
                          isSmallScreen,
                        ),
                        Container(
                          width: 1,
                          height: isSmallScreen ? 24 : 30,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildCompactPaymentStat(
                          'Kalan',
                          totalRemainingDebt >= 1000
                              ? '₺${(totalRemainingDebt / 1000).toStringAsFixed(totalRemainingDebt % 1000 == 0 ? 0 : 1)}K'
                              : '₺${totalRemainingDebt.toStringAsFixed(0)}',
                          Icons.pending_rounded,
                          isSmallScreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // Gerçek firma borç kartları
            ...companyDebts.values.map((companyInfo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDebtCard(companyInfo),
                )),

            // Eğer hiç firma borcu yoksa boş durum mesajı
            if (companyDebts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz ödeme bulunmuyor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Siparişleriniz tamamlandıkça ödemeler burada görünecek',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Gerçek firma borç kartı
  Widget _buildDebtCard(CompanyDebtInfo companyInfo) {
    final formatter = DateFormat('d MMM', 'tr_TR');
    final remainingDebt = companyInfo.totalDebt - companyInfo.paidAmount;
    final isPaid = remainingDebt <= 0;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Durum rengini belirle
    Color statusColor = isPaid ? Colors.green : Colors.orange;
    if (remainingDebt > 0) statusColor = Colors.orange[700]!;
    if (remainingDebt < 0) statusColor = Colors.green[700]!;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: isSmallScreen ? 4 : 10,
            offset: Offset(0, isSmallScreen ? 1 : 4),
          ),
        ],
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRealCompanyDebtDetails(companyInfo),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
          child: Column(
            children: [
              // Ana içerik - Daha kompakt
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Row(
                  children: [
                    // Avatar - Daha kompakt
                    Container(
                      width: isSmallScreen ? 24 : 32,
                      height: isSmallScreen ? 24 : 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 6 : 8),
                      ),
                      child: Center(
                        child: Text(
                          companyInfo.companyName.length >= 2
                              ? companyInfo.companyName
                                  .substring(0, 2)
                                  .toUpperCase()
                              : companyInfo.companyName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 8 : 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),

                    // Firma bilgileri - Kompakt
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyInfo.companyName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 1 : 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${companyInfo.orderCount} sipariş',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 2 : 4,
                                  vertical: isSmallScreen ? 0 : 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 4 : 6),
                                ),
                                child: Text(
                                  isPaid ? 'Ödendi' : 'Bekliyor',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 7 : 8,
                                    color:
                                        isPaid ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Borç tutarı - Kompakt
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            remainingDebt >= 1000
                                ? '₺${(remainingDebt / 1000).toStringAsFixed(remainingDebt % 1000 == 0 ? 0 : 1)}K'
                                : '₺${remainingDebt.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 14,
                              fontWeight: FontWeight.w800,
                              color: remainingDebt > 0
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 1 : 2),
                          Text(
                            'Kalan Borç',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 7 : 9,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Alt Kısım - Ödeme Detayları (sadece ödenmemişler için)
              if (!isPaid) ...[
                Container(
                  padding: EdgeInsets.fromLTRB(isSmallScreen ? 8 : 12, 0,
                      isSmallScreen ? 8 : 12, isSmallScreen ? 8 : 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDebtStat(
                          'Toplam',
                          companyInfo.totalDebt >= 1000
                              ? '₺${(companyInfo.totalDebt / 1000).toStringAsFixed(companyInfo.totalDebt % 1000 == 0 ? 0 : 1)}K'
                              : '₺${companyInfo.totalDebt.toStringAsFixed(0)}',
                          Icons.account_balance_wallet_rounded,
                          isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildDebtStat(
                          'Ödenen',
                          companyInfo.paidAmount >= 1000
                              ? '₺${(companyInfo.paidAmount / 1000).toStringAsFixed(companyInfo.paidAmount % 1000 == 0 ? 0 : 1)}K'
                              : '₺${companyInfo.paidAmount.toStringAsFixed(0)}',
                          Icons.check_circle_rounded,
                          isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Expanded(
                        child: _buildDebtStat(
                          'Kalan',
                          remainingDebt >= 1000
                              ? '₺${(remainingDebt / 1000).toStringAsFixed(remainingDebt % 1000 == 0 ? 0 : 1)}K'
                              : '₺${remainingDebt.toStringAsFixed(0)}',
                          Icons.pending_rounded,
                          isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Gerçek firma borç detayları
  void _showRealCompanyDebtDetails(CompanyDebtInfo companyInfo) {
    final formatter = DateFormat('d MMMM yyyy', 'tr_TR');
    final remainingDebt = companyInfo.totalDebt - companyInfo.paidAmount;

    // Bu firmaya ait siparişleri al
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final companyOrders = orderProvider.orders
        .where((order) =>
            order.customer.name.replaceFirst('Müşteri → ', '') ==
            companyInfo.companyName)
        .toList();

    // Tarihe göre sırala (en yeni önce)
    companyOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                    '${companyInfo.companyName} - Borç Detayı',
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
                    // Firma Özeti
                    Container(
                      padding: const EdgeInsets.all(16),
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
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                companyInfo.companyName.length >= 2
                                    ? companyInfo.companyName
                                        .substring(0, 2)
                                        .toUpperCase()
                                    : companyInfo.companyName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companyInfo.companyName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${companyInfo.orderCount} sipariş • ${formatter.format(companyInfo.lastPaymentDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₺${remainingDebt.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: remainingDebt > 0
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                ),
                              ),
                              Text(
                                'Kalan Borç',
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

                    const SizedBox(height: 24),

                    // Siparişler Başlığı
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sipariş Detayları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Siparişler Listesi
                    ...companyOrders.map(
                        (order) => _buildOrderDetailCard(order, formatter)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sipariş detay kartı
  Widget _buildOrderDetailCard(Order order, DateFormat formatter) {
    final remainingAmount = order.totalAmount - (order.paidAmount ?? 0.0);
    final isPaid = remainingAmount <= 0;
    final statusText = _getStatusText(order.status);
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green[200]! : Colors.orange[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - Sipariş bilgileri
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatter.format(order.orderDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Teslimat: ${formatter.format(order.deliveryDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPaid
                          ? 'Ödendi'
                          : '₺${remainingAmount.toStringAsFixed(2)} kalan',
                      style: TextStyle(
                        color: isPaid ? Colors.green[700] : Colors.orange[700],
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

          // Ürünler
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ürünler:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
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
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.product.name} x${item.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${order.items.length - 3} ürün daha',
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

          const SizedBox(height: 12),

          // Ödeme detayları
          Row(
            children: [
              Expanded(
                child: _buildPaymentDetailItem(
                  'Toplam',
                  order.totalAmount,
                  Colors.blue,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentDetailItem(
                  'Ödenen',
                  order.paidAmount ?? 0.0,
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentDetailItem(
                  'Kalan',
                  remainingAmount,
                  remainingAmount > 0 ? Colors.orange : Colors.green,
                  remainingAmount > 0 ? Icons.pending : Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ödeme detay item'ı
  Widget _buildPaymentDetailItem(
      String label, double amount, Color color, IconData icon) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 12 : 16,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            amount >= 1000
                ? '₺${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K'
                : '₺${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 7 : 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPaymentStat(
      String label, String value, IconData icon, bool isSmallScreen) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: isSmallScreen ? 12 : 16,
          ),
          SizedBox(height: isSmallScreen ? 1 : 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 9 : 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isSmallScreen ? 7 : 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  // Borç istatistik widget'ı
  Widget _buildDebtStat(
      String label, String value, IconData icon, bool isSmallScreen) {
    final color = label == 'Toplam'
        ? Colors.blue
        : label == 'Ödenen'
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 12 : 16,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 7 : 9,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
