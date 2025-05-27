import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/theme/app_theme.dart';

class StockFilterBar extends StatelessWidget {
  const StockFilterBar({Key? key}) : super(key: key);

  // StockStatus için yardımcı metotlar (Stock modelindekilere benzer)
  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.normal:
        return AppTheme.success;
      case StockStatus.critical:
        return AppTheme.warning;
      case StockStatus.outOfStock:
        return AppTheme.error;
      case StockStatus.excess:
        return AppTheme.info;
    }
  }

  String _getStatusText(StockStatus status) {
    switch (status) {
      case StockStatus.normal:
        return 'Normal';
      case StockStatus.critical:
        return 'Kritik';
      case StockStatus.outOfStock:
        return 'Tükendi';
      case StockStatus.excess:
        return 'Fazla';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockProvider>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.cardShadow,
        // Üst tarafında hafif bir border olabilir veya AppTheme.primary'nin açık bir tonu
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Kategori Filtresi
          Expanded(
            flex: 3,
            child: _buildDropdownFilter<String>(
              context: context,
              label: 'Kategori',
              value: provider.selectedCategory,
              items: provider.categories,
              onChanged: (value) {
                if (value != null) {
                  provider.setSelectedCategory(value);
                }
              },
              itemBuilder: (category) =>
                  Text(category, style: theme.textTheme.bodyMedium),
              icon: Icons.folder_open_outlined,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          // Durum Filtresi
          Expanded(
            flex: 3,
            child: _buildDropdownFilter<StockStatus?>(
              context: context,
              label: 'Durum',
              value: provider.selectedStatus,
              items: [null, ...StockStatus.values], // 'Tümü' için null değeri
              onChanged: provider.setSelectedStatus,
              itemBuilder: (status) {
                if (status == null)
                  return Text('Tümü', style: theme.textTheme.bodyMedium);
                return Row(
                  children: [
                    Icon(Icons.circle,
                        color: _getStatusColor(status), size: 10), // Düzeltildi
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(_getStatusText(status),
                        style: theme.textTheme
                            .bodyMedium), // Modeldeki statusText kullanılır
                  ],
                );
              },
              icon: Icons.traffic_outlined,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          // Sıralama Butonu
          _buildSortButton(context, provider, theme),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T item) itemBuilder,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        prefixIcon: icon != null
            ? Icon(icon,
                color: AppTheme.textSecondary, size: AppTheme.iconSize - 4)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall,
          vertical: AppTheme.spacingSmall * 1.2, // Biraz daha kompakt
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: AppTheme.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: AppTheme.border, width: 0.5),
        ),
        filled: true,
        fillColor: AppTheme.background, // Arama çubuğu ile uyumlu
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      dropdownColor: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      style: theme.textTheme.bodyMedium,
    );
  }

  Widget _buildSortButton(
      BuildContext context, StockProvider provider, ThemeData theme) {
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: InkWell(
        onTap: () => _showSortDialog(context, provider, theme),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSmall,
            vertical:
                AppTheme.spacingSmall * 1.2, // Dropdown ile aynı yükseklik
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                provider.sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: AppTheme.primary,
                size: AppTheme.iconSize - 4,
              ),
              const SizedBox(width: AppTheme.spacingSmall / 2),
              Text(
                _getSortFieldText(provider.sortBy),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortFieldText(String sortBy) {
    switch (sortBy) {
      case 'productName':
        return 'Ada Göre';
      case 'category':
        return 'Kategoriye Göre';
      case 'currentQuantity':
        return 'Miktara Göre';
      case 'unitPrice':
        return 'Fiyata Göre';
      case 'lastUpdated':
        return 'Tarihe Göre';
      default:
        return 'Sırala';
    }
  }

  void _showSortDialog(
      BuildContext context, StockProvider provider, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sıralama Seçenekleri'),
          contentPadding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingMedium,
              horizontal: AppTheme.spacingSmall / 2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOptionTile(context, provider, theme, 'Ürün Adı',
                  'productName', Icons.sort_by_alpha_outlined),
              _buildSortOptionTile(context, provider, theme, 'Kategori',
                  'category', Icons.folder_special_outlined),
              _buildSortOptionTile(context, provider, theme, 'Miktar',
                  'currentQuantity', Icons.format_list_numbered_outlined),
              _buildSortOptionTile(context, provider, theme, 'Birim Fiyat',
                  'unitPrice', Icons.price_check_outlined),
              _buildSortOptionTile(context, provider, theme, 'Son Güncelleme',
                  'lastUpdated', Icons.date_range_outlined),
              const Divider(
                  height: AppTheme.spacingSmall, indent: 16, endIndent: 16),
              SwitchListTile(
                title: Text('Artan Sıralama (A-Z, 0-9)',
                    style: theme.textTheme.bodyMedium),
                value: provider.sortAscending,
                onChanged: (value) {
                  provider.setSortBy(provider.sortBy, ascending: value);
                  // Dialog kapatılmayabilir, kullanıcı birden fazla değişiklik yapabilir.
                },
                activeColor: AppTheme.primary,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('KAPAT'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortOptionTile(BuildContext context, StockProvider provider,
      ThemeData theme, String title, String field, IconData icon) {
    final bool isSelected = provider.sortBy == field;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(title,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2)),
      onTap: () {
        provider.setSortBy(field);
        // Navigator.pop(context); // Dialog kapatılmayabilir
      },
      trailing: isSelected
          ? Icon(
              provider.sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: AppTheme.primary,
              size: 20)
          : null,
    );
  }
}
