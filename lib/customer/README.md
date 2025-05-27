# Müşteri Arayüzü

Bu klasör, sipariş takip uygulamasının müşteri arayüzü bileşenlerini içerir. Müşteri arayüzü, ana sistem arayüzünden tamamen ayrı tutulmuş ve müşterilerin sipariş verme, takip etme ve profil yönetimi yapabilmesi için tasarlanmıştır.

## Klasör Yapısı

```
customer/
├── screens/
│   ├── customer_home_screen.dart          # Ana müşteri ekranı
│   └── tabs/
│       ├── customer_dashboard_tab.dart    # Müşteri dashboard (günlük üretilecekler olmadan)
│       ├── customer_orders_tab.dart       # Müşteri siparişleri
│       ├── customer_products_tab.dart     # Ürün kataloğu
│       └── customer_profile_tab.dart      # Müşteri profili
└── README.md                              # Bu dosya
```

## Özellikler

### 1. Ana Sayfa (Dashboard)
- Mevcut home screen tasarımını kullanır
- **Günlük üretilecekler kısmı çıkarılmıştır**
- Sipariş durumu özetleri
- Aktif ve son siparişler
- Temiz ve kullanıcı dostu arayüz

### 2. Siparişlerim
- Aktif, tamamlanan ve tüm siparişler
- Sipariş arama ve filtreleme
- Sipariş detaylarını görüntüleme
- Tab tabanlı organizasyon

### 3. Ürünler
- Ürün kataloğu görüntüleme
- Kategori bazlı filtreleme
- Ürün arama
- Sipariş verme dialog'u
- Grid layout ile modern tasarım

### 4. Profil
- Müşteri bilgileri
- Uygulama ayarları
- Destek ve yardım
- Çıkış işlemi

## Tasarım Prensipleri

1. **Ayrı Mimari**: Müşteri arayüzü ana sistemden tamamen ayrı tutulmuştur
2. **Temiz Kod**: Her component kendi sorumluluğuna odaklanır
3. **Tutarlı Tasarım**: Ana sistem ile aynı tema ve tasarım dilini kullanır
4. **Kullanıcı Deneyimi**: Müşteri odaklı basit ve anlaşılır arayüz

## Kullanım

Müşteri arayüzüne erişmek için:

```dart
Navigator.pushNamed(context, '/customer');
```

veya

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
);
```

## Geliştirme Notları

- Tüm müşteri ekranları `customer/screens/` altında organize edilmiştir
- Tab'lar ayrı dosyalarda tutularak modülerlik sağlanmıştır
- Mevcut provider'lar ve model'lar kullanılmıştır
- Müşteri arayüzünde durum değişikliği yapılamaz (sadece görüntüleme)

## Gelecek Geliştirmeler

- Müşteri authentication sistemi
- Push notification entegrasyonu
- Sipariş geçmişi detayları
- Favori ürünler
- Sepet yönetimi
- Online ödeme entegrasyonu 