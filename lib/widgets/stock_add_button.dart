import 'package:flutter/material.dart';
import 'package:siparis/theme/app_theme.dart';
import 'package:siparis/widgets/stock_edit_dialog.dart'; // Yeni stok ekleme için de kullanılabilir
import 'package:siparis/models/stock.dart'; // Boş bir Stock nesnesi oluşturmak için
import 'package:uuid/uuid.dart'; // Benzersiz ID oluşturmak için

class StockAddButton extends StatelessWidget {
  const StockAddButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddStockDialog(context),
      backgroundColor: AppTheme.primary, // AppTheme'den renkler
      foregroundColor: AppTheme.textOnPrimary,
      icon: const Icon(Icons.add_rounded, size: AppTheme.iconSize),
      label:
          Text('Yeni Stok Ekle', style: Theme.of(context).textTheme.labelLarge),
      elevation: AppTheme.spacingSmall / 2, // AppTheme'den değer
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppTheme.borderRadius * 1.5), // Daha yuvarlak
      ),
    );
  }

  void _showAddStockDialog(BuildContext context) {
    // Yeni, boş bir Stock nesnesi oluştur. ID'si ve lastUpdated otomatik atanacak.
    // Diğer alanlar dialog içinde kullanıcı tarafından doldurulacak.
    // StockEditDialog'u "ekleme" modunda kullanacağız.
    // StockEditDialog, null stock aldığında "ekleme" moduna geçecek şekilde güncellenebilir
    // veya ayrı bir StockAddDialog oluşturulabilir. Şimdilik StockEditDialog'u yeniden kullanıyoruz.

    final newStock = Stock(
      id: const Uuid().v4(), // Benzersiz ID
      productName: '',
      category: '', // İlk kategori seçili gelebilir veya boş olabilir
      currentQuantity: 0,
      minQuantity: 0,
      unitPrice: 0,
      unit: '', // Varsayılan birim (örn: adet)
      lastUpdated: DateTime.now(),
      // Diğer zorunlu olmayan alanlar için varsayılan değerler Stock modelinde atanmıştı.
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // StockEditDialog'un yeni stok ekleme senaryosunu da handle etmesi gerekir.
        // Bu, StockEditDialog'a opsiyonel bir `isEditMode` parametresi ekleyerek
        // veya `stock` parametresi null ise yeni stok modunda çalışmasını sağlayarak yapılabilir.
        // Şimdilik, StockEditDialog'un bu durumu yönettiğini varsayıyoruz.
        return StockEditDialog(stock: newStock, isAdding: true);
      },
    );
  }
}
