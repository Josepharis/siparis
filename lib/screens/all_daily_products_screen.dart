import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

class AllDailyProductsScreen extends StatelessWidget {
  final Map<String, DailyProductSummary> products;

  const AllDailyProductsScreen({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final sortedProducts = products.entries.toList()
      ..sort((a, b) => b.value.totalQuantity.compareTo(a.value.totalQuantity));

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Günlük Üretilecekler',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bakery_dining_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 14 : 16,
                ),
                SizedBox(width: isSmallScreen ? 4 : 6),
                Text(
                  '${products.length} Ürün',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tarih bilgisi - responsive
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange[600]!,
                  Colors.orange[400]!,
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  _getTodayDateText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  'Bugün üretilmesi gereken ürünler',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Ürün listesi - responsive padding ve spacing
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState(isSmallScreen)
                : ListView.builder(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    itemCount: sortedProducts.length,
                    itemBuilder: (context, index) {
                      final entry = sortedProducts[index];
                      final product = entry.value;
                      return _buildCompactProductRow(
                          context, product, isSmallScreen);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProductRow(
      BuildContext context, DailyProductSummary product, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: isSmallScreen ? 6 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol taraf - Kategori ikonu (responsive boyut)
            Container(
              width: isSmallScreen ? 40 : 50,
              height: isSmallScreen ? 40 : 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(product.category),
                    _getCategoryColor(product.category).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                color: Colors.white,
                size: isSmallScreen ? 20 : 24,
              ),
            ),

            SizedBox(width: isSmallScreen ? 8 : 12),

            // Orta kısım - Ürün bilgileri (responsive font ve spacing)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: isSmallScreen ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),

                  // Telefonda daha kompakt layout
                  if (isSmallScreen) ...[
                    // Telefon layout - dikey
                    Row(
                      children: [
                        Icon(
                          _getCategorySmallIcon(product.category),
                          size: 10,
                          color: _getCategoryColor(product.category),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product.category,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (product.firmaCounts != null &&
                        product.firmaCounts!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(product.category)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.business_rounded,
                              size: 8,
                              color: _getCategoryColor(product.category),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.firmaCounts!.length} firma',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(product.category),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Tablet layout - yatay
                    Row(
                      children: [
                        Icon(
                          _getCategorySmallIcon(product.category),
                          size: 12,
                          color: _getCategoryColor(product.category),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.firmaCounts != null &&
                            product.firmaCounts!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(product.category)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 10,
                                  color: _getCategoryColor(product.category),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${product.firmaCounts!.length} firma',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getCategoryColor(product.category),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Sağ taraf - Miktar (responsive boyut)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 12,
                vertical: isSmallScreen ? 4 : 8,
              ),
              decoration: BoxDecoration(
                color: _getCategoryColor(product.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                border: Border.all(
                  color: _getCategoryColor(product.category).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.production_quantity_limits_rounded,
                    color: _getCategoryColor(product.category),
                    size: isSmallScreen ? 12 : 16,
                  ),
                  SizedBox(width: isSmallScreen ? 3 : 6),
                  Text(
                    '${product.totalQuantity}',
                    style: TextStyle(
                      color: _getCategoryColor(product.category),
                      fontSize: isSmallScreen ? 12 : 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 1 : 2),
                  if (!isSmallScreen)
                    Text(
                      'adet',
                      style: TextStyle(
                        color: _getCategoryColor(product.category),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: isSmallScreen ? 4 : 8),

            // Detay ok ikonu (responsive boyut)
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: isSmallScreen ? 12 : 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bakery_dining_rounded,
              size: isSmallScreen ? 36 : 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'Bugün için üretilecek ürün yok',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Yeni siparişler geldiğinde burada görünecek',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTodayDateText() {
    final now = DateTime.now();
    final formatter = DateFormat.yMMMMEEEEd('tr_TR');
    return formatter.format(now);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Colors.pink[400]!;
      case 'hamur işleri':
        return Colors.amber[600]!;
      case 'kurabiyeler':
        return Colors.orange[500]!;
      case 'pastalar':
        return Colors.purple[400]!;
      default:
        return Colors.blue[400]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.cake;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'kurabiyeler':
        return Icons.cookie;
      case 'pastalar':
        return Icons.cake_rounded;
      default:
        return Icons.fastfood;
    }
  }

  IconData _getCategorySmallIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.bakery_dining;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'kurabiyeler':
        return Icons.cookie;
      case 'pastalar':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }
}
