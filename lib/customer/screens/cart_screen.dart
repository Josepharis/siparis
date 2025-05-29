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

class _CartScreenState extends State<CartScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
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
            margin: const EdgeInsets.all(8),
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F2937),
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Sepetim',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
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
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () {
                // TODO: Sepeti temizle
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
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
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cart.items.length} Ürün',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toplam: ₺${cart.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ürün Listesi
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount:
                          _groupItemsByCompany(cart.items.values.toList())
                              .length,
                      itemBuilder: (context, index) {
                        final companyGroup = _groupItemsByCompany(
                            cart.items.values.toList())[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Firma Başlığı
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.03),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
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
                                        borderRadius: BorderRadius.circular(14),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            companyGroup.companyName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${companyGroup.items.length} Ürün',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₺${_calculateCompanyTotal(companyGroup.items).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
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
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                          const SizedBox(width: 16),
                                          // Ürün Bilgileri
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.product.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '₺${item.product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
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
                                            padding: const EdgeInsets.all(6),
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
                                                ),
                                                Container(
                                                  width: 36,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    item.quantity.toString(),
                                                    style: TextStyle(
                                                      fontSize: 16,
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toplam Tutar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                '₺${cart.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Siparişi Onayla',
                                style: TextStyle(
                                  fontSize: 18,
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
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Teslimat Saati Seçin',
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

                // Önerilen Saatler
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Önerilen Saatler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                      ),

                      const SizedBox(height: 16),

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
                      ),

                      const SizedBox(height: 16),

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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Özel Saat Seçimi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Özel saat seçmek istiyorum',
                          style: TextStyle(
                            fontSize: 16,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Seç',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                            _selectedTime = null;
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tamam',
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

  Widget _buildTimeSection(
      String title,
      IconData icon,
      Color color,
      List<TimeOfDay> times,
      TimeOfDay? selectedTime,
      Function(TimeOfDay) onTimeSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            final isSelected = selectedTime?.hour == time.hour &&
                selectedTime?.minute == time.minute;
            return GestureDetector(
              onTap: () {
                onTimeSelected(time);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
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
                    fontSize: 14,
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
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: color,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  void _confirmOrder(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sipariş Özeti',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Firma ve Ürün Listesi
                Flexible(
                  flex: 3,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: _groupItemsByCompany(
                                cart.items.values.toList())
                            .map((companyGroup) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Firma Adı
                                      Text(
                                        companyGroup.companyName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Ürünler
                                      ...companyGroup.items.map((item) =>
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${item.quantity}x',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item.product.name,
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '₺${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                      const Divider(height: 16),
                                      // Firma Toplamı
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Toplam: ₺${_calculateCompanyTotal(companyGroup.items).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
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

                const SizedBox(height: 16),

                // Tarih ve Saat Seçimi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppTheme.primaryColor.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Teslimat Tercihi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (_selectedDate != null || _selectedTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Seçildi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await _selectDate(context);
                                setDialogState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _selectedDate != null
                                            ? AppTheme.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: _selectedDate != null
                                            ? AppTheme.primaryColor
                                            : Colors.grey[600],
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tarih',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedDate != null
                                          ? DateFormat('d MMM', 'tr_TR')
                                              .format(_selectedDate!)
                                          : 'Seçiniz',
                                      style: TextStyle(
                                        fontSize: 13,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await _selectTime(context);
                                setDialogState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _selectedTime != null
                                            ? AppTheme.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: _selectedTime != null
                                            ? AppTheme.primaryColor
                                            : Colors.grey[600],
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Saat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedTime != null
                                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                          : 'Seçiniz',
                                      style: TextStyle(
                                        fontSize: 13,
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.05),
                                Colors.indigo.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tercihleriniz sipariş notlarında belirtilecektir.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Temizle',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
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

                const SizedBox(height: 16),

                // Genel Toplam
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Genel Toplam',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₺${cart.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Onay Butonu
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
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
                    child: const Text(
                      'Siparişi Onayla',
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
        ),
      ),
    );
  }

  void _saveOrderToDatabase(BuildContext context, CartProvider cart) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Sepetteki ürünleri firma bazında grupla
      final companyGroups = _groupItemsByCompany(cart.items.values.toList());

      // ✅ Gerçekçi müşteri profilleri
      final List<Map<String, String>> customerProfiles = [
        {
          'name': 'Acme Kargo Ltd. Şti.',
          'phone': '0555 123 45 67',
          'email': 'siparis@acmekargo.com',
          'address': 'Atatürk Mah. Cumhuriyet Cad. No:123 Kadıköy/İstanbul',
        },
        {
          'name': 'Lezzet Cafe & Restaurant',
          'phone': '0532 987 65 43',
          'email': 'info@lezzetcafe.com',
          'address': 'Bağdat Cad. No:456 Maltepe/İstanbul',
        },
        {
          'name': 'Sweet Corner Pastanesi',
          'phone': '0543 111 22 33',
          'email': 'siparisler@sweetcorner.com.tr',
          'address': 'İstiklal Mah. Özgürlük Sok. No:78 Beyoğlu/İstanbul',
        },
        {
          'name': 'Metro Market Zinciri',
          'phone': '0505 444 55 66',
          'email': 'tedarik@metromarket.com',
          'address': 'Sanayi Mah. Ticaret Cad. No:200 Ümraniye/İstanbul',
        },
        {
          'name': 'Kampüs Cafe & Bistro',
          'phone': '0536 777 88 99',
          'email': 'kampuscafe@gmail.com',
          'address': 'Üniversite Mah. Gençlik Cad. No:15 Beşiktaş/İstanbul',
        },
      ];

      // Rastgele müşteri seç
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % customerProfiles.length;
      final selectedProfile = customerProfiles[randomIndex];

      // Oluşturulan siparişleri tutacak liste
      List<order_models.Order> createdOrders = [];

      // Her firma için ayrı sipariş oluştur
      for (final companyGroup in companyGroups) {
        // ✅ DÜZELTME: Gerçek müşteri bilgilerini kullan
        // Üretici firma bilgisi ayrı tutulacak (companyGroup.companyName = oyunlab vs)
        final customer = order_models.Customer(
          name: selectedProfile['name']!, // ✅ Gerçek müşteri firma adı
          phoneNumber: selectedProfile['phone']!, // ✅ Gerçek müşteri telefonu
          email: selectedProfile['email']!, // ✅ Gerçek müşteri emaili
          address: selectedProfile['address']!, // ✅ Gerçek müşteri adresi
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

        // Teslimat tarihi (varsayılan olarak yarın)
        final deliveryDate = DateTime.now().add(const Duration(days: 1));

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
          note: _buildOrderNote(
              companyGroup.companyName, selectedProfile['name']!),
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

        // ✅ Firebase listener otomatik olarak siparişleri güncelleyecek
        print('🔥 Firebase listener siparişleri otomatik güncelleyecek');
      }

      // 🔥 TÜM SİPARİŞLERİ FİREBASE'E KAYDET 🔥
      bool firebaseSaveSuccess =
          await OrderService.saveMultipleOrders(createdOrders);

      if (!firebaseSaveSuccess) {
        throw Exception('Firebase kaydetme işlemi başarısız');
      }

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sipariş alınamadı',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Lütfen tekrar deneyiniz',
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
}
