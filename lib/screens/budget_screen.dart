import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:siparis/services/notification_service.dart';

// Ödeme yöntemi
enum PaymentMethod { card, cash }

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tarih aralığı seçimi için state değişkenleri
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, int> _filteredProductSummary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Varsayılan tarih aralığı - son 30 gün
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tarih aralığına göre ürün analizi hesapla
  void _calculateProductAnalysis(OrderProvider orderProvider) {
    _filteredProductSummary.clear();

    final allOrders = [
      ...orderProvider.waitingOrders,
      ...orderProvider.processingOrders,
      ...orderProvider.completedOrders,
    ];

    for (final order in allOrders) {
      // Tarih aralığı kontrolü
      if (_startDate != null && _endDate != null) {
        if (order.orderDate.isBefore(_startDate!) ||
            order.orderDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          continue;
        }
      }

      // Sipariş öğelerini analiz et
      for (final item in order.items) {
        _filteredProductSummary[item.product.name] =
            (_filteredProductSummary[item.product.name] ?? 0) + item.quantity;
      }
    }
  }

  // Detaylı ürün analizi hesapla - eski formatta
  List<Map<String, dynamic>> _calculateDetailedProductAnalysis(
      OrderProvider orderProvider) {
    Map<String, Map<String, dynamic>> productAnalysis = {};

    final allOrders = [
      ...orderProvider.waitingOrders,
      ...orderProvider.processingOrders,
      ...orderProvider.completedOrders,
    ];

    for (final order in allOrders) {
      // Tarih aralığı kontrolü
      if (_startDate != null && _endDate != null) {
        if (order.orderDate.isBefore(_startDate!) ||
            order.orderDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          continue;
        }
      }

      // Sipariş öğelerini analiz et
      for (final item in order.items) {
        final productName = item.product.name;
        final companyName = order.customer.name;

        if (!productAnalysis.containsKey(productName)) {
          productAnalysis[productName] = {
            'productName': productName,
            'category': item.product.category,
            'totalQuantity': 0,
            'firmaCounts': <String, int>{},
            'firmaCount': 0,
          };
        }

        productAnalysis[productName]!['totalQuantity'] += item.quantity;

        if (productAnalysis[productName]!['firmaCounts'][companyName] == null) {
          productAnalysis[productName]!['firmaCounts'][companyName] = 0;
        }
        productAnalysis[productName]!['firmaCounts'][companyName] +=
            item.quantity;
      }
    }

    // Firma sayılarını hesapla
    productAnalysis.forEach((key, value) {
      value['firmaCount'] = value['firmaCounts'].length;
    });

    // Listeye çevir ve sırala
    final result = productAnalysis.values.toList();
    result.sort((a, b) => b['totalQuantity'].compareTo(a['totalQuantity']));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
        final financialSummary = orderProvider.financialSummary;
        final companySummaries = orderProvider.companySummaries;

        // Yetki kontrolü
        final hasFullBudgetAccess = authProvider.hasPermission('view_budget');
        final hasPartialBudgetAccess =
            authProvider.hasPermission('view_partial_budget');

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false, // Geri butonunu kaldır
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bütçe Yönetimi',
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isSmallScreen)
                        Text(
                          'Finansal durum ve analiz',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Tarih aralığı seçici buton - sağ üstte kompakt
              if (hasFullBudgetAccess)
                Container(
                  margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 10),
                      onTap: () => _showDateRangeModal(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 6),
                            Text(
                              isSmallScreen ? 'Tarih' : 'Tarih Aralığı',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: isSmallScreen ? 11 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_startDate != null && _endDate != null) ...[
                              SizedBox(width: isSmallScreen ? 4 : 6),
                              Container(
                                width: isSmallScreen ? 6 : 8,
                                height: isSmallScreen ? 6 : 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Refresh butonu
              Container(
                margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.primaryColor,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  onPressed: () {
                    // Refresh functionality
                    context.read<OrderProvider>().loadOrders();
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Tab Bar (sadece tam yetki olanlar için) - padding eklendi
              if (hasFullBudgetAccess)
                Container(
                  margin: EdgeInsets.fromLTRB(
                    isSmallScreen ? 12 : 16,
                    isSmallScreen ? 8 : 12,
                    isSmallScreen ? 12 : 16,
                    isSmallScreen ? 8 : 12,
                  ),
                  height: isSmallScreen ? 40 : 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 10 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: isSmallScreen ? 6 : 8,
                          offset: Offset(0, isSmallScreen ? 1 : 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondaryColor,
                    labelStyle: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        fontWeight: FontWeight.w600),
                    unselectedLabelStyle:
                        TextStyle(fontSize: isSmallScreen ? 11 : 13),
                    tabs: [
                      Tab(
                          text: isSmallScreen
                              ? 'Genel'
                              : 'Genel Durum & Ödemeler'),
                      Tab(
                          text:
                              isSmallScreen ? 'Analiz' : 'Ürün Satış Analizi'),
                    ],
                  ),
                ),

              // Tab View veya Kısmi Görünüm
              Expanded(
                child: hasFullBudgetAccess
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFinancialTab(
                              financialSummary, companySummaries),
                          Builder(
                            builder: (context) {
                              // Analiz hesapla
                              _calculateProductAnalysis(orderProvider);
                              return _buildProductAnalysisTab(orderProvider);
                            },
                          ),
                        ],
                      )
                    : hasPartialBudgetAccess
                        ? _buildPartialBudgetView(companySummaries)
                        : _buildNoAccessView(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Genel durum ve ödemeler sekmesi
  Widget _buildFinancialTab(
    FinancialSummary? financialSummary,
    List<CompanySummary> companies,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (financialSummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genel Finansal Özet Kartları
          _buildBudgetSummaryCards(financialSummary),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Firma Bazlı Ödemeler Başlık
          Row(
            children: [
              Text(
                'Firma Ödemeleri',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                'Toplam ${companies.length} firma',
                style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey.shade600),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              // Modern Ödeme Bildirimi Gönder Butonu
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 12 : 16),
                    onTap: () => _sendPaymentNotifications(context, companies),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(isSmallScreen ? 6 : 8),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Text(
                            isSmallScreen ? 'Bildirim' : 'Ödeme Bildirimi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 8 : 12),

          // Firma Kartları
          _buildCompanyCards(companies),
        ],
      ),
    );
  }

  // Genel özet kartları
  Widget _buildBudgetSummaryCards(FinancialSummary summary) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Ciro ve Tahsilat Durumu Kartı
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: isSmallScreen ? 8 : 12,
                offset: Offset(0, isSmallScreen ? 3 : 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toplam Bütçe',
                    style: TextStyle(
                        color: Colors.white, fontSize: isSmallScreen ? 12 : 14),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 6 : 8),
                    ),
                    child: Text(
                      '₺${summary.totalAmount >= 1000 ? '${(summary.totalAmount / 1000).toStringAsFixed(summary.totalAmount % 1000 == 0 ? 0 : 1)}K' : summary.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Row(
                children: [
                  // Tahsilat Miktarı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tahsil Edilen',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 10 : 12),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          '₺${summary.collectedAmount >= 1000 ? '${(summary.collectedAmount / 1000).toStringAsFixed(summary.collectedAmount % 1000 == 0 ? 0 : 1)}K' : summary.collectedAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bekleyen Tahsilat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bekleyen',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 10 : 12),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          '₺${summary.pendingAmount >= 1000 ? '${(summary.pendingAmount / 1000).toStringAsFixed(summary.pendingAmount % 1000 == 0 ? 0 : 1)}K' : summary.pendingAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tahsilat Oranı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tahsilat Oranı',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 10 : 12),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          '%${summary.collectionRate.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 8 : 12),

        // Sipariş İstatistikleri
        Row(
          children: [
            // Toplam Sipariş
            Expanded(
              child: _buildInfoCard(
                'Toplam Sipariş',
                summary.totalOrders.toString(),
                Icons.shopping_bag_outlined,
                Colors.blue,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 12),
            // Ödenmiş Sipariş
            Expanded(
              child: _buildInfoCard(
                'Ödenmiş',
                summary.paidOrders.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 12),
            // Bekleyen Sipariş
            Expanded(
              child: _buildInfoCard(
                'Bekleyen',
                summary.pendingOrders.toString(),
                Icons.pending_outlined,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Bilgi kartı
  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isSmallScreen ? 3 : 5,
            spreadRadius: isSmallScreen ? 0.5 : 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isSmallScreen ? 14 : 18),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Firma kartları
  Widget _buildCompanyCards(List<CompanySummary> companies) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (companies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Henüz firma verisi bulunmuyor.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        final isPaid = company.pendingAmount == 0;

        return GestureDetector(
          onTap: () {
            // Firmaya tıklandığında ödeme diyaloğunu aç
            _showPaymentDialog(context, company);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              border: Border.all(
                color: isPaid ? Colors.green.shade300 : Colors.orange.shade300,
                width: isSmallScreen ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: isSmallScreen ? 3 : 5,
                  offset: Offset(0, isSmallScreen ? 1 : 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Column(
                children: [
                  // Firma adı ve ödeme durumu
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isPaid
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        radius: isSmallScreen ? 16 : 20,
                        child: Text(
                          company.company.name.substring(0, 1),
                          style: TextStyle(
                            color: isPaid
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.company.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${company.totalOrders} Sipariş',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: isSmallScreen ? 10 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 6 : 8),
                        ),
                        child: Text(
                          isPaid ? 'Tamamlandı' : 'Bekliyor',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 10 : 16),

                  // Ödeme detayları
                  Row(
                    children: [
                      // Toplam Tutar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam Tutar',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              '₺${company.totalAmount >= 1000 ? '${(company.totalAmount / 1000).toStringAsFixed(company.totalAmount % 1000 == 0 ? 0 : 1)}K' : company.totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Ödenen Tutar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ödenen',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              '₺${company.paidAmount >= 1000 ? '${(company.paidAmount / 1000).toStringAsFixed(company.paidAmount % 1000 == 0 ? 0 : 1)}K' : company.paidAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Kalan Tutar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kalan',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              '₺${company.pendingAmount >= 1000 ? '${(company.pendingAmount / 1000).toStringAsFixed(company.pendingAmount % 1000 == 0 ? 0 : 1)}K' : company.pendingAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.orange,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 6 : 8),

                  // İlerleme çubuğu
                  LinearProgressIndicator(
                    value: company.collectionRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid ? Colors.green : AppTheme.primaryColor,
                    ),
                    minHeight: isSmallScreen ? 3 : 4,
                    borderRadius: BorderRadius.circular(2),
                  ),

                  SizedBox(height: isSmallScreen ? 3 : 4),

                  // Tahsilat oranı
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '%${company.collectionRate.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? Colors.green.shade700
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Ödeme alma diyaloğu
  void _showPaymentDialog(BuildContext context, CompanySummary company) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Ödeme yöntemi ve tutarı için controller'lar
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    // Varsayılan olarak tam ödeme tutarını göster
    amountController.text = company.pendingAmount.toStringAsFixed(2);

    // Ödeme yöntemi ve tarihi için değişkenler
    PaymentMethod selectedPaymentMethod = PaymentMethod.card;
    DateTime selectedDate = DateTime.now();
    bool isFullPayment = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: isSmallScreen
                  ? MediaQuery.of(context).size.height * 0.88
                  : MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Başlık
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 16 : 24,
                        isSmallScreen ? 16 : 24,
                        isSmallScreen ? 16 : 24,
                        isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ödeme Al',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    company.company.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: isSmallScreen ? 13 : 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Firma bilgileri - Kompakt hale getirildi
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 10 : 12),
                          ),
                          child: Row(
                            children: [
                              // Toplam Tutar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Toplam',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 2 : 4),
                                    Text(
                                      '₺${company.totalAmount >= 1000 ? '${(company.totalAmount / 1000).toStringAsFixed(1)}K' : company.totalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 12 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Ödenmiş Tutar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ödenmiş',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 2 : 4),
                                    Text(
                                      '₺${company.paidAmount >= 1000 ? '${(company.paidAmount / 1000).toStringAsFixed(1)}K' : company.paidAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 12 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Kalan Tutar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kalan',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 2 : 4),
                                    Text(
                                      '₺${company.pendingAmount >= 1000 ? '${(company.pendingAmount / 1000).toStringAsFixed(1)}K' : company.pendingAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 12 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 8 : 16),

                        // Siparişleri Görüntüle Butonu - Küçültüldü
                        Center(
                          child: Consumer<OrderProvider>(
                            builder: (context, orderProvider, child) {
                              final unpaidOrdersCount = orderProvider.orders
                                  .where((order) =>
                                      order.customer.name ==
                                          company.company.name &&
                                      order.status == OrderStatus.completed &&
                                      order.paymentStatus != PaymentStatus.paid)
                                  .length;

                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 4 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      color: Colors.white.withOpacity(0.9),
                                      size: isSmallScreen ? 12 : 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${unpaidOrdersCount} sipariş',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: isSmallScreen ? 9 : 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tam/Kısmi Ödeme Seçimi - Kompakt
                          Text(
                            'Ödeme Tutarı',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFullPayment = true;
                                      amountController.text = company
                                          .pendingAmount
                                          .toStringAsFixed(2);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 8 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFullPayment
                                          ? AppTheme.primaryColor
                                              .withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 6 : 8),
                                      border: Border.all(
                                        color: isFullPayment
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: isFullPayment
                                              ? AppTheme.primaryColor
                                              : Colors.grey.shade500,
                                          size: isSmallScreen ? 16 : 20,
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 4),
                                        Text(
                                          'Tam Ödeme',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 13,
                                            fontWeight: FontWeight.w500,
                                            color: isFullPayment
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 4),
                                        Text(
                                          '₺${company.pendingAmount >= 1000 ? '${(company.pendingAmount / 1000).toStringAsFixed(1)}K' : company.pendingAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: isFullPayment
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFullPayment = false;
                                      amountController.text = '';
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 8 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isFullPayment
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 6 : 8),
                                      border: Border.all(
                                        color: !isFullPayment
                                            ? Colors.orange.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.payments_outlined,
                                          color: !isFullPayment
                                              ? Colors.orange.shade700
                                              : Colors.grey.shade500,
                                          size: isSmallScreen ? 16 : 20,
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 4),
                                        Text(
                                          'Kısmi Ödeme',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 13,
                                            fontWeight: FontWeight.w500,
                                            color: !isFullPayment
                                                ? Colors.orange.shade700
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 4),
                                        Text(
                                          'Tutar girin',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: !isFullPayment
                                                ? Colors.orange.shade600
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isSmallScreen ? 12 : 20),

                          // Tutar Girişi - Kompakt
                          if (!isFullPayment) ...[
                            Text(
                              'Ödeme Tutarını Girin',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 8 : 12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Ödeme tutarı',
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 12,
                                    ),
                                    child: Text(
                                      '₺',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 20),
                          ],

                          // Ödeme Yöntemi - Kompakt
                          Text(
                            'Ödeme Yöntemi',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPaymentMethod =
                                          PaymentMethod.card;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 8 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedPaymentMethod ==
                                              PaymentMethod.card
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 6 : 8),
                                      border: Border.all(
                                        color: selectedPaymentMethod ==
                                                PaymentMethod.card
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.credit_card,
                                          color: selectedPaymentMethod ==
                                                  PaymentMethod.card
                                              ? Colors.blue
                                              : Colors.grey.shade500,
                                          size: isSmallScreen ? 16 : 20,
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 4),
                                        Text(
                                          isSmallScreen
                                              ? 'Kart'
                                              : 'Kart ile Ödeme',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 13,
                                            fontWeight: FontWeight.w500,
                                            color: selectedPaymentMethod ==
                                                    PaymentMethod.card
                                                ? Colors.blue
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPaymentMethod =
                                          PaymentMethod.cash;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 8 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedPaymentMethod ==
                                              PaymentMethod.cash
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 6 : 8),
                                      border: Border.all(
                                        color: selectedPaymentMethod ==
                                                PaymentMethod.cash
                                            ? Colors.green
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.attach_money_rounded,
                                          color: selectedPaymentMethod ==
                                                  PaymentMethod.cash
                                              ? Colors.green
                                              : Colors.grey.shade500,
                                          size: isSmallScreen ? 16 : 20,
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 4),
                                        Text(
                                          isSmallScreen
                                              ? 'Nakit'
                                              : 'Nakit Ödeme',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 13,
                                            fontWeight: FontWeight.w500,
                                            color: selectedPaymentMethod ==
                                                    PaymentMethod.cash
                                                ? Colors.green
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isSmallScreen ? 12 : 20),

                          // Ödeme Tarihi - Kompakt
                          Text(
                            'Ödeme Tarihi',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 30),
                                ),
                              );
                              if (pickedDate != null &&
                                  pickedDate != selectedDate) {
                                setState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 10 : 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 8 : 12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: isSmallScreen ? 14 : 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: isSmallScreen ? 12 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 12 : 20),

                          // Not - Kompakt (Telefonda sadece tek satır)
                          Text(
                            'Not (İsteğe Bağlı)',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius:
                                  BorderRadius.circular(isSmallScreen ? 8 : 12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: noteController,
                              maxLines: isSmallScreen ? 1 : 2,
                              style:
                                  TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 8 : 12,
                                ),
                                border: InputBorder.none,
                                hintText: 'Ödeme notu...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Alt Butonlar - Kompakt
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // İptal Butonu
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 8 : 12),
                              ),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        // Ödeme Al Butonu
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              // Ödeme işlemi
                              _processPayment(
                                context,
                                company,
                                amountController.text,
                                selectedPaymentMethod,
                                selectedDate,
                                noteController.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 8 : 12),
                              ),
                            ),
                            child: Text(
                              isSmallScreen ? 'Tamamla' : 'Ödemeyi Tamamla',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Ödeme işleme - Modern ve Şık Onay Sistemi
  void _processPayment(
    BuildContext context,
    CompanySummary company,
    String amountText,
    PaymentMethod paymentMethod,
    DateTime date,
    String note,
  ) {
    // Tutarı double'a çevir
    double? amount = double.tryParse(amountText.replaceAll(',', '.'));

    // Tutar geçerli değilse uyarı göster
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Lütfen geçerli bir tutar girin.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Tutar kalan tutardan büyükse uyarı göster
    if (amount > company.pendingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                  child: Text('Girilen tutar kalan tutardan büyük olamaz.')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Diyaloğu kapat
    Navigator.pop(context);

    // Modern ödeme onay diyaloğunu göster
    _showModernPaymentConfirmation(
        context, company, amount, paymentMethod, date, note);
  }

  // Modern ve Şık Ödeme Onay Diyaloğu
  void _showModernPaymentConfirmation(
    BuildContext context,
    CompanySummary company,
    double amount,
    PaymentMethod paymentMethod,
    DateTime date,
    String note,
  ) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık Bölümü
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // İkon ve Başlık
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              paymentMethod == PaymentMethod.card
                                  ? Icons.credit_card_rounded
                                  : Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ödeme Onayı',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'İşlemi onaylamak üzeresiniz',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Tutar Gösterimi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₺${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik Bölümü
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Ödeme Detayları
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildPaymentDetailRow(
                              'Firma',
                              company.company.name,
                              Icons.business_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildPaymentDetailRow(
                              'Ödeme Yöntemi',
                              paymentMethod == PaymentMethod.card
                                  ? 'Kredi/Banka Kartı'
                                  : 'Nakit Ödeme',
                              paymentMethod == PaymentMethod.card
                                  ? Icons.credit_card
                                  : Icons.money,
                            ),
                            const SizedBox(height: 16),
                            _buildPaymentDetailRow(
                              'Tarih',
                              '${date.day}/${date.month}/${date.year}',
                              Icons.calendar_today_rounded,
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildPaymentDetailRow(
                                'Not',
                                note,
                                Icons.note_rounded,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Uyarı Mesajı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bu işlem geri alınamaz. Ödeme kaydı sisteme işlenecektir.',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          // İptal Butonu
                          Expanded(
                            child: TextButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'İptal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Onayla Butonu
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      setState(() {
                                        isProcessing = true;
                                      });

                                      try {
                                        // Ödeme işlemini simüle et
                                        await Future.delayed(
                                            const Duration(milliseconds: 1500));

                                        // Gerçek ödeme işlemi - Sadece Firebase'e kaydet
                                        if (context.mounted) {
                                          await Provider.of<OrderProvider>(
                                                  context,
                                                  listen: false)
                                              .processCustomerPayment(
                                                  company.company.name, amount);

                                          // Diyaloğu kapat
                                          Navigator.of(context).pop();

                                          // Başarı mesajı göster
                                          _showPaymentSuccessMessage(context,
                                              amount, company.company.name);
                                        }
                                      } catch (e) {
                                        setState(() {
                                          isProcessing = false;
                                        });

                                        if (context.mounted) {
                                          // Hata mesajı göster
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(Icons.error_outline,
                                                      color: Colors.white),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                      child: Text(
                                                          'Ödeme kaydedilemedi: ${e.toString()}')),
                                                ],
                                              ),
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isProcessing
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'İşleniyor...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Ödemeyi Onayla',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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

  // Ödeme detay satırı
  Widget _buildPaymentDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Başarı mesajı gösterme
  void _showPaymentSuccessMessage(
      BuildContext context, double amount, String companyName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başarı İkonu
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 50,
                ),
              ),

              const SizedBox(height: 20),

              // Başarı Mesajı
              Text(
                'Ödeme Başarılı!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                '₺${amount.toStringAsFixed(2)} tutarında ödeme başarıyla ${companyName} firmasından tahsil edildi.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Tamam Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // ctx kullanarak dialog'u kapat
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Yeni Ürün Analizi Sekmesi - Tarih aralığı ile
  Widget _buildProductAnalysisTab(OrderProvider orderProvider) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Detaylı analiz hesapla
    final products = _calculateDetailedProductAnalysis(orderProvider);

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Seçilen tarih aralığında\nürün satış verisi bulunmuyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showDateRangeModal(context),
              icon: const Icon(Icons.date_range_rounded),
              label: const Text('Tarih Aralığı Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // En çok satan ilk 8 ürünü al (pasta grafik için ideal)
    final topProducts = products.take(8).toList();

    // Renk paletimiz (canlı ve birbirine uyumlu renkler)
    final List<Color> pieColors = [
      const Color(0xFF5D43FB), // Mor
      const Color(0xFF4285F4), // Mavi
      const Color(0xFF00BCD4), // Cam göbeği
      const Color(0xFF00D287), // Yeşil
      const Color(0xFFFFCC00), // Sarı
      const Color(0xFFFF9800), // Turuncu
      const Color(0xFFFF5252), // Kırmızı
      const Color(0xFF9C27B0), // Mor tonları
    ];

    // Toplam satış adedi (yüzde hesaplamak için)
    final totalQuantity = topProducts.fold(
      0,
      (sum, product) => sum + product['totalQuantity'] as int,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Zenginleştirilmiş satış analizi grafiği
          Container(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık bölümü - Modern tasarım
                Container(
                  padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                      topRight: Radius.circular(isSmallScreen ? 16 : 20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 10 : 12),
                        ),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 26,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ürün Satış Dağılımı',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Toplam ${totalQuantity} adet ürün',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isSmallScreen ? 11 : 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // İstatistik göstergesi - Modern
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 16 : 20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isSmallScreen ? 6 : 8,
                              height: isSmallScreen ? 6 : 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 6),
                            Text(
                              'Güncel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik - Grafik - Modern tasarım
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    children: <Widget>[
                      // Kompakt İstatistik Kartları
                      Row(
                        children: [
                          // Toplam Satış
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 10 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                      SizedBox(width: isSmallScreen ? 3 : 4),
                                      Expanded(
                                        child: Text(
                                          'Toplam Satış',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: isSmallScreen ? 9 : 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    '${totalQuantity}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'adet',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: isSmallScreen ? 8 : 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(width: isSmallScreen ? 6 : 8),

                          // Ürün Çeşitliliği
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade300,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 10 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                      SizedBox(width: isSmallScreen ? 3 : 4),
                                      Expanded(
                                        child: Text(
                                          'Ürün Çeşidi',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: isSmallScreen ? 9 : 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    '${products.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'farklı ürün',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: isSmallScreen ? 8 : 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(width: isSmallScreen ? 6 : 8),

                          // En Çok Satan
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade300,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 10 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                      SizedBox(width: isSmallScreen ? 3 : 4),
                                      Expanded(
                                        child: Text(
                                          'En Çok Satan',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: isSmallScreen ? 9 : 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    '${topProducts.isNotEmpty ? topProducts.first['totalQuantity'] : 0}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    topProducts.isNotEmpty
                                        ? (topProducts.first['productName']
                                                    .length >
                                                6
                                            ? '${topProducts.first['productName'].substring(0, 6)}...'
                                            : topProducts.first['productName'])
                                        : 'Ürün yok',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: isSmallScreen ? 8 : 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // En Çok Satan Ürünler Listesi
                      _buildModernProductList(
                          products, totalQuantity, isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kısmi bütçe görünümü (sadece firma ödemeleri)
  Widget _buildPartialBudgetView(List<CompanySummary> companies) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Firma Bazlı Ödemeler Başlık
          Row(
            children: [
              Text(
                'Firma Ödemeleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                'Toplam ${companies.length} firma',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Firma Kartları
          _buildCompanyCards(companies),
        ],
      ),
    );
  }

  // Yetkisiz erişim görünümü
  Widget _buildNoAccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Bütçe Bilgilerine Erişim Yetkisi Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu sayfayı görüntülemek için yetki almanız gerekiyor.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Tarih aralığı seçici modalı
  void _showDateRangeModal(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 400,
              maxHeight: isSmallScreen ? 500 : 450,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                      topRight: Radius.circular(isSmallScreen ? 16 : 20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                        ),
                        child: Icon(
                          Icons.date_range_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analiz Dönemi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tarih aralığını seçin',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      children: [
                        // Hızlı seçim butonları
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickDateButton(
                                'Son 7 Gün',
                                Icons.looks_one_rounded,
                                () {
                                  setState(() {
                                    _endDate = DateTime.now();
                                    _startDate = _endDate!
                                        .subtract(const Duration(days: 7));
                                  });
                                  Navigator.of(context).pop();
                                },
                                isSmallScreen,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: _buildQuickDateButton(
                                'Son 30 Gün',
                                Icons.looks_two_rounded,
                                () {
                                  setState(() {
                                    _endDate = DateTime.now();
                                    _startDate = _endDate!
                                        .subtract(const Duration(days: 30));
                                  });
                                  Navigator.of(context).pop();
                                },
                                isSmallScreen,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickDateButton(
                                'Son 3 Ay',
                                Icons.looks_3_rounded,
                                () {
                                  setState(() {
                                    _endDate = DateTime.now();
                                    _startDate = _endDate!
                                        .subtract(const Duration(days: 90));
                                  });
                                  Navigator.of(context).pop();
                                },
                                isSmallScreen,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: _buildQuickDateButton(
                                'Tüm Zamanlar',
                                Icons.all_inclusive_rounded,
                                () {
                                  setState(() {
                                    _startDate = DateTime(2020);
                                    _endDate = DateTime.now();
                                  });
                                  Navigator.of(context).pop();
                                },
                                isSmallScreen,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 20 : 24),

                        // Özel tarih seçimi başlığı
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16),
                              child: Text(
                                'Özel Tarih Aralığı',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Özel tarih seçiciler
                        Row(
                          children: [
                            Expanded(
                              child: _buildModalDateButton('Başlangıç Tarihi',
                                  _startDate, true, isSmallScreen),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: _buildModalDateButton('Bitiş Tarihi',
                                  _endDate, false, isSmallScreen),
                            ),
                          ],
                        ),

                        Spacer(),

                        // Uygula butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.check_rounded,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            label: Text(
                              'Filtrele',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 10 : 12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hızlı tarih seçim butonu
  Widget _buildQuickDateButton(
      String label, IconData icon, VoidCallback onTap, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: isSmallScreen ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal içindeki tarih butonu
  Widget _buildModalDateButton(
      String label, DateTime? date, bool isStartDate, bool isSmallScreen) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedDate != null) {
          setState(() {
            if (isStartDate) {
              _startDate = selectedDate;
            } else {
              _endDate = selectedDate;
            }
          });
        }
      },
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(
            color: date != null
                ? AppTheme.primaryColor.withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: date != null
                      ? AppTheme.primaryColor
                      : Colors.grey.shade500,
                  size: isSmallScreen ? 16 : 18,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  date != null
                      ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                      : 'Tarih seçin',
                  style: TextStyle(
                    color: date != null
                        ? AppTheme.textPrimaryColor
                        : Colors.grey.shade500,
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modern Ürün Listesi
  Widget _buildModernProductList(
    List<Map<String, dynamic>> products,
    int totalQuantity,
    bool isSmallScreen,
  ) {
    // En çok satan 10 ürünü al
    final topProducts = products.take(10).toList();

    // Renk paleti
    final List<Color> pieColors = [
      const Color(0xFF5D43FB), // Mor
      const Color(0xFF4285F4), // Mavi
      const Color(0xFF00BCD4), // Cam göbeği
      const Color(0xFF00D287), // Yeşil
      const Color(0xFFFFCC00), // Sarı
      const Color(0xFFFF9800), // Turuncu
      const Color(0xFFFF5252), // Kırmızı
      const Color(0xFF9C27B0), // Mor tonları
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
    ];

    return Column(
      children: [
        // Başlık
        Row(
          children: [
            Text(
              'En Çok Satan Ürünler',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Text(
                'TOP ${topProducts.length}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Kompakt ürün listesi
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final percentage =
                  (product['totalQuantity'] / totalQuantity) * 100;
              final isLast = index == topProducts.length - 1;

              return Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    // Rank badge - daha küçük
                    Container(
                      width: isSmallScreen ? 24 : 28,
                      height: isSmallScreen ? 24 : 28,
                      decoration: BoxDecoration(
                        color: pieColors[index % pieColors.length],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: isSmallScreen ? 10 : 12),

                    // Ürün bilgisi
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['productName'],
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 3),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 6,
                                  vertical: isSmallScreen ? 1 : 2,
                                ),
                                decoration: BoxDecoration(
                                  color: pieColors[index % pieColors.length]
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 4 : 6),
                                ),
                                child: Text(
                                  product['category'],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 9 : 11,
                                    color: pieColors[index % pieColors.length],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (product['firmaCount'] > 0) ...[
                                SizedBox(width: isSmallScreen ? 4 : 6),
                                Icon(
                                  Icons.business_rounded,
                                  size: isSmallScreen ? 10 : 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '${product['firmaCount']}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 9 : 11,
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: isSmallScreen ? 8 : 12),

                    // Progress bar
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '%${percentage.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Stack(
                            children: [
                              Container(
                                height: isSmallScreen ? 4 : 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 2 : 3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: isSmallScreen ? 4 : 6,
                                  decoration: BoxDecoration(
                                    color: pieColors[index % pieColors.length],
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 2 : 3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: isSmallScreen ? 8 : 12),

                    // Adet bilgisi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product['totalQuantity']}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: pieColors[index % pieColors.length],
                          ),
                        ),
                        Text(
                          'adet',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Ürün açıklama satırları - Modern tasarım
  List<Widget> _buildLegendItems(
    List<Map<String, dynamic>> products,
    List<Color> colors,
    bool isSmallScreen,
  ) {
    return List<Widget>.generate(
      products.length > 5 ? 5 : products.length, // İlk 5 ürünü göster
      (index) {
        final product = products[index];
        final color = colors[index % colors.length];

        return Padding(
          padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
          child: Row(
            children: [
              // Renk göstergesi - Modern
              Container(
                width: isSmallScreen ? 14 : 16,
                height: isSmallScreen ? 14 : 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),

              // Ürün adı
              Expanded(
                child: Text(
                  product['productName'],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Adet bilgisi - Modern tasarım
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${product['totalQuantity']} adet',
                      style: TextStyle(
                        color: color,
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 2 : 3),
                    Icon(Icons.arrow_forward_ios,
                        color: color, size: isSmallScreen ? 8 : 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Ürün satış kartı - Modern tasarım
  Widget _buildProductSalesCard(
      Map<String, dynamic> product, Color cardColor, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Row(
          children: [
            // Ürün kategorisi ikonu - Modern tasarım
            Container(
              width: isSmallScreen ? 40 : 50,
              height: isSmallScreen ? 40 : 50,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(product['category']),
                  color: cardColor,
                  size: isSmallScreen ? 18 : 24,
                ),
              ),
            ),

            SizedBox(width: isSmallScreen ? 8 : 12),

            // Ürün bilgileri - Modern layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['productName'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 13 : 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 6 : 8),
                        ),
                        child: Text(
                          '${product['totalQuantity']} adet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 3 : 4),

                  Text(
                    product['category'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 6 : 8),

                  // Firma bilgileri - Modern tasarım
                  Text(
                    '${product['firmaCount']} farklı firma tarafından sipariş edildi',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),

                  if (product['firmaCounts'] != null &&
                      product['firmaCounts'].isNotEmpty)
                    SizedBox(height: isSmallScreen ? 6 : 8),

                  if (product['firmaCounts'] != null &&
                      product['firmaCounts'].isNotEmpty)
                    Wrap(
                      spacing: isSmallScreen ? 4 : 8,
                      runSpacing: isSmallScreen ? 2 : 4,
                      children: product['firmaCounts']
                          .entries
                          .take(3)
                          .map<Widget>(
                            (entry) => _buildFirmaChip(
                              entry.key,
                              entry.value,
                              cardColor,
                              isSmallScreen,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Firma etiketi (chip) - Modern tasarım
  Widget _buildFirmaChip(
      String firmaName, int adet, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            firmaName,
            style: TextStyle(
              fontSize: isSmallScreen ? 8 : 10,
              color: color.withOpacity(0.8),
            ),
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 1 : 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 1 : 2),
            ),
            child: Text(
              '$adet adet',
              style: TextStyle(
                fontSize: isSmallScreen ? 7 : 8,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kategori ikonunu belirle
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.cake;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'pastalar':
        return Icons.cake_outlined;
      case 'kurabiyeler':
        return Icons.cookie_outlined;
      case 'şerbetli tatlılar':
        return Icons.local_drink_outlined;
      default:
        return Icons.restaurant;
    }
  }

  // Ödeme bildirimi gönder
  Future<void> _sendPaymentNotifications(
      BuildContext context, List<CompanySummary> companies) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Ödemesi olan firmaları filtrele
    final companiesWithPendingPayments =
        companies.where((company) => company.pendingAmount > 0).toList();

    if (companiesWithPendingPayments.isEmpty) {
      // Ödemesi olan firma yoksa uyarı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Bekleyen ödemesi olan firma bulunmuyor.'),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Modern Onay Diyaloğu
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? double.infinity : 420,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Başlık Bölümü
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 20 : 24,
                  isSmallScreen ? 20 : 24,
                  isSmallScreen ? 20 : 24,
                  isSmallScreen ? 16 : 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 20 : 24),
                    topRight: Radius.circular(isSmallScreen ? 20 : 24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 10 : 12),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ödeme Bildirimi',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Hatırlatma mesajı gönder',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // İçerik Bölümü
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bekleyen ödemesi olan ${companiesWithPendingPayments.length} firmaya ödeme hatırlatma bildirimi gönderilecek.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade50,
                            Colors.orange.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 12 : 16),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 6 : 8),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.orange.shade700,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 10),
                              Text(
                                'Bildirim Detayları',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 12),
                          ...companiesWithPendingPayments.take(3).map(
                                (company) => Container(
                                  margin: EdgeInsets.only(
                                      bottom: isSmallScreen ? 6 : 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 10,
                                    vertical: isSmallScreen ? 4 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 6 : 8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.store_rounded,
                                        size: isSmallScreen ? 12 : 14,
                                        color: Colors.orange.shade600,
                                      ),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Text(
                                        company.company.name,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 4 : 6,
                                          vertical: isSmallScreen ? 2 : 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade600,
                                          borderRadius: BorderRadius.circular(
                                              isSmallScreen ? 4 : 6),
                                        ),
                                        child: Text(
                                          '₺${company.pendingAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          if (companiesWithPendingPayments.length > 3)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 6 : 8),
                              ),
                              child: Text(
                                '... ve ${companiesWithPendingPayments.length - 3} firma daha',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  color: Colors.orange.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 24),
                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              foregroundColor: Colors.grey.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 10 : 12),
                              ),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 10 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 10 : 12),
                                onTap: () => Navigator.of(context).pop(true),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: isSmallScreen ? 16 : 18,
                                      ),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Text(
                                        'Gönder',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
    );

    if (confirm != true) return;

    // Modern Loading Diyaloğu
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSmallScreen ? 60 : 80,
                height: isSmallScreen ? 60 : 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 30 : 40),
                ),
                child: Center(
                  child: SizedBox(
                    width: isSmallScreen ? 30 : 40,
                    height: isSmallScreen ? 30 : 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: isSmallScreen ? 3 : 4,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'Bildirimler Gönderiliyor',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                'Lütfen bekleyin...',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Her ödemesi olan firma için ayrı bildirim gönder
      int successCount = 0;
      int failureCount = 0;

      for (CompanySummary company in companiesWithPendingPayments) {
        try {
          final result = await NotificationService.sendPaymentReminder(
            companyId: company.company.name,
            title: '💳 Ödeme Hatırlatması',
            body:
                'Bekleyen ödemeniz bulunmaktadır: ₺${company.pendingAmount.toStringAsFixed(2)}. Ödeme yapmak için uygulamayı kontrol edin.',
            pendingAmount: company.pendingAmount,
          );

          if (result != null && result['success'] == true) {
            successCount++;
            print(
                '✅ ${company.company.name} firmasına bildirim gönderildi - ${result['successCount']} başarılı');
          } else {
            failureCount++;
            print(
                '❌ ${company.company.name} firmasına bildirim gönderilemedi: ${result?['message'] ?? 'Bilinmeyen hata'}');
          }
        } catch (e) {
          failureCount++;
          print(
              '❌ ${company.company.name} firmasına bildirim gönderilemedi: $e');
        }
      }

      // Loading diyaloğunu kapat
      Navigator.of(context).pop();

      // Sonuç mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                successCount > 0 ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  successCount > 0
                      ? '✅ ${successCount} firmaya bildirim gönderildi${failureCount > 0 ? ', ${failureCount} başarısız' : ''}'
                      : '❌ Bildirim gönderilemedi (${failureCount} hata)',
                ),
              ),
            ],
          ),
          backgroundColor:
              successCount > 0 ? Colors.green.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 4),
        ),
      );

      print(
          '📊 Bildirim özeti: ${successCount} başarılı, ${failureCount} başarısız');
    } catch (e) {
      // Loading diyaloğunu kapat
      Navigator.of(context).pop();

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child:
                    Text('Bildirim gönderilirken hata oluştu: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      print('❌ Bildirim gönderme genel hatası: $e');
    }
  }
}
