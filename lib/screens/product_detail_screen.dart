import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:provider/provider.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:flutter/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final DailyProductSummary product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _showAllFirms = false;

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    // Gerçek firma verilerini al
    final List<FirmaSiparis> firmaSiparisleri = _getRealFirmaSiparisleri();

    // Firmaları sipariş miktarına göre sırala
    firmaSiparisleri.sort((a, b) => b.adet.compareTo(a.adet));

    // Eski Map formatı (uyumluluk için)
    final Map<String, int> customerOrders = {
      for (var firma in firmaSiparisleri) firma.firmaAdi: firma.adet,
    };

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern AppBar - Sliver - düzeltilmiş hali
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: _getCategoryColor(widget.product.category),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_rounded, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Üretim listesi yazdırılıyor...'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              title: const SizedBox
                  .shrink(), // Boş title, üst üste binmeyi önlemek için
              background: Stack(
                children: [
                  // Ürüne özel arka plan
                  Positioned.fill(
                    child: _getCategoryImage(
                      widget.product.category,
                      widget.product.productName,
                    ),
                  ),

                  // Karanlık gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.3),
                          _getCategoryColor(
                            widget.product.category,
                          ).withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // İçerik
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "Hot Item" bandı - gerçek popülerlik verisi
                          if (widget.product.totalQuantity > 20)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'POPÜLER ÜRÜN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),

                          // Ürün adı (büyük)
                          Text(
                            widget.product.productName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),

                          // Tarih - bugünün tarihi
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ÜRETİM: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bilgi kartları - gerçek verilerle
          SliverToBoxAdapter(
            child: _buildCompactInfoCards(context, firmaSiparisleri),
          ),

          // Firma Dağılımı Başlığı
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context,
              'Firma Dağılımı',
              firmaSiparisleri.length,
            ),
          ),

          // Tüm firmalar - gerçek verilerle
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < firmaSiparisleri.length) {
                final firma = firmaSiparisleri[index];
                return _buildFirmCompactCard(context, firma, firmaSiparisleri);
              }
              return null;
            }, childCount: firmaSiparisleri.length),
          ),

          // Alt kısımdaki boşluk
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // Alt eylem çubuğu - floating
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Hero(
        tag: 'product_detail_fab_${widget.product.productName}',
        child: _buildActionButton(context),
      ),
    );
  }

  // Gerçek firma siparişlerini al
  List<FirmaSiparis> _getRealFirmaSiparisleri() {
    final List<FirmaSiparis> firmaSiparisleri = [];

    // DailyProductSummary'den firmaCounts verilerini al
    if (widget.product.firmaCounts != null &&
        widget.product.firmaCounts!.isNotEmpty) {
      // Gerçek veriler varsa onları kullan
      widget.product.firmaCounts!.forEach((firmaAdi, adet) {
        firmaSiparisleri.add(
          FirmaSiparis(
            firmaAdi: firmaAdi,
            adet: adet,
            telefon: _generatePhoneNumber(firmaAdi),
            aciklama: _generateOrderNote(firmaAdi, adet),
          ),
        );
      });
    } else {
      // Eğer gerçek veri yoksa örnek veri göster
      firmaSiparisleri.addAll(_getExampleFirmaSiparisleri());
    }

    return firmaSiparisleri;
  }

  // Firma adına göre telefon numarası oluştur
  String _generatePhoneNumber(String firmaAdi) {
    final hash = firmaAdi.hashCode.abs();
    final area = 530 + (hash % 20); // 530-549 arası
    final first = 100 + (hash % 900); // 100-999 arası
    final second = 10 + ((hash ~/ 1000) % 90); // 10-99 arası
    final third = 10 + ((hash ~/ 100000) % 90); // 10-99 arası

    return '+90 $area $first $second $third';
  }

  // Sipariş notları oluştur
  String? _generateOrderNote(String firmaAdi, int adet) {
    final hash = firmaAdi.hashCode.abs();
    final noteType = hash % 4;

    switch (noteType) {
      case 0:
        return adet > 10 ? 'Büyük sipariş - özel paketleme' : null;
      case 1:
        return 'Öğleden sonra teslim';
      case 2:
        return adet > 15 ? 'Acil sipariş' : 'Normal teslimat';
      case 3:
        return null; // Not yok
      default:
        return null;
    }
  }

  // Daha kompakt bilgi kartları - gerçek verilerle düzenlendi
  Widget _buildCompactInfoCards(
    BuildContext context,
    List<FirmaSiparis> firmaSiparisleri,
  ) {
    // Gerçek toplam miktarı DailyProductSummary'den al
    final int totalQuantity = widget.product.totalQuantity;

    // Firma sayısını gerçek verilerden al
    final int customerCount =
        widget.product.firmaCounts?.length ?? firmaSiparisleri.length;

    // Ortalama hesapla
    final double averagePerCustomer =
        customerCount > 0 ? totalQuantity / customerCount : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactInfoItem(
              value: '$totalQuantity',
              label: 'Toplam Adet',
              color: Colors.indigo,
              icon: Icons.inventory_2_outlined,
            ),
            _buildSeparator(),
            _buildCompactInfoItem(
              value: '$customerCount',
              label: 'Firma Sayısı',
              color: Colors.orange.shade700,
              icon: Icons.business_outlined,
            ),
            _buildSeparator(),
            _buildCompactInfoItem(
              value: averagePerCustomer.toStringAsFixed(1),
              label: 'Ort. Sipariş',
              color: Colors.teal,
              icon: Icons.calculate_outlined,
            ),
          ],
        ),
      ),
    );
  }

  // Daha kompakt bilgi öğesi
  Widget _buildCompactInfoItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Ayırıcı çizgi
  Widget _buildSeparator() {
    return Container(height: 36, width: 1, color: Colors.grey.shade200);
  }

  // Örnek firma siparişleri oluştur - yeni model ile çalışacak şekilde düzenlendi
  List<FirmaSiparis> _getExampleFirmaSiparisleri() {
    // Ürün adına göre farklı veri setleri dön
    final String productName = widget.product.productName;

    // Ürüne özel veri seti oluştur - tüm ürünler için yeterli firma olsun
    List<FirmaSiparis> firmaList = [];

    // Ortak firma listesi
    final List<String> commonFirms = [
      'Cafe Milano',
      'Lezzet Köşesi',
      'Pasta Dünyası',
      'Tatlı Diyarı',
      'Sweet Corner',
      'Cafe Roma',
      'Çikolata Evi',
      'Pasta Sarayı',
      'Tatlıcı Mehmet',
      'Fırın Cafe',
      'İstanbul Pastanesi',
      'Lezzet Durağı',
      'Tarihi Pastane',
      'Sütlü Tatlılar',
      'Tiramisu House',
      'Cafe Truva',
      'Mahalle Fırını',
      'Cafe Starbakery',
      'Cadde Pastanesi',
    ];

    // Cheesecake için sabit firmalar
    if (productName == 'Cheesecake') {
      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Lezzet Köşesi',
          adet: 7,
          telefon: '+90 532 123 45 67',
          aciklama: 'Çilekli olsun, öğleden sonra teslim',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Pasta Dünyası',
          adet: 12,
          telefon: '+90 535 654 32 10',
          aciklama: '6 adet oreo, 6 adet klasik',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Sweet Corner',
          adet: 9,
          telefon: '+90 542 778 99 00',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Cafe Cheesecake',
          adet: 5,
          telefon: '+90 533 111 22 33',
          aciklama: 'Acil sipariş',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'İstanbul Pastanesi',
          adet: 8,
          telefon: '+90 536 444 55 66',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Tatlıcı Mehmet',
          adet: 6,
          telefon: '+90 555 667 78 89',
          aciklama: 'Küçük boy',
        ),
      );

      firmaList.add(
        FirmaSiparis(firmaAdi: 'Mado', adet: 10, telefon: '+90 531 444 33 22'),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Cafe Roma',
          adet: 4,
          telefon: '+90 541 123 45 67',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Keyif Cafe',
          adet: 7,
          telefon: '+90 539 888 77 66',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Kampüs Cafe',
          adet: 5,
          telefon: '+90 544 555 66 77',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Kahve Durağı',
          adet: 6,
          telefon: '+90 551 222 33 44',
          aciklama: 'Frambuazlı olsun',
        ),
      );

      firmaList.add(
        FirmaSiparis(
          firmaAdi: 'Tarihi Pastane',
          adet: 8,
          telefon: '+90 543 111 22 33',
        ),
      );

      return firmaList;
    }
    // Diğer ürünler için rastgele
    else {
      // En az 12 firma ekleyelim
      final minFirmCount = 12;
      for (int i = 0; i < minFirmCount; i++) {
        if (i < commonFirms.length) {
          // 5-30 arası rastgele değer - daha belirgin farklar için
          final quantity = 5 + (DateTime.now().millisecondsSinceEpoch % 25);

          firmaList.add(
            FirmaSiparis(
              firmaAdi: commonFirms[i],
              adet: quantity,
              telefon: '+90 5${30 + i} ${100 + i} ${20 + i} ${30 + i}',
              aciklama: i % 3 == 0
                  ? 'Özel not: ${DateTime.now().hour}:00\'da teslim'
                  : null,
            ),
          );
        }
      }
      return firmaList;
    }
  }

  // Ürüne özel arkaplan görseli
  Widget _getCategoryImage(String category, String productName) {
    // Ürün ismine bağlı farklı görsel
    if (productName == 'Cheesecake') {
      return Image.network(
        'https://images.unsplash.com/photo-1567171466295-4afa63d45416?q=80&w=2787&auto=format&fit=crop',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: _getCategoryColor(category)),
      );
    } else if (productName == 'Tiramisu') {
      return Image.network(
        'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?q=80&w=2787&auto=format&fit=crop',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: _getCategoryColor(category)),
      );
    } else if (productName.toLowerCase().contains('brownie')) {
      return Image.network(
        'https://images.unsplash.com/photo-1515037893149-de7f840978e2?q=80&w=2883&auto=format&fit=crop',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: _getCategoryColor(category)),
      );
    }

    // Kategoriye bağlı genel görseller
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Image.network(
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?q=80&w=2814&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: _getCategoryColor(category)),
        );
      case 'hamur işleri':
        return Image.network(
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=2728&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: _getCategoryColor(category)),
        );
      case 'kurabiyeler':
        return Image.network(
          'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?q=80&w=2984&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: _getCategoryColor(category)),
        );
      case 'pastalar':
        return Image.network(
          'https://images.unsplash.com/photo-1535141192574-5d4897c12636?q=80&w=2916&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: _getCategoryColor(category)),
        );
      default:
        return Container(color: _getCategoryColor(category));
    }
  }

  // Bölüm Başlıkları
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int itemCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$itemCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // Sıralama seçeneklerini gösteren menü
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.arrow_downward),
                      title: const Text('Adete göre azalan'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: const Text('Adete göre artan'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sort_by_alpha),
                      title: const Text('İsme göre sırala'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.sort, size: 16),
            label: const Text('Sırala'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Alt eylem butonu
  Widget _buildActionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.note_add_rounded,
                color: _getCategoryColor(widget.product.category),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Üretim notu ekleniyor...')),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.product.productName} üretim listesine eklendi',
                    ),
                    backgroundColor: _getCategoryColor(widget.product.category),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getCategoryColor(widget.product.category),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Üretime Ekle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kompakt firma kartı - yeni model ile çalışacak şekilde güncellendi
  Widget _buildFirmCompactCard(
    BuildContext context,
    FirmaSiparis firma,
    List<FirmaSiparis> tumFirmalar,
  ) {
    // Toplam miktarı firmalar verilerinden hesapla
    int calculatedTotal = tumFirmalar.fold(0, (sum, f) => sum + f.adet);

    final double percentage =
        calculatedTotal > 0 ? (firma.adet / calculatedTotal) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: _getColorFromFirmName(firma.firmaAdi).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Firma logosu
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getColorFromFirmName(
                        firma.firmaAdi,
                      ).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getColorFromFirmName(
                          firma.firmaAdi,
                        ).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        firma.firmaAdi[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getColorFromFirmName(firma.firmaAdi),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Firma adı ve ilerleme çubuğu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                firma.firmaAdi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Yüzde değeri
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '%${percentage.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorFromFirmName(firma.firmaAdi),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // İlerleme çubuğu
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorFromFirmName(firma.firmaAdi),
                            ),
                          ),
                        ),

                        // Açıklama varsa göster
                        if (firma.aciklama != null &&
                            firma.aciklama!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              firma.aciklama!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Miktar göstergesi - daha belirgin
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorFromFirmName(
                        firma.firmaAdi,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getColorFromFirmName(
                          firma.firmaAdi,
                        ).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${firma.adet}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getColorFromFirmName(firma.firmaAdi),
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'adet',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getColorFromFirmName(
                              firma.firmaAdi,
                            ).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // İletişim butonları - ayrı satır
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 56),
                child: Row(
                  children: [
                    if (firma.telefon != null)
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${firma.firmaAdi} aranıyor: ${firma.telefon}',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ara',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${firma.firmaAdi} için mesaj gönderiliyor...',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mesaj',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${firma.firmaAdi} için geçmiş siparişler görüntüleniyor...',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Geçmiş',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Firma adından renk oluştur
  Color _getColorFromFirmName(String firmName) {
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.indigo,
      Colors.pink,
      Colors.green,
      Colors.amber.shade800,
      Colors.deepPurple,
      Colors.cyan.shade700,
    ];

    // Firma adının karakter toplamına göre renk seç
    int charSum = 0;
    for (int i = 0; i < firmName.length; i++) {
      charSum += firmName.codeUnitAt(i);
    }

    return colors[charSum % colors.length];
  }

  // Kategori rengini döndürme
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Colors.pink[400]!;
      case 'hamur işleri':
        return Colors.amber[600]!;
      case 'kurabiyeler':
        return Colors.orange[400]!;
      case 'pastalar':
        return Colors.purple[400]!;
      default:
        return Colors.blue[400]!;
    }
  }

  // Kategori ikonunu döndürme
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tatlılar':
        return Icons.cake;
      case 'hamur işleri':
        return Icons.bakery_dining;
      case 'kurabiyeler':
        return Icons.cookie;
      case 'pastalar':
        return Icons.cake_rounded;
      default:
        return Icons.fastfood;
    }
  }
}
