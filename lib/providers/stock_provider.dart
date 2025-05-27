import 'package:flutter/material.dart';
import 'package:siparis/models/stock.dart';

class StockProvider with ChangeNotifier {
  List<Stock> _stocks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  StockStatus? _selectedStatus;
  String _sortBy = 'productName';
  bool _sortAscending = true;

  List<Stock> get stocks => _filterAndSortStocks();
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  StockStatus? get selectedStatus => _selectedStatus;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  int get totalDistinctProducts =>
      _stocks.map((s) => s.productName).toSet().length;
  double get totalStockQuantity =>
      _stocks.fold(0, (sum, stock) => sum + stock.currentQuantity);
  int get criticalStockCount =>
      _stocks.where((s) => s.status == StockStatus.critical).length;
  int get outOfStockCount =>
      _stocks.where((s) => s.status == StockStatus.outOfStock).length;
  int get excessStockCount =>
      _stocks.where((s) => s.status == StockStatus.excess).length;

  double get totalStockValue {
    return _stocks.fold(
      0,
      (sum, stock) => sum + (stock.currentQuantity * stock.unitPrice),
    );
  }

  double get totalPurchaseValue {
    return _stocks.fold(
      0,
      (sum, stock) => sum + (stock.currentQuantity * stock.purchasePrice),
    );
  }

  List<String> get categories {
    final categories = _stocks.map((s) => s.category).toSet().toList();
    categories.sort();
    categories.insert(0, 'Tümü');
    return categories;
  }

