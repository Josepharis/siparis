import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/screens/product_detail_screen.dart';
import 'package:siparis/screens/add_product_screen.dart';
import 'package:siparis/services/product_service.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'dart:developer' as developer;

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final Map<String, List<Product>> _categorizedProducts = {};
  final List<String> _categories = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  // Arama için yeni değişkenler
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, List<Product>> _filteredProducts = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();

    // Arama dinleyicisi ekle
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProducts() async {
    developer.log('ProductsTab: Ürün yükleme işlemi başlatıldı',
        name: 'ProductsTab');

    setState(() {
      _isLoading = true;
    });

    try {
      // AuthProvider'dan kullanıcı bilgisini al
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? companyId;

      if (authProvider.isEmployeeLogin) {
        // Çalışan girişi - şirket ID'sini employee'dan al
        companyId = authProvider.currentEmployee?.companyId;
        developer.log('ProductsTab: Çalışan girişi - Company ID: $companyId',
            name: 'ProductsTab');
      } else if (authProvider.currentUser != null) {
        // Sahip girişi - user ID'sini kullan
        companyId = authProvider.currentUser!.uid;
        developer.log('ProductsTab: Sahip girişi - User ID: $companyId',
            name: 'ProductsTab');
      } else {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Firebase'den kullanıcının ürünlerini çek
      developer.log('ProductsTab: Firebase\'den ürünler getiriliyor',
          name: 'ProductsTab');
      final List<Product> products = await ProductService.getUserProducts(
        companyId: companyId,
      );

      developer.log('ProductsTab: ${products.length} ürün alındı',
          name: 'ProductsTab');

      // Kategorileri organize et
      _categorizedProducts.clear();
      _categories.clear();

      // Kategorileri topla
      final Set<String> categorySet = {};
      for (var product in products) {
        categorySet.add(product.category);
        developer.log(
            'ProductsTab: Ürün kategorisi eklendi: ${product.category}',
            name: 'ProductsTab');
      }

      _categories.addAll(categorySet.toList()..sort());
      developer.log(
          'ProductsTab: Toplam ${_categories.length} kategori bulundu: $_categories',
          name: 'ProductsTab');

      // Ürünleri kategorilere göre grupla
      for (var category in _categories) {
        _categorizedProducts[category] =
            products.where((product) => product.category == category).toList();
        developer.log(
            'ProductsTab: $category kategorisinde ${_categorizedProducts[category]!.length} ürün',
            name: 'ProductsTab');
      }

      // Filtrelenmiş ürünleri başlat
      _filteredProducts = Map.from(_categorizedProducts);

      // Eski TabController'ı dispose et
      _tabController?.dispose();

      // TabController'ı başlat
      if (_categories.isNotEmpty) {
        _tabController = TabController(
          length: _categories.length,
          vsync: this,
        );

        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            setState(() {
              _selectedCategoryIndex = _tabController!.index;
            });
          }
        });

        developer.log('ProductsTab: TabController başarıyla oluşturuldu',
            name: 'ProductsTab');
      } else {
        _tabController = null;
        developer.log(
            'ProductsTab: Kategori bulunamadı, TabController oluşturulmadı',
            name: 'ProductsTab');
      }
    } catch (e, stackTrace) {
      developer.log('ProductsTab: Ürünler yüklenirken hata oluştu',
          name: 'ProductsTab', error: e, stackTrace: stackTrace, level: 1000);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürünler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      developer.log('ProductsTab: Ürün yükleme işlemi tamamlandı',
          name: 'ProductsTab');
    }
  }

  Future<void> _navigateToAddProduct() async {
    developer.log('ProductsTab: Ürün ekleme ekranına yönlendiriliyor',
        name: 'ProductsTab');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    developer.log(
        'ProductsTab: Ürün ekleme ekranından dönüldü, result: $result',
        name: 'ProductsTab');

    // Eğer ürün başarıyla eklendiyse listeyi yenile
    if (result == true) {
      developer.log('ProductsTab: Ürün başarıyla eklendi, liste yenileniyor',
          name: 'ProductsTab');
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(() {});
    _tabController?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Arama değişiklik dinleyicisi
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterProducts();
    });
  }

  // Ürünleri arama sorgusuna göre filtrele
  void _filterProducts() {
    _filteredProducts.clear();

    if (_searchQuery.isEmpty) {
      _filteredProducts = Map.from(_categorizedProducts);
    } else {
      for (var category in _categories) {
        final products = _categorizedProducts[category] ?? [];
        final filtered = products.where((product) {
          return product.name.toLowerCase().contains(_searchQuery) ||
              product.category.toLowerCase().contains(_searchQuery) ||
              (product.description?.toLowerCase().contains(_searchQuery) ??
                  false);
        }).toList();

        if (filtered.isNotEmpty) {
          _filteredProducts[category] = filtered;
        }
      }
    }
  }

  // Arama modunu değiştir
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
        _filteredProducts = Map.from(_categorizedProducts);
      }
    });
  }

  // Kategori ikonlarını belirle
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.cake;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'pastalar':
        return Icons.cake_outlined;
      case 'kurabiyeler':
        return Icons.cookie_outlined;
      case 'şerbetli tatlılar':
        return Icons.local_drink_outlined;
      default:
        return Icons.restaurant;
    }
  }

  // Kategori renklerini belirle
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return const Color(0xFFFF5252);
      case 'hamur işleri':
        return const Color(0xFFFFB74D);
      case 'pastalar':
        return const Color(0xFF9C27B0);
      case 'kurabiyeler':
        return const Color(0xFF4CAF50);
      case 'şerbetli tatlılar':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Eğer hiç ürün yoksa boş durum ekranını göster
    if (_categories.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Şık başlık alanı
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst başlık ve butonlar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ürünlerimiz',
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isSearchMode
                                    ? _searchQuery.isEmpty
                                        ? '${_categorizedProducts.values.expand((e) => e).length} farklı ürün'
                                        : '${_filteredProducts.values.expand((e) => e).length} sonuç bulundu'
                                    : '${_categorizedProducts.values.expand((e) => e).length} farklı ürün',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arama butonu
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search_rounded),
                            onPressed: _toggleSearchMode,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Yeni ürün ekleme butonu
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: _navigateToAddProduct,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Arama kutusu - sadece arama modunda görünür
                    if (_isSearchMode) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Ürün ara...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _toggleSearchMode,
                              color: Colors.grey.shade600,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Kategori seçici - yatay kaydırılabilir kartlar
                    SizedBox(
                      height: 70,
                      child: _categories.isNotEmpty && !_isSearchMode
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    index == _selectedCategoryIndex;
                                final categoryColor =
                                    _getCategoryColor(category);

                                return GestureDetector(
                                  onTap: () {
                                    if (_tabController != null) {
                                      _tabController!.animateTo(index);
                                      setState(() {
                                        _selectedCategoryIndex = index;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 70,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                categoryColor,
                                                categoryColor.withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isSelected ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? categoryColor.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getCategoryIcon(category),
                                          color: isSelected
                                              ? Colors.white
                                              : categoryColor,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Ürünler
            SliverFillRemaining(
              child: _isSearchMode
                  ? _buildSearchResults()
                  : _tabController != null
                      ? TabBarView(
                          controller: _tabController,
                          children: _categories.map((category) {
                            final products = _filteredProducts[category] ?? [];
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _buildProductCard(context, product);
                                },
                              ),
                            );
                          }).toList(),
                        )
                      : const Center(
                          child: Text('Kategori bulunamadı'),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Başlık alanı
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 5),
                    blurRadius: 15,
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ürünlerimiz',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Henüz ürün eklenmemiş',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Yeni ürün ekleme butonu
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: _navigateToAddProduct,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Boş durum içeriği
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // İkon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Başlık
                      Text(
                        'Henüz Ürün Yok',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Açıklama
                      Text(
                        'İlk ürününüzü ekleyerek başlayın.\nMüşterileriniz ürünlerinizi görebilsin!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Ürün ekleme butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToAddProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'İlk Ürününü Ekle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: () {
        // Ürün detay ve düzenleme sayfasını göster
        _showProductDetailSheet(context, product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün görseli - kapak kısmı
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  // Ürün görseli
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildProductImage(product),
                    ),
                  ),

                  // Durum göstergesi - sol üst
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isActive
                            ? Colors.green.withOpacity(0.9)
                            : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        product.isActive ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 8 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),

                  // Fiyat göstergesi - sağ üst (BÜYÜK)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 40 : 50,
                        maxWidth: isSmallScreen ? 80 : 100,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(product.category),
                            _getCategoryColor(product.category)
                                .withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '₺${product.price >= 1000 ? '${(product.price / 1000).toStringAsFixed(product.price % 1000 == 0 ? 0 : 1)}K' : product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),

                  // Ürün adı - alt kısım (gradient overlay ile)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 30,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.3),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        product.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ürün bilgileri - alt kısım (yeniden düzenlendi)
            Container(
              constraints: BoxConstraints(
                minHeight: isSmallScreen ? 25 : 30,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 4 : 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kategori bilgisi
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(product.category),
                          size: isSmallScreen ? 10 : 12,
                          color: _getCategoryColor(product.category),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Düzenle butonu
                  InkWell(
                    onTap: () => _showProductDetailSheet(context, product),
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 35 : 40,
                        minHeight: isSmallScreen ? 18 : 20,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: isSmallScreen ? 8 : 10,
                            color: Colors.grey.shade700,
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 3),
                          Text(
                            'Düzenle',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 7 : 8,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ürün görselini oluşturan yardımcı fonksiyon
  Widget _buildProductImage(Product product) {
    // Eğer ürünün resmi varsa onu göster
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: _getCategoryColor(product.category).withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: _getCategoryColor(product.category),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Resim yüklenemezse kategori renginde placeholder göster
          return _buildCategoryPlaceholder(product);
        },
      );
    } else {
      // Resim yoksa kategori renginde placeholder göster
      return _buildCategoryPlaceholder(product);
    }
  }

  // Kategori placeholder'ı oluşturan yardımcı fonksiyon
  Widget _buildCategoryPlaceholder(Product product) {
    final Color categoryColor = _getCategoryColor(product.category);

    return Container(
      color: categoryColor.withOpacity(0.1),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Kategori renginde gradient arka plan
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.7),
                  categoryColor.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Kategori ikonu merkeze yerleştir
          Center(
            child: Icon(
              _getCategoryIcon(product.category),
              size: 50,
              color: Colors.white.withOpacity(0.5),
            ),
          ),

          // Ürün adı altta göster
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ürün detay ve düzenleme sayfasını göster
  void _showProductDetailSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Ürün görseli ve başlık
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor(product.category).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                image: null,
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getCategoryColor(
                            product.category,
                          ).withOpacity(0.7),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: 60,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),

                  // Başlık
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(product.category),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.isActive
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.isActive ? 'Aktif' : 'Pasif',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Kapat butonu
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ürün detayları
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fiyat bilgisi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ürün Fiyatı',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₺${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Fiyat güncelleme diyalogunu göster
                              _showPriceUpdateDialog(context, product);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Fiyat Güncelle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Açıklama
                    const Text(
                      'Ürün Açıklaması',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        product.description ?? 'Açıklama bulunmuyor.',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Aksiyonlar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Ürün durumunu değiştir
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    product.isActive
                                        ? '${product.name} pasife alındı.'
                                        : '${product.name} aktife alındı.',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              product.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            label: Text(
                              product.isActive ? 'Pasife Al' : 'Aktife Al',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                        ? 12
                                        : 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width < 600
                                        ? 8
                                        : 16,
                                vertical:
                                    MediaQuery.of(context).size.width < 600
                                        ? 8
                                        : 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Ürünü düzenle
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} düzenlendi.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: Text(
                              MediaQuery.of(context).size.width < 600
                                  ? 'Kaydet'
                                  : 'Değişiklikleri Kaydet',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                        ? 12
                                        : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width < 600
                                        ? 8
                                        : 16,
                                vertical:
                                    MediaQuery.of(context).size.width < 600
                                        ? 8
                                        : 12,
                              ),
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
      ),
    );
  }

  // Fiyat güncelleme diyalogu
  void _showPriceUpdateDialog(BuildContext context, Product product) {
    final TextEditingController priceController = TextEditingController(
      text: product.price.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fiyat Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Yeni Fiyat (₺)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPriceText = priceController.text.trim();
              final newPrice = double.tryParse(newPriceText);

              if (newPrice == null || newPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen geçerli bir fiyat girin'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // ProductService kullanarak fiyatı güncelle
                final updatedProduct = Product(
                  id: product.id,
                  name: product.name,
                  price: newPrice,
                  category: product.category,
                  description: product.description,
                  isActive: product.isActive,
                  imageUrl: product.imageUrl,
                );

                await ProductService.updateProduct(product.id, updatedProduct);

                Navigator.pop(context);

                // Ürün listesini yenile
                _loadProducts();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${product.name} fiyatı ₺${newPrice.toStringAsFixed(2)} olarak güncellendi.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fiyat güncellenirken hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Arama modunda tüm sonuçları tek listede göster
    final allProducts = _filteredProducts.values.expand((e) => e).toList();

    if (allProducts.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç Bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$_searchQuery" için ürün bulunamadı.\nFarklı bir arama terimi deneyin.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
        ),
        itemCount: allProducts.length,
        itemBuilder: (context, index) {
          final product = allProducts[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }
}
