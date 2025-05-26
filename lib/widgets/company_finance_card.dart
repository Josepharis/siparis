import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';

class CompanyFinanceCard extends StatelessWidget {
  final CompanySummary company;
  final VoidCallback onTap;

  const CompanyFinanceCard({
    super.key,
    required this.company,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Firma avatarı
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _getCompanyColor(company.company.name),
                            _getCompanyColor(company.company.name).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getCompanyColor(company.company.name).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          company.company.name.substring(0, 1),
                          style: TextStyle(
                            color: _getCompanyColor(company.company.name),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
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
                          Text(
                            company.company.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${company.totalOrders} Sipariş',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (company.company.phoneNumber != null) ...[
                                Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  company.company.phoneNumber!,
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Finansal özet
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Toplam tutar
                    _buildFinanceItem(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppTheme.primaryColor,
                      title: 'Toplam Tutar',
                      value: '₺${company.totalAmount.toStringAsFixed(2)}',
                    ),
                    
                    // Tahsil edilen
                    _buildFinanceItem(
                      context,
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.successColor,
                      title: 'Tahsil Edilen',
                      value: '₺${company.paidAmount.toStringAsFixed(2)}',
                    ),
                    
                    // Bekleyen ödeme
                    _buildFinanceItem(
                      context,
                      icon: Icons.pending_rounded,
                      iconColor: AppTheme.warningColor,
                      title: 'Bekleyen',
                      value: '₺${company.pendingAmount.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // İlerleme çubuğu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tahsilat Oranı',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCollectionRateColor(company.collectionRate).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '%${company.collectionRate.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: _getCollectionRateColor(company.collectionRate),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: (company.collectionRate / 100) * MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getProgressGradient(company.collectionRate),
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: _getCollectionRateColor(company.collectionRate).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Color _getCompanyColor(String name) {
    final colors = [
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEC407A), // Pink
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFF42A5F5), // Blue
    ];

    final index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  Color _getCollectionRateColor(double rate) {
    if (rate >= 80) return const Color(0xFF4CAF50);
    if (rate >= 60) return const Color(0xFF8BC34A);
    if (rate >= 40) return const Color(0xFFFFC107);
    if (rate >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
  
  List<Color> _getProgressGradient(double rate) {
    if (rate >= 80) {
      return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
    } else if (rate >= 60) {
      return [const Color(0xFF8BC34A), const Color(0xFFCDDC39)];
    } else if (rate >= 40) {
      return [const Color(0xFFFFC107), const Color(0xFFFFEB3B)];
    } else if (rate >= 20) {
      return [const Color(0xFFFF9800), const Color(0xFFFFC107)];
    } else {
      return [const Color(0xFFF44336), const Color(0xFFFF5722)];
    }
  }
}
