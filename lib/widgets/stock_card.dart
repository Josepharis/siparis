import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/theme/app_theme.dart';

class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback onEdit;
  final VoidCallback onMovement;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const StockCard({
    Key? key,
    required this.stock,
    required this.onEdit,
    required this.onMovement,
    required this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final theme = Theme.of(context);

    return Card(
      // CardTheme'den gelen margin ve shape'i kullanır.
      // Ekstra gölge ve tıklama efekti için BoxDecoration ve InkWell
      child: InkWell(
        onTap: onTap ?? onMovement, // onTap verilmezse onMovement çalışır
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: AppTheme.cardShadow, // AppTheme'den gölge
            color: AppTheme.surface, // CardTheme'den farklı bir renk isterseniz
          ),
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: AppTheme.spacingSmall),
              const Divider(height: 1, color: AppTheme.divider),
              const SizedBox(height: AppTheme.spacingMedium),
              _buildStockInfo(context, currencyFormat, theme),
              const SizedBox(height: AppTheme.spacingMedium),
              _buildFooter(context, dateFormat, theme),
              const SizedBox(height: AppTheme.spacingSmall),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.productName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (stock.category.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSmall / 2),
                Text(
                  stock.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        _buildStatusChip(theme),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: stock.statusColor,
        radius: 6,
      ),
      label: Text(
        stock.statusText,
        style: theme.chipTheme.labelStyle?.copyWith(color: stock.statusColor),
      ),
      backgroundColor: stock.statusColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall,
          vertical: AppTheme.spacingSmall / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius / 1.5),
        side: BorderSide(color: stock.statusColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildStockInfo(
      BuildContext context, NumberFormat currencyFormat, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildInfoColumn(
            context,
            'Miktar',
            '${stock.currentQuantity} ${stock.unit}',
            Icons.inventory_2_outlined,
            theme,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          flex: 4,
          child: _buildInfoColumn(
            context,
            'Birim Fiyat',
            currencyFormat.format(stock.unitPrice),
            Icons.attach_money_outlined,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(
      BuildContext context, DateFormat dateFormat, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (stock.barcode.isNotEmpty)
          _buildInfoChip(
            Icons.qr_code_scanner_outlined,
            stock.barcode,
            theme,
            AppTheme.textSecondary,
          ),
        const Spacer(),
        _buildInfoChip(
          Icons.update_outlined,
          'Güncelleme: ${dateFormat.format(stock.lastUpdated)}',
          theme,
          AppTheme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value,
      IconData icon, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.spacingSmall / 2),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall / 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      IconData icon, String text, ThemeData theme, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppTheme.spacingSmall / 2),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: AppTheme.iconSize - 4),
          color: AppTheme.primary,
          tooltip: 'Düzenle',
          onPressed: onEdit,
          splashRadius: 20,
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz_outlined,
              size: AppTheme.iconSize - 4),
          color: AppTheme.secondary, // Ya da AppTheme.info
          tooltip: 'Hareket Ekle',
          onPressed: onMovement,
          splashRadius: 20,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: AppTheme.iconSize - 4),
          color: AppTheme.error,
          tooltip: 'Sil',
          onPressed: onDelete,
          splashRadius: 20,
        ),
      ],
    );
  }
}
