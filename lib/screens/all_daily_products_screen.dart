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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Günlük Üretilecekler',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${products.length} Ürün',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
          // Tarih bilgisi - daha kompakt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bugün üretilmesi gereken ürünler',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Ürün listesi - satır satır daha fazla ürün gösterelim
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sortedProducts.length,
                    itemBuilder: (context, index) {
                      final entry = sortedProducts[index];
                      final product = entry.value;
                      return _buildCompactProductRow(context, product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProductRow(
      BuildContext context, DailyProductSummary product) {
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol taraf - Kategori ikonu
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(product.category),
                    _getCategoryColor(product.category).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // Orta kısım - Ürün bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
              ),
            ),

            // Sağ taraf - Miktar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _getCategoryColor(product.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${product.totalQuantity}',
                    style: TextStyle(
                      color: _getCategoryColor(product.category),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
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

            const SizedBox(width: 8),

            // Detay ok ikonu
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bakery_dining_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bugün için üretilecek ürün yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni siparişler geldiğinde burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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
