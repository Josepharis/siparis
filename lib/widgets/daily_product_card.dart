import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';

class DailyProductCard extends StatelessWidget {
  final String name;
  final int quantity;
  final String category;
  final String? imageUrl;

  const DailyProductCard({
    super.key,
    required this.name,
    required this.quantity,
    required this.category,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Kategoriye göre bir renk ve ikon belirle
    final categoryInfo = _getCategoryInfo(category);

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün görseli veya kategori ikonu
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryInfo.color.withOpacity(0.8),
                      categoryInfo.color.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child:
                      imageUrl != null
                          ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: Image.network(
                              imageUrl!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _buildCategoryIcon(categoryInfo),
                            ),
                          )
                          : _buildCategoryIcon(categoryInfo),
                ),
              ),

              // İçerik
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: categoryInfo.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Ürün adı
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 5),

                    // Üretim adedi
                    Row(
                      children: [
                        Icon(
                          Icons.add_business_rounded,
                          size: 14,
                          color: categoryInfo.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$quantity adet üretilecek',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Miktar rozeti
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: quantity > 10 ? Colors.redAccent : Colors.orangeAccent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(_CategoryInfo categoryInfo) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(categoryInfo.icon, color: Colors.white, size: 30),
    );
  }

  _CategoryInfo _getCategoryInfo(String category) {
    switch (category) {
      case 'Tatlılar':
        return _CategoryInfo(
          color: const Color(0xFFEC407A),
          icon: Icons.cake_rounded,
        );
      case 'Hamur İşleri':
        return _CategoryInfo(
          color: const Color(0xFFFFA726),
          icon: Icons.breakfast_dining_rounded,
        );
      case 'Kurabiyeler':
        return _CategoryInfo(
          color: const Color(0xFFFF7043),
          icon: Icons.cookie_rounded,
        );
      case 'Pastalar':
        return _CategoryInfo(
          color: const Color(0xFF7E57C2),
          icon: Icons.cake_rounded,
        );
      case 'Şerbetli Tatlılar':
        return _CategoryInfo(
          color: const Color(0xFFFF5722),
          icon: Icons.local_dining_rounded,
        );
      case 'Ekmekler':
        return _CategoryInfo(
          color: const Color(0xFF8D6E63),
          icon: Icons.bakery_dining_rounded,
        );
      default:
        return _CategoryInfo(
          color: const Color(0xFF42A5F5),
          icon: Icons.restaurant_rounded,
        );
    }
  }
}

class _CategoryInfo {
  final Color color;
  final IconData icon;

  _CategoryInfo({required this.color, required this.icon});
}
