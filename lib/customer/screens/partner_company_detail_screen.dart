import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/company.dart';
import 'package:siparis/models/product.dart';
import 'package:siparis/providers/cart_provider.dart';
import 'package:siparis/customer/screens/cart_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class PartnerCompanyDetailScreen extends StatefulWidget {
  final Company company;

  const PartnerCompanyDetailScreen({super.key, required this.company});

  @override
  State<PartnerCompanyDetailScreen> createState() =>
      _PartnerCompanyDetailScreenState();
}

class _PartnerCompanyDetailScreenState
    extends State<PartnerCompanyDetailScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  List<String> _categories = ['Tümü'];
  Map<String, int> _selectedQuantities = {}; // Her ürün için adet takibi

  @override
  void initState() {
    super.initState();
    print('DEBUG: Partner firma detayları:');
    print('DEBUG: Firma ID: ${widget.company.id}');
    print('DEBUG: Firma adı: ${widget.company.name}');
    print('DEBUG: Ürün sayısı: ${widget.company.products.length}');
    if (widget.company.products.isEmpty) {
      print('DEBUG: Firma ürünleri boş!');
    } else {
      print('DEBUG: Firma ürünleri:');
      for (var product in widget.company.products) {
        print('DEBUG: - ${product.name} (${product.id}) - ${product.price}₺');
        // Her ürün için başlangıç adedi 1
        _selectedQuantities[product.id] = 1;
      }
    }
    _loadCategories();
  }

  void _loadCategories() {
    final categories =
        widget.company.products.map((p) => p.category).toSet().toList();
    setState(() {
      _categories = ['Tümü', ...categories];
    });
  }

  List<Product> get _filteredProducts {
    return widget.company.products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Tümü' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showProductDetail(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Üst bar
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Kapat çubuğu
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Başlık ve butonlar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.arrow_back_ios_new_rounded),
                              color: Colors.black54,
                            ),
                            const Expanded(
                              child: Text(
                                'Ürün Detayı',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Consumer<CartProvider>(
                              builder: (context, cartProvider, child) {
                                final quantity =
                                    cartProvider.getQuantity(product.id);
                                return quantity > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.shopping_cart,
                                              color: Colors.green[700],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              quantity.toString(),
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ürün detayları
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ürün resmi
                        Stack(
                          children: [
                            Container(
                              height: 300,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(32),
                                  bottomRight: Radius.circular(32),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(32),
                                  bottomRight: Radius.circular(32),
                                ),
                                child: Hero(
                                  tag: 'product_${product.id}',
                                  child: Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Fiyat etiketi
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '₺${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Ürün bilgileri
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ürün adı
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Kategori ve stok durumu
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      product.category,
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green[700],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stokta',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Açıklama başlığı
                              const Text(
                                'Ürün Açıklaması',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Açıklama metni
                              Text(
                                product.description,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Firma bilgisi
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.store_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.company.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Partner Firma',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            color: Colors.blue[700],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Onaylı',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Alt bar - Adet seçimi ve sepete ekle
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      final quantity = cartProvider.getQuantity(product.id);
                      return Row(
                        children: [
                          // Adet seçici
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Azalt butonu
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final currentQty =
                                          _getQuantityForProduct(product.id);
                                      if (currentQty > 1) {
                                        setState(() {
                                          _setQuantityForProduct(
                                              product.id, currentQty - 1);
                                        });
                                      }
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.remove,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                // Adet
                                Container(
                                  width: 48,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _getQuantityForProduct(product.id)
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Artır butonu
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        final currentQty =
                                            _getQuantityForProduct(product.id);
                                        _setQuantityForProduct(
                                            product.id, currentQty + 1);
                                      });
                                    },
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(16),
                                    ),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.add,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Sepete ekle butonu
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  final qty =
                                      _getQuantityForProduct(product.id);
                                  for (var i = 0; i < qty; i++) {
                                    cartProvider.addToCart(product);
                                  }
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  quantity > 0
                                      ? 'Sepete Ekle (${quantity + _getQuantityForProduct(product.id)})'
                                      : 'Sepete Ekle',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      const Color(0xFF0D47A1),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Text(
                          widget.company.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Partner',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber[400],
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.company.rating.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Arama ve Filtreler
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Arama ve kategori dropdown'ı yan yana
                  Row(
                    children: [
                      // Arama kutusu
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Ürün ara...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kategori Dropdown
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                size: 20,
                              ),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                              items: _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: category == _selectedCategory
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: category == _selectedCategory
                                          ? AppTheme.primaryColor
                                          : Colors.grey[700],
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
          ),

          // Ürün Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: _getChildAspectRatio(context),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(product);
                },
                childCount: _filteredProducts.length,
              ),
            ),
          ),
        ],
      ),
      // Sepet butonu
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final totalItems = cartProvider.totalItems;
          if (totalItems == 0) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryColor,
            label: Row(
              children: [
                const Icon(Icons.shopping_cart),
                const SizedBox(width: 8),
                Text(
                  'Sepet ($totalItems)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showProductDetail(product),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün resmi
              Expanded(
                flex: isSmallScreen ? 2 : 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(product.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Fiyat etiketi
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ürün bilgileri
              Expanded(
                flex: isSmallScreen ? 3 : 2,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ürün adı - Sabit yükseklik ile
                      SizedBox(
                        height: isSmallScreen ? 32 : 36,
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),

                      // Kategori
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),

                      const Spacer(),

                      // Sepete ekle ve adet seçimi
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final quantity = cartProvider.getQuantity(product.id);
                          if (quantity > 0) {
                            // Ürün zaten sepette
                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Sepette: $quantity',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 13,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      cartProvider.removeFromCart(product.id),
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red,
                                      size: isSmallScreen ? 18 : 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            );
                          }
                          // Ürün sepette değil
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  // Adet seçici
                                  Container(
                                    height: isSmallScreen ? 32 : 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Azalt butonu
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              final currentQty =
                                                  _getQuantityForProduct(
                                                      product.id);
                                              if (currentQty > 1) {
                                                setState(() {
                                                  _setQuantityForProduct(
                                                      product.id,
                                                      currentQty - 1);
                                                });
                                              }
                                            },
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            child: Container(
                                              width: isSmallScreen ? 28 : 32,
                                              height: isSmallScreen ? 32 : 36,
                                              alignment: Alignment.center,
                                              child: Icon(Icons.remove,
                                                  size: isSmallScreen ? 14 : 16,
                                                  color: Colors.black54),
                                            ),
                                          ),
                                        ),
                                        // Adet
                                        Container(
                                          width: isSmallScreen ? 28 : 32,
                                          alignment: Alignment.center,
                                          color: Colors.white,
                                          child: Text(
                                            _getQuantityForProduct(product.id)
                                                .toString(),
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        // Artır butonu
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                final currentQty =
                                                    _getQuantityForProduct(
                                                        product.id);
                                                _setQuantityForProduct(
                                                    product.id, currentQty + 1);
                                              });
                                            },
                                            borderRadius:
                                                const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            child: Container(
                                              width: isSmallScreen ? 28 : 32,
                                              height: isSmallScreen ? 32 : 36,
                                              alignment: Alignment.center,
                                              child: Icon(Icons.add,
                                                  size: isSmallScreen ? 14 : 16,
                                                  color: Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  // Sepete ekle butonu
                                  SizedBox(
                                    width: double.infinity,
                                    height: isSmallScreen ? 32 : 36,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        for (var i = 0;
                                            i <
                                                _getQuantityForProduct(
                                                    product.id);
                                            i++) {
                                          cartProvider.addToCart(product);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Sepete Ekle',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) {
      return 1; // Çok küçük ekranlar için 1 sütun
    } else if (screenWidth < 800) {
      return 2; // Telefon ve küçük tabletler için 2 sütun
    } else if (screenWidth < 1200) {
      return 3; // Tablet için 3 sütun
    } else {
      return 4; // Büyük ekranlar için 4 sütun
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) {
      return 0.85; // Tek sütun için kompakt kartlar
    } else if (screenWidth < 800) {
      return 0.7; // Telefon için kompakt kartlar
    } else {
      return 0.75; // Tablet ve büyük ekranlar için
    }
  }

  // Helper method to get quantity for a product
  int _getQuantityForProduct(String productId) {
    return _selectedQuantities[productId] ?? 1;
  }

  // Helper method to set quantity for a product
  void _setQuantityForProduct(String productId, int quantity) {
    _selectedQuantities[productId] = quantity;
  }
}
