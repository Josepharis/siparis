import 'package:flutter/material.dart';
import 'package:siparis/models/company.dart';
import '../../config/theme.dart';

class CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback? onTap;

  const CompanyCard({
    super.key,
    required this.company,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Firma avatarı
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCompanyColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      company.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Firma bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              company.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D35),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: company.isActive
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE57373),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              company.isActive ? 'Açık' : 'Kapalı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Ürün sayısı ve adres
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 14,
                            color: Color(0xFF8E8EA9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${company.products.length} ürün',
                            style: const TextStyle(
                              color: Color(0xFF666687),
                              fontSize: 12,
                            ),
                          ),
                          if (company.address != null) ...[
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFF8E8EA9),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                company.address!,
                                style: const TextStyle(
                                  color: Color(0xFF666687),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (company.phone != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: Color(0xFF8E8EA9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              company.phone,
                              style: const TextStyle(
                                color: Color(0xFF666687),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Ok ikonu
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF7B61FF),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      child: Text(
        company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7B61FF),
        ),
      ),
    );
  }

  Color _getCompanyColor() {
    // Firma adının ilk harfine göre renk belirleme
    final firstChar = company.name[0].toUpperCase();
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];
    return colors[firstChar.codeUnitAt(0) % colors.length];
  }
}
