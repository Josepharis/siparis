import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/company.dart';
import 'package:siparis/models/company_model.dart';
import 'package:siparis/providers/company_provider.dart';
import 'package:siparis/providers/work_request_provider.dart';
import 'package:siparis/customer/screens/company_detail_screen.dart';
import 'package:siparis/customer/screens/partner_company_detail_screen.dart';
import 'package:siparis/services/partnership_service.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/services/company_service.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CustomerCompaniesTab extends StatefulWidget {
  const CustomerCompaniesTab({super.key});

  @override
  State<CustomerCompaniesTab> createState() => _CustomerCompaniesTabState();
}

class _CustomerCompaniesTabState extends State<CustomerCompaniesTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Company>? _cachedCompanies;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerships();
    // Provider verilerinin yüklenmesini beklemek için biraz gecikme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndCacheCompanies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAndCacheCompanies() async {
    try {
      final companyProvider =
          Provider.of<CompanyProvider>(context, listen: false);

      // Önce direkt Firestore'dan kontrol et
      await _testFirestoreConnection();

      // Her durumda sample firmaları başlangıç olarak kullan
      final sampleCompanies = companyProvider.activeCompanies;
      List<Company> convertedCompanies = List.from(sampleCompanies);

      print('DEBUG: Sample firmalar eklendi, sayı: ${sampleCompanies.length}');

      // Eğer CompanyProvider'da Firebase veri yoksa, yüklemeyi dene
      if (companyProvider.activeFirestoreCompanies.isEmpty) {
        print('DEBUG: CompanyProvider boş, Firebase verileri yükleniyor...');
        await companyProvider.loadFirestoreCompanies();
      }

      final firestoreCompanies = companyProvider.activeFirestoreCompanies;
      print('DEBUG: Firebase firma sayısı: ${firestoreCompanies.length}');

      // Firebase firmalarını sample firmalara ekle (duplicate olmadan)
      for (var companyModel in firestoreCompanies) {
        // Aynı ID'ye sahip firma var mı kontrol et
        bool exists = convertedCompanies
            .any((existing) => existing.id == companyModel.id);
        if (!exists) {
          await companyModel.loadProducts();
          convertedCompanies.add(Company(
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
      }

      print(
          'DEBUG: Toplam firma sayısı (sample + Firebase): ${convertedCompanies.length}');

      // Her firmanın detaylarını logla
      for (var company in convertedCompanies) {
        print(
            'DEBUG: Final Firma - ID: ${company.id}, Name: ${company.name}, Services: ${company.services}');
      }

      if (mounted) {
        setState(() {
          _cachedCompanies = convertedCompanies;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Firma cache hatası: $e');

      // Hata durumunda en azından sample firmaları göster
      try {
        final companyProvider =
            Provider.of<CompanyProvider>(context, listen: false);
        final sampleCompanies = companyProvider.activeCompanies;
        print(
            'DEBUG: Hata durumunda ${sampleCompanies.length} sample firma kullanılıyor');

        if (mounted) {
          setState(() {
            _cachedCompanies = sampleCompanies;
            _isLoading = false;
          });
        }
      } catch (e2) {
        print('DEBUG: Sample firmalar da yüklenemedi: $e2');
        if (mounted) {
          setState(() {
            _cachedCompanies = [];
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onSearchChanged(String query) {
    // Önceki timer'ı iptal et
    _debounceTimer?.cancel();

    // 500ms bekle, sonra arama yap (daha uzun süre)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.toLowerCase().trim();
        });
      }
    });
  }

  Future<void> _loadPartnerships() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);

    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      print('DEBUG: Partnership verileri Firebase\'den yükleniyor...');
      await workRequestProvider.loadUserPartnerships(currentUser.uid);
      print('DEBUG: Partnership verileri yüklendi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CompanyProvider, WorkRequestProvider>(
      builder: (context, companyProvider, workRequestProvider, child) {
        // Cache'den firma verilerini kullan, ama eğer cache boşsa ve provider'da veri varsa tekrar yükle
        if (_isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Eğer cache boş ama provider'da veri varsa, cache'i yenile
        if ((_cachedCompanies == null || _cachedCompanies!.isEmpty) &&
            companyProvider.activeFirestoreCompanies.isNotEmpty) {
          print(
              'DEBUG: Cache boş ama provider\'da veri var, yeniden yükleniyor...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadAndCacheCompanies();
          });
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Firmalar yükleniyor...'),
                ],
              ),
            ),
          );
        }

        if (_cachedCompanies == null || _cachedCompanies!.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz firma bulunamadı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lütfen daha sonra tekrar deneyin',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _loadAndCacheCompanies();
                    },
                    child: const Text('Yeniden Yükle'),
                  ),
                ],
              ),
            ),
          );
        }

        final convertedFirestoreCompanies = _cachedCompanies!;
        final partneredCompanyIds = workRequestProvider.partneredCompanies;

        // Debug log'ları
        print('DEBUG: CustomerCompaniesTab build çağrıldı');
        print(
            'DEBUG: Cache firma sayısı: ${convertedFirestoreCompanies.length}');
        print('DEBUG: Partner firma ID\'leri: $partneredCompanyIds');

        // İş ortağı firmaları - cache'den
        final partneredFirestoreCompanies = convertedFirestoreCompanies
            .where((company) => partneredCompanyIds.contains(company.id))
            .toList();

        final totalPartneredCompanies = partneredFirestoreCompanies.length;

        print(
            'DEBUG: Bulunan partner firma sayısı: ${partneredFirestoreCompanies.length}');

        // Diğer firmalar (iş ortağı olmayanlar) - cache'den
        final otherFirestoreCompanies = convertedFirestoreCompanies
            .where((company) => !partneredCompanyIds.contains(company.id))
            .toList();

        final filteredOtherFirestoreCompanies =
            _getFilteredCompanies(otherFirestoreCompanies);

        // Responsive değerler
        final isSmallScreen = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // Modern App Bar - Responsive
              SliverAppBar(
                expandedHeight: isSmallScreen ? 160 : 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                          const Color(0xFF1E40AF),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Dekoratif elementler - Responsive
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: isSmallScreen ? 100 : 150,
                            height: isSmallScreen ? 100 : 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          left: -40,
                          child: Container(
                            width: isSmallScreen ? 120 : 200,
                            height: isSmallScreen ? 120 : 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // İçerik - Responsive
                        SafeArea(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                isSmallScreen ? 16 : 24,
                                isSmallScreen ? 12 : 16,
                                isSmallScreen ? 16 : 24,
                                isSmallScreen ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          isSmallScreen ? 8 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 12 : 16),
                                      ),
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        color: Colors.white,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 12 : 16),
                                    Expanded(
                                      child: Text(
                                        'İş Ortaklarım',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 20 : 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 16 : 20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${totalPartneredCompanies} Aktif İş Ortağı',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 16 : 20,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                                height: isSmallScreen ? 2 : 4),
                                            Text(
                                              'Güvenilir iş ortaklarınızla çalışın',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 11 : 13,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(
                                            isSmallScreen ? 8 : 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.handshake_rounded,
                                          color: Colors.white,
                                          size: isSmallScreen ? 20 : 24,
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
              ),
            ],
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İş Ortaklarım Bölümü - Horizontal List
                  if (totalPartneredCompanies > 0) ...[
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.fromLTRB(
                          isSmallScreen ? 16 : 24,
                          isSmallScreen ? 16 : 24,
                          isSmallScreen ? 16 : 24,
                          isSmallScreen ? 12 : 16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(isSmallScreen ? 8 : 12),
                            ),
                            child: Icon(
                              Icons.handshake_rounded,
                              color: Colors.green,
                              size: isSmallScreen ? 16 : 20,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Text(
                            'Aktif İş Ortaklarım',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 16 : 20),
                            ),
                            child: Text(
                              '$totalPartneredCompanies',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Partner Firmalar - Horizontal Row Cards
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 24),
                      child: Column(
                        children: List.generate(
                          totalPartneredCompanies,
                          (index) {
                            final company = partneredFirestoreCompanies[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: isSmallScreen ? 12 : 16),
                              child:
                                  _buildHorizontalPartnerCard(company, index),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                  ],

                  // Modern Arama Barı
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24),
                    padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arama başlığı
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 14),
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yeni Firmalar Keşfedin',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    'İş ortaklığı kurmak istediğiniz firmaları arayın',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Gelişmiş arama kutusu
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 16 : 20),
                            border: Border.all(
                              color: _searchQuery.isNotEmpty
                                  ? AppTheme.primaryColor.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _searchQuery.isNotEmpty
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: isSmallScreen ? 12 : 20,
                                offset: Offset(0, isSmallScreen ? 4 : 8),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Firma adı, hizmet türü veya konum...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: Container(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 12 : 14),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: _searchQuery.isNotEmpty
                                      ? AppTheme.primaryColor
                                      : Colors.grey[400],
                                  size: isSmallScreen ? 20 : 22,
                                ),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? Container(
                                      margin: EdgeInsets.all(
                                          isSmallScreen ? 8 : 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: Colors.grey[600],
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 20,
                                vertical: isSmallScreen ? 16 : 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tüm Firmalar Grid - Sadece arama yapıldığında göster
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Arama Sonuçları Başlığı
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.grey[600],
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                SizedBox(width: isSmallScreen ? 6 : 8),
                                Text(
                                  'Arama Sonuçları',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 6 : 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 6 : 8,
                                    vertical: isSmallScreen ? 2 : 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 10 : 12),
                                  ),
                                  child: Text(
                                    '${filteredOtherFirestoreCompanies.length}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Arama Sonuçları Grid
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredOtherFirestoreCompanies.length,
                            itemBuilder: (context, index) {
                              final company =
                                  filteredOtherFirestoreCompanies[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom: isSmallScreen ? 12 : 16),
                                child:
                                    _buildHorizontalCompanyCard(company, index),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Arama yapılmadığında gösterilecek boş alan mesajı
                  if (_searchQuery.isEmpty)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 32 : 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                size: isSmallScreen ? 32 : 40,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            Text(
                              'Firma Ara',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Yukarıdaki arama kutusunu kullanarak\nyeni firmalar keşfedin',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                color: Colors.grey[500],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalPartnerCard(Company company, int index) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: Colors.green,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isSmallScreen ? 8 : 12,
            offset: Offset(0, isSmallScreen ? 2 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: InkWell(
          onTap: () => _navigateToPartnerCompanyDetail(company),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                // Sol: Logo ve Partner Badge
                Column(
                  children: [
                    // Partner Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4 : 6,
                        vertical: isSmallScreen ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 6 : 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 8 : 10,
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 3),
                          Text(
                            'Partner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 7 : 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // Logo
                    Container(
                      width: isSmallScreen ? 35 : 40,
                      height: isSmallScreen ? 35 : 40,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
                      child: Center(
                        child: Text(
                          company.name.length >= 2
                              ? company.name.substring(0, 2).toUpperCase()
                              : company.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: isSmallScreen ? 12 : 16),

                // Orta: Firma Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Firma Adı
                      Text(
                        company.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: isSmallScreen ? 3 : 4),

                      // Hizmet Kategorisi
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 6 : 8),
                        ),
                        child: Text(
                          company.services.first,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: isSmallScreen ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 4 : 6),

                      // Açıklama
                      Text(
                        company.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8 : 12),

                // Sağ: Action Button
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCompanyCard(Company company, int index) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: _getCompanyColor(index),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isSmallScreen ? 8 : 12,
            offset: Offset(0, isSmallScreen ? 2 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: InkWell(
          onTap: () => _navigateToCompanyDetail(company),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                // Sol: Logo ve Kategori Badge
                Column(
                  children: [
                    // Kategori Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4 : 6,
                        vertical: isSmallScreen ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCompanyColor(index),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 6 : 8),
                      ),
                      child: Text(
                        company.services.first,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 7 : 8,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // Logo
                    Container(
                      width: isSmallScreen ? 35 : 40,
                      height: isSmallScreen ? 35 : 40,
                      decoration: BoxDecoration(
                        color: _getCompanyColor(index),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
                      child: Center(
                        child: Text(
                          company.name.length >= 2
                              ? company.name.substring(0, 2).toUpperCase()
                              : company.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: isSmallScreen ? 12 : 16),

                // Orta: Firma Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Firma Adı
                      Text(
                        company.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: isSmallScreen ? 4 : 6),

                      // Açıklama
                      Text(
                        company.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8 : 12),

                // Sağ: Action Button
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: _getCompanyColor(index),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCompanyColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      const Color(0xFF059669),
      const Color(0xFFEA580C),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
    ];
    return colors[index % colors.length];
  }

  List<Company> _getFilteredCompanies(List<Company> companies) {
    if (_searchQuery.isEmpty) return companies;

    return companies.where((company) {
      return company.name.toLowerCase().contains(_searchQuery) ||
          company.description.toLowerCase().contains(_searchQuery) ||
          company.services.any(
            (service) => service.toLowerCase().contains(_searchQuery),
          );
    }).toList();
  }

  void _navigateToCompanyDetail(Company company) async {
    // Oturum açmış kullanıcının bilgilerini al
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    String currentCustomerId = currentUser?.uid ?? 'customer_001';
    String currentCustomerName = 'Test Müşteri'; // Varsayılan

    // Önce oturum açmış kullanıcının kayıt sırasında girdiği firma adını kullan
    if (currentUser?.companyName != null &&
        currentUser!.companyName!.isNotEmpty) {
      currentCustomerName = currentUser.companyName!;
      print(
          'DEBUG: Kullanıcının kayıt firma adı kullanılıyor: $currentCustomerName');
    } else {
      // Eğer kayıt sırasında firma adı girilmemişse Firebase'den al
      try {
        final userCompanies =
            await CompanyService.getUserCompanies(currentCustomerId);
        if (userCompanies.isNotEmpty) {
          currentCustomerName = userCompanies.first.name;
          print('DEBUG: Firebase firma adı kullanılıyor: $currentCustomerName');
        } else {
          // Son seçenek olarak mevcut Firebase firmalarından birini al
          final companyProvider =
              Provider.of<CompanyProvider>(context, listen: false);
          final firestoreCompanies = companyProvider.activeFirestoreCompanies;
          if (firestoreCompanies.isNotEmpty) {
            currentCustomerName = firestoreCompanies.first.name;
            print(
                'DEBUG: Yedek Firebase firma adı kullanılıyor: $currentCustomerName');
          }
        }
      } catch (e) {
        print('DEBUG: Firma adı alınamadı, varsayılan kullanılıyor: $e');
      }
    }

    print(
        'DEBUG: Çalışma isteği gönderilecek - Kimden: $currentCustomerName, Kime: ${company.name}');

    try {
      // Partnerlik durumunu kontrol et
      final partnershipStatus = await PartnershipService.getPartnershipStatus(
        currentCustomerId,
        company.id,
      );

      if (!mounted) return;

      switch (partnershipStatus) {
        case PartnershipStatus.approved:
          // Partner - ürünleri göster
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
          break;

        case PartnershipStatus.pending:
          // İstek bekliyor - bilgi göster
          _showPartnershipStatusDialog(
            company,
            'İstek Bekliyor',
            'Bu firmaya gönderdiğiniz partnerlik isteği henüz değerlendirilmedi. İsteğiniz onaylandıktan sonra ürünleri görüntüleyebileceksiniz.',
            Colors.orange,
            Icons.schedule_rounded,
            currentCustomerId: currentCustomerId,
            currentCustomerName: currentCustomerName,
          );
          break;

        case PartnershipStatus.rejected:
          // İstek reddedildi - yeniden istek gönderebilir
          _showPartnershipStatusDialog(
            company,
            'İstek Reddedildi',
            'Bu firmaya gönderdiğiniz partnerlik isteği maalesef reddedilmiştir. Yeniden partnerlik isteği gönderebilirsiniz.',
            Colors.red,
            Icons.block_rounded,
            showRequestButton: true,
            currentCustomerId: currentCustomerId,
            currentCustomerName: currentCustomerName,
          );
          break;

        case PartnershipStatus.notPartner:
        default:
          // Partner değil - partnerlik isteği gönder
          _showPartnershipRequestDialog(
              company, currentCustomerId, currentCustomerName);
          break;
      }
    } catch (e) {
      print('❌ Partnerlik durumu kontrol edilemedi: $e');
      // Hata durumunda default davranış - partnerlik isteği gönder
      _showPartnershipRequestDialog(
          company, currentCustomerId, currentCustomerName);
    }
  }

  // Partnerlik durumu dialog'u
  void _showPartnershipStatusDialog(
    Company company,
    String title,
    String message,
    Color color,
    IconData icon, {
    bool showRequestButton = false,
    required String currentCustomerId,
    required String currentCustomerName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // Başlık
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Firma adı
              Text(
                company.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Mesaj
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Butonlar
              Row(
                children: [
                  // Kapat butonu
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

                  if (showRequestButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showPartnershipRequestDialog(
                              company, currentCustomerId, currentCustomerName);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Yeniden İstek Gönder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Partnerlik isteği dialog'u
  void _showPartnershipRequestDialog(
      Company company, String customerId, String customerName) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık bölümü
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // İkon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Başlık
                    const Text(
                      'Partnerlik İsteği',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Alt başlık
                    Text(
                      '${company.name} firmasına çalışma isteği gönderin',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // İçerik bölümü
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Açıklama
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Firmanın ürünlerini görüntüleyebilmeniz için partner olmanız gerekmektedir.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mesaj alanı
                    const Text(
                      'İsteğe mesaj ekleyin (İsteğe bağlı)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: messageController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          hintText:
                              'Firmayla çalışmak isteme nedeninizi kısaca açıklayın...',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Butonlar
                    Row(
                      children: [
                        // İptal butonu
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'İptal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Gönder butonu
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _sendPartnershipRequest(
                                ctx,
                                company,
                                customerId,
                                customerName,
                                messageController.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'İstek Gönder',
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
            ],
          ),
        ),
      ),
    );
  }

  // Partnerlik isteği gönderme
  Future<void> _sendPartnershipRequest(
    BuildContext dialogContext,
    Company company,
    String customerId,
    String customerName,
    String message,
  ) async {
    try {
      // 1. Partnerlik isteği gönder
      final request = PartnershipRequest(
        customerId: customerId,
        companyId: company.id,
        customerName: customerName,
        companyName: company.name,
        message: message.isNotEmpty ? message : null,
        requestDate: DateTime.now(),
      );

      await PartnershipService.sendPartnershipRequest(request);

      // 2. Aynı zamanda WorkRequest olarak da gönder (üreticinin görebilmesi için)
      final workRequestProvider =
          Provider.of<WorkRequestProvider>(context, listen: false);
      await workRequestProvider.sendWorkRequest(
        fromUserId: customerId,
        toCompanyId: company.id,
        fromUserName: customerName,
        toCompanyName: company.name,
        message: message.isNotEmpty ? message : 'Partnerlik isteği',
      );

      if (mounted && dialogContext.mounted) {
        // Dialog'u kapat
        Navigator.of(dialogContext).pop();

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      '${company.name} firmasına partnerlik isteği gönderildi!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('❌ Partnerlik isteği gönderilemedi: $e');

      if (mounted && dialogContext.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('İstek gönderilemedi. Lütfen tekrar deneyin.')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // Partner firma için direkt ürün sayfasına git
  void _navigateToPartnerCompanyDetail(Company company) {
    print('DEBUG: Partner firmaya navigasyon: ${company.name}');
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PartnerCompanyDetailScreen(company: company),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  Future<void> _testFirestoreConnection() async {
    try {
      print('DEBUG: Direkt Firestore companies sorgusu yapılıyor...');
      final firestore = FirebaseFirestore.instance;

      // Tüm companies koleksiyonunu kontrol et
      final snapshot = await firestore.collection('companies').get();
      print(
          'DEBUG: Firestore\'da toplam ${snapshot.docs.length} firma belgesi var');

      // Aktif firmaları say
      int activeCompanies = 0;
      int producerCompanies = 0;
      int customerCompanies = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? true;
        final type = data['type'] ?? 'unknown';

        if (isActive) {
          activeCompanies++;
          if (type == 'producer') producerCompanies++;
          if (type == 'customer') customerCompanies++;
        }

        print(
            'DEBUG: Firma - ID: ${doc.id}, Name: ${data['name']}, Type: $type, Active: $isActive');
      }

      print('DEBUG: Firestore - Toplam aktif firma: $activeCompanies');
      print('DEBUG: Firestore - Producer firma: $producerCompanies');
      print('DEBUG: Firestore - Customer firma: $customerCompanies');
    } catch (e) {
      print('DEBUG: Firestore bağlantı testi hatası: $e');
    }
  }
}
