import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/home/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final financialSummary = orderProvider.financialSummary;
    final companies = orderProvider.companySummaries;
    final productSummaries = orderProvider.dailyProductSummary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bütçe & Finansal Durum',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            onPressed: () {
              orderProvider.loadOrders();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
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
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  tabs: const [
                    Tab(text: 'Genel Durum & Ödemeler'),
                    Tab(text: 'Ürün Satış Analizi'),
                  ],
                ),
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Genel Durum & Ödemeler Sekmesi
                  _buildFinancialTab(financialSummary, companies),

                  // Ürün Satış Analizi Sekmesi
                  _buildProductSalesTab(productSummaries.values.toList()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomAppBar(
          height: 70,
          padding: EdgeInsets.zero,
          elevation: 0,
          notchMargin: 10,
          shape: const CircularNotchedRectangle(),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Ana Sayfa'),
              _buildNavItem(
                context,
                1,
                Icons.receipt_long_rounded,
                'Siparişler',
              ),
              const SizedBox(width: 40), // FAB için boşluk
              _buildNavItem(
                context,
                3,
                Icons.restaurant_menu_rounded,
                'Ürünler',
              ),
              _buildNavItem(
                context,
                4,
                Icons.analytics_rounded,
                'Bütçe',
                isActive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation Item
  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData iconData,
    String label, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          // Ana ekrana dön ve ilgili sekmeyi seç
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      HomeScreen(initialIndex: index, skipLoading: true),
            ),
          );
        }
      },
      customBorder: const CircleBorder(),
      splashColor: AppTheme.primaryColor.withOpacity(0.1),
      highlightColor: AppTheme.primaryColor.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 50,
        width: 65,
        decoration: BoxDecoration(
          color:
              isActive
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color:
                  isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
              size: isActive ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondaryColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Floating Action Button
  Widget _buildFloatingActionButton() {
    return Container(
      height: 64,
      width: 64,
      margin: const EdgeInsets.only(top: 25),
      child: FloatingActionButton(
        heroTag: 'budget_screen_fab',
        onPressed: () {
          // Yeni işlem ekle
        },
        elevation: 2,
        highlightElevation: 5,
        backgroundColor: AppTheme.primaryColor,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withBlue(255).withRed(60),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  // Genel durum ve ödemeler sekmesi
  Widget _buildFinancialTab(
    FinancialSummary? financialSummary,
    List<CompanySummary> companies,
  ) {
    if (financialSummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genel Finansal Özet Kartları
          _buildBudgetSummaryCards(financialSummary),

          const SizedBox(height: 24),

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

  // Genel özet kartları
  Widget _buildBudgetSummaryCards(FinancialSummary summary) {
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam Bütçe',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₺${summary.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Tahsilat Miktarı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tahsil Edilen',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺${summary.collectedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
                        const Text(
                          'Bekleyen',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺${summary.pendingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
                        const Text(
                          'Tahsilat Oranı',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '%${summary.collectionRate.toStringAsFixed(1)}',
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
            ],
          ),
        ),

        const SizedBox(height: 12),

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
            const SizedBox(width: 12),
            // Ödenmiş Sipariş
            Expanded(
              child: _buildInfoCard(
                'Ödenmiş',
                summary.paidOrders.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPaid ? Colors.green.shade300 : Colors.orange.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Firma adı ve ödeme durumu
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isPaid
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                        radius: 20,
                        child: Text(
                          company.company.name.substring(0, 1),
                          style: TextStyle(
                            color:
                                isPaid
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.company.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${company.totalOrders} Sipariş',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isPaid
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPaid ? 'Tamamlandı' : 'Bekliyor',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isPaid
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${company.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${company.paidAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${company.pendingAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // İlerleme çubuğu
                  LinearProgressIndicator(
                    value: company.collectionRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid ? Colors.green : AppTheme.primaryColor,
                    ),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),

                  const SizedBox(height: 4),

                  // Tahsilat oranı
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tahsilat Oranı: %${company.collectionRate.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
              height: MediaQuery.of(context).size.height * 0.75,
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                                  const Text(
                                    'Ödeme Al',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    company.company.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Firma bilgileri
                        Row(
                          children: [
                            // Toplam Tutar
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Toplam Tutar',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₺${company.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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
                                  const Text(
                                    'Ödenmiş',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₺${company.paidAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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
                                  const Text(
                                    'Kalan Tutar',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₺${company.pendingAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tam/Kısmi Ödeme Seçimi
                          Text(
                            'Ödeme Tutarı',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isFullPayment
                                              ? AppTheme.primaryColor
                                                  .withOpacity(0.1)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isFullPayment
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          color:
                                              isFullPayment
                                                  ? AppTheme.primaryColor
                                                  : Colors.grey.shade500,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tam Ödeme',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isFullPayment
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₺${company.pendingAmount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isFullPayment
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFullPayment = false;
                                      // Tutarı kullanıcının girmesi için boş bırak
                                      amountController.text = '';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          !isFullPayment
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            !isFullPayment
                                                ? Colors.orange.shade300
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.payments_outlined,
                                          color:
                                              !isFullPayment
                                                  ? Colors.orange.shade700
                                                  : Colors.grey.shade500,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kısmi Ödeme',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                !isFullPayment
                                                    ? Colors.orange.shade700
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tutar girin',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                !isFullPayment
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

                          const SizedBox(height: 20),

                          // Tutar Girişi
                          if (!isFullPayment) ...[
                            Text(
                              'Ödeme Tutarını Girin',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Ödeme tutarı',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      '₺',
                                      style: TextStyle(
                                        fontSize: 18,
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
                            const SizedBox(height: 20),
                          ],

                          // Ödeme Yöntemi
                          Text(
                            'Ödeme Yöntemi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedPaymentMethod ==
                                                  PaymentMethod.card
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            selectedPaymentMethod ==
                                                    PaymentMethod.card
                                                ? Colors.blue
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.credit_card,
                                          color:
                                              selectedPaymentMethod ==
                                                      PaymentMethod.card
                                                  ? Colors.blue
                                                  : Colors.grey.shade500,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kart ile Ödeme',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                selectedPaymentMethod ==
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPaymentMethod =
                                          PaymentMethod.cash;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedPaymentMethod ==
                                                  PaymentMethod.cash
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            selectedPaymentMethod ==
                                                    PaymentMethod.cash
                                                ? Colors.green
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.attach_money_rounded,
                                          color:
                                              selectedPaymentMethod ==
                                                      PaymentMethod.cash
                                                  ? Colors.green
                                                  : Colors.grey.shade500,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Nakit Ödeme',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                selectedPaymentMethod ==
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

                          const SizedBox(height: 20),

                          // Ödeme Tarihi
                          Text(
                            'Ödeme Tarihi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Not
                          Text(
                            'Ödeme Notu (İsteğe Bağlı)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: noteController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: InputBorder.none,
                                hintText: 'Ödeme ile ilgili not ekleyin...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Alt Butonlar
                  Container(
                    padding: const EdgeInsets.all(20),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Ödemeyi Tamamla',
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Ödeme işleme
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
        const SnackBar(
          content: Text('Lütfen geçerli bir tutar girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tutar kalan tutardan büyükse uyarı göster
    if (amount > company.pendingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Girilen tutar kalan tutardan büyük olamaz.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ödeme bilgilerini göster ve işlem yap
    String paymentMethodText =
        paymentMethod == PaymentMethod.card ? 'Kart' : 'Nakit';

    // Diyaloğu kapat
    Navigator.pop(context);

    // Ödeme onay diyaloğunu göster
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Ödeme Onayı'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firma: ${company.company.name}'),
                const SizedBox(height: 8),
                Text('Tutar: ₺${amount.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('Ödeme Yöntemi: $paymentMethodText'),
                const SizedBox(height: 4),
                Text('Tarih: ${date.day}/${date.month}/${date.year}'),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Not:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(note),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Ödemeyi kaydet - gerçek uygulama API'ye istek atabilir
                  Navigator.pop(context);

                  // Başarılı mesaj göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '₺${amount.toStringAsFixed(2)} tutarında ödeme başarıyla alındı.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Veri yenile - gerçek uygulamada OrderProvider üzerinden yapılabilir
                  Provider.of<OrderProvider>(
                    context,
                    listen: false,
                  ).loadOrders();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Onayla'),
              ),
            ],
          ),
    );
  }

  // Ürün Satış Analizi Sekmesi
  Widget _buildProductSalesTab(List<DailyProductSummary> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Henüz ürün satış verisi bulunmuyor.'));
    }

    // Ürünleri toplam adede göre sırala
    products.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

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
      (sum, product) => sum + product.totalQuantity,
    );

    // Pasta grafik için sektör verilerini hazırla
    final List<PieChartSectionData> pieChartSections = [];
    for (int i = 0; i < topProducts.length; i++) {
      final product = topProducts[i];
      final double percentage = (product.totalQuantity / totalQuantity) * 100;

      // Her bir dilim için veri oluştur
      pieChartSections.add(
        PieChartSectionData(
          color: pieColors[i % pieColors.length],
          value: product.totalQuantity.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80, // Vurgulanmış dilim daha büyük görünecek
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          badgeWidget: _getBadge(
            product.productName,
            product.totalQuantity,
            pieColors[i % pieColors.length],
          ),
          badgePositionPercentageOffset:
              1.2, // Ürün adı etiketini dışarıya doğru konumlandır
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zenginleştirilmiş satış analizi grafiği
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Başlık bölümü
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ürün Satış Dağılımı',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toplam ${totalQuantity} adet ürün',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // İstatistik göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
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
                            const SizedBox(width: 6),
                            Text(
                              'Güncel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // İçerik - Grafik
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Grafiği yükseklik ver
                      SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            // Pasta grafik
                            PieChart(
                              PieChartData(
                                sections: pieChartSections,
                                centerSpaceRadius: 50,
                                sectionsSpace: 2,
                                startDegreeOffset: -90,
                                pieTouchData: PieTouchData(
                                  touchCallback: (
                                    FlTouchEvent event,
                                    PieTouchResponse? response,
                                  ) {
                                    // Dokunma etkileşimi eklenebilir
                                  },
                                  enabled: true,
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                              swapAnimationDuration: const Duration(
                                milliseconds: 800,
                              ),
                              swapAnimationCurve: Curves.easeInOutQuint,
                            ),

                            // Merkez içerik
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    totalQuantity.toString(),
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Toplam\nSatış',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Ürün bilgilendirme satırları
                      ..._buildLegendItems(topProducts, pieColors),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ürün satış detayları başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Text(
              'Ürün Satış Detayları',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),

          // Ürün kartları
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductSalesCard(
                product,
                pieColors[index % pieColors.length],
              );
            },
          ),
        ],
      ),
    );
  }

  // Grafik için maksimum Y değerini hesapla
  double _calculateMaxY(List<DailyProductSummary> products) {
    if (products.isEmpty) return 100;

    final maxQuantity = products.fold(
      0,
      (max, product) => math.max(max, product.totalQuantity),
    );

    // Yukarıda biraz boşluk bırakmak için %20 ekle
    return (maxQuantity * 1.2).ceilToDouble();
  }

  // Ürün bilgi rozeti
  Widget _getBadge(String productName, int quantity, Color color) {
    // Kısa ürün adı
    String shortName =
        productName.length > 6
            ? productName.substring(0, 6) + '...'
            : productName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            shortName,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Ürün açıklama satırları
  List<Widget> _buildLegendItems(
    List<DailyProductSummary> products,
    List<Color> colors,
  ) {
    return List.generate(
      math.min(products.length, 5), // İlk 5 ürünü göster
      (index) {
        final product = products[index];
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // Renk göstergesi
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),

              // Ürün adı
              Expanded(
                child: Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Adet bilgisi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${product.totalQuantity} adet',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios, color: color, size: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Ürün satış kartı
  Widget _buildProductSalesCard(DailyProductSummary product, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ürün kategorisi ikonu
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(product.category),
                  color: cardColor,
                  size: 24,
                ),
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
                          product.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.totalQuantity} adet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  // Firma bilgileri
                  Text(
                    '${product.firmaCount} farklı firma tarafından sipariş edildi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),

                  if (product.firmaCounts != null &&
                      product.firmaCounts!.isNotEmpty)
                    const SizedBox(height: 8),

                  if (product.firmaCounts != null &&
                      product.firmaCounts!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          product.firmaCounts!.entries
                              .take(3)
                              .map(
                                (entry) => _buildFirmaChip(
                                  entry.key,
                                  entry.value,
                                  cardColor,
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

  // Firma etiketi (chip)
  Widget _buildFirmaChip(String firmaName, int adet, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            firmaName,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '$adet adet',
              style: TextStyle(
                fontSize: 8,
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
}
