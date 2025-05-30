import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/company.dart';
import 'package:siparis/models/company_model.dart';
import 'package:siparis/models/work_request.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:siparis/providers/company_provider.dart';
import 'package:siparis/providers/work_request_provider.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/add_company_screen.dart';
import 'package:siparis/screens/order_detail_screen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Firebase firmalarını ve iş ortaklıklarını yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Veri yükleme metodunu ayrı bir metoda çıkar
  Future<void> _loadData() async {
    final companyProvider =
        Provider.of<CompanyProvider>(context, listen: false);
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Firebase firmalarını yükle
    await companyProvider.loadFirestoreCompanies();

    // Kullanıcının iş ortaklıklarını ve çalışma isteklerini yükle
    if (authProvider.currentUser != null) {
      print('DEBUG: CompaniesScreen - Veriler yükleniyor...');
      await Future.wait([
        workRequestProvider.loadUserPartnerships(authProvider.currentUser!.uid),
        workRequestProvider
            .loadUserCompanyRequests(authProvider.currentUser!.uid),
      ]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ekran her göründüğünde verileri yenile
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Firmalar',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Çalışılan Firmalar'),
            Tab(text: 'Çalışma İstekleri'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPartneredCompaniesTab(),
          _buildWorkRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCompanyScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Firma Ekle',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPartneredCompaniesTab() {
    return Consumer2<CompanyProvider, WorkRequestProvider>(
      builder: (context, companyProvider, workRequestProvider, child) {
        final partneredCompanyIds = workRequestProvider.partneredCompanies;

        // Debug log'ları
        print('DEBUG: CompaniesScreen _buildPartneredCompaniesTab çağrıldı');
        print('DEBUG: Partner firma ID\'leri: $partneredCompanyIds');
        print('DEBUG: Örnek firma sayısı: ${companyProvider.companies.length}');
        print(
            'DEBUG: Firebase firma sayısı: ${companyProvider.firestoreCompanies.length}');

        // Firebase firmalarının ID'lerini yazdır
        print('DEBUG: Firebase firma ID\'leri:');
        for (var company in companyProvider.firestoreCompanies) {
          print(
              'DEBUG: Firebase Firma - ID: ${company.id}, Name: ${company.name}');
        }

        // Örnek firmalarının ID'lerini yazdır
        print('DEBUG: Örnek firma ID\'leri:');
        for (var company in companyProvider.companies) {
          print(
              'DEBUG: Örnek Firma - ID: ${company.id}, Name: ${company.name}');
        }

        // Hem örnek hem de Firebase firmalarından partnered olanları al
        final partneredSampleCompanies = companyProvider.companies
            .where((company) => partneredCompanyIds.contains(company.id))
            .toList();

        final partneredFirestoreCompanies = companyProvider.firestoreCompanies
            .where((company) => partneredCompanyIds.contains(company.id))
            .toList();

        final totalPartnered = partneredSampleCompanies.length +
            partneredFirestoreCompanies.length;

        print(
            'DEBUG: Bulunan örnek partner firma sayısı: ${partneredSampleCompanies.length}');
        print(
            'DEBUG: Bulunan Firebase partner firma sayısı: ${partneredFirestoreCompanies.length}');
        print('DEBUG: Toplam partner firma sayısı: $totalPartnered');

        for (var company in partneredSampleCompanies) {
          print('DEBUG: Örnek Partner firma: ${company.name} (${company.id})');
        }

        for (var company in partneredFirestoreCompanies) {
          print(
              'DEBUG: Firebase Partner firma: ${company.name} (${company.id})');
        }

        if (totalPartnered == 0) {
          return _buildEmptyState(
            icon: Icons.business_outlined,
            title: 'Henüz Çalışılan Firma Yok',
            subtitle: 'Yeni firmalar ekleyerek çalışma başlayabilirsiniz.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: totalPartnered,
          itemBuilder: (context, index) {
            if (index < partneredSampleCompanies.length) {
              final company = partneredSampleCompanies[index];
              return _buildSampleCompanyCard(company, isPartnered: true);
            } else {
              final firestoreIndex = index - partneredSampleCompanies.length;
              final company = partneredFirestoreCompanies[firestoreIndex];
              return _buildFirestoreCompanyCard(company, isPartnered: true);
            }
          },
        );
      },
    );
  }

  Widget _buildWorkRequestsTab() {
    return Consumer<WorkRequestProvider>(
      builder: (context, workRequestProvider, child) {
        // Bekleyen çalışma isteklerini al
        final pendingRequests = workRequestProvider.workRequests
            .where((request) => request.status == WorkRequestStatus.pending)
            .toList();

        print('DEBUG: _buildWorkRequestsTab çağrıldı');
        print(
            'DEBUG: Toplam çalışma isteği: ${workRequestProvider.workRequests.length}');
        print('DEBUG: Bekleyen istek sayısı: ${pendingRequests.length}');

        if (workRequestProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          );
        }

        if (pendingRequests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Çalışma İsteği Yok',
            subtitle: 'Henüz bekleyen çalışma isteğiniz bulunmuyor.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            final request = pendingRequests[index];
            return _buildWorkRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildWorkRequestCard(WorkRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fromUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.toCompanyName} firmasına',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Bekliyor',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Mesaj
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                // Kabul Et butonu
                ElevatedButton(
                  onPressed: () => _acceptWorkRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Kabul Et',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Reddet butonu
                OutlinedButton(
                  onPressed: () => _rejectWorkRequest(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reddet',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _acceptWorkRequest(WorkRequest request) async {
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);

    final success = await workRequestProvider.acceptWorkRequest(request.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request.fromUserName} ile çalışma başladı!'),
          backgroundColor: Colors.green,
        ),
      );
      // Verileri yenile
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İstek kabul edilirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectWorkRequest(WorkRequest request) async {
    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);

    final success = await workRequestProvider.rejectWorkRequest(request.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request.fromUserName} isteği reddedildi'),
          backgroundColor: Colors.orange,
        ),
      );
      // Verileri yenile
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İstek reddedilirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSampleCompanyCard(Company company, {required bool isPartnered}) {
    return GestureDetector(
      onTap: isPartnered
          ? () => _showCompanyOrderHistory(company.name, company.id)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPartnered
              ? Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                company.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Örnek',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isPartnered) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Çalışıyor',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                company.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    company.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.work_outline,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${company.totalProjects} proje',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (!isPartnered)
                    Consumer<WorkRequestProvider>(
                      builder: (context, workRequestProvider, child) {
                        final isPartner =
                            workRequestProvider.isPartneredCompany(company.id);

                        if (isPartner) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Çalışıyor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        return ElevatedButton(
                          onPressed: () =>
                              _showWorkRequestDialog(company.name, company.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Çalışma İsteği',
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirestoreCompanyCard(CompanyModel company,
      {required bool isPartnered}) {
    return GestureDetector(
      onTap: isPartnered
          ? () => _showCompanyOrderHistory(company.name, company.id)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPartnered
              ? Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                company.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Firebase',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isPartnered) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Çalışıyor',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                company.description ?? 'Açıklama bulunmuyor.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.business_center,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    company.type == 'producer' ? 'Üretici' : 'Müşteri',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${company.createdAt.day}/${company.createdAt.month}/${company.createdAt.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (!isPartnered)
                    Consumer<WorkRequestProvider>(
                      builder: (context, workRequestProvider, child) {
                        final isPartner =
                            workRequestProvider.isPartneredCompany(company.id);

                        if (isPartner) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Çalışıyor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        return ElevatedButton(
                          onPressed: () =>
                              _showWorkRequestDialog(company.name, company.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Çalışma İsteği',
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showWorkRequestDialog(String companyName, String companyId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '$companyName ile Çalışma İsteği',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Çalışma isteği mesajınızı yazın:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Merhaba, sizinle çalışmak istiyorum...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => _sendWorkRequest(
                companyName, companyId, messageController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _sendWorkRequest(
      String companyName, String companyId, String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir mesaj yazın'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context); // Dialog'u kapat

    print(
        'DEBUG: Çalışma isteği gönderiliyor - Company: $companyName, ID: $companyId');

    final workRequestProvider =
        Provider.of<WorkRequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Gerçek kullanıcı bilgilerini al
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce giriş yapın'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await workRequestProvider.sendWorkRequest(
      fromUserId: currentUser.uid, // Gerçek kullanıcı ID'si
      toCompanyId: companyId,
      fromUserName: currentUser.name ??
          currentUser.email ??
          'Kullanıcı', // Gerçek kullanıcı adı
      toCompanyName: companyName,
      message: message,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$companyName firmasına çalışma isteği gönderildi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu firmaya zaten çalışma isteği gönderilmiş'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showCompanyOrderHistory(String companyName, String companyId) {
    DateTimeRange? selectedDateRange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
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
              children: [
                // Başlık
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sipariş Geçmişi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              companyName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tarih Filtreleme
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTimeRange? picked =
                                await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                              initialDateRange: selectedDateRange,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDateRange = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedDateRange == null
                                        ? 'Tarih aralığı seçin'
                                        : '${_formatDate(selectedDateRange!.start)} - ${_formatDate(selectedDateRange!.end)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: selectedDateRange == null
                                          ? Colors.grey.shade600
                                          : AppTheme.textPrimaryColor,
                                      fontWeight: selectedDateRange == null
                                          ? FontWeight.normal
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedDateRange != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDateRange = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.clear,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Sipariş Listesi
                Expanded(
                  child: Consumer<OrderProvider>(
                    builder: (context, orderProvider, child) {
                      // Firmaya ait siparişleri filtrele
                      final companyOrders = orderProvider.orders
                          .where((order) => order.customer.name == companyName)
                          .toList();

                      // Tarih filtrelemesi
                      final filteredOrders = selectedDateRange == null
                          ? companyOrders
                          : companyOrders.where((order) {
                              final orderDate = DateTime(
                                order.orderDate.year,
                                order.orderDate.month,
                                order.orderDate.day,
                              );
                              final startDate = DateTime(
                                selectedDateRange!.start.year,
                                selectedDateRange!.start.month,
                                selectedDateRange!.start.day,
                              );
                              final endDate = DateTime(
                                selectedDateRange!.end.year,
                                selectedDateRange!.end.month,
                                selectedDateRange!.end.day,
                              );
                              return orderDate.isAfter(startDate
                                      .subtract(const Duration(days: 1))) &&
                                  orderDate.isBefore(
                                      endDate.add(const Duration(days: 1)));
                            }).toList();

                      // Tarihe göre sırala (en yeni önce)
                      filteredOrders
                          .sort((a, b) => b.orderDate.compareTo(a.orderDate));

                      if (filteredOrders.isEmpty) {
                        return _buildEmptyOrderHistory(
                            selectedDateRange != null);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderHistoryCard(order);
                        },
                      );
                    },
                  ),
                ),

                // Alt Bilgi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sipariş kartına dokunarak detaylarını görüntüleyebilirsiniz.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
      ),
    );
  }

  Widget _buildEmptyOrderHistory(bool hasDateFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasDateFilter
                ? Icons.date_range_outlined
                : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasDateFilter
                ? 'Seçilen Tarih Aralığında\nSipariş Bulunamadı'
                : 'Henüz Sipariş Yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasDateFilter
                ? 'Farklı bir tarih aralığı deneyin.'
                : 'Bu firma ile henüz sipariş geçmişiniz bulunmuyor.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryCard(Order order) {
    return GestureDetector(
      onTap: () {
        // Sipariş detayına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sipariş başlığı ve durum
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${order.id.substring(0, 6).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      Order.getStatusText(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tarih ve tutar
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Ürünler
              Text(
                'Ürünler: ${order.items.map((item) => '${item.product.name} (${item.quantity})').join(', ')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Ödeme durumu
              if (order.status == OrderStatus.completed) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      order.paymentStatus == PaymentStatus.paid
                          ? Icons.check_circle
                          : Icons.pending,
                      size: 16,
                      color: order.paymentStatus == PaymentStatus.paid
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.paymentStatus == PaymentStatus.paid
                          ? 'Ödeme Tamamlandı'
                          : 'Ödeme Bekliyor (₺${order.remainingAmount.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: order.paymentStatus == PaymentStatus.paid
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waiting:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
