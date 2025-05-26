import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';

class StatusSummaryCard extends StatelessWidget {
  final int totalOrders;
  final int waitingOrders;
  final int processingOrders;
  final int completedOrders;

  const StatusSummaryCard({
    super.key,
    required this.totalOrders,
    required this.waitingOrders,
    required this.processingOrders,
    required this.completedOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF7F9FC)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.primaryColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş Özeti',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.receipt_rounded,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalOrders Sipariş',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bugün',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _buildTotalProgressRing(),
            ],
          ),

          const SizedBox(height: 20),

          // İstatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem(
                context: context,
                title: 'Bekleyen',
                value: waitingOrders,
                iconData: Icons.watch_later_outlined,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                ),
                bgColor: const Color(0xFFE3F2FD),
              ),
              _buildStatusItem(
                context: context,
                title: 'Hazırlanıyor',
                value: processingOrders,
                iconData: Icons.sync_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
                ),
                bgColor: const Color(0xFFFFF8E1),
              ),
              _buildStatusItem(
                context: context,
                title: 'Tamamlanan',
                value: completedOrders,
                iconData: Icons.check_circle_outline_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
                ),
                bgColor: const Color(0xFFE8F5E9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalProgressRing() {
    final double completionRate =
        totalOrders > 0 ? completedOrders / totalOrders : 0.0;

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          // Arka plan
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade300),
            ),
          ),

          // İlerleme
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: completionRate,
              strokeWidth: 5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
            ),
          ),

          // Yüzde
          Center(
            child: Text(
              '%${(completionRate * 100).toInt()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required BuildContext context,
    required String title,
    required int value,
    required IconData iconData,
    required Gradient gradient,
    required Color bgColor,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.27,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(iconData, color: Colors.white, size: 18),
          ),

          const SizedBox(height: 12),

          // Değer
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 4),

          // Başlık
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
