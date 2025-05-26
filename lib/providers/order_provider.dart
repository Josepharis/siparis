import 'package:flutter/foundation.dart';
import 'package:siparis/models/order.dart';

class OrderProvider extends ChangeNotifier {
  // Tüm siparişler
  List<Order> _orders = [];

  // Günlük ürün özetleri
  Map<String, DailyProductSummary> _dailyProductSummary = {};

  // Finansal özet
  FinancialSummary? _financialSummary;

  // Firma özetleri
  List<CompanySummary> _companySummaries = [];

  // Getters
  List<Order> get orders => _orders;
  List<Order> get waitingOrders =>
      _orders.where((order) => order.status == OrderStatus.waiting).toList();
  List<Order> get processingOrders =>
      _orders.where((order) => order.status == OrderStatus.processing).toList();
  List<Order> get completedOrders =>
      _orders.where((order) => order.status == OrderStatus.completed).toList();
  Map<String, DailyProductSummary> get dailyProductSummary =>
      _dailyProductSummary;
  FinancialSummary? get financialSummary => _financialSummary;
  List<CompanySummary> get companySummaries => _companySummaries;

  // Siparişleri yükle (gerçek uygulamada bu veriler API'den veya yerel depodan gelecek)
  Future<void> loadOrders() async {
    // Örnek veri
    await Future.delayed(const Duration(seconds: 1));

    // TODO: API veya yerel depodan siparişleri yükle
    _buildMockData();

    notifyListeners();
  }

  // Sipariş ekleme
  void addOrder(Order order) {
    _orders.add(order);
    _updateSummaries();
    notifyListeners();
  }

