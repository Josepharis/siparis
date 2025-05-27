import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/theme/app_theme.dart';

class StockSearchBar extends StatefulWidget {
  const StockSearchBar({Key? key}) : super(key: key);

  @override
  State<StockSearchBar> createState() => _StockSearchBarState();
}

class _StockSearchBarState extends State<StockSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  late StockProvider _stockProvider;

  @override
  void initState() {
    super.initState();
    _stockProvider = Provider.of<StockProvider>(context, listen: false);
    // Eğer provider'da başlangıçta bir arama sorgusu varsa controller'a ata
    _searchController.text = _stockProvider.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _stockProvider.setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall / 2), // Biraz daha az padding
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ürün adı, barkod, kategori ara...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    // _stockProvider.setSearchQuery(''); // Listener zaten yapacak
                  },
                  splashRadius: 20,
                )
              : null,
          filled: true,
          fillColor: AppTheme.background, // Arkaplan rengiyle aynı veya yüzey
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingSmall, // Daha kompakt
            horizontal: AppTheme.spacingMedium,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                AppTheme.borderRadius * 2), // Daha yuvarlak
            borderSide: BorderSide(color: AppTheme.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
            borderSide: BorderSide(color: AppTheme.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
