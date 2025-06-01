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

class CustomerCompaniesTab extends StatefulWidget {
  const CustomerCompaniesTab({super.key});

  @override
  State<CustomerCompaniesTab> createState() => _CustomerCompaniesTabState();
}

class _CustomerCompaniesTabState extends State<CustomerCompaniesTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPartnerships();
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
        // Sadece Firebase firmalarını kullan (sample companies kaldırıldı)
        final firestoreCompanies = companyProvider.activeFirestoreCompanies;

        // Firebase firmalarını Company tipine dönüştür
        Future<List<Company>> convertFirestoreCompanies() async {
          List<Company> convertedCompanies = [];
          for (var companyModel in firestoreCompanies) {
            await companyModel.loadProducts(); // Ürünleri yükle
            convertedCompanies.add(Company(
              id: companyModel.id,
              name: companyModel.name,
              description: companyModel.description ?? '',
              services: companyModel.categories ?? ['Genel'],
              address: companyModel.address,
              phone: companyModel.phone ?? '',
              email: companyModel.email ?? '',
              website: companyModel.website,
              rating: 4.5, // Varsayılan rating
              totalProjects: 0, // Varsayılan proje sayısı
              products: companyModel.products,
              isActive: companyModel.isActive,
            ));
          }
          return convertedCompanies;
        }

        return FutureBuilder<List<Company>>(
          future: convertFirestoreCompanies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('DEBUG: Firma dönüştürme hatası: ${snapshot.error}');
              return const Center(
                  child: Text('Firmalar yüklenirken bir hata oluştu'));
            }

            final convertedFirestoreCompanies = snapshot.data ?? [];
            final partneredCompanyIds = workRequestProvider.partneredCompanies;

            // Debug log'ları
            print('DEBUG: CustomerCompaniesTab build çağrıldı');
            print(
                'DEBUG: Firebase firma sayısı: ${convertedFirestoreCompanies.length}');
            print('DEBUG: Partner firma ID\'leri: $partneredCompanyIds');

            for (var company in convertedFirestoreCompanies) {
              print(
                  'DEBUG: Firebase Firma - ID: ${company.id}, Name: ${company.name}');
            }

            // İş ortağı firmaları - sadece Firebase'den
            final partneredFirestoreCompanies = convertedFirestoreCompanies
                .where((company) => partneredCompanyIds.contains(company.id))
                .toList();

            final totalPartneredCompanies = partneredFirestoreCompanies.length;

            print(
                'DEBUG: Bulunan Firebase partner firma sayısı: ${partneredFirestoreCompanies.length}');
            print(
                'DEBUG: Toplam partner firma sayısı: $totalPartneredCompanies');

            for (var company in partneredFirestoreCompanies) {
              print(
                  'DEBUG: Firebase Partner firma: ${company.name} (${company.id})');
            }

            // Diğer firmalar (iş ortağı olmayanlar) - sadece Firebase'den
            final otherFirestoreCompanies = convertedFirestoreCompanies
                .where((company) => !partneredCompanyIds.contains(company.id))
                .toList();

            final filteredOtherFirestoreCompanies =
                _getFilteredCompanies(otherFirestoreCompanies);

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  // Modern App Bar
                  SliverAppBar(
                    expandedHeight: 200,
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
                            // Dekoratif elementler
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 150,
                                height: 150,
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
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // İçerik
                            SafeArea(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.storefront_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            'İş Ortaklarım',
                                            style: TextStyle(
                                              fontSize: 24,
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
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
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
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Güvenilir iş ortaklarınızla çalışın',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.handshake_rounded,
                                              color: Colors.white,
                                              size: 24,
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
                      // İş Ortaklarım Bölümü
                      if (totalPartneredCompanies > 0) ...[
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.handshake_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Aktif İş Ortaklarım',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$totalPartneredCompanies',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: totalPartneredCompanies,
                            itemBuilder: (context, index) {
                              final company =
                                  partneredFirestoreCompanies[index];
                              return _buildPartnerCompanyCard(company, index);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Arama Bölümü
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Yeni İş Ortakları Keşfedin',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                initialValue: _searchQuery,
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      _searchQuery = value.toLowerCase();
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Firma veya ürün ara...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.5),
                                    size: 24,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            if (mounted) {
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            }
                                          },
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tüm Firmalar Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                        ),
                        itemCount: filteredOtherFirestoreCompanies.length,
                        itemBuilder: (context, index) {
                          final company =
                              filteredOtherFirestoreCompanies[index];
                          return _buildCompanyCard(company, index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartnerCompanyCard(Company company, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToPartnerCompanyDetail(company),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Badge + Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.green,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Partner',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green,
                            Colors.green.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          company.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Company Name
                Text(
                  company.name,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Service Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    company.services.first,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Spacer(),

                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFACC15),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      company.rating.toString(),
                      style: const TextStyle(
                        color: Color(0xFFFACC15),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.green,
                        size: 14,
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

  Widget _buildCompanyCard(Company company, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getCompanyColor(index).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _navigateToCompanyDetail(company),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Container
                Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCompanyColor(index),
                        _getCompanyColor(index).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          company.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Company Info
                Text(
                  company.name,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Service Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getCompanyColor(index).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    company.services.first,
                    style: TextStyle(
                      color: _getCompanyColor(index),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Spacer(),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip(
                      Icons.star_rounded,
                      company.rating.toString(),
                      const Color(0xFFFACC15),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getCompanyColor(index).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: _getCompanyColor(index),
                        size: 18,
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

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
}
