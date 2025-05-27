import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/theme/app_theme.dart';

class StockStatsCard extends StatelessWidget {
  const StockStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockProvider>(context);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stok Özeti',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          GridView.count(
            crossAxisCount: 2, // Yan yana 2 veya 3 öğe olabilir
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5, // Öğelerin en boy oranı
            mainAxisSpacing: AppTheme.spacingSmall,
            crossAxisSpacing: AppTheme.spacingSmall,
            children: [
              _buildStatItem(
                context,
                'Toplam Ürün Çeşidi',
                provider.totalDistinctProducts.toString(), // Yeni getter
                Icons.category_outlined,
                AppTheme.primary,
              ),
              _buildStatItem(
                context,
                'Toplam Stok Miktarı',
                provider.totalStockQuantity.toStringAsFixed(0), // Yeni getter
                Icons.inventory_2_outlined,
                AppTheme.secondary,
              ),
              _buildStatItem(
                context,
                'Kritik Seviyedekiler',
                provider.criticalStockCount.toString(),
                Icons.warning_amber_outlined,
                AppTheme.warning,
              ),
              _buildStatItem(
                context,
                'Tükenmiş Ürünler',
                provider.outOfStockCount.toString(),
                Icons.error_outline,
                AppTheme.error,
              ),
              _buildStatItem(
                context,
                'Toplam Stok Değeri',
                currencyFormat.format(provider.totalStockValue),
                Icons.monetization_on_outlined,
                AppTheme.success,
              ),
              _buildStatItem(
                context,
                'Toplam Alış Değeri',
                currencyFormat
                    .format(provider.totalPurchaseValue), // Yeni getter
                Icons.shopping_cart_checkout_outlined,
                AppTheme.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppTheme.iconSize + 4),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingSmall / 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
