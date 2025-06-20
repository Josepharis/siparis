import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/order_detail_screen.dart';
import 'package:siparis/screens/product_detail_screen.dart';
import 'package:siparis/widgets/daily_product_card.dart';
import 'package:siparis/widgets/order_card.dart';
import 'package:siparis/widgets/status_summary_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math'; // min fonksiyonu için eklendi
import 'package:siparis/screens/all_daily_products_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLocaleInitialized = false;
  String _selectedSortOption = 'Yakın Teslimat'; // Varsayılan sıralama

  @override
  void initState() {
    super.initState();

    // Türkçe tarih formatını başlat
    initializeDateFormatting('tr_TR').then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final waitingOrders = orderProvider.waitingOrders;
    final processingOrders = orderProvider.processingOrders;
    final completedOrders = orderProvider.completedOrders;
    final dailyProducts = orderProvider.dailyProductSummary;

    // Bugünün tarihini hesapla
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Bugüne ait aktif siparişleri filtrele
    final todayActiveOrders =
        [...waitingOrders, ...processingOrders].where((order) {
      final orderDeliveryDate = DateTime(
        order.deliveryDate.year,
        order.deliveryDate.month,
        order.deliveryDate.day,
      );
      return orderDeliveryDate.isAtSameMomentAs(today);
    }).toList();

    // Sıralama uygula
    _applySorting(todayActiveOrders);

    // Bugünün sipariş durumlarını hesapla
    final todayWaitingOrders = todayActiveOrders
        .where((order) => order.status == OrderStatus.waiting)
        .length;
    final todayProcessingOrders = todayActiveOrders
        .where((order) => order.status == OrderStatus.processing)
        .length;

    // Bugün tamamlanan siparişleri de hesapla
    final todayCompletedOrders = completedOrders.where((order) {
      final orderDeliveryDate = DateTime(
        order.deliveryDate.year,
        order.deliveryDate.month,
        order.deliveryDate.day,
      );
      return orderDeliveryDate.isAtSameMomentAs(today);
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar - Tamamen yeniden tasarlandı
            SliverAppBar(
              backgroundColor: Colors.white,
              pinned: true,
              floating: true,
              centerTitle: false,
              elevation: 0,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sipariş Paneli',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arama kutusu - Ayrı bir SliverToBoxAdapter olarak taşındı
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    // Tarih göstergesi
                    if (_isLocaleInitialized)
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _getTodayDateText(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Özet Bilgi Kartı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: _buildSummaryCard(
                  waiting: todayWaitingOrders,
                  processing: todayProcessingOrders,
                  completed: todayCompletedOrders,
                ),
              ),
            ),

            // Günlük Üretilecekler Başlığı
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                'Günlük Üretilecekler',
                Icons.bakery_dining_rounded,
                Colors.orange,
                trailing: dailyProducts.isNotEmpty
                    ? GestureDetector(
                        onTap: () =>
                            _showAllDailyProducts(context, dailyProducts),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 600
                                ? 8
                                : 12,
                            vertical:
                                MediaQuery.of(context).size.width < 600 ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width < 600
                                    ? 12
                                    : 20),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                MediaQuery.of(context).size.width < 600
                                    ? 'Tümü'
                                    : 'Hepsini Gör',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.width < 600
                                          ? 10
                                          : 12,
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width < 600
                                      ? 2
                                      : 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.orange[700],
                                size: MediaQuery.of(context).size.width < 600
                                    ? 10
                                    : 12,
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // Günlük Üretilecekler Listesi
            SliverToBoxAdapter(
              child: SizedBox(
                height: 170,
                child: dailyProducts.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.bakery_dining_rounded,
                        message: 'Bugün için üretilecek ürün bulunmuyor',
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: dailyProducts.entries.length,
                        itemBuilder: (context, index) {
                          final entry = dailyProducts.entries.elementAt(
                            index,
                          );
                          final product = entry.value;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    product: product,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(
                                right: 10,
                                bottom: 4,
                                top: 4,
                              ),
                              child: Stack(
                                children: [
                                  // Ana kart
                                  Card(
                                    elevation: 3,
                                    shadowColor: _getCategoryColor(
                                      product.category,
                                    ).withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Üst renkli bölüm
                                          Container(
                                            height: 70,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  _getCategoryColor(
                                                    product.category,
                                                  ),
                                                  _getCategoryLighterColor(
                                                    product.category,
                                                  ),
                                                ],
                                                stops: const [0.2, 1.0],
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Dekoratif öğeler
                                                Positioned(
                                                  right: -20,
                                                  top: -20,
                                                  child: Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: -15,
                                                  bottom: -15,
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),

                                                // Kategori ikonu
                                                Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      10,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                            0.1,
                                                          ),
                                                          blurRadius: 6,
                                                          spreadRadius: 0,
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      _getCategoryIcon(
                                                        product.category,
                                                      ),
                                                      color: Colors.white,
                                                      size: 28,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                            0.2,
                                                          ),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Alt bilgi bölümü
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(
                                                6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(14),
                                                  bottomRight:
                                                      Radius.circular(14),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    product.productName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        _getCategorySmallIcon(
                                                          product.category,
                                                        ),
                                                        size: 10,
                                                        color:
                                                            _getCategoryColor(
                                                          product.category,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 3,
                                                      ),
                                                      Text(
                                                        product.category,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 10,
                                                        ),
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
                                  ),

                                  // Miktar göstergesi
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            Colors.white.withOpacity(0.9),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${product.totalQuantity}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _getCategoryColor(
                                              product.category,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Aktif Siparişler Başlığı
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                'Bugünün Siparişleri',
                Icons.receipt_rounded,
                AppTheme.primaryColor,
                trailing: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen =
                        MediaQuery.of(context).size.width < 600;

                    if (isSmallScreen) {
                      // Küçük ekranlar için kompakt tasarım
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Sıralama butonu - kompakt
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSortOption =
                                    _selectedSortOption == 'Yakın Teslimat'
                                        ? 'Uzak Teslimat'
                                        : 'Yakın Teslimat';
                                // Sıralamayı hemen uygula
                                _applySorting(todayActiveOrders);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedSortOption == 'Yakın Teslimat'
                                        ? Icons.north_rounded
                                        : Icons.south_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    _selectedSortOption == 'Yakın Teslimat'
                                        ? 'Yakın'
                                        : 'Uzak',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          // Sipariş sayısı
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${todayActiveOrders.length}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Büyük ekranlar için orijinal tasarım
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Sıralama dropdown'ı
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedSortOption,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.sort_rounded,
                                color: AppTheme.primaryColor,
                                size: 16,
                              ),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Yakın Teslimat',
                                  child: Text('Yakın Teslimat'),
                                ),
                                DropdownMenuItem(
                                  value: 'Uzak Teslimat',
                                  child: Text('Uzak Teslimat'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedSortOption = value;
                                    // Sıralamayı hemen uygula
                                    _applySorting(todayActiveOrders);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sipariş sayısı
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '${todayActiveOrders.length} Sipariş',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),

            // Sipariş Listesi
            todayActiveOrders.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(
                      icon: Icons.receipt_long_rounded,
                      message: 'Bugün için aktif sipariş bulunmuyor',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final order = todayActiveOrders[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                          child: _buildOrderCard(context, order, orderProvider),
                        );
                      }, childCount: todayActiveOrders.length),
                    ),
                  ),

            // Alt Boşluk
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_tab_fab',
        backgroundColor: AppTheme.primaryColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () {
          orderProvider.loadOrders();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bilgiler yenilendi',
                style: TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  // Özet bilgi kartı - şık tasarım
  Widget _buildSummaryCard({
    required int waiting,
    required int processing,
    required int completed,
  }) {
    final totalOrders = waiting + processing + completed;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: EdgeInsets.zero, // Kenar boşluklarını kaldır
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.blueGrey.withOpacity(0.2),
      child: Container(
        width: double.infinity, // Tam genişlik kullan
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2), // Daha canlı mavi
              Color(0xFF039BE5), // Parlak turkuaz mavi
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Üst başlık kısmı - şık ayraç tasarımı ile
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 10 : 14,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 10 : 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Text(
                    'Günlük Sipariş Özeti',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 10,
                        vertical: isSmallScreen ? 3 : 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: isSmallScreen ? 12 : 14,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          '$totalOrders Sipariş',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ana içerik - yeniden düzenlenmiş durum kartları
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 6 : 8,
                  isSmallScreen ? 8 : 12,
                  isSmallScreen ? 6 : 8,
                  isSmallScreen ? 8 : 12),
              child: Row(
                children: [
                  _buildStatusCard(
                    'Bekleyen',
                    waiting,
                    totalOrders,
                    Colors.amber[400]!, // Daha canlı amber
                    Icons.hourglass_empty_rounded,
                  ),
                  _buildStatusCard(
                    'Hazırlanıyor',
                    processing,
                    totalOrders,
                    Colors.orange[500]!, // Daha canlı turuncu
                    Icons.sync_rounded,
                  ),
                  _buildStatusCard(
                    'Tamamlanan',
                    completed,
                    totalOrders,
                    Colors.greenAccent[400]!, // Canlı yeşil-turkuaz
                    Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Şık durum kartı
  Widget _buildStatusCard(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Expanded(
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
        elevation: 0,
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          constraints: BoxConstraints(
            minHeight: isSmallScreen ? 80 : 100,
            minWidth: 0,
          ),
          padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon ve sayaç
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(icon, color: color, size: isSmallScreen ? 10 : 12),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      minWidth: isSmallScreen ? 20 : 25,
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 6 : 8),

              // Etiket
              Container(
                constraints: BoxConstraints(
                  minHeight: isSmallScreen ? 12 : 15,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: isSmallScreen ? 4 : 6),

              // Mini ilerleme çubuğu
              Container(
                height: 4,
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                ),
                child: Stack(
                  children: [
                    // Arkaplan
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Değer
                    if (percentage > 0)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 4,
                            width: (percentage / 100) * constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 4 : 6),

              // Yüzde göstergesi
              Container(
                constraints: BoxConstraints(
                  minHeight: isSmallScreen ? 10 : 12,
                ),
                child: Text(
                  '%${percentage.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: isSmallScreen ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sipariş kartı - Kompakt Modern Tasarım
  Widget _buildOrderCard(
    BuildContext context,
    Order order,
    OrderProvider orderProvider,
  ) {
    final textTheme = Theme.of(context).textTheme;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (order.status) {
      case OrderStatus.waiting:
        statusColor = Colors.amber;
        statusIcon = Icons.pending_outlined;
        statusText = 'Bekliyor';
        break;
      case OrderStatus.processing:
        statusColor = Colors.orange[700]!;
        statusIcon = Icons.sync_rounded;
        statusText = 'Hazırlanıyor';
        break;
      case OrderStatus.completed:
        statusColor = Colors.green[600]!;
        statusIcon = Icons.task_alt;
        statusText = 'Tamamlandı';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = 'Bilinmiyor';
    }

    // Ürün sayısını daha anlamlı göstermek için
    final String productCountText =
        order.items.length > 1 ? '${order.items.length} ürün' : '1 ürün';

    // Teslimat tarihinden kalan gün sayısı
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

    final bool isUrgent = daysLeft <= 1;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: statusColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.6), width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: statusColor.withOpacity(0.1),
        highlightColor: statusColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Avatar ve durum indikatörü
              Stack(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        order.customer.name.isNotEmpty
                            ? order.customer.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Durum göstergesi
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Sipariş bilgileri - Genişletildi
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Müşteri adı
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customer.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Ürün özeti ve tarih
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${order.items.map((item) => item.product.name).join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Alt bilgi çipleri - Daha kompakt
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.shopping_bag_outlined,
                          productCountText,
                          Colors.purple[700]!,
                        ),
                        const SizedBox(width: 6),
                        _buildInfoChip(
                          Icons.payments_outlined,
                          '${order.totalAmount.toStringAsFixed(0)} ₺',
                          Colors.green[700]!,
                        ),
                        const SizedBox(width: 6),
                        _buildTimeChip(timeIndicator, isUrgent),
                      ],
                    ),
                  ],
                ),
              ),

              // Durum etiketi ve durum değiştirme butonları
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Durum etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Durum değiştirme butonları
                  if (order.status != OrderStatus.completed &&
                      order.status != OrderStatus.cancelled) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İlerleme butonu
                        InkWell(
                          onTap: () async {
                            // Context'i sakla
                            final buttonContext = context;

                            try {
                              await orderProvider.updateOrderStatus(
                                order.id,
                                order.status == OrderStatus.waiting
                                    ? OrderStatus.processing
                                    : OrderStatus.completed,
                              );

                              // Başarı mesajı göster
                              if (buttonContext.mounted) {
                                ScaffoldMessenger.of(buttonContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('Sipariş durumu güncellendi'),
                                      ],
                                    ),
                                    backgroundColor:
                                        order.status == OrderStatus.waiting
                                            ? Colors.orange.shade600
                                            : Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('❌ Dashboard buton hatası: $e');

                              // Hata mesajı göster
                              if (buttonContext.mounted) {
                                ScaffoldMessenger.of(buttonContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                              'Güncelleme başarısız: ${e.toString()}'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: order.status == OrderStatus.waiting
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.status == OrderStatus.waiting
                                      ? Icons.play_arrow_rounded
                                      : Icons.check_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  order.status == OrderStatus.waiting
                                      ? 'Hazırla'
                                      : 'Tamamla',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bilgi çipi widget'ı - daha küçük
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Zaman çipi widget'ı
  Widget _buildTimeChip(String label, bool isUrgent) {
    final color = isUrgent ? Colors.red[700]! : Colors.blue[700]!;
    final icon = isUrgent ? Icons.hourglass_top : Icons.calendar_today_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Üst başlık bölümü - Artık kullanılmıyor, SliverAppBar title kısmına taşındı
  Widget _buildHeader(BuildContext context) {
    return Container(color: Colors.white);
  }

  // Bölüm başlığı oluşturma
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Boş durum gösterimi
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[500], size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Tarih formatını oluşturma
  String _getTodayDateText() {
    if (!_isLocaleInitialized) return '';

    final now = DateTime.now();
    final formatter = DateFormat.yMMMMEEEEd('tr_TR');
    return formatter.format(now);
  }

  // Kategori rengini döndürme
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Colors.pink[300]!;
      case 'hamur işleri':
        return Colors.amber[400]!;
      case 'kurabiyeler':
        return Colors.orange[300]!;
      case 'pastalar':
        return Colors.purple[300]!;
      default:
        return Colors.blue[300]!;
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

  // Kategori açık rengini döndürme
  Color _getCategoryLighterColor(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Colors.pink[200]!;
      case 'hamur işleri':
        return Colors.amber[300]!;
      case 'kurabiyeler':
        return Colors.orange[200]!;
      case 'pastalar':
        return Colors.purple[200]!;
      default:
        return Colors.blue[200]!;
    }
  }

  // Kategori küçük ikonunu döndürme
  IconData _getCategorySmallIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.bakery_dining;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'kurabiyeler':
        return Icons.cookie;
      case 'pastalar':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }

  void _applySorting(List<Order> orders) {
    switch (_selectedSortOption) {
      case 'Yakın Teslimat':
        orders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
        break;
      case 'Uzak Teslimat':
        orders.sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));
        break;
    }
  }

  void _showAllDailyProducts(
      BuildContext context, Map<String, DailyProductSummary> products) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllDailyProductsScreen(products: products),
      ),
    );
  }
}
