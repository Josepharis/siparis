import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/customer/screens/tabs/customer_dashboard_tab.dart';
import 'package:siparis/customer/screens/tabs/customer_companies_tab.dart';
import 'package:siparis/customer/screens/cart_screen.dart';
import 'package:siparis/customer/screens/transactions_screen.dart';
import 'package:siparis/customer/screens/tabs/customer_profile_tab.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/providers/work_request_provider.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:siparis/providers/cart_provider.dart';
import 'package:siparis/services/company_service.dart';
import 'package:siparis/providers/company_provider.dart';
import 'package:siparis/customer/screens/partner_company_detail_screen.dart';
import 'package:siparis/models/company.dart';
import 'package:siparis/middleware/subscription_guard.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int initialIndex;
  final bool skipLoading;

  const CustomerHomeScreen({
    super.key,
    this.initialIndex = 0,
    this.skipLoading = false,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late int _selectedIndex;
  final List<Widget> _tabs = [
    SubscriptionGuard(child: const CustomerDashboardTab()),
    SubscriptionGuard(child: const CustomerCompaniesTab()),
    SubscriptionGuard(
      child: Container(
        child: const Center(
          child: Text('Siparişler'),
        ),
      ),
    ),
    SubscriptionGuard(child: const TransactionsScreen()),
    SubscriptionGuard(child: const CustomerProfileTab()),
  ];
  late bool _isLoading;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    print('🔥🔥🔥 CUSTOMER HOME SCREEN BAŞLADI 🔥🔥🔥');
    print('DEBUG: CustomerHomeScreen initState çağrıldı');
    super.initState();

    // Lifecycle observer'ı ekle
    WidgetsBinding.instance.addObserver(this);

    _selectedIndex = widget.initialIndex;
    _isLoading = !widget.skipLoading;

    print(
        'DEBUG: Customer _isLoading: $_isLoading, skipLoading: ${widget.skipLoading}');

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
      print('DEBUG: Customer Loading path - _loadData çağrılıyor');
      _loadData().then((_) {
        if (mounted) {
          print(
              'DEBUG: Customer Loading tamamlandı, FAB animasyonu başlatılıyor');
          // Veri yüklendikten sonra FAB animasyonunu göster
          _fabAnimationController.forward();
          // Çalışma isteklerini kontrol et
          print('DEBUG: Customer Loading path - _checkWorkRequests çağrılıyor');
          _checkWorkRequests();
        }
      });
    } else {
      print('DEBUG: Customer Skip loading path - FAB animasyonu başlatılıyor');
      // Yükleme atlanıyorsa, hemen FAB animasyonunu başlat
      _fabAnimationController.forward();
      // Çalışma isteklerini kontrol et
      print(
          'DEBUG: Customer Skip loading path - WidgetsBinding.addPostFrameCallback ile _checkWorkRequests çağrılıyor');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print(
            'DEBUG: Customer PostFrameCallback çalıştı, _checkWorkRequests çağrılıyor');
        _checkWorkRequests();
      });
    }
  }

  @override
  void dispose() {
    // Lifecycle observer'ı temizle
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    _hidePartnerDropdown(); // Overlay temizle
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Uygulama ön plana geldiğinde UI'ı yenile
    if (state == AppLifecycleState.resumed) {
      print('🔄 Customer Home - Uygulama ön plana geldi - UI yenileniyor');
      _refreshUI();
    }
  }

  void _refreshUI() {
    if (!mounted) return;

    try {
      // Provider'ları yenile
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final companyProvider =
          Provider.of<CompanyProvider>(context, listen: false);

      // State'i yenile
      setState(() {
        // UI'ı yeniden render et
      });

      // Verileri yenile
      orderProvider.startListeningToOrders();

      // Şirket verilerini yenile
      companyProvider.loadCompanies();

      // Dropdown açıksa kapat
      if (_isDropdownOpen) {
        _hidePartnerDropdown();
      }

      // Text rendering problemlerini düzelt
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            // İkinci kez render ederek text problemlerini düzelt
          });
        }
      });

      // Animasyonları yenile
      if (_fabAnimationController.isCompleted) {
        _fabAnimationController.reset();
        _fabAnimationController.forward();
      }
    } catch (e) {
      print('❌ Customer UI yenileme hatası: $e');
    }
  }

  Future<void> _loadData() async {
    // Müşteri verilerini yükleme işlemi
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
      body: _isLoading
          ? _buildLoadingView()
          : IndexedStack(index: _selectedIndex, children: _tabs),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
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
              'Siparişleriniz Yükleniyor...',
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
          heroTag: 'customer_home_screen_fab',
          onPressed: () {
            if (_isDropdownOpen) {
              _hidePartnerDropdown();
            } else {
              _showPartnerDropdown();
            }
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
            child: AnimatedRotation(
              turns: _isDropdownOpen ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(_isDropdownOpen ? Icons.close : Icons.shopping_cart,
                  size: 28, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _showPartnerDropdown() {
    if (_isDropdownOpen) return;

    setState(() {
      _isDropdownOpen = true;
    });

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Arka plan tıklama alanı
          Positioned.fill(
            child: GestureDetector(
              onTap: _hidePartnerDropdown,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Partner firmaları dropdown
          Positioned(
            bottom: 140, // FAB'ın üstünde
            left: size.width / 2 - 160, // Ortalanmış
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 320,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.handshake_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Partner Firmalar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Partner firmalar listesi
                    Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: Consumer2<WorkRequestProvider, CompanyProvider>(
                        builder: (context, workRequestProvider, companyProvider,
                            child) {
                          final partneredCompanyIds =
                              workRequestProvider.partneredCompanies;

                          // Firestore firmalarını Company tipine dönüştür
                          final firestoreCompanies =
                              companyProvider.activeFirestoreCompanies;
                          final sampleCompanies =
                              companyProvider.activeCompanies;

                          List<Company> allCompanies = [];

                          // Firestore firmalarını dönüştür
                          for (var companyModel in firestoreCompanies) {
                            allCompanies.add(Company(
                              id: companyModel.id,
                              name: companyModel.name,
                              description: companyModel.description ?? '',
                              services: companyModel.categories ?? ['Genel'],
                              address: companyModel.address,
                              phone: companyModel.phone ?? '',
                              email: companyModel.email ?? '',
                              website: companyModel.website,
                              rating: 4.5,
                              totalProjects: 0,
                              products: companyModel.products,
                              isActive: companyModel.isActive,
                            ));
                          }

                          // Sample firmaları ekle
                          allCompanies.addAll(sampleCompanies);

                          // Partner firmaları filtrele
                          final partneredCompanies = allCompanies
                              .where((company) =>
                                  partneredCompanyIds.contains(company.id))
                              .toList();

                          if (partneredCompanies.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Henüz Partner Firma Yok',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Firmalar sekmesinden iş ortaklığı kurun',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: partneredCompanies.length,
                            itemBuilder: (context, index) {
                              final company = partneredCompanies[index];
                              return _buildDropdownCompanyItem(company);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hidePartnerDropdown() {
    if (!_isDropdownOpen) return;

    setState(() {
      _isDropdownOpen = false;
    });

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownCompanyItem(Company company) {
    return InkWell(
      onTap: () {
        _hidePartnerDropdown();
        // Partner company detail sayfasına git
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PartnerCompanyDetailScreen(company: company),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Firma logosu
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  company.name.length >= 2
                      ? company.name.substring(0, 2).toUpperCase()
                      : company.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Firma bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company.services.first,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
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
              _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
              _buildNavItem(1, Icons.business_rounded, 'Firmalar'),
              _buildNavItem(2, Icons.shopping_cart_rounded, 'Siparişler'),
              _buildNavItem(3, Icons.receipt_long_rounded, 'İşlemler'),
              _buildNavItem(4, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconData, String label) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
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
            Icon(
              iconData,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              size: isSelected ? 28 : 24,
            ),
            // Siparişler tab'ı (index 2) için label'ı gizle
            if (index != 2) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _checkWorkRequests() {
    print('DEBUG: Customer _checkWorkRequests metodu çağrıldı');

    // Çalışma isteklerini kontrol etmek için WorkRequestProvider'a eriş
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('DEBUG: Customer Provider\'lar alındı');

    // Gerçek kullanıcı ID'sini al
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      print('DEBUG: Customer Kullanıcı giriş yapmamış');
      return;
    }

    print('DEBUG: Customer Giriş yapan kullanıcı ID: ${currentUser.uid}');

    // Callback'i ayarla
    workRequestProvider.onWorkRequestsFound = (pendingRequests) {
      print(
          'DEBUG: Customer Bulunan bekleyen istek sayısı: ${pendingRequests.length}');
      if (mounted && pendingRequests.isNotEmpty) {
        print('DEBUG: Customer Alert dialog açılıyor...');
        _showWorkRequestsAlert(pendingRequests);
      } else {
        print(
            'DEBUG: Customer Alert dialog açılmıyor - mounted: $mounted, isEmpty: ${pendingRequests.isEmpty}');
      }
    };

    print('DEBUG: Customer Callback ayarlandı');

    // Firebase'den gerçek çalışma isteklerini yükle
    // Kullanıcının sahip olduğu tüm firmalara gelen istekleri çek
    print(
        'DEBUG: Customer Firebase\'den kullanıcının firmalarına gelen istekler yükleniyor...');

    workRequestProvider.loadUserCompanyRequests(currentUser.uid).then((_) {
      print('DEBUG: Customer Firebase yükleme tamamlandı');
      // Yükleme tamamlandıktan sonra kontrol et
      print('DEBUG: Customer checkWorkRequests çağrılıyor...');
      workRequestProvider.checkWorkRequests();
    }).catchError((error) {
      print('DEBUG: Customer Firebase yükleme hatası: $error');
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
    return FutureBuilder<String>(
      future: _getSenderCompanyName(request.fromUserId),
      builder: (context, snapshot) {
        String senderName = snapshot.data ?? request.fromUserName;
        String displayName =
            senderName.isNotEmpty ? senderName : 'Bilinmeyen Firma';

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
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
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
                            displayName,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                            colors: [
                              Colors.green.shade500,
                              Colors.green.shade600
                            ],
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
      },
    );
  }

  void _acceptRequest(String requestId) async {
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);

    final success = await workRequestProvider.acceptWorkRequest(requestId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çalışma isteği kabul edildi! İş ortaklığı kuruldu.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(); // Dialog'u kapat

      // Ekranı yenile - iş ortaklıkları güncellensin
      setState(() {});
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

  Future<String> _getSenderCompanyName(String userId) async {
    try {
      // CompanyService'i kullanarak kullanıcının sahip olduğu firmaları al
      final companies = await CompanyService.getUserCompanies(userId);

      if (companies.isNotEmpty) {
        // İlk firmayı döndür (kullanıcının ana firması)
        return companies.first.name;
      }

      return 'Bilinmeyen Firma';
    } catch (e) {
      print('DEBUG: Firma adı alınırken hata: $e');
      return 'Bilinmeyen Firma';
    }
  }
}
