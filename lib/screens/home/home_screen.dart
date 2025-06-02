import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:siparis/providers/subscription_provider.dart';
import 'package:siparis/providers/work_request_provider.dart';
import 'package:siparis/screens/home/tabs/dashboard_tab.dart';
import 'package:siparis/screens/home/tabs/finance_tab.dart';
import 'package:siparis/screens/home/tabs/orders_tab.dart';
import 'package:siparis/screens/home/tabs/products_tab.dart';
import 'package:siparis/screens/budget_screen.dart';
import 'package:siparis/screens/stock_screen.dart';
import 'package:siparis/screens/selection_screen.dart';
import 'package:siparis/screens/admin/subscription_management_screen.dart';
import 'package:siparis/middleware/subscription_guard.dart';
// import 'package:siparis/screens/home/tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final bool skipLoading;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.skipLoading = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late int _selectedIndex;
  final List<Widget> _tabs = [];
  late bool _isLoading;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    print('DEBUG: HomeScreen initState çağrıldı');
    super.initState();

    // Lifecycle observer'ı ekle
    WidgetsBinding.instance.addObserver(this);

    _selectedIndex = widget.initialIndex;
    _isLoading = !widget.skipLoading;

    print('DEBUG: _isLoading: $_isLoading, skipLoading: ${widget.skipLoading}');

    _tabs.addAll([
      SubscriptionGuard(child: const DashboardTab()),
      SubscriptionGuard(child: const OrdersTab()),
      Container(), // FAB için boş tab
      SubscriptionGuard(child: const ProductsTab()),
      SubscriptionGuard(child: const BudgetScreen()),
    ]);

    // Çalışan ise geçersiz tab kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isEmployeeLogin) {
        _validateCurrentTab();
      }
    });

    // FAB animasyonu
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    // Yükleme durumunu ve FAB animasyonunu başlat
    if (_isLoading) {
      print('DEBUG: Loading path - _loadData çağrılıyor');
      _loadData().then((_) {
        if (mounted) {
          print('DEBUG: Loading tamamlandı, FAB animasyonu başlatılıyor');
          // Veri yüklendikten sonra FAB animasyonunu göster
          _fabAnimationController.forward();
          // Çalışma isteklerini kontrol et
          print('DEBUG: Loading path - _checkWorkRequests çağrılıyor');
          _checkWorkRequests();
        }
      });
    } else {
      print('DEBUG: Skip loading path - FAB animasyonu başlatılıyor');
      // Yükleme atlanıyorsa, hemen FAB animasyonunu başlat
      _fabAnimationController.forward();
      // Çalışma isteklerini kontrol et
      print(
          'DEBUG: Skip loading path - WidgetsBinding.addPostFrameCallback ile _checkWorkRequests çağrılıyor');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print(
            'DEBUG: PostFrameCallback çalıştı, _checkWorkRequests çağrılıyor');
        _checkWorkRequests();
      });
    }
  }

  @override
  void dispose() {
    // Lifecycle observer'ı temizle
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Uygulama ön plana geldiğinde UI'ı yenile
    if (state == AppLifecycleState.resumed) {
      print('🔄 Uygulama ön plana geldi - UI yenileniyor');
      _refreshUI();
    }
  }

  void _refreshUI() {
    if (!mounted) return;

    try {
      // Provider'ları yenile
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);

      // State'i yenile
      setState(() {
        // UI'ı yeniden render et
      });

      // Verileri yenile
      orderProvider.startListeningToOrders();

      // Abonelik durumunu kontrol et
      if (authProvider.currentUser != null) {
        subscriptionProvider
            .loadUserSubscription(authProvider.currentUser!.uid);
      } else if (authProvider.currentEmployee != null &&
          authProvider.currentEmployee!.companyId.isNotEmpty) {
        subscriptionProvider
            .loadCompanySubscription(authProvider.currentEmployee!.companyId);
      }

      // Text rendering problemlerini düzelt
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            // İkinci kez render ederek text problemlerini düzelt
          });
        }
      });
    } catch (e) {
      print('❌ UI yenileme hatası: $e');
    }
  }

  Future<void> _loadData() async {
    // Veri yükleme işlemi
    await Provider.of<OrderProvider>(context, listen: false).loadOrders();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _selectedIndex == 0
          ? _buildAppBar()
          : null, // Sadece dashboard'da AppBar göster
      body: _isLoading
          ? _buildLoadingView()
          : IndexedStack(index: _selectedIndex, children: _tabs),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Text(
            'Sipariş Takip',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          // Abonelik durumu göstergesi
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              if (subscriptionProvider.hasActiveSubscription) {
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showLogoutDialog(),
          icon: const Icon(
            Icons.logout,
            color: AppTheme.primaryColor,
          ),
          tooltip: 'Çıkış Yap',
        ),
      ],
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
          title: const Text(
            'Çıkış Yap',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          content: const Text(
            'Uygulamadan çıkış yapmak istediğinizden emin misiniz?',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dialog'u kapat

                // AuthProvider'dan çıkış yap
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();

                // Ana sayfaya yönlendir
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppTheme.backgroundColor],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Siparişler Yükleniyor...',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 25),
        child: FloatingActionButton(
          heroTag: 'home_screen_fab',
          onPressed: () {
            // Seçim ekranına yönlendir
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SelectionScreen()),
            );
          },
          elevation: 2,
          highlightElevation: 5,
          backgroundColor: AppTheme.primaryColor,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withBlue(255).withRed(60),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomAppBar(
          height: 70,
          padding: EdgeInsets.zero,
          elevation: 0,
          notchMargin: 10,
          shape: const CircularNotchedRectangle(),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Ana Sayfa - herkese açık
              _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),

              // Siparişler - her zaman görünür
              _buildNavItem(1, Icons.receipt_long_rounded, 'Siparişler'),

              // FAB için boşluk
              const SizedBox(width: 40),

              // Ürünler - her zaman görünür
              _buildNavItem(3, Icons.restaurant_menu_rounded, 'Ürünler'),

              // Bütçe - her zaman görünür
              _buildNavItem(4, Icons.analytics_rounded, 'Bütçe'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconData, String label) {
    final isSelected = _selectedIndex == index;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Yetki kontrolü
    bool hasAccess = false;
    switch (index) {
      case 0: // Ana Sayfa
        hasAccess = true;
        break;
      case 1: // Siparişler
        hasAccess = authProvider.hasPermission('manage_orders');
        break;
      case 3: // Ürünler
        hasAccess = authProvider.hasPermission('manage_products');
        break;
      case 4: // Bütçe
        hasAccess = authProvider.hasPermission('view_budget') ||
            authProvider.hasPermission('view_partial_budget');
        break;
      default:
        hasAccess = false;
    }

    return InkWell(
      onTap: () {
        if (hasAccess) {
          setState(() {
            _selectedIndex = index;
          });
        } else {
          // Yetki yoksa uyarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bu alana erişim izniniz bulunmamaktadır.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      customBorder: const CircleBorder(),
      splashColor: AppTheme.primaryColor.withOpacity(0.1),
      highlightColor: AppTheme.primaryColor.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 50,
        width: 65,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  iconData,
                  color: hasAccess
                      ? (isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor)
                      : AppTheme.textSecondaryColor.withOpacity(0.3),
                  size: isSelected ? 28 : 24,
                ),
                // Yetkisiz sekmeler için kilit ikonu
                if (!hasAccess)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: hasAccess
                    ? (isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondaryColor)
                    : AppTheme.textSecondaryColor.withOpacity(0.3),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkWorkRequests() {
    print('DEBUG: _checkWorkRequests metodu çağrıldı');

    // Çalışma isteklerini kontrol etmek için WorkRequestProvider'a eriş
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('DEBUG: Provider\'lar alındı');

    // Gerçek kullanıcı ID'sini al
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      print('DEBUG: Kullanıcı giriş yapmamış');
      return;
    }

    print('DEBUG: Giriş yapan kullanıcı ID: ${currentUser.uid}');

    // Callback'i ayarla
    workRequestProvider.onWorkRequestsFound = (pendingRequests) {
      print('DEBUG: Bulunan bekleyen istek sayısı: ${pendingRequests.length}');
      if (mounted && pendingRequests.isNotEmpty) {
        print('DEBUG: Alert dialog açılıyor...');
        _showWorkRequestsAlert(pendingRequests);
      } else {
        print(
            'DEBUG: Alert dialog açılmıyor - mounted: $mounted, isEmpty: ${pendingRequests.isEmpty}');
      }
    };

    print('DEBUG: Callback ayarlandı');

    // Firebase'den gerçek çalışma isteklerini yükle
    // Kullanıcının sahip olduğu tüm firmalara gelen istekleri çek
    print(
        'DEBUG: Firebase\'den kullanıcının firmalarına gelen istekler yükleniyor...');

    workRequestProvider.loadUserCompanyRequests(currentUser.uid).then((_) {
      print('DEBUG: Firebase yükleme tamamlandı');
      // Yükleme tamamlandıktan sonra kontrol et
      print('DEBUG: checkWorkRequests çağrılıyor...');
      workRequestProvider.checkWorkRequests();
    }).catchError((error) {
      print('DEBUG: Firebase yükleme hatası: $error');
    });
  }

  void _showWorkRequestsAlert(List<dynamic> pendingRequests) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withBlue(255).withRed(60),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Yeni Çalışma İstekleri',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pendingRequests.length} adet yeni istek',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: pendingRequests.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final request = pendingRequests[index];
                              return _buildRequestCard(request);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Sonra Bak',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
  }

  Widget _buildRequestCard(dynamic request) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      request.fromUserName.isNotEmpty
                          ? request.fromUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fromUserName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sizinle çalışmak istiyor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Yeni',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message
            if (request.message.isNotEmpty &&
                request.message != 'Merhaba, sizinle çalışmak istiyorum.')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _rejectRequest(request.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reddet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade500, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _acceptRequest(request.id),
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Kabul Et',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRequest(String requestId) async {
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);

    final success = await workRequestProvider.acceptWorkRequest(requestId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çalışma isteği kabul edildi'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Dialog'u kapat
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İstek kabul edilirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectRequest(String requestId) async {
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);

    final success = await workRequestProvider.rejectWorkRequest(requestId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çalışma isteği reddedildi'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop(); // Dialog'u kapat
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İstek reddedilirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Çalışan için geçersiz tab kontrolü
  void _validateCurrentTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool canAccessCurrentTab = false;

    switch (_selectedIndex) {
      case 0: // Ana Sayfa
        canAccessCurrentTab = true;
        break;
      case 1: // Siparişler
        canAccessCurrentTab = authProvider.hasPermission('manage_orders');
        break;
      case 3: // Ürünler
        canAccessCurrentTab = authProvider.hasPermission('manage_products');
        break;
      case 4: // Bütçe
        canAccessCurrentTab = authProvider.hasPermission('view_budget') ||
            authProvider.hasPermission('view_partial_budget');
        break;
      default:
        canAccessCurrentTab = false;
    }

    // Eğer mevcut tab'e erişim yoksa ana sayfaya yönlendir
    if (!canAccessCurrentTab && mounted) {
      setState(() {
        _selectedIndex = 0; // Ana sayfaya yönlendir
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erişim yetkiniz olmayan bölümden ana sayfaya yönlendirildiniz.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

// Navigation item helper sınıfı
class NavItem {
  final int index;
  final IconData icon;
  final String label;
  final bool isVisible;

  NavItem({
    required this.index,
    required this.icon,
    required this.label,
    this.isVisible = true,
  });
}