  List<Stock> _filterAndSortStocks() {
    var filteredStocks = _stocks;

    if (_searchQuery.isNotEmpty) {
      filteredStocks = filteredStocks.where((stock) {
        final query = _searchQuery.toLowerCase();
        return stock.productName.toLowerCase().contains(query) ||
            stock.barcode.toLowerCase().contains(query) ||
            stock.category.toLowerCase().contains(query) ||
            stock.subCategory.toLowerCase().contains(query) ||
            stock.supplier.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCategory != 'Tümü') {
      filteredStocks =
          filteredStocks.where((s) => s.category == _selectedCategory).toList();
    }

    if (_selectedStatus != null) {
      filteredStocks =
          filteredStocks.where((s) => s.status == _selectedStatus).toList();
    }

    filteredStocks.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'productName':
          comparison = a.productName
              .toLowerCase()
              .compareTo(b.productName.toLowerCase());
          break;
        case 'category':
          comparison =
              a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
        case 'currentQuantity':
          comparison = a.currentQuantity.compareTo(b.currentQuantity);
          break;
        case 'unitPrice':
          comparison = a.unitPrice.compareTo(b.unitPrice);
          break;
        case 'lastUpdated':
          comparison = b.lastUpdated.compareTo(a.lastUpdated);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredStocks;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedStatus(StockStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSortBy(String field, {bool? ascending}) {
    _sortBy = field;
    if (ascending != null) {
      _sortAscending = ascending;
    }
    notifyListeners();
  }

  void toggleSortAscending() {
    _sortAscending = !_sortAscending;
    notifyListeners();
  }

  Future<void> loadStocks() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _stocks = _getDummyStocks();
    } catch (e) {
      debugPrint('Stok yükleme hatası: $e');
      _stocks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStock(Stock stock) async {
    _stocks.add(stock);
    notifyListeners();
  }

  Future<void> updateStock(Stock stock) async {
    final index = _stocks.indexWhere((s) => s.id == stock.id);
    if (index != -1) {
      _stocks[index] = stock;
      notifyListeners();
    }
  }

  Future<void> deleteStock(String stockId) async {
    _stocks.removeWhere((s) => s.id == stockId);
    notifyListeners();
  }

  Future<void> addStockMovement(String stockId, StockMovement movement) async {
    final index = _stocks.indexWhere((s) => s.id == stockId);
    if (index != -1) {
      final stock = _stocks[index];
      final newQuantity = stock.currentQuantity +
          (movement.type == MovementType.incoming
              ? movement.quantity
              : -movement.quantity);

      final updatedStock = stock.copyWith(
        currentQuantity: newQuantity,
        lastUpdated: DateTime.now(),
        movements: [...stock.movements, movement],
      );
      _stocks[index] = updatedStock;
      notifyListeners();
    }
  }

  List<Stock> _getDummyStocks() {
    return [
      Stock(
        id: '1',
        productName: 'Endüstriyel Un Tip 1',
        category: 'Hammadde',
        subCategory: 'Unlu Mamüller',
        barcode: '8690000000001',
        supplier: 'Anadolu Gıda A.Ş.',
        currentQuantity: 150.5,
        minQuantity: 50,
        maxQuantity: 500,
        unitPrice: 27.75,
        purchasePrice: 22.50,
        unit: 'kg',
        location: 'Depo A-1-R1',
        lastUpdated: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        movements: [],
        imageUrl: 'https://via.placeholder.com/150/2196F3/FFFFFF?Text=Un',
        description: 'Yüksek kaliteli endüstriyel kullanım için un.',
        tags: ['un', 'endüstriyel', 'hammadde'],
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        batchNumber: 'B202407S001',
      ),
      Stock(
        id: '2',
        productName: 'Kristal Toz Şeker',
        category: 'Hammadde',
        subCategory: 'Tatlandırıcılar',
        barcode: '8690000000002',
        supplier: 'Şeker Fabrikaları A.Ş.',
        currentQuantity: 80,
        minQuantity: 100,
        maxQuantity: 300,
        unitPrice: 32.50,
        purchasePrice: 28.00,
        unit: 'kg',
        location: 'Depo A-2-R3',
        lastUpdated:
            DateTime.now().subtract(const Duration(days: 1, hours: 10)),
        movements: [],
        imageUrl: 'https://via.placeholder.com/150/4CAF50/FFFFFF?Text=Seker',
        description: 'Pastacılık ve genel kullanım için kristal toz şeker.',
        tags: ['şeker', 'kristal', 'hammadde'],
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        batchNumber: 'B202407S002',
      ),
      Stock(
        id: '3',
        productName: 'Organik Yumurta (30\'lu)',
        category: 'Hammadde',
        subCategory: 'Kahvaltılık',
        barcode: '8690000000003',
        supplier: 'Doğal Çiftlik Ürünleri',
        currentQuantity: 0,
        minQuantity: 20,
        maxQuantity: 100,
        unitPrice: 90.00,
        purchasePrice: 75.00,
        unit: 'koli',
        location: 'Soğuk Hava Deposu R1',
        lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        movements: [],
        tags: ['yumurta', 'organik', 'kahvaltılık'],
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        batchNumber: 'B202407Y001',
      ),
      Stock(
        id: '4',
        productName: 'Ayçiçek Yağı 5L',
        category: 'Hammadde',
        subCategory: 'Sıvı Yağlar',
        barcode: '8690000000004',
        supplier: 'Bereket Yağ Sanayi',
        currentQuantity: 250,
        minQuantity: 50,
        maxQuantity: 200,
        unitPrice: 180.00,
        purchasePrice: 155.00,
        unit: 'adet',
        location: 'Depo B-1-R2',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
        movements: [],
        imageUrl: 'https://via.placeholder.com/150/FFC107/000000?Text=Yag',
        description: '5 Litrelik teneke ayçiçek yağı.',
        tags: ['yağ', 'ayçiçek', 'sıvı yağ'],
        isActive: true,
        batchNumber: 'B202407A001',
      ),
      Stock(
        id: '5',
        productName: 'Domates Salçası (Teneke)',
        category: 'İşlenmiş Gıda',
        subCategory: 'Konserve',
        barcode: '8690000000005',
        supplier: 'Güneş Konservecilik',
        currentQuantity: 75,
        minQuantity: 30,
        maxQuantity: 150,
        unitPrice: 65.00,
        purchasePrice: 50.00,
        unit: 'adet',
        location: 'Depo C-1-R1',
        lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
        movements: [],
        description: 'Ev tipi domates salçası, 830g teneke.',
        tags: ['salça', 'domates', 'konserve'],
        isActive: false,
        expiryDate: DateTime.now().add(const Duration(days: 730)),
        batchNumber: 'B202312S001',
      ),
    ];
  }
}
