import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/subscription.dart';

class SystemStatisticsScreen extends StatefulWidget {
  const SystemStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<SystemStatisticsScreen> createState() => _SystemStatisticsScreenState();
}

class _SystemStatisticsScreenState extends State<SystemStatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  // Güvenli tarih dönüştürme helper metodu
  DateTime? _safeToDate(dynamic dateValue) {
    try {
      if (dateValue == null) return null;

      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }
    } catch (e) {
      print('⚠️ Tarih dönüştürme hatası: $e');
    }
    return null;
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Kullanıcı istatistikleri
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final subscriptionsSnapshot =
          await FirebaseFirestore.instance.collection('subscriptions').get();

      // Kullanıcı sayıları
      final totalUsers = usersSnapshot.docs.length;
      final producers = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'producer';
      }).length;
      final customers = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'customer';
      }).length;
      final admins = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'admin';
      }).length;

      // Abonelik istatistikleri
      final totalSubscriptions = subscriptionsSnapshot.docs.length;
      final activeSubscriptions = subscriptionsSnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          final subscription = Subscription.fromMap(data, doc.id);
          return subscription.isValid;
        } catch (e) {
          print('⚠️ Abonelik kontrol hatası: $e');
          return false;
        }
      }).length;

      // Bu ay kayıt olan kullanıcılar
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthUsers = usersSnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          final createdAt = _safeToDate(data['createdAt']);
          return createdAt != null && createdAt.isAfter(thisMonthStart);
        } catch (e) {
          print('⚠️ Kullanıcı tarihi kontrol hatası: $e');
          return false;
        }
      }).length;

      // Bu ay oluşturulan abonelikler
      final thisMonthSubscriptions = subscriptionsSnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          final createdAt = _safeToDate(data['createdAt']);
          return createdAt != null && createdAt.isAfter(thisMonthStart);
        } catch (e) {
          print('⚠️ Abonelik tarihi kontrol hatası: $e');
          return false;
        }
      }).length;

      // Günlük istatistikler (son 7 gün)
      List<Map<String, dynamic>> dailyStats = [];
      for (int i = 6; i >= 0; i--) {
        final day = DateTime.now().subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayUsers = usersSnapshot.docs.where((doc) {
          try {
            final data = doc.data();
            final createdAt = _safeToDate(data['createdAt']);
            return createdAt != null &&
                createdAt.isAfter(dayStart) &&
                createdAt.isBefore(dayEnd);
          } catch (e) {
            print('⚠️ Günlük kullanıcı kontrol hatası: $e');
            return false;
          }
        }).length;

        final daySubscriptions = subscriptionsSnapshot.docs.where((doc) {
          try {
            final data = doc.data();
            final createdAt = _safeToDate(data['createdAt']);
            return createdAt != null &&
                createdAt.isAfter(dayStart) &&
                createdAt.isBefore(dayEnd);
          } catch (e) {
            print('⚠️ Günlük abonelik kontrol hatası: $e');
            return false;
          }
        }).length;

        dailyStats.add({
          'date': day,
          'users': dayUsers,
          'subscriptions': daySubscriptions,
        });
      }

      setState(() {
        _statistics = {
          'totalUsers': totalUsers,
          'producers': producers,
          'customers': customers,
          'admins': admins,
          'totalSubscriptions': totalSubscriptions,
          'activeSubscriptions': activeSubscriptions,
          'inactiveSubscriptions': totalSubscriptions - activeSubscriptions,
          'thisMonthUsers': thisMonthUsers,
          'thisMonthSubscriptions': thisMonthSubscriptions,
          'dailyStats': dailyStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('❌ İstatistikleri yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstatistikler yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistem İstatistikleri'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genel istatistikler
                    const Text(
                      'Genel İstatistikler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          'Toplam Kullanıcı',
                          _statistics['totalUsers']?.toString() ?? '0',
                          Colors.blue,
                          Icons.people,
                        ),
                        _buildStatCard(
                          'Aktif Abonelik',
                          _statistics['activeSubscriptions']?.toString() ?? '0',
                          Colors.green,
                          Icons.check_circle,
                        ),
                        _buildStatCard(
                          'Üretici',
                          _statistics['producers']?.toString() ?? '0',
                          Colors.teal,
                          Icons.business,
                        ),
                        _buildStatCard(
                          'Müşteri',
                          _statistics['customers']?.toString() ?? '0',
                          Colors.orange,
                          Icons.shopping_cart,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Bu ay istatistikleri
                    const Text(
                      'Bu Ay',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Yeni Kullanıcı',
                            _statistics['thisMonthUsers']?.toString() ?? '0',
                            Colors.indigo,
                            Icons.person_add,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Yeni Abonelik',
                            _statistics['thisMonthSubscriptions']?.toString() ??
                                '0',
                            Colors.purple,
                            Icons.add_circle,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Abonelik durumu grafiği
                    const Text(
                      'Abonelik Durumu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPieSection(
                                'Aktif',
                                _statistics['activeSubscriptions'] ?? 0,
                                Colors.green,
                              ),
                              _buildPieSection(
                                'Pasif',
                                _statistics['inactiveSubscriptions'] ?? 0,
                                Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Toplam ${_statistics['totalSubscriptions'] ?? 0} Abonelik',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Son 7 gün trendi
                    const Text(
                      'Son 7 Gün Trendi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_statistics['dailyStats'] != null)
                            ..._statistics['dailyStats'].map<Widget>((dayStat) {
                              final date = dayStat['date'] as DateTime;
                              final users = dayStat['users'] as int;
                              final subscriptions =
                                  dayStat['subscriptions'] as int;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '${date.day}/${date.month}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_add,
                                              color: Colors.blue, size: 16),
                                          const SizedBox(width: 4),
                                          Text('$users'),
                                          const SizedBox(width: 16),
                                          Icon(Icons.payment,
                                              color: Colors.green, size: 16),
                                          const SizedBox(width: 4),
                                          Text('$subscriptions'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPieSection(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