  // Sipariş güncelleme
  void updateOrder(Order updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
      _updateSummaries();
      notifyListeners();
    }
  }

  // Sipariş durumunu güncelleme
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      // Yeni sipariş oluştur, final değişkenleri güncellemek için
      final updatedOrder = Order(
        id: _orders[index].id,
        customer: _orders[index].customer,
        items: _orders[index].items,
        orderDate: _orders[index].orderDate,
        deliveryDate: _orders[index].deliveryDate,
        status: newStatus,
        paymentStatus: _orders[index].paymentStatus,
        paidAmount: _orders[index].paidAmount,
        note: _orders[index].note,
      );

      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  // Sipariş silme
  void deleteOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    _updateSummaries();
    notifyListeners();
  }

  // Özetleri güncelleme
  void _updateSummaries() {
    _updateDailyProductSummary();
    _updateFinancialSummary();
    _updateCompanySummaries();
  }

  // Günlük ürün özetini güncelleme
  void _updateDailyProductSummary() {
    final Map<String, DailyProductSummary> summaryMap = {};
    // Ürün adına göre firma miktarlarını tutan harita
    final Map<String, Map<String, int>> productFirmaCounts = {};

    // Bugün için olan siparişleri filtrele
    final todayOrders =
        _orders
            .where(
              (order) =>
                  order.deliveryDate.day == DateTime.now().day &&
                  order.deliveryDate.month == DateTime.now().month &&
                  order.deliveryDate.year == DateTime.now().year,
            )
            .toList();

    // Her bir sipariş öğesi için özet oluştur
    for (final order in todayOrders) {
      for (final item in order.items) {
        final productName = item.product.name;
        final firmaName = order.customer.name;

        // Ürün için firma miktarlarını güncelle
        if (!productFirmaCounts.containsKey(productName)) {
          productFirmaCounts[productName] = {};
        }

        // Firma miktarını güncelle
        productFirmaCounts[productName]![firmaName] =
            (productFirmaCounts[productName]![firmaName] ?? 0) + item.quantity;

        if (summaryMap.containsKey(productName)) {
          // Mevcut özeti güncelle
          final existingSummary = summaryMap[productName]!;
          final newTotalQuantity =
              existingSummary.totalQuantity + item.quantity;

          summaryMap[productName] = DailyProductSummary(
            productName: productName,
            totalQuantity: newTotalQuantity,
            category: item.product.category,
            imageUrl: item.product.imageUrl,
            firmaCounts: productFirmaCounts[productName],
          );
        } else {
          // Yeni özet oluştur
          summaryMap[productName] = DailyProductSummary(
            productName: productName,
            totalQuantity: item.quantity,
            category: item.product.category,
            imageUrl: item.product.imageUrl,
            firmaCounts: productFirmaCounts[productName],
          );
        }
      }
    }

    _dailyProductSummary = summaryMap;
  }

  // Finansal özeti güncelleme
  void _updateFinancialSummary() {
    double totalAmount = 0;
    double collectedAmount = 0;
    int totalOrders = _orders.length;
    int paidOrders = 0;
    int pendingOrders = 0;

    for (final order in _orders) {
      totalAmount += order.totalAmount;
      collectedAmount += order.paidAmount ?? 0;

      if (order.paymentStatus == PaymentStatus.paid) {
        paidOrders++;
      } else {
        pendingOrders++;
      }
    }

    final pendingAmount = totalAmount - collectedAmount;
    final collectionRate =
        totalAmount > 0 ? (collectedAmount / totalAmount) * 100 : 0.0;

    _financialSummary = FinancialSummary(
      totalAmount: totalAmount,
      collectedAmount: collectedAmount,
      pendingAmount: pendingAmount,
      collectionRate: collectionRate,
      totalOrders: totalOrders,
      paidOrders: paidOrders,
      pendingOrders: pendingOrders,
    );
  }

  // Firma özetlerini güncelleme
  void _updateCompanySummaries() {
    final Map<String, CompanySummary> summaryMap = {};

    // Her bir firma için sipariş ve ödeme özetlerini hazırla
    for (final order in _orders) {
      final customerId = order.customer.id;

      if (summaryMap.containsKey(customerId)) {
        // Mevcut özeti güncelle
        final existingSummary = summaryMap[customerId]!;

        summaryMap[customerId] = CompanySummary(
          company: order.customer,
          totalAmount: existingSummary.totalAmount + order.totalAmount,
          paidAmount: existingSummary.paidAmount + (order.paidAmount ?? 0),
          pendingAmount: existingSummary.pendingAmount + order.remainingAmount,
          totalOrders: existingSummary.totalOrders + 1,
          collectionRate: 0, // Şimdilik 0 olarak ayarla, sonra hesapla
        );
      } else {
        // Yeni özet oluştur
        summaryMap[customerId] = CompanySummary(
          company: order.customer,
          totalAmount: order.totalAmount,
          paidAmount: order.paidAmount ?? 0,
          pendingAmount: order.remainingAmount,
          totalOrders: 1,
          collectionRate: 0, // Şimdilik 0 olarak ayarla, sonra hesapla
        );
      }
    }

    // Koleksiyon oranlarını hesapla
    final List<CompanySummary> summaries =
        summaryMap.values.map((summary) {
          final collectionRate =
              summary.totalAmount > 0
                  ? (summary.paidAmount / summary.totalAmount) * 100
                  : 0.0;

          return CompanySummary(
            company: summary.company,
            totalAmount: summary.totalAmount,
            paidAmount: summary.paidAmount,
            pendingAmount: summary.pendingAmount,
            totalOrders: summary.totalOrders,
            collectionRate: collectionRate,
          );
        }).toList();

    // Toplam tutara göre sırala
    summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    _companySummaries = summaries;
  }

  // Örnek veri oluştur (geliştirme aşamasında kullanılır)
  void _buildMockData() {
    // Örnek müşteriler/firmalar
    final cafeSera = Customer(
      id: '1',
      name: 'Cafe Sera',
      phoneNumber: '0555 123 4567',
      email: 'info@cafesera.com',
      address: 'Bağdat Caddesi No:123, Kadıköy/İstanbul',
    );

    final patisserieLina = Customer(
      id: '2',
      name: 'Patisserie Lina',
      phoneNumber: '0533 765 4321',
      email: 'contact@patisserielina.com',
      address: 'Nispetiye Cad. No:45, Beşiktaş/İstanbul',
    );

    final firinDunyasi = Customer(
      id: '3',
      name: 'Fırın Dünyası',
      phoneNumber: '0532 987 6543',
      email: 'info@firindunyasi.com',
      address: 'İstiklal Caddesi No:78, Beyoğlu/İstanbul',
    );

    // Yeni eklenmiş müşteriler
    final sweetGarden = Customer(
      id: '4',
      name: 'Sweet Garden',
      phoneNumber: '0545 765 9812',
      email: 'info@sweetgarden.com',
      address: 'Bağcılar Bulvarı No:36, Bakırköy/İstanbul',
    );

    final cafeMondo = Customer(
      id: '5',
      name: 'Cafe Mondo',
      phoneNumber: '0535 111 2233',
      email: 'contact@cafemondo.com',
      address: 'Acıbadem Cad. No:127, Üsküdar/İstanbul',
    );

    final royalPatisserie = Customer(
      id: '6',
      name: 'Royal Patisserie',
      phoneNumber: '0543 444 5566',
      email: 'info@royalpatisserie.com',
      address: 'Bağdat Caddesi No:287, Kadıköy/İstanbul',
    );

    final coffeeHeaven = Customer(
      id: '7',
      name: 'Coffee Heaven',
      phoneNumber: '0553 999 7788',
      email: 'contact@coffeeheaven.com',
      address: 'İzzetpaşa Mah. No:42, Şişli/İstanbul',
    );

    final sweetDelights = Customer(
      id: '8',
      name: 'Sweet Delights',
      phoneNumber: '0554 333 2211',
      email: 'info@sweetdelights.com',
      address: 'Alemdağ Cad. No:176, Ümraniye/İstanbul',
    );

    // Örnek ürünler
    final tiramisu = Product(
      id: '101',
      name: 'Tiramisu',
      price: 70.0,
      category: 'Tatlılar',
      description:
          'İtalyan usulü mascarpone, kahve ve kakao ile hazırlanan tatlı',
    );

    final cheesecake = Product(
      id: '102',
      name: 'Cheesecake',
      price: 85.0,
      category: 'Tatlılar',
      description:
          'Yumuşak kıvamlı, labne peyniri ve vanilya ile hazırlanmış tatlı',
    );

    final brownie = Product(
      id: '103',
      name: 'Brownie',
      price: 45.0,
      category: 'Tatlılar',
      description: 'Yoğun çikolatalı kek',
    );

    final pogaca = Product(
      id: '201',
      name: 'Poğaça',
      price: 12.0,
      category: 'Hamur İşleri',
      description: 'Geleneksel Türk hamur işi',
    );

    final macarons = Product(
      id: '202',
      name: 'Macarons',
      price: 15.0,
      category: 'Kurabiyeler',
      description: 'Fransız badem ezmeli kurabiye',
    );

    final baklava = Product(
      id: '203',
      name: 'Baklava',
      price: 25.0,
      category: 'Şerbetli Tatlılar',
      description: 'Geleneksel Türk tatlısı',
    );

    // Yeni eklenmiş ürünler
    final profiterol = Product(
      id: '104',
      name: 'Profiterol',
      price: 60.0,
      category: 'Tatlılar',
      description: 'Çikolata soslu, kremalı milföy hamuru tatlısı',
    );

    final muffin = Product(
      id: '105',
      name: 'Muffin',
      price: 20.0,
      category: 'Hamur İşleri',
      description: 'Çikolatalı veya meyveli yumuşak kek',
    );

    final sanSebastian = Product(
      id: '106',
      name: 'San Sebastian',
      price: 90.0,
      category: 'Pastalar',
      description: 'Bask usulü pürüzsüz cheesecake',
    );

    // Ek yeni ürünler
    final ekler = Product(
      id: '107',
      name: 'Ekler',
      price: 40.0,
      category: 'Tatlılar',
      description: 'İçi krema dolu, üzeri çikolatalı hamur tatlısı',
    );

    final kurabiye = Product(
      id: '108',
      name: 'Kurabiye',
      price: 10.0,
      category: 'Kurabiyeler',
      description:
          'Çeşitli aromalarda cevizli, çikolatalı, tarçınlı kurabiyeler',
    );

    final kekPasta = Product(
      id: '109',
      name: 'Yaş Pasta',
      price: 120.0,
      category: 'Pastalar',
      description: 'Çikolatalı, meyveli veya fındıklı yaş pasta çeşitleri',
    );

    final cikolataliSufle = Product(
      id: '110',
      name: 'Çikolatalı Sufle',
      price: 55.0,
      category: 'Tatlılar',
      description: 'İçi akışkan sıcak çikolatalı tatlı',
    );

    final revani = Product(
      id: '111',
      name: 'Revani',
      price: 30.0,
      category: 'Şerbetli Tatlılar',
      description: 'Şerbetli irmik tatlısı',
    );

    // Örnek siparişler
    final now = DateTime.now();

    // Sipariş 1 - Cafe Sera
    final order1 = Order(
      id: '1001',
      customer: cafeSera,
      items: [
        OrderItem(product: tiramisu, quantity: 15),
        OrderItem(product: cheesecake, quantity: 12),
      ],
      orderDate: now.subtract(const Duration(hours: 3)),
      deliveryDate: now.add(const Duration(hours: 3)),
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.pending,
    );

    // Sipariş 2 - Patisserie Lina
    final order2 = Order(
      id: '1002',
      customer: patisserieLina,
      items: [
        OrderItem(product: brownie, quantity: 25),
        OrderItem(product: macarons, quantity: 30),
      ],
      orderDate: now.subtract(const Duration(hours: 5)),
      deliveryDate: now.add(const Duration(hours: 2)),
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.partial,
      paidAmount: 300.0,
    );

    // Sipariş 3 - Fırın Dünyası
    final order3 = Order(
      id: '1003',
      customer: firinDunyasi,
      items: [
        OrderItem(product: pogaca, quantity: 50),
        OrderItem(product: baklava, quantity: 20),
      ],
      orderDate: now.subtract(const Duration(hours: 8)),
      deliveryDate: now.add(const Duration(hours: 4)),
      status: OrderStatus.processing,
      paymentStatus: PaymentStatus.paid,
      paidAmount: 420.0,
    );

    // Yeni eklenen sipariş 4 - Sweet Garden
    final order4 = Order(
      id: '1004',
      customer: sweetGarden,
      items: [
        OrderItem(product: cheesecake, quantity: 18),
        OrderItem(product: profiterol, quantity: 25),
      ],
      orderDate: now.subtract(const Duration(hours: 6)),
      deliveryDate: now.add(const Duration(hours: 1)),
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.pending,
    );

    // Yeni eklenen sipariş 5 - Cafe Mondo
    final order5 = Order(
      id: '1005',
      customer: cafeMondo,
      items: [
        OrderItem(product: sanSebastian, quantity: 14),
        OrderItem(product: muffin, quantity: 35),
      ],
      orderDate: now.subtract(const Duration(hours: 5)),
      deliveryDate: now.add(const Duration(hours: 5)),
      status: OrderStatus.processing,
      paymentStatus: PaymentStatus.partial,
      paidAmount: 250.0,
    );

    // Yeni eklenen sipariş 6 - Royal Patisserie
    final order6 = Order(
      id: '1006',
      customer: royalPatisserie,
      items: [
        OrderItem(product: tiramisu, quantity: 22),
        OrderItem(product: brownie, quantity: 30),
        OrderItem(product: cheesecake, quantity: 16),
      ],
      orderDate: now.subtract(const Duration(hours: 10)),
      deliveryDate: now.add(const Duration(hours: 2)),
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.pending,
    );

    // Yeni eklenen sipariş 7 - Coffee Heaven
    final order7 = Order(
      id: '1007',
      customer: coffeeHeaven,
      items: [
        OrderItem(product: muffin, quantity: 60),
        OrderItem(product: macarons, quantity: 45),
      ],
      orderDate: now.subtract(const Duration(hours: 7)),
      deliveryDate: now.add(const Duration(hours: 6)),
      status: OrderStatus.processing,
      paymentStatus: PaymentStatus.paid,
      paidAmount: 1050.0,
    );

    // Yeni eklenen sipariş 8 - Sweet Delights
    final order8 = Order(
      id: '1008',
      customer: sweetDelights,
      items: [
        OrderItem(product: sanSebastian, quantity: 17),
        OrderItem(product: profiterol, quantity: 28),
        OrderItem(product: cheesecake, quantity: 15),
      ],
      orderDate: now.subtract(const Duration(hours: 4)),
      deliveryDate: now,
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.partial,
      paidAmount: 680.0,
    );

    // Yeni eklenen sipariş 9 - Cafe Sera (ekstra)
    final order9 = Order(
      id: '1009',
      customer: cafeSera,
      items: [
        OrderItem(product: ekler, quantity: 30),
        OrderItem(product: kurabiye, quantity: 45),
        OrderItem(product: kekPasta, quantity: 8),
      ],
      orderDate: now.subtract(const Duration(hours: 9)),
      deliveryDate: now.add(const Duration(hours: 1)),
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.pending,
    );

    // Yeni eklenen sipariş 10 - Patisserie Lina (ekstra)
    final order10 = Order(
      id: '1010',
      customer: patisserieLina,
      items: [
        OrderItem(product: cikolataliSufle, quantity: 25),
        OrderItem(product: revani, quantity: 20),
      ],
      orderDate: now.subtract(const Duration(hours: 8)),
      deliveryDate: now.add(const Duration(hours: 4)),
      status: OrderStatus.processing,
      paymentStatus: PaymentStatus.partial,
      paidAmount: 550.0,
    );

    // Yeni eklenen sipariş 11 - Royal Patisserie (ekstra)
    final order11 = Order(
      id: '1011',
      customer: royalPatisserie,
      items: [
        OrderItem(product: kekPasta, quantity: 12),
        OrderItem(product: ekler, quantity: 35),
        OrderItem(product: kurabiye, quantity: 60),
      ],
      orderDate: now.subtract(const Duration(hours: 5)),
      deliveryDate: now.add(const Duration(hours: 2)),
      status: OrderStatus.waiting,
      paymentStatus: PaymentStatus.pending,
    );

    _orders = [
      order1,
      order2,
      order3,
      order4,
      order5,
      order6,
      order7,
      order8,
      order9,
      order10,
      order11,
    ];
    _updateSummaries();
  }
}
