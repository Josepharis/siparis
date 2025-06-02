import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/cart_provider.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/models/company_group.dart';
import 'package:siparis/models/cart_item.dart';
import 'package:siparis/models/order.dart' as order_models;
import 'package:siparis/models/product.dart' as product_models;
import 'package:siparis/services/order_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:siparis/providers/auth_provider.dart';

// Arka plan deseni için özel painter sınıfı
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.03)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double spacing = 30;
    final double radius = 10;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Lifecycle observer'ı ekle
    WidgetsBinding.instance.addObserver(this);
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
      print('🔄 Cart Screen - Uygulama ön plana geldi - UI yenileniyor');
      _refreshUI();
    }
  }

  void _refreshUI() {
    if (!mounted) return;

    try {
      // Provider'ları yenile
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

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
      print('❌ Cart UI yenileme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: const Color(0xFF1F2937),
              size: isSmallScreen ? 18 : 20,
            ),
          ),
        ),
        title: Text(
          'Sepetim',
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: isSmallScreen ? 18 : 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isSmallScreen)
            // Telefon için kompakt buton
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('Sepeti Temizle'),
                      content: const Text(
                          'Sepetinizdeki tüm ürünler silinecek. Emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<CartProvider>(context, listen: false)
                                .clearCart();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sepet temizlendi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 16,
                ),
                label: const Text(
                  'Sil',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          else
            // Büyük ekranlar için normal buton
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('Sepeti Temizle'),
                      content: const Text(
                          'Sepetinizdeki tüm ürünler silinecek. Emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<CartProvider>(context, listen: false)
                                .clearCart();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sepet temizlendi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Stack(
              children: [
                // Arka plan deseni
                Positioned.fill(
                  child: CustomPaint(
                    painter: BackgroundPatternPainter(),
                  ),
                ),
                // Boş sepet içeriği
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Sepetiniz Boş',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hemen alışverişe başlayın!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Alışverişe Başla',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              // Arka plan deseni
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundPatternPainter(),
                ),
              ),
              Column(
                children: [
                  // Üst boşluk (AppBar için)
                  const SizedBox(height: kToolbarHeight + 20),

                  // Sepet özeti
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 20),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 16 : 24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: isSmallScreen ? 15 : 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 12 : 16),
                            ),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cart.items.length} Ürün',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 2 : 4),
                              Text(
                                'Toplam: ₺${cart.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Ürün Listesi
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 20),
                      itemCount:
                          _groupItemsByCompany(cart.items.values.toList())
                              .length,
                      itemBuilder: (context, index) {
                        final companyGroup = _groupItemsByCompany(
                            cart.items.values.toList())[index];
                        return Container(
                          margin:
                              EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 16 : 24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: isSmallScreen ? 15 : 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Firma Başlığı
                              Container(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 12 : 20),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.03),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(
                                        isSmallScreen ? 16 : 24),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isSmallScreen ? 40 : 48,
                                      height: isSmallScreen ? 40 : 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor,
                                            AppTheme.primaryColor
                                                .withOpacity(0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 10 : 14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          companyGroup.companyName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 16 : 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 12 : 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            companyGroup.companyName,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 15 : 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${companyGroup.items.length} Ürün',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 12,
                                        vertical: isSmallScreen ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₺${_calculateCompanyTotal(companyGroup.items).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Firma Ürünleri
                              ...companyGroup.items.map((item) => Dismissible(
                                    key: Key(item.product.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[400],
                                        size: 24,
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      cart.removeFromCart(item.product.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${item.product.name} sepetten çıkarıldı'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          action: SnackBarAction(
                                            label: 'Geri Al',
                                            onPressed: () {
                                              cart.addToCart(item.product);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 12,
                                        vertical: isSmallScreen ? 8 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[100]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Ürün Görseli
                                          Hero(
                                            tag: 'product_${item.product.id}',
                                            child: Container(
                                              width: isSmallScreen ? 50 : 60,
                                              height: isSmallScreen ? 50 : 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        isSmallScreen
                                                            ? 10
                                                            : 12),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      item.product.imageUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                              width: isSmallScreen ? 12 : 16),
                                          // Ürün Bilgileri
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.product.name,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 12 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF1F2937),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(
                                                    height:
                                                        isSmallScreen ? 1 : 2),
                                                Text(
                                                  '₺${item.product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 11 : 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Adet Kontrolü
                                          Container(
                                            padding: EdgeInsets.all(
                                                isSmallScreen ? 4 : 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                _buildQuantityButton(
                                                  icon: item.quantity == 1
                                                      ? Icons.delete_outline
                                                      : Icons.remove,
                                                  color: item.quantity == 1
                                                      ? Colors.red
                                                      : Colors.grey[700]!,
                                                  onPressed: () {
                                                    if (item.quantity > 1) {
                                                      cart.updateQuantity(
                                                        item.product.id,
                                                        item.quantity - 1,
                                                      );
                                                    } else {
                                                      cart.removeFromCart(
                                                          item.product.id);
                                                    }
                                                  },
                                                  isSmallScreen: isSmallScreen,
                                                ),
                                                Container(
                                                  width:
                                                      isSmallScreen ? 28 : 36,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    item.quantity.toString(),
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen
                                                          ? 14
                                                          : 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ),
                                                _buildQuantityButton(
                                                  icon: Icons.add,
                                                  color: AppTheme.primaryColor,
                                                  onPressed: () {
                                                    cart.updateQuantity(
                                                      item.product.id,
                                                      item.quantity + 1,
                                                    );
                                                  },
                                                  isSmallScreen: isSmallScreen,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Alt Toplam ve Sipariş Ver
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 24,
                      isSmallScreen ? 12 : 20,
                      isSmallScreen ? 16 : 24,
                      isSmallScreen ? 12 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(isSmallScreen ? 20 : 32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: isSmallScreen ? 10 : 20,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Toplam Tutar',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                '₺${cart.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 44 : 56,
                            child: ElevatedButton(
                              onPressed: () {
                                _confirmOrder(context, cart);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                              ),
                              child: Text(
                                'Siparişi Onayla',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? tempSelectedDate = _selectedDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Teslimat Tarihi Seçin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Takvim
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar<DateTime>(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: tempSelectedDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    selectedDayPredicate: (day) {
                      return tempSelectedDate != null &&
                          isSameDay(tempSelectedDate!, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setDialogState(() {
                        tempSelectedDate = selectedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red[400]),
                      holidayTextStyle: TextStyle(color: Colors.red[400]),
                      selectedDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      weekendDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: AppTheme.primaryColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    locale: 'tr_TR',
                  ),
                ),

                const SizedBox(height: 24),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Temizle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: tempSelectedDate != null
                            ? () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedDate = tempSelectedDate;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Seç',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? tempSelectedTime = _selectedTime;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * (isSmallScreen ? 0.8 : 0.85),
              maxWidth: screenWidth * (isSmallScreen ? 0.95 : 0.9),
            ),
            padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 18 : 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Text(
                        'Teslimat Saati Seçin',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: isSmallScreen ? 18 : 20),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 24),

                // Önerilen Saatler - Scrollable hale getiriyoruz
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: AppTheme.primaryColor,
                                size: isSmallScreen ? 16 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Text(
                                'Önerilen Saatler',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 16),

                          // Sabah Saatleri
                          _buildTimeSection(
                            'Sabah',
                            Icons.wb_sunny_rounded,
                            Colors.orange,
                            [
                              TimeOfDay(hour: 8, minute: 0),
                              TimeOfDay(hour: 9, minute: 0),
                              TimeOfDay(hour: 10, minute: 0),
                              TimeOfDay(hour: 11, minute: 0),
                            ],
                            tempSelectedTime,
                            (time) {
                              setDialogState(() {
                                tempSelectedTime = time;
                              });
                            },
                            isSmallScreen,
                          ),

                          SizedBox(height: isSmallScreen ? 8 : 16),

                          // Öğlen Saatleri
                          _buildTimeSection(
                            'Öğlen',
                            Icons.wb_sunny,
                            Colors.amber,
                            [
                              TimeOfDay(hour: 12, minute: 0),
                              TimeOfDay(hour: 13, minute: 0),
                              TimeOfDay(hour: 14, minute: 0),
                              TimeOfDay(hour: 15, minute: 0),
                            ],
                            tempSelectedTime,
                            (time) {
                              setDialogState(() {
                                tempSelectedTime = time;
                              });
                            },
                            isSmallScreen,
                          ),

                          SizedBox(height: isSmallScreen ? 8 : 16),

                          // Akşam Saatleri
                          _buildTimeSection(
                            'Akşam',
                            Icons.nights_stay_rounded,
                            Colors.indigo,
                            [
                              TimeOfDay(hour: 16, minute: 0),
                              TimeOfDay(hour: 17, minute: 0),
                              TimeOfDay(hour: 18, minute: 0),
                              TimeOfDay(hour: 19, minute: 0),
                            ],
                            tempSelectedTime,
                            (time) {
                              setDialogState(() {
                                tempSelectedTime = time;
                              });
                            },
                            isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 20),

                // Özel Saat Seçimi
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 16 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Text(
                          'Özel saat seçmek istiyorum',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: tempSelectedTime ??
                                const TimeOfDay(hour: 9, minute: 0),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  timePickerTheme: TimePickerThemeData(
                                    backgroundColor: Colors.white,
                                    hourMinuteTextColor: AppTheme.primaryColor,
                                    hourMinuteColor:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    dialHandColor: AppTheme.primaryColor,
                                    dialBackgroundColor:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    entryModeIconColor: AppTheme.primaryColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedTime = picked;
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 16,
                            vertical: isSmallScreen ? 4 : 8,
                          ),
                        ),
                        child: Text(
                          'Seç',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 24),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedTime = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Temizle',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: tempSelectedTime != null
                            ? () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedTime = tempSelectedTime;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Tamam',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildTimeSection(
      String title,
      IconData icon,
      Color color,
      List<TimeOfDay> times,
      TimeOfDay? selectedTime,
      Function(TimeOfDay) onTimeSelected,
      bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 14 : 18),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Wrap(
          spacing: isSmallScreen ? 6 : 8,
          runSpacing: isSmallScreen ? 6 : 8,
          children: times.map((time) {
            final isSelected = selectedTime?.hour == time.hour &&
                selectedTime?.minute == time.minute;
            return GestureDetector(
              onTap: () {
                onTimeSelected(time);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<CompanyGroup> _groupItemsByCompany(List<CartItem> items) {
    // Ürünleri firma ID'sine göre grupla
    final Map<String, List<CartItem>> groupedItems = {};

    for (var item in items) {
      final companyId = item.product.companyId;
      if (!groupedItems.containsKey(companyId)) {
        groupedItems[companyId] = [];
      }
      groupedItems[companyId]!.add(item);
    }

    // Her grup için CompanyGroup nesnesi oluştur
    return groupedItems.entries.map((entry) {
      final firstItem = entry.value.first;
      return CompanyGroup(
        companyId: entry.key,
        companyName: firstItem.product.companyName,
        items: entry.value,
      );
    }).toList();
  }

  double _calculateCompanyTotal(List<CartItem> items) {
    return items.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: color,
        size: isSmallScreen ? 20 : 24,
      ),
      onPressed: onPressed,
    );
  }

  void _saveOrderToDatabase(BuildContext context, CartProvider cart) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Sepetteki ürünleri firma bazında grupla
      final companyGroups = _groupItemsByCompany(cart.items.values.toList());

      // ✅ Oturum açmış kullanıcının gerçek bilgilerini al
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Oluşturulan siparişleri tutacak liste
      List<order_models.Order> createdOrders = [];

      // Her firma için ayrı sipariş oluştur
      for (final companyGroup in companyGroups) {
        // ✅ Gerçek oturum açmış kullanıcının bilgilerini kullan
        final customer = order_models.Customer(
          name: currentUser.companyName ??
              'Firma Adı Girilmemiş', // ✅ Oturum açan kullanıcının firma adı
          phoneNumber: currentUser.phone ??
              'Telefon Girilmemiş', // ✅ Kullanıcının telefonu
          email: currentUser.email, // ✅ Kullanıcının emaili
          address: currentUser.companyAddress ??
              'Adres Girilmemiş', // ✅ Kullanıcının adresi
        );

        // Sipariş öğelerini oluştur
        final orderItems = companyGroup.items.map((cartItem) {
          // Cart Product'ını Order Product'ına dönüştür
          final orderProduct = order_models.Product(
            id: cartItem.product.id,
            name: cartItem.product.name,
            price: cartItem.product.price,
            category: cartItem.product.category,
            description: cartItem.product.description,
            imageUrl: cartItem.product.imageUrl,
          );

          return order_models.OrderItem(
            product: orderProduct,
            quantity: cartItem.quantity,
          );
        }).toList();

        // Teslimat tarihi - seçilen tarih (artık zorunlu)
        final deliveryDate = _selectedDate!;

        // Sipariş oluştur
        final order = order_models.Order(
          customer: customer,
          items: orderItems,
          orderDate: DateTime.now(),
          deliveryDate: deliveryDate,
          requestedDate: _selectedDate,
          requestedTime: _selectedTime,
          status: order_models.OrderStatus.waiting,
          paymentStatus: order_models.PaymentStatus.pending,
          note: _buildOrderNote(companyGroup.companyName,
              currentUser.companyName ?? 'Bilinmeyen Firma'),
          producerCompanyName: companyGroup.companyName,
          producerCompanyId: companyGroup.companyId,
        );

        // Debug: Sipariş bilgilerini yazdır
        print('🔍 Sipariş Oluşturuldu:');
        print('   Siparişi Veren Müşteri: ${customer.name}');
        print('   Müşteri Email: ${customer.email}');
        print('   Müşteri Adres: ${customer.address}');
        print('   Müşteri Telefon: ${customer.phoneNumber}');
        print('   Sipariş Alan Üretici: ${companyGroup.companyName}');
        print('   Ürün sayısı: ${orderItems.length}');
        print('   Toplam tutar: ₺${order.totalAmount}');

        // Siparişi listeye ekle
        createdOrders.add(order);
      }

      // 🔥 TÜM SİPARİŞLERİ FİREBASE'E KAYDET 🔥
      bool firebaseSaveSuccess =
          await OrderService.saveMultipleOrders(createdOrders);

      if (!firebaseSaveSuccess) {
        throw Exception('Firebase kaydetme işlemi başarısız');
      }

      // ✅ Firebase listener otomatik olarak siparişleri OrderProvider'a ekleyecek
      // Manuel olarak ekleme işlemi kaldırıldı (duplikasyon önlemi)
      print('🔥 Firebase listener siparişleri otomatik olarak yükleyecek');

      // Sepeti temizle
      cart.clearCart();

      // Dialog'u kapat
      Navigator.pop(context);

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${companyGroups.length} adet sipariş alındı! 🎉',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Siparişleriniz işleme alınmıştır',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

      // Ana sayfaya dön
      Navigator.pop(context);
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sipariş alınamadı',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Hata: $e',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _buildOrderNote(String producerCompanyName, String customerName) {
    String note = 'Sipariş Detayları:\n';
    note += '👤 Siparişi Veren: $customerName\n';
    note += '🏭 Üretici Firma: $producerCompanyName';

    if (_selectedDate != null || _selectedTime != null) {
      note += '\n\n📋 Teslimat Tercihi:';

      if (_selectedDate != null) {
        note +=
            '\n📅 Tarih: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      }

      if (_selectedTime != null) {
        note +=
            '\n🕐 Saat: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      }
    }

    return note;
  }

  void _confirmOrder(BuildContext context, CartProvider cart) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  (isSmallScreen ? 0.85 : 0.85),
              maxWidth: MediaQuery.of(context).size.width *
                  (isSmallScreen ? 0.95 : 0.9),
            ),
            padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 16 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Sipariş Özeti',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: isSmallScreen ? 16 : 20),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 16),

                // Firma ve Ürün Listesi
                Flexible(
                  flex: 3,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height *
                          (isSmallScreen ? 0.35 : 0.35),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: _groupItemsByCompany(
                                cart.items.values.toList())
                            .map((companyGroup) => Container(
                                  margin: EdgeInsets.only(
                                      bottom: isSmallScreen ? 6 : 12),
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 6 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 6 : 12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Firma Adı
                                      Text(
                                        companyGroup.companyName,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 8),
                                      // Ürünler
                                      ...companyGroup.items.map((item) =>
                                          Padding(
                                            padding: EdgeInsets.only(
                                                bottom: isSmallScreen ? 2 : 6),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${item.quantity}x',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 10 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        isSmallScreen ? 3 : 6),
                                                Expanded(
                                                  child: Text(
                                                    item.product.name,
                                                    style: TextStyle(
                                                        fontSize: isSmallScreen
                                                            ? 10
                                                            : 14),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '₺${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 10 : 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                      Divider(height: isSmallScreen ? 8 : 16),
                                      // Firma Toplamı
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Toplam: ₺${_calculateCompanyTotal(companyGroup.items).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 10 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 8 : 16),

                // Tarih ve Saat Seçimi
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppTheme.primaryColor.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 12 : 18,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 12),
                          Text(
                            'Teslimat Tercihi (Opsiyonel)',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 12),
                      // Tarih ve Saat Butonları
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await _selectDate(context);
                                setDialogState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 6 : 12),
                                  border: Border.all(
                                    color: _selectedDate != null
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedDate != null
                                          ? AppTheme.primaryColor
                                              .withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.all(isSmallScreen ? 4 : 8),
                                      decoration: BoxDecoration(
                                        color: _selectedDate != null
                                            ? AppTheme.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: _selectedDate != null
                                            ? AppTheme.primaryColor
                                            : Colors.grey[600],
                                        size: isSmallScreen ? 12 : 18,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 8),
                                    Text(
                                      'Tarih',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 8 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 1 : 2),
                                    Text(
                                      _selectedDate != null
                                          ? DateFormat('d MMM', 'tr_TR')
                                              .format(_selectedDate!)
                                          : 'Seçiniz',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 13,
                                        color: _selectedDate != null
                                            ? AppTheme.primaryColor
                                            : Colors.grey[600],
                                        fontWeight: _selectedDate != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await _selectTime(context);
                                setDialogState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 6 : 12),
                                  border: Border.all(
                                    color: _selectedTime != null
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedTime != null
                                          ? AppTheme.primaryColor
                                              .withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.all(isSmallScreen ? 4 : 8),
                                      decoration: BoxDecoration(
                                        color: _selectedTime != null
                                            ? AppTheme.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: _selectedTime != null
                                            ? AppTheme.primaryColor
                                            : Colors.grey[600],
                                        size: isSmallScreen ? 12 : 18,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 8),
                                    Text(
                                      'Saat',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 8 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 1 : 2),
                                    Text(
                                      _selectedTime != null
                                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                          : 'Seçiniz',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 13,
                                        color: _selectedTime != null
                                            ? AppTheme.primaryColor
                                            : Colors.grey[600],
                                        fontWeight: _selectedTime != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDate != null || _selectedTime != null) ...[
                        SizedBox(height: isSmallScreen ? 6 : 12),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.05),
                                Colors.indigo.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: isSmallScreen ? 12 : 16,
                                color: Colors.blue[600],
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Expanded(
                                child: Text(
                                  'Tercihleriniz sipariş notlarında belirtilecektir.',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 11,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                  _selectedTime = null;
                                });
                                setDialogState(() {});
                              },
                              icon: Icon(
                                Icons.clear_rounded,
                                size: isSmallScreen ? 10 : 14,
                              ),
                              label: Text(
                                'Temizle',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 12,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 8 : 16),

                // Genel Toplam
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 0,
                    vertical: isSmallScreen ? 6 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Genel Toplam',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₺${cart.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 16),

                // Onay Butonu
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 40 : 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ Tarih ve saat seçim kontrolü
                      if (_selectedDate == null || _selectedTime == null) {
                        // Dialog içinde uyarı göster
                        setDialogState(() {});
                        return; // Sipariş işlemini durdur
                      }

                      _saveOrderToDatabase(context, cart);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Siparişi Onayla',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // ✅ Uyarı mesajı (tarih/saat eksikse göster)
                if (_selectedDate == null || _selectedTime == null) ...[
                  SizedBox(height: isSmallScreen ? 4 : 12),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red.shade600,
                          size: isSmallScreen ? 14 : 20,
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Teslimat bilgileri eksik',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 10 : 14,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              if (isSmallScreen)
                                SizedBox(height: 1)
                              else
                                SizedBox(height: 2),
                              Text(
                                'Lütfen ${_selectedDate == null ? 'tarih' : ''}${_selectedDate == null && _selectedTime == null ? ' ve ' : ''}${_selectedTime == null ? 'saat' : ''} seçiniz',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 12,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
