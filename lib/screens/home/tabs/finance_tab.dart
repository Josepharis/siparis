import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/widgets/company_finance_card.dart';
import 'package:siparis/widgets/finance_summary_card.dart';

class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab>
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

    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Finansal Takip',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                // Tarih filtresi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bu Ay',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Yenile butonu
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    // Verileri yenile
                    orderProvider.loadOrders();
                  },
                ),
              ],
            ),
          ),

          // Finansal Özet
          if (financialSummary != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FinanceSummaryCard(
                totalAmount: financialSummary.totalAmount,
                collectedAmount: financialSummary.collectedAmount,
                pendingAmount: financialSummary.pendingAmount,
                collectionRate: financialSummary.collectionRate,
              ),
            ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              tabs: const [
                Tab(text: 'Firma Ödemeleri'),
                Tab(text: 'Ödeme Durumu'),
              ],
            ),
          ),

          // Tab İçeriği
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Firma Ödemeleri
                _buildCompanyList(companies),

                // Ödeme Durumu
                _buildPaymentStatusList(orderProvider.orders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyList(List<CompanySummary> companies) {
    if (companies.isEmpty) {
      return const Center(child: Text('Henüz firma bulunmuyor.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CompanyFinanceCard(
            company: company,
            onTap: () {
              // Firma finansal detaylarını göster
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentStatusList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('Henüz sipariş bulunmuyor.'));
    }

    // Ödenmiş ve ödenmemiş siparişleri grupla
    final paidOrders =
        orders
            .where((order) => order.paymentStatus == PaymentStatus.paid)
            .toList();
    final unpaidOrders =
        orders
            .where((order) => order.paymentStatus != PaymentStatus.paid)
            .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Alt tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                labelColor: AppTheme.textPrimaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                tabs: [
                  Tab(text: 'Ödenmemiş (${unpaidOrders.length})'),
                  Tab(text: 'Ödenmiş (${paidOrders.length})'),
                ],
              ),
            ),
          ),

          // İçerik
          Expanded(
            child: TabBarView(
              children: [
                // Ödenmemiş siparişler
                _buildOrderList(unpaidOrders, isUnpaid: true),

                // Ödenmiş siparişler
                _buildOrderList(paidOrders, isUnpaid: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {required bool isUnpaid}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isUnpaid
              ? 'Ödenmemiş sipariş bulunmuyor.'
              : 'Ödenmiş sipariş bulunmuyor.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor:
                  isUnpaid ? Colors.orange.shade100 : Colors.green.shade100,
              child: Text(
                order.customer.name.substring(0, 1),
                style: TextStyle(
                  color: isUnpaid ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              order.customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Sipariş #${order.id.substring(0, 4)}'),
                const SizedBox(height: 4),
                Text(
                  '${order.deliveryDate.day} ${_getMonthName(order.deliveryDate.month)} ${order.deliveryDate.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isUnpaid
                            ? AppTheme.primaryColor
                            : AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isUnpaid
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isUnpaid ? 'Ödenmedi' : 'Tamamlandı',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isUnpaid
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              // Sipariş detayını göster
            },
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }
}
