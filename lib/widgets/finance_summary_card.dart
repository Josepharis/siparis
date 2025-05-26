import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:siparis/config/theme.dart';

class FinanceSummaryCard extends StatelessWidget {
  final double totalAmount;
  final double collectedAmount;
  final double pendingAmount;
  final double collectionRate;

  const FinanceSummaryCard({
    super.key,
    required this.totalAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.collectionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient başlık
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.95),
                  AppTheme.primaryColor.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Finansal Durum',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toplam Ciro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '%${collectionRate.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            collectionRate >= 80
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color:
                                collectionRate >= 80
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // İçerik bölümü
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.check_circle_rounded,
                      title: 'Tahsil Edilen',
                      amount: collectedAmount,
                      currency: '₺',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _buildSummaryItem(
                      icon: Icons.pending_rounded,
                      title: 'Bekleyen',
                      amount: pendingAmount,
                      currency: '₺',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Grafik bölümü
                AspectRatio(
                  aspectRatio: 1.8,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: collectedAmount,
                          color: AppTheme.successColor,
                          radius: 60,
                          title: '${(collectionRate).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          badgeWidget: _Badge(
                            size: 40,
                            borderColor: AppTheme.successColor,
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          badgePositionPercentageOffset: .98,
                        ),
                        PieChartSectionData(
                          value: pendingAmount,
                          color: AppTheme.warningColor,
                          radius: 55,
                          title:
                              '${(100 - collectionRate).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          badgeWidget: _Badge(
                            size: 40,
                            borderColor: AppTheme.warningColor,
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          badgePositionPercentageOffset: .98,
                        ),
                      ],
                      sectionsSpace: 5,
                      centerSpaceRadius: 0,
                      startDegreeOffset: 270,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Alt bilgi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppTheme.successColor, 'Tahsil Edilen'),
                    const SizedBox(width: 20),
                    _buildLegendItem(AppTheme.warningColor, 'Bekleyen'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required double amount,
    required String currency,
    required Gradient gradient,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Widget child;
  final double size;
  final Color borderColor;

  const _Badge({
    required this.child,
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
