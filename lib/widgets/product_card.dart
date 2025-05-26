import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            // ProductDetailScreen, DailyProductSummary alıyor ama bizde Product var
            // Bu nedenle doğrudan yönlendirme yapamıyoruz
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => ProductDetailScreen(product: product),
            //   ),
            // );
          },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün görseli/rengi başlık
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Arkaplan resmi veya renk
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                  child: _buildProductImage(),
                ),

                // Durum etiketi
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          product.isActive
                              ? const Color(0xFF66BB6A)
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.isActive
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.isActive ? 'Aktif' : 'Pasif',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fiyat etiketi
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: AppTheme.primaryColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Kategori rozeti - alt ortalı
                Positioned(
                  bottom: -15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(product.category),
                            _getCategoryColor(
                              product.category,
                            ).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(
                              product.category,
                            ).withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(product.category),
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün adı
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Ürün açıklaması
                  if (product.description != null &&
                      product.description!.isNotEmpty)
                    Text(
                      product.description!,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Düzenle butonu
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Düzenle',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildProductImage() {
    return Stack(
      children: [
        // Arkaplan rengi
        Container(
          height: 140,
          width: double.infinity,
          color: _getCategoryColor(product.category).withOpacity(0.15),
        ),

        // Resim veya ikon
        if (product.imageUrl != null)
          Image.network(
            product.imageUrl!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCategoryIcon(),
          )
        else
          _buildCategoryIcon(),
      ],
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(product.category).withOpacity(0.2),
            _getCategoryColor(product.category).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(product.category),
          size: 50,
          color: _getCategoryColor(product.category).withOpacity(0.5),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tatlılar':
        return const Color(0xFFEC407A);
      case 'Hamur İşleri':
        return const Color(0xFFFFA726);
      case 'Kurabiyeler':
        return const Color(0xFFFF7043);
      case 'Pastalar':
        return const Color(0xFF7E57C2);
      case 'Şerbetli Tatlılar':
        return const Color(0xFFFF5722);
      case 'Ekmekler':
        return const Color(0xFF8D6E63);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tatlılar':
        return Icons.cake_rounded;
      case 'Hamur İşleri':
        return Icons.breakfast_dining_rounded;
      case 'Kurabiyeler':
        return Icons.cookie_rounded;
      case 'Pastalar':
        return Icons.cake_rounded;
      case 'Şerbetli Tatlılar':
        return Icons.local_dining_rounded;
      case 'Ekmekler':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
