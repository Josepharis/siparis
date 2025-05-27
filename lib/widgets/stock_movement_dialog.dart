import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/models/stock.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class StockMovementDialog extends StatefulWidget {
  final Stock stock;

  const StockMovementDialog({Key? key, required this.stock}) : super(key: key);

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  MovementType _selectedType = MovementType.incoming;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _operatorIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unitPriceController.text = widget.stock.purchasePrice > 0
        ? widget.stock.purchasePrice.toStringAsFixed(2)
        : widget.stock.unitPrice.toStringAsFixed(2);
    _operatorIdController.text = "CurrentUser";
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _operatorIdController.dispose();
    super.dispose();
  }

  // MovementType için yardımcı metotlar
  Color _getMovementTypeColor(MovementType type) {
    switch (type) {
      case MovementType.incoming:
        return AppTheme.success;
      case MovementType.outgoing:
        return AppTheme.error;
      case MovementType.adjustment:
        return AppTheme.info;
      case MovementType.returned:
        return AppTheme.warning;
      case MovementType.damage:
        return Colors.brown; // Veya AppTheme'den bir renk
    }
  }

  String _getMovementTypeText(MovementType type) {
    switch (type) {
      case MovementType.incoming:
        return 'Giriş';
      case MovementType.outgoing:
        return 'Çıkış';
      case MovementType.adjustment:
        return 'Düzeltme';
      case MovementType.returned:
        return 'İade';
      case MovementType.damage:
        return 'Hasar';
    }
  }

  IconData _getMovementTypeIcon(MovementType type) {
    switch (type) {
      case MovementType.incoming:
        return Icons.add_circle_outline;
      case MovementType.outgoing:
        return Icons.remove_circle_outline;
      case MovementType.adjustment:
        return Icons.sync_alt_outlined;
      case MovementType.returned:
        return Icons.undo_outlined;
      case MovementType.damage:
        return Icons.warning_amber_outlined;
    }
  }

  void _saveMovement() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final quantity = double.tryParse(_quantityController.text);
      final unitPrice = double.tryParse(_unitPriceController.text);

      if (quantity == null || unitPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Miktar ve Birim Fiyat geçerli sayılar olmalıdır.'),
              backgroundColor: AppTheme.error),
        );
        return;
      }

      final movement = StockMovement(
        id: const Uuid().v4(),
        date: DateTime.now(),
        type: _selectedType,
        quantity: quantity,
        unitPrice: unitPrice,
        reference: _referenceController.text,
        notes: _notesController.text,
        operatorId: _operatorIdController.text,
      );

      Provider.of<StockProvider>(context, listen: false)
          .addStockMovement(widget.stock.id, movement);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return AlertDialog(
      title: Text('${widget.stock.productName} - Stok Hareketi'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<MovementType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Hareket Tipi'),
                items: MovementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getMovementTypeIcon(type),
                            color: _getMovementTypeColor(type),
                            size: AppTheme.iconSize - 4),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(_getMovementTypeText(type),
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Hareket tipi seçin' : null,
              ),
              _buildTextFormField(
                controller: _quantityController,
                label: 'Miktar (${widget.stock.unit})',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Miktar boş olamaz';
                  if (double.tryParse(value) == null)
                    return 'Geçerli bir sayı girin';
                  if (double.parse(value) <= 0)
                    return 'Miktar 0\'dan büyük olmalı';
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _unitPriceController,
                label: 'Birim Fiyat (${currencyFormat.currencySymbol})',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Birim fiyat boş olamaz';
                  if (double.tryParse(value) == null)
                    return 'Geçerli bir sayı girin';
                  if (double.parse(value) < 0) return 'Fiyat negatif olamaz';
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _referenceController,
                label: 'Referans No (Fatura, Sipariş vb.)',
                validator: (value) =>
                    value!.isEmpty ? 'Referans boş olamaz' : null,
              ),
              _buildTextFormField(
                  controller: _operatorIdController,
                  label: 'İşlemi Yapan',
                  enabled: false),
              _buildTextFormField(
                  controller: _notesController, label: 'Notlar', maxLines: 3),
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
          onPressed: _saveMovement,
          child: const Text('KAYDET'),
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
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall / 2),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
      ),
    );
  }
}
