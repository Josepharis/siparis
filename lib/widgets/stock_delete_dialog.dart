import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/theme/app_theme.dart';

class StockDeleteDialog extends StatelessWidget {
  final Stock stock;

  const StockDeleteDialog({Key? key, required this.stock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      title: Row(
        children: [
          const Icon(Icons.delete_forever_outlined, color: AppTheme.error),
          const SizedBox(width: AppTheme.spacingSmall),
          Text('Stok Sil',
              style:
                  theme.textTheme.titleLarge?.copyWith(color: AppTheme.error)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textPrimary),
              children: <TextSpan>[
                const TextSpan(text: 'Emin misiniz? '),
                TextSpan(
                  text: stock.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                    text: ' adlı ürünü kalıcı olarak silmek üzeresiniz.'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Bu işlem geri alınamaz ve bu ürüne ait tüm stok hareketleri de silinecektir.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(AppTheme.spacingMedium),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('İPTAL',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppTheme.textSecondary)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_outline, size: AppTheme.iconSize - 4),
          label: const Text('SİL'),
          onPressed: () {
            Provider.of<StockProvider>(context, listen: false)
                .deleteStock(stock.id);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${stock.productName} silindi.'),
                backgroundColor: AppTheme.success,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: AppTheme.textOnPrimary,
          ),
        ),
      ],
    );
  }
}
