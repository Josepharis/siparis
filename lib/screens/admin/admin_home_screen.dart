import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import 'subscription_management_screen.dart';
import 'user_management_screen.dart';
import 'system_statistics_screen.dart';
import 'admin_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Lifecycle observer'ı ekle
    WidgetsBinding.instance.addObserver(this);
    
    // Admin kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }

  @override
  void dispose() {
    // Lifecycle observer'ı temizle
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Uygulama ön plana geldiğinde UI'ı yenile
    if (state == AppLifecycleState.resumed) {
      print('🔄 Admin Home - Uygulama ön plana geldi - UI yenileniyor');
      _refreshUI();
    }
  }

  void _refreshUI() {
    if (!mounted) return;

    try {
      // State'i yenile
      setState(() {
        // UI'ı yeniden render et
      });

      // Text rendering problemlerini düzelt
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            // İkinci kez render ederek text problemlerini düzelt
          });
        }
      });
    } catch (e) {
      print('❌ Admin UI yenileme hatası: $e');
    }
  }

  // Admin erişim kontrolü
  void _checkAdminAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Admin kontrolü - sadece admin rolüne sahip kullanıcılar girebilir
    if (authProvider.currentUser == null || !authProvider.currentUser!.isAdmin) {
      print('❌ Admin olmayan kullanıcı admin paneline erişmeye çalışıyor');
      
      // Admin değilse çıkış yapıp login'e yönlendir
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
    
    print('✅ Admin erişimi onaylandı: ${authProvider.currentUser!.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    authProvider.currentUser?.name
                            .substring(0, 1)
                            .toUpperCase() ??
                        'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'user_info',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.currentUser?.name ?? 'Admin',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authProvider.currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Çıkış Yap'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive değerler
          final screenWidth = constraints.maxWidth;
          final isTablet = screenWidth > 768;
          final isMobile = screenWidth < 600;
          final padding = isMobile ? 16.0 : 24.0;
          final crossAxisCount = isTablet ? 4 : (isMobile ? 1 : 2);
          final childAspectRatio = isMobile ? 2.0 : (isTablet ? 0.9 : 1.0);
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hoş geldin mesajı
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[600]!, Colors.indigo[700]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: isMobile ? 28 : 32,
                              ),
                            ),
                            SizedBox(height: 12),
                            Column(
                              children: [
                                Text(
                                  'Hoş Geldiniz!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Admin yönetim paneline erişiminiz var',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş Geldiniz!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Admin yönetim paneline erişiminiz var',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // Yönetim kartları başlığı
                Text(
                  'Yönetim Paneli',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // Yönetim kartları
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: isMobile ? 12 : 16,
                  crossAxisSpacing: isMobile ? 12 : 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildAdminCard(
                      title: 'Abonelik Yönetimi',
                      subtitle: 'Kullanıcı aboneliklerini yönet',
                      icon: Icons.payment,
                      color: Colors.green,
                      isMobile: isMobile,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SubscriptionManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildAdminCard(
                      title: 'Kullanıcı Yönetimi',
                      subtitle: 'Kullanıcıları görüntüle ve yönet',
                      icon: Icons.people,
                      color: Colors.blue,
                      isMobile: isMobile,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildAdminCard(
                      title: 'Sistem İstatistikleri',
                      subtitle: 'Uygulama kullanım verileri',
                      icon: Icons.analytics,
                      color: Colors.purple,
                      isMobile: isMobile,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SystemStatisticsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildAdminCard(
                      title: 'Ayarlar',
                      subtitle: 'Sistem ayarları ve konfigürasyon',
                      icon: Icons.settings,
                      color: Colors.orange,
                      isMobile: isMobile,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 16 : 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    final cardPadding = isMobile ? 16.0 : 20.0;
    final iconPadding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 28.0 : 32.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final subtitleSize = isMobile ? 11.0 : 12.0;
    final spacing = isMobile ? 12.0 : 16.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
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
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: isMobile ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Çıkış Yap'),
          content: const Text(
              'Admin panelinden çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();

                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }
}
