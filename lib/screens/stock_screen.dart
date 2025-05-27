import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/providers/stock_provider.dart';
// import 'package:siparis/screens/stock_detail_screen.dart'; // Stok detay sayfası için - ŞİMDİLİK YORUMDA
import 'package:siparis/theme/app_theme.dart';
import 'package:siparis/widgets/stock_add_button.dart';
import 'package:siparis/widgets/stock_card.dart';
import 'package:siparis/widgets/stock_delete_dialog.dart';
import 'package:siparis/widgets/stock_edit_dialog.dart';
import 'package:siparis/widgets/stock_filter_bar.dart';
import 'package:siparis/widgets/stock_movement_dialog.dart';
import 'package:siparis/widgets/stock_search_bar.dart';
import 'package:siparis/widgets/stock_stats_card.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında stokları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockProvider>(context, listen: false).loadStocks();
    });
  }

  void _showEditDialog(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (_) => StockEditDialog(stock: stock),
    );
  }

  void _showMovementDialog(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (_) => StockMovementDialog(stock: stock),
    );
  }

  void _showDeleteDialog(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (_) => StockDeleteDialog(stock: stock),
    );
  }

  /* // ŞİMDİLİK YORUMDA
  void _navigateToDetailScreen(BuildContext context, Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailScreen(stockId: stock.id),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Stok Yönetimi'),
        // AppBarTheme zaten AppTheme içinde tanımlı
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: () {
              Provider.of<StockProvider>(context, listen: false).loadStocks();
            },
          ),
          // Diğer eylemler (örn: dışa aktar, ayarlar) buraya eklenebilir
        ],
      ),
      body: Column(
        children: [
          // Üst Bilgi ve Arama Alanı
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.surface, // Veya AppTheme.primary.withOpacity(0.1)
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: const [
                StockStatsCard(),
                SizedBox(height: AppTheme.spacingMedium),
                StockSearchBar(),
              ],
            ),
          ),
          // Filtreleme ve Sıralama Çubuğu
          const StockFilterBar(),
          // Stok Listesi Alanı
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.stocks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.stocks.isEmpty && !provider.isLoading) {
                  return _buildEmptyState(theme, provider);
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadStocks(),
                  backgroundColor: AppTheme.primary,
                  color: AppTheme.textOnPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    itemCount: provider.stocks.length,
                    itemBuilder: (context, index) {
                      final stock = provider.stocks[index];
                      return StockCard(
                        stock: stock,
                        // onTap: () => _navigateToDetailScreen(context, stock), // ŞİMDİLİK YORUMDA
                        onTap: () => _showMovementDialog(context,
                            stock), // Geçici olarak hareket dialoğuna yönlendir
                        onEdit: () => _showEditDialog(context, stock),
                        onMovement: () => _showMovementDialog(context, stock),
                        onDelete: () => _showDeleteDialog(context, stock),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const StockAddButton(),
    );
  }

  Widget _buildEmptyState(ThemeData theme, StockProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              provider.searchQuery.isNotEmpty ||
                      provider.selectedCategory != 'Tümü' ||
                      provider.selectedStatus != null
                  ? 'Arama kriterlerinize uygun stok bulunamadı.'
                  : 'Henüz hiç stok eklenmemiş.',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            if (provider.searchQuery.isNotEmpty ||
                provider.selectedCategory != 'Tümü' ||
                provider.selectedStatus != null)
              TextButton.icon(
                icon: const Icon(Icons.filter_alt_off_outlined,
                    size: AppTheme.iconSize - 4),
                label: const Text('Filtreleri Temizle'),
                onPressed: () {
                  provider.setSearchQuery('');
                  provider.setSelectedCategory('Tümü');
                  provider.setSelectedStatus(null);
                },
              )
            else
              Text(
                'Yeni stok eklemek için aşağıdaki + butonunu kullanabilirsiniz.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
