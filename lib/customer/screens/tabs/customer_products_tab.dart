import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';

class CustomerProductsTab extends StatefulWidget {
  const CustomerProductsTab({super.key});

  @override
  State<CustomerProductsTab> createState() => _CustomerProductsTabState();
}

class _CustomerProductsTabState extends State<CustomerProductsTab> {
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  List<Product> _products = [];
  List<String> _categories = ['Tümü'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // Örnek ürünler - gerçek uygulamada API'den gelecek
    _products = [
      Product(
        name: 'Hamburger Ekmeği',
        price: 2.50,
        category: 'Ekmek',
        description: 'Taze hamburger ekmeği',
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Product(
        name: 'Sandviç Ekmeği',
        price: 3.00,
        category: 'Ekmek',
        description: 'Yumuşak sandviç ekmeği',
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Product(
        name: 'Çikolatalı Kek',
        price: 15.00,
        category: 'Kek',
        description: 'Ev yapımı çikolatalı kek',
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Product(
        name: 'Vanilyalı Kek',
        price: 12.00,
        category: 'Kek',
        description: 'Vanilyalı sünger kek',
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Product(
        name: 'Çikolatalı Kurabiye',
        price: 8.00,
        category: 'Kurabiye',
        description: 'Çıtır çikolatalı kurabiye',
        imageUrl: 'https://via.placeholder.com/150',
      ),
    ];

    // Kategorileri çıkar
    final categories = _products.map((p) => p.category).toSet().toList();
    _categories = ['Tümü', ...categories];
  }

  List<Product> get _filteredProducts {
    var filtered = _products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Tümü' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory && product.isActive;
    }).toList();

    return filtered;
  }

  // Responsive boyutları hesapla
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 400) {
      return 1; // Çok küçük ekranlar için 1 sütun
    } else if (screenWidth < 600) {
      return 2; // Telefon için 2 sütun
    } else if (screenWidth < 900) {
      return 3; // Tablet için 3 sütun
    } else {
      return 4; // Büyük ekranlar için 4 sütun
    }
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 400) {
      return 1.2; // Tek sütun için daha geniş kartlar
    } else if (screenWidth < 600) {
      return 0.75; // Telefon için
    } else {
      return 0.8; // Tablet ve büyük ekranlar için
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Text(
                          'Ürünler',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  // Arama kutusu ve kategori dropdown'ı yan yana
                  Row(
                    children: [
                      // Arama kutusu
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: isSmallScreen ? 44 : 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Ürün ara...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[500],
                                size: isSmallScreen ? 18 : 20,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      // Kategori Dropdown
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: isSmallScreen ? 44 : 48,
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                                size: isSmallScreen ? 18 : 20,
                              ),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                              items: _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: category == _selectedCategory
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ürün listesi
            Expanded(
              child: _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(screenWidth),
                        childAspectRatio: _getChildAspectRatio(screenWidth),
                        crossAxisSpacing: isSmallScreen ? 8 : 12,
                        mainAxisSpacing: isSmallScreen ? 8 : 12,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductCard(product, isSmallScreen);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isSmallScreen ? 6 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün resmi
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSmallScreen ? 8 : 12),
                  topRight: Radius.circular(isSmallScreen ? 8 : 12),
                ),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallScreen ? 8 : 12),
                        topRight: Radius.circular(isSmallScreen ? 8 : 12),
                      ),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(isSmallScreen);
                        },
                      ),
                    )
                  : _buildPlaceholderImage(isSmallScreen),
            ),
          ),

          // Ürün bilgileri
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showOrderDialog(product),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallScreen ? 8 : 12),
          topRight: Radius.circular(isSmallScreen ? 8 : 12),
        ),
      ),
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: isSmallScreen ? 30 : 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ürün bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arama kriterlerinizi değiştirerek tekrar deneyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDialog(Product product) {
    int quantity = 1;
    String note = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Sipariş Ver: ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Miktar:'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () {
                                    setState(() {
                                      quantity--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Not (Opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      note = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Toplam:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₺${(product.price * quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addToCart(product, quantity, note);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sepete Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addToCart(Product product, int quantity, String note) {
    // Sepete ekleme işlemi - gerçek uygulamada provider kullanılacak
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} sepete eklendi'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
