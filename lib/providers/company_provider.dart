import 'package:flutter/material.dart';
import 'package:siparis/models/company.dart';
import 'package:siparis/models/product.dart';

class CompanyProvider with ChangeNotifier {
  List<Company> _companies = [];
  bool _isLoading = false;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;

  List<Company> get activeCompanies =>
      _companies.where((company) => company.isActive).toList();

  CompanyProvider() {
    _loadSampleData();
  }

  void _loadSampleData() {
    _companies = [
      Company(
        id: '1',
        name: 'Anadolu Gıda',
        description:
            'Geleneksel lezzetleri modern üretim teknikleriyle buluşturan köklü gıda üreticisi.',
        address: 'Organize Sanayi Bölgesi, 1. Cadde No:15, Kocaeli',
        phone: '+90 262 555 0123',
        email: 'info@anadolugida.com.tr',
        website: 'https://anadolugida.com.tr',
        services: [
          'Süt Ürünleri',
          'Et Ürünleri',
          'Konserve',
          'Dondurulmuş Gıda'
        ],
        rating: 4.8,
        totalProjects: 156,
        isActive: true,
        products: [
          Product(
            id: '1-1',
            name: 'Organik Tam Yağlı Süt',
            description:
                'Doğal yollarla üretilen, katkısız ve taze günlük süt. A, D, E ve K vitaminleri açısından zengin.',
            price: 29.90,
            imageUrl:
                'https://images.unsplash.com/photo-1550583724-b2692b85b150?ixlib=rb-4.0.3',
            category: 'Süt Ürünleri',
            companyId: '1',
            companyName: 'Anadolu Gıda',
            rating: 4.9,
            reviewCount: 128,
          ),
          Product(
            id: '1-2',
            name: 'Taze Kaşar Peyniri',
            description:
                'Özel olarak olgunlaştırılmış, tam yağlı inek sütünden üretilen geleneksel lezzet.',
            price: 189.90,
            imageUrl:
                'https://images.unsplash.com/photo-1624806992066-5ffcf7ca186b?ixlib=rb-4.0.3',
            category: 'Süt Ürünleri',
            companyId: '1',
            companyName: 'Anadolu Gıda',
            rating: 4.8,
            reviewCount: 95,
          ),
          Product(
            id: '1-3',
            name: 'Dana Antrikot',
            description:
                'Özenle seçilmiş, dinlendirilmiş, kaliteli dana eti. Kilogram fiyatıdır.',
            price: 450.00,
            imageUrl:
                'https://images.unsplash.com/photo-1603048297172-c92544798d5a?ixlib=rb-4.0.3',
            category: 'Et Ürünleri',
            companyId: '1',
            companyName: 'Anadolu Gıda',
            rating: 4.7,
            reviewCount: 73,
          ),
        ],
      ),
      Company(
        id: '2',
        name: 'Doğal Tarım',
        description:
            'Organik ve doğal tarım ürünleri üretimi yapan sertifikalı üretici firma.',
        address: 'Tarım Mahallesi, Çiftlik Cad. No:45, Bursa',
        phone: '+90 224 555 0456',
        email: 'contact@dogaltarim.com',
        website: 'https://dogaltarim.com',
        services: ['Organik Sebze', 'Meyve', 'Tahıl', 'Bakliyat'],
        rating: 4.9,
        totalProjects: 89,
        isActive: true,
        products: [
          Product(
            id: '2-1',
            name: 'Organik Çeri Domates',
            description:
                'Tamamen doğal yöntemlerle yetiştirilen, tatlı ve sulu çeri domatesler. 500g paket.',
            price: 34.90,
            imageUrl:
                'https://images.unsplash.com/photo-1566635285905-0c82de7f0d47?ixlib=rb-4.0.3',
            category: 'Organik Sebze',
            companyId: '2',
            companyName: 'Doğal Tarım',
            rating: 4.9,
            reviewCount: 156,
          ),
          Product(
            id: '2-2',
            name: 'Yerli Muz',
            description: 'Anamur muzunun en taze hali. Kilogram fiyatıdır.',
            price: 44.90,
            imageUrl:
                'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?ixlib=rb-4.0.3',
            category: 'Meyve',
            companyId: '2',
            companyName: 'Doğal Tarım',
            rating: 4.8,
            reviewCount: 112,
          ),
        ],
      ),
      Company(
        id: '3',
        name: 'Deniz Ürünleri A.Ş.',
        description:
            'Taze ve kaliteli deniz ürünleri işleme ve paketleme konusunda uzman firma.',
        address: 'Liman Mahallesi, Balıkçı Cad. No:789, İzmir',
        phone: '+90 232 555 0789',
        email: 'hello@denizurunleri.com',
        website: null,
        services: [
          'Taze Balık',
          'Dondurulmuş Balık',
          'Konserve Balık',
          'Deniz Mahsulleri'
        ],
        rating: 4.7,
        totalProjects: 234,
        isActive: true,
        products: [
          Product(
            id: '3-1',
            name: 'Norveç Somonu',
            description:
                'Taze Norveç somonu. Omega-3 açısından zengin. Kilogram fiyatıdır.',
            price: 890.00,
            imageUrl:
                'https://images.unsplash.com/photo-1599084993091-1cb5c0721cc6?ixlib=rb-4.0.3',
            category: 'Taze Balık',
            companyId: '3',
            companyName: 'Deniz Ürünleri A.Ş.',
            rating: 4.9,
            reviewCount: 87,
          ),
          Product(
            id: '3-2',
            name: 'Jumbo Karides',
            description: 'Temizlenmiş, hazır jumbo karides. 500g paket.',
            price: 450.00,
            imageUrl:
                'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?ixlib=rb-4.0.3',
            category: 'Deniz Mahsulleri',
            companyId: '3',
            companyName: 'Deniz Ürünleri A.Ş.',
            rating: 4.8,
            reviewCount: 64,
          ),
        ],
      ),
      Company(
        id: '4',
        name: 'Şeker Fabrikası',
        description:
            'Şeker pancarından şeker üretimi ve şekerli ürünler imalatı yapan fabrika.',
        address: 'Sanayi Mahallesi, Fabrika Cad. No:321, Konya',
        phone: '+90 332 555 0321',
        email: 'info@sekerfabrikasi.com.tr',
        website: 'https://sekerfabrikasi.com.tr',
        services: ['Kristal Şeker', 'Toz Şeker', 'Küp Şeker', 'Şurup'],
        rating: 4.6,
        totalProjects: 67,
        isActive: true,
        products: [
          Product(
            id: '4-1',
            name: 'Kristal Toz Şeker',
            description:
                'İnce taneli, çay ve kahve için ideal kristal toz şeker. 1kg paket.',
            price: 29.90,
            imageUrl:
                'https://images.unsplash.com/photo-1581441363689-1f3c3c414635?ixlib=rb-4.0.3',
            category: 'Toz Şeker',
            companyId: '4',
            companyName: 'Şeker Fabrikası',
            rating: 4.7,
            reviewCount: 234,
          ),
          Product(
            id: '4-2',
            name: 'Küp Şeker',
            description:
                'Geleneksel küp şeker, çay servisi için ideal. 1kg kutu.',
            price: 34.90,
            imageUrl:
                'https://images.unsplash.com/photo-1626790291085-19a27173773c?ixlib=rb-4.0.3',
            category: 'Küp Şeker',
            companyId: '4',
            companyName: 'Şeker Fabrikası',
            rating: 4.6,
            reviewCount: 187,
          ),
        ],
      ),
      Company(
        id: '5',
        name: 'Baharat Dünyası',
        description:
            'Doğal baharat ve çeşni üretimi yapan geleneksel imalat firması.',
        address: 'Eski Çarşı, Baharat Sokak No:654, Gaziantep',
        phone: '+90 342 555 0654',
        email: 'support@baharatdunyasi.com',
        website: 'https://baharatdunyasi.com',
        services: ['Toz Baharat', 'Karışım Baharat', 'Çay', 'Bitki Çayı'],
        rating: 4.8,
        totalProjects: 123,
        isActive: true,
        products: [
          Product(
            id: '5-1',
            name: 'Pul Biber',
            description:
                'Gaziantep yöresine özgü, özenle kurutulmuş ve çekilmiş pul biber. 250g paket.',
            price: 45.90,
            imageUrl:
                'https://images.unsplash.com/photo-1635341814519-62c2d5122bf9?ixlib=rb-4.0.3',
            category: 'Toz Baharat',
            companyId: '5',
            companyName: 'Baharat Dünyası',
            rating: 4.9,
            reviewCount: 342,
          ),
          Product(
            id: '5-2',
            name: 'Adaçayı',
            description:
                'Doğal yollarla toplanmış ve kurutulmuş adaçayı. 100g paket.',
            price: 39.90,
            imageUrl:
                'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?ixlib=rb-4.0.3',
            category: 'Bitki Çayı',
            companyId: '5',
            companyName: 'Baharat Dünyası',
            rating: 4.8,
            reviewCount: 156,
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  Future<void> loadCompanies() async {
    _isLoading = true;
    notifyListeners();

    // Simüle edilmiş API çağrısı
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
  }

  Company? getCompanyById(String id) {
    try {
      return _companies.firstWhere((company) => company.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Company> searchCompanies(String query) {
    if (query.isEmpty) return _companies;

    return _companies.where((company) {
      return company.name.toLowerCase().contains(query.toLowerCase()) ||
          company.description.toLowerCase().contains(query.toLowerCase()) ||
          company.services.any(
              (service) => service.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  List<Company> getCompaniesByService(String service) {
    return _companies.where((company) {
      return company.services
          .any((s) => s.toLowerCase().contains(service.toLowerCase()));
    }).toList();
  }
}
