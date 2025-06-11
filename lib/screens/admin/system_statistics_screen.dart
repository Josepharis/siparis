import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/subscription.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

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
    
    // Admin kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
    
    _loadStatistics();
  }

  // Admin erişim kontrolü
  void _checkAdminAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || !authProvider.currentUser!.isAdmin) {
      print('❌ Admin olmayan kullanıcı system statistics\'e erişmeye çalışıyor');
      
      authProvider.signOut().then((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu alana erişim yetkiniz bulunmamaktadır'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return;
    }
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
    // Responsive değerler
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;
    final crossAxisCount = isTablet ? 4 : (isMobile ? 1 : 2);
    final childAspectRatio = isMobile ? 2.5 : (isTablet ? 1.2 : 1.0);
    final padding = isMobile ? 12.0 : 16.0;
    final fontSize = isMobile ? 18.0 : 20.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sistem İstatistikleri',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
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
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genel istatistikler
                    Text(
                      'Genel İstatistikler',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    
                    // Responsive Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: isMobile ? 12 : 16,
                          crossAxisSpacing: isMobile ? 12 : 16,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _buildStatCard(
                              'Toplam Kullanıcı',
                              _statistics['totalUsers']?.toString() ?? '0',
                              Colors.blue,
                              Icons.people,
                              isMobile,
                            ),
                            _buildStatCard(
                              'Aktif Abonelik',
                              _statistics['activeSubscriptions']?.toString() ?? '0',
                              Colors.green,
                              Icons.check_circle,
                              isMobile,
                            ),
                            _buildStatCard(
                              'Üretici',
                              _statistics['producers']?.toString() ?? '0',
                              Colors.teal,
                              Icons.business,
                              isMobile,
                            ),
                            _buildStatCard(
                              'Müşteri',
                              _statistics['customers']?.toString() ?? '0',
                              Colors.orange,
                              Icons.shopping_cart,
                              isMobile,
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: isMobile ? 24 : 32),

                    // Bu ay istatistikleri
                    Text(
                      'Bu Ay',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    
                    // Responsive Row/Column
                    isMobile
                        ? Column(
                            children: [
                              _buildStatCard(
                                'Yeni Kullanıcı',
                                _statistics['thisMonthUsers']?.toString() ?? '0',
                                Colors.indigo,
                                Icons.person_add,
                                isMobile,
                              ),
                              SizedBox(height: 12),
                              _buildStatCard(
                                'Yeni Abonelik',
                                _statistics['thisMonthSubscriptions']?.toString() ?? '0',
                                Colors.purple,
                                Icons.add_circle,
                                isMobile,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Yeni Kullanıcı',
                                  _statistics['thisMonthUsers']?.toString() ?? '0',
                                  Colors.indigo,
                                  Icons.person_add,
                                  isMobile,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Yeni Abonelik',
                                  _statistics['thisMonthSubscriptions']?.toString() ?? '0',
                                  Colors.purple,
                                  Icons.add_circle,
                                  isMobile,
                                ),
                              ),
                            ],
                          ),

                    SizedBox(height: isMobile ? 24 : 32),

                    // Abonelik durumu grafiği
                    Text(
                      'Abonelik Durumu',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                          isMobile
                              ? Column(
                                  children: [
                                    _buildPieSection(
                                      'Aktif',
                                      _statistics['activeSubscriptions'] ?? 0,
                                      Colors.green,
                                      isMobile,
                                    ),
                                    SizedBox(height: 16),
                                    _buildPieSection(
                                      'Pasif',
                                      _statistics['inactiveSubscriptions'] ?? 0,
                                      Colors.red,
                                      isMobile,
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildPieSection(
                                      'Aktif',
                                      _statistics['activeSubscriptions'] ?? 0,
                                      Colors.green,
                                      isMobile,
                                    ),
                                    _buildPieSection(
                                      'Pasif',
                                      _statistics['inactiveSubscriptions'] ?? 0,
                                      Colors.red,
                                      isMobile,
                                    ),
                                  ],
                                ),
                          SizedBox(height: isMobile ? 16 : 20),
                          Text(
                            'Toplam ${_statistics['totalSubscriptions'] ?? 0} Abonelik',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 24 : 32),

                    // Son 7 gün trendi
                    Text(
                      'Son 7 Gün Trendi',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                                padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 6 : 8,
                                ),
                                child: isMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${date.day}/${date.month}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.person_add,
                                                  color: Colors.blue, size: 16),
                                              SizedBox(width: 4),
                                              Text('$users kullanıcı'),
                                              SizedBox(width: 16),
                                              Icon(Icons.payment,
                                                  color: Colors.green, size: 16),
                                              SizedBox(width: 4),
                                              Text('$subscriptions abonelik'),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Row(
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

                    SizedBox(height: isMobile ? 16 : 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon, bool isMobile) {
    final cardPadding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 24.0 : 28.0;
    final valueSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 11.0 : 12.0;
    final iconPadding = isMobile ? 10.0 : 12.0;
    final spacing = isMobile ? 8.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
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
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
          SizedBox(height: spacing),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPieSection(String label, int value, Color color, bool isMobile) {
    final circleSize = isMobile ? 50.0 : 60.0;
    final valueSize = isMobile ? 16.0 : 18.0;
    final labelSize = isMobile ? 12.0 : 14.0;
    
    return Column(
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(circleSize / 2),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
