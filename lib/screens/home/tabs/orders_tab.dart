import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/order_detail_screen.dart';
import 'package:siparis/widgets/order_list_item.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Text(
                  'Siparişler',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textPrimaryColor,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    // Arama ekranını aç
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    // Filtre ekranını aç
                  },
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade50,
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 600 ? 10 : 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorPadding: const EdgeInsets.all(4),
              tabs: MediaQuery.of(context).size.width < 600
                  ? [
                      const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Bekleyen'),
                        ),
                      ),
                      const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Hazırlanıyor'),
                        ),
                      ),
                      const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Tamamlanan'),
                        ),
                      ),
                    ]
                  : [
                      const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Bekleyen'),
                        ),
                      ),
                      const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Hazırlanıyor'),
                        ),
                      ),
                      const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Tamamlanan'),
                        ),
                      ),
                    ],
            ),
          ),

          // Tab İçeriği
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Bekleyen Siparişler
                OrderListView(
                  orders: orderProvider.waitingOrders,
                  emptyMessage: 'Bekleyen sipariş bulunmuyor.',
                ),

                // Hazırlanan Siparişler
                OrderListView(
                  orders: orderProvider.processingOrders,
                  emptyMessage: 'Hazırlanmakta olan sipariş bulunmuyor.',
                ),

                // Tamamlanan Siparişler
                OrderListView(
                  orders: orderProvider.completedOrders,
                  emptyMessage: 'Tamamlanan sipariş bulunmuyor.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderListView extends StatelessWidget {
  final List<Order> orders;
  final String emptyMessage;

  const OrderListView({
    super.key,
    required this.orders,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.textLightColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: OrderListItem(
            order: order,
            onStatusChanged: (newStatus) async {
              // Context'i sakla
              final orderContext = context;

              try {
                await orderProvider.updateOrderStatus(order.id, newStatus);

                // Başarı mesajı göster
                if (orderContext.mounted) {
                  ScaffoldMessenger.of(orderContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                              'Sipariş durumu güncellendi: ${Order.getStatusText(newStatus)}'),
                        ],
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('❌ OrdersTab buton hatası: $e');

                // Hata mesajı göster
                if (orderContext.mounted) {
                  ScaffoldMessenger.of(orderContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child:
                                Text('Güncelleme başarısız: ${e.toString()}'),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: order),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
