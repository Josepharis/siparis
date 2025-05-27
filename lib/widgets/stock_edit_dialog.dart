import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class StockEditDialog extends StatefulWidget {
  final Stock? stock; // Düzenleme için var olan stok, ekleme için null olabilir
  final bool isAdding;

  const StockEditDialog({Key? key, this.stock, this.isAdding = false})
      : super(key: key);

  @override
  State<StockEditDialog> createState() => _StockEditDialogState();
}

class _StockEditDialogState extends State<StockEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late Stock _editableStock; // Dialog içinde düzenlenecek/oluşturulacak stok

  // Text Editing Controllers
  late TextEditingController _productNameController;
  late TextEditingController _categoryController;
  late TextEditingController _subCategoryController;
  late TextEditingController _barcodeController;
  late TextEditingController _supplierController;
  late TextEditingController _currentQuantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _maxQuantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _unitController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _batchNumberController;

  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();

    if (widget.isAdding || widget.stock == null) {
      // Yeni stok ekleme modu
      _editableStock = Stock(
        id: const Uuid().v4(), // Yeni ID
        productName: '',
        category: '',
        currentQuantity: 0,
        minQuantity: 0,
        unitPrice: 0,
        unit: '', // Varsayılan birim (örn: adet)
        lastUpdated: DateTime.now(),
      );
    } else {
      // Düzenleme modu
      _editableStock = widget.stock!;
    }

    // Controller'ları _editableStock'tan başlat
    _productNameController =
        TextEditingController(text: _editableStock.productName);
    _categoryController = TextEditingController(text: _editableStock.category);
    _subCategoryController =
        TextEditingController(text: _editableStock.subCategory);
    _barcodeController = TextEditingController(text: _editableStock.barcode);
    _supplierController = TextEditingController(text: _editableStock.supplier);
    _currentQuantityController = TextEditingController(
        text: _editableStock.currentQuantity.toStringAsFixed(2));
    _minQuantityController = TextEditingController(
        text: _editableStock.minQuantity.toStringAsFixed(2));
    _maxQuantityController = TextEditingController(
        text: _editableStock.maxQuantity == double.infinity
            ? ''
            : _editableStock.maxQuantity.toStringAsFixed(2));
    _unitPriceController = TextEditingController(
        text: _editableStock.unitPrice.toStringAsFixed(2));
    _purchasePriceController = TextEditingController(
        text: _editableStock.purchasePrice.toStringAsFixed(2));
    _unitController = TextEditingController(text: _editableStock.unit);
    _locationController = TextEditingController(text: _editableStock.location);
    _imageUrlController = TextEditingController(text: _editableStock.imageUrl);
    _descriptionController =
        TextEditingController(text: _editableStock.description);
    _tagsController =
        TextEditingController(text: _editableStock.tags.join(', '));
    _batchNumberController =
        TextEditingController(text: _editableStock.batchNumber);
    _expiryDate = _editableStock.expiryDate;
  }

  @override
  void dispose() {
    // Controller'ları dispose et
    _productNameController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _barcodeController.dispose();
    _supplierController.dispose();
    _currentQuantityController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _unitPriceController.dispose();
    _purchasePriceController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Formdaki onSave metotlarını çalıştırır

      final finalStock = _editableStock.copyWith(
        productName: _productNameController.text,
        category: _categoryController.text,
        subCategory: _subCategoryController.text,
        barcode: _barcodeController.text,
        supplier: _supplierController.text,
        currentQuantity: double.tryParse(_currentQuantityController.text) ??
            _editableStock.currentQuantity,
        minQuantity: double.tryParse(_minQuantityController.text) ??
            _editableStock.minQuantity,
        maxQuantity: _maxQuantityController.text.isEmpty
            ? double.infinity
            : double.tryParse(_maxQuantityController.text) ??
                _editableStock.maxQuantity,
        unitPrice: double.tryParse(_unitPriceController.text) ??
            _editableStock.unitPrice,
        purchasePrice: double.tryParse(_purchasePriceController.text) ??
            _editableStock.purchasePrice,
        unit: _unitController.text,
        location: _locationController.text,
        imageUrl: _imageUrlController.text,
        description: _descriptionController.text,
        tags: _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        batchNumber: _batchNumberController.text,
        expiryDate: _expiryDate,
        lastUpdated: DateTime.now(), // Her zaman güncelle
        isActive: _editableStock
            .isActive, // isActive durumunu koru veya bir switch ile yönet
      );

      final provider = Provider.of<StockProvider>(context, listen: false);
      if (widget.isAdding) {
        provider.addStock(finalStock);
      } else {
        provider.updateStock(finalStock);
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.isAdding ? 'Yeni Stok Ekle' : 'Stok Düzenle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingSmall), // Dialog content padding'i
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTextFormField(
                  controller: _productNameController,
                  label: 'Ürün Adı',
                  validator: (value) =>
                      value!.isEmpty ? 'Ürün adı boş olamaz' : null),
              _buildTextFormField(
                  controller: _categoryController, label: 'Kategori'),
              _buildTextFormField(
                  controller: _subCategoryController, label: 'Alt Kategori'),
              _buildTextFormField(
                  controller: _barcodeController, label: 'Barkod'),
              _buildTextFormField(
                  controller: _supplierController, label: 'Tedarikçi'),
              Row(
                children: [
                  Expanded(
                      child: _buildTextFormField(
                          controller: _currentQuantityController,
                          label: 'Mevcut Miktar',
                          keyboardType: TextInputType.number,
                          validator: (value) => double.tryParse(value!) == null
                              ? 'Geçerli sayı girin'
                              : null)),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                      child: _buildTextFormField(
                          controller: _unitController, label: 'Birim')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: _buildTextFormField(
                          controller: _minQuantityController,
                          label: 'Min. Miktar',
                          keyboardType: TextInputType.number,
                          validator: (value) => double.tryParse(value!) == null
                              ? 'Geçerli sayı girin'
                              : null)),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                      child: _buildTextFormField(
                          controller: _maxQuantityController,
                          label: 'Max. Miktar (Boş = ∞)',
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isNotEmpty &&
                                  double.tryParse(value) == null
                              ? 'Geçerli sayı ya da boş'
                              : null)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: _buildTextFormField(
                          controller: _unitPriceController,
                          label: 'Birim Satış Fiyatı',
                          keyboardType: TextInputType.number,
                          validator: (value) => double.tryParse(value!) == null
                              ? 'Geçerli sayı girin'
                              : null)),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                      child: _buildTextFormField(
                          controller: _purchasePriceController,
                          label: 'Birim Alış Fiyatı',
                          keyboardType: TextInputType.number,
                          validator: (value) => double.tryParse(value!) == null
                              ? 'Geçerli sayı girin'
                              : null)),
                ],
              ),
              _buildTextFormField(
                  controller: _locationController, label: 'Depo Lokasyonu'),
              _buildTextFormField(
                  controller: _batchNumberController, label: 'Parti Numarası'),
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Son Kullanma Tarihi Seç'
                    : 'SKT: ${MaterialLocalizations.of(context).formatShortDate(_expiryDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectExpiryDate(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    side: BorderSide(color: AppTheme.border)),
                tileColor: AppTheme.surface,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              _buildTextFormField(
                  controller: _imageUrlController,
                  label: 'Ürün Görsel URL',
                  keyboardType: TextInputType.url),
              _buildTextFormField(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  maxLines: 3),
              _buildTextFormField(
                  controller: _tagsController,
                  label: 'Etiketler (virgülle ayırın)'),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İPTAL'),
        ),
        ElevatedButton(
          onPressed: _saveForm,
          child: Text(widget.isAdding ? 'EKLE' : 'KAYDET'),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall / 2),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onSaved: (value) {
          // Her bir alan için onSaved'a gerek yok, controller'lar zaten güncel
        },
      ),
    );
  }
}
