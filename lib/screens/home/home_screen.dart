import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/home/tabs/dashboard_tab.dart';
import 'package:siparis/screens/home/tabs/finance_tab.dart';
import 'package:siparis/screens/home/tabs/orders_tab.dart';
import 'package:siparis/screens/home/tabs/products_tab.dart';
import 'package:siparis/screens/budget_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late int _selectedIndex;
  final List<Widget> _tabs = [];
  late bool _isLoading;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _isLoading = !widget.skipLoading;

    _tabs.addAll([
      const DashboardTab(),
      const OrdersTab(),
      Container(), // FAB için boş tab
      const ProductsTab(),
      const FinanceTab(),
    ]);

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
      _loadData().then((_) {
        if (mounted) {
          // Veri yüklendikten sonra FAB animasyonunu göster
          _fabAnimationController.forward();
        }
      });
    } else {
      // Yükleme atlanıyorsa, hemen FAB animasyonunu başlat
      _fabAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
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
      body:
          _isLoading
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
            // Yeni sipariş ekleme ekranını aç
            // Navigator.of(context).push(...);
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
              _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
              _buildNavItem(1, Icons.receipt_long_rounded, 'Siparişler'),
              const SizedBox(width: 40), // FAB için boşluk
              _buildNavItem(3, Icons.restaurant_menu_rounded, 'Ürünler'),
              _buildNavItem(4, Icons.analytics_rounded, 'Bütçe'),
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
        // Bütçe sekmesi (4) dışındaki sekmelere tıklandığında
        if (index != 4) {
          setState(() {
            _selectedIndex = index;
          });
        }
        // Bütçe sekmesine tıklandığında
        else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetScreen()),
          ).then((_) {
            // Bütçe ekranından dönüldüğünde FAB animasyonunu yeniden göster
            if (!_fabAnimationController.isCompleted && mounted) {
              _fabAnimationController.forward();
            }
          });
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
          color:
              isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color:
                  isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondaryColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
