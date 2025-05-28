import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/order_detail_screen.dart';
import 'package:siparis/customer/widgets/customer_order_card.dart';
import 'package:siparis/widgets/status_summary_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math';

class CustomerDashboardTab extends StatefulWidget {
  const CustomerDashboardTab({super.key});

  @override
  State<CustomerDashboardTab> createState() => _CustomerDashboardTabState();
}

class _CustomerDashboardTabState extends State<CustomerDashboardTab> {
  bool _isLocaleInitialized = false;

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

    // Firebase real-time listener'ı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      // Real-time listener'ı başlat
      orderProvider.startListeningToOrders();
      print('🔥 Müşteri dashboard: Firebase listener başlatıldı');
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    // Müşteri adı - gerçek uygulamada kullanıcı bilgilerinden alınacak
    const String currentCustomerPrefix =
        'Müşteri →'; // Müşteri siparişlerinin prefix'i

    // Sadece bu müşterinin siparişlerini filtrele
    final allOrders = orderProvider.orders;
    final customerOrders = allOrders
        .where((order) =>
                order.customer.name.startsWith(currentCustomerPrefix) ||
                order.note == 'Müşteri siparişi' // Eski siparişler için
            )
        .toList();

    // Müşteri siparişlerini duruma göre ayır
    final waitingOrders = customerOrders
        .where((order) => order.status == OrderStatus.waiting)
        .toList();
    final processingOrders = customerOrders
        .where((order) => order.status == OrderStatus.processing)
        .toList();
    final completedOrders = customerOrders
        .where((order) => order.status == OrderStatus.completed)
        .toList();

    // Müşterinin aktif siparişleri
    final todayActiveOrders = [...waitingOrders, ...processingOrders];

    // Debug: Sipariş sayılarını yazdır
    print('🔍 Müşteri Dashboard Debug:');
    print('   Toplam sipariş: ${allOrders.length}');
    print('   Müşteri siparişleri: ${customerOrders.length}');
    print('   Bekleyen: ${waitingOrders.length}');
    print('   Hazırlanan: ${processingOrders.length}');
    print('   Tamamlanan: ${completedOrders.length}');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<OrderProvider>(context, listen: false)
                .loadOrders();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                floating: true,
                centerTitle: false,
                elevation: 0,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor
                                      .withBlue(255)
                                      .withRed(60),
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
                            child: const Icon(
                              Icons.dashboard_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merhaba! 👋',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Sipariş Takip',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bildirim ikonu
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Arama kutusu ve tarih
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Tarih göstergesi
                      if (_isLocaleInitialized)
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getTodayDateText(),
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Arama kutusu
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Sipariş ara...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.search_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            suffixIcon: Container(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                ),
                              ),
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                  child: _buildSummaryCard(
                    waiting: waitingOrders.length,
                    processing: processingOrders.length,
                    completed: completedOrders.length,
                  ),
                ),
              ),

              // Aktif Siparişler Başlığı
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Devam Eden Siparişlerim',
                  Icons.pending_actions_rounded,
                  Colors.blue,
                ),
              ),

              // Aktif Siparişler Listesi
              todayActiveOrders.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(
                        icon: Icons.shopping_bag_outlined,
                        message: 'Henüz devam eden siparişiniz yok',
                        actionText: 'Yeni Sipariş Ver',
                        onActionPressed: () {
                          // Ana ekrandaki FAB'a benzer işlev
                          _showNewOrderDialog();
                        },
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = todayActiveOrders[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderDetailScreen(order: order),
                                  ),
                                );
                              },
                              child: CustomerOrderCard(
                                order: order,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OrderDetailScreen(order: order),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        childCount: min(todayActiveOrders.length, 5),
                      ),
                    ),

              // Teslim Edilen Siparişler Başlığı
              if (completedOrders.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionTitle(
                    'Teslim Edilen Siparişlerim',
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
                ),

              // Son Siparişler Listesi
              if (completedOrders.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = completedOrders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          child: CustomerOrderCard(
                            order: order,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrderDetailScreen(order: order),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    childCount: min(completedOrders.length, 3),
                  ),
                ),

              // Alt boşluk
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTodayDateText() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
    return formatter.format(now);
  }

  Widget _buildSummaryCard({
    required int waiting,
    required int processing,
    required int completed,
  }) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final totalOrders = waiting + processing + completed;
    final activeOrders = waiting + processing;

    // Hazırlanıyor durumundaki ürünleri al
    final processingProducts = orderProvider.processingOrders
        .expand((order) => order.items)
        .map((item) => item.product.name)
        .take(3)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withBlue(255).withRed(60),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kompakt başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sipariş Özeti',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$totalOrders Toplam • $activeOrders Aktif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Kompakt durum kartları
            Row(
              children: [
                Expanded(
                  child: _buildCompactSummaryItem(
                    'Bekliyor',
                    waiting.toString(),
                    Colors.orange,
                    Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildCompactSummaryItem(
                    'Hazırlanıyor',
                    processing.toString(),
                    Colors.blue,
                    Icons.construction_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildCompactSummaryItem(
                    'Tamamlandı',
                    completed.toString(),
                    Colors.green,
                    Icons.check_circle_rounded,
                  ),
                ),
              ],
            ),

            // Hazırlanıyor ürünleri (varsa)
            if (processingProducts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.construction_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Şu an hazırlanıyor:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: processingProducts
                          .map((product) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
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

  Widget _buildCompactSummaryItem(
      String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSummaryItem(String title, String count, Color color,
      IconData icon, double percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // İkon ve sayı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Başlık
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Siparişlerinizi takip edin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni siparişler burada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (actionText != null && onActionPressed != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withBlue(255).withRed(60),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_shopping_cart, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      actionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNewOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Sipariş'),
          content: const Text(
              'Yeni sipariş oluşturmak için ürünler sekmesinden istediğiniz ürünleri seçebilirsiniz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Ana ekrandaki tab değiştirme işlemi burada yapılacak
              },
              child: const Text('Ürünlere Git'),
            ),
          ],
        );
      },
    );
  }
}
