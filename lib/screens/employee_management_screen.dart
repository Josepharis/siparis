import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/screens/add_employee_screen.dart';
import 'package:siparis/screens/edit_employee_screen.dart';
import 'package:siparis/providers/employee_provider.dart';
import 'package:siparis/providers/auth_provider.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmployees();
  }

  void _loadEmployees() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final employeeProvider =
          Provider.of<EmployeeProvider>(context, listen: false);

      // Şirket ID'sini al
      final companyId = authProvider.currentUser?.uid ?? 'demo-company-id';

      print('🔍 Çalışanlar yükleniyor... Company ID: $companyId');

      // Çalışanları yükle
      employeeProvider.loadEmployees(companyId);
    });
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
          'Çalışan Yönetimi',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadEmployees,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Aktif Çalışanlar'),
            Tab(text: 'Bekleyen İstekler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveEmployeesTab(),
          _buildPendingRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEmployeeScreen(),
            ),
          );

          // Çalışan eklendikten sonra listeyi yenile
          if (result == true) {
            _loadEmployees();
          }
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Yeni Çalışan Ekle',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActiveEmployeesTab() {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, child) {
        if (employeeProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final activeEmployees = employeeProvider.activeEmployees;

        if (activeEmployees.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Henüz Aktif Çalışan Yok',
            subtitle: 'Yeni çalışan ekleyerek başlayabilirsiniz.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeEmployees.length,
          itemBuilder: (context, index) {
            final employee = activeEmployees[index];
            return _buildEmployeeCard(employee);
          },
        );
      },
    );
  }

  Widget _buildEmployeeCard(employee) {
    return GestureDetector(
      onTap: () async {
        print('🔧 ${employee.name} düzenleme ekranı açılıyor...');

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditEmployeeScreen(employee: employee),
          ),
        );

        // Güncelleme sonrası listeyi yenile
        if (result == true) {
          _loadEmployees();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      employee.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          employee.position,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email,
                      size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    employee.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone,
                      size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    employee.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: employee.permissions.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => _buildPermissionChip(entry.key))
                    .cast<Widget>()
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String permission) {
    final permissionLabels = {
      'view_budget': 'Bütçe',
      'approve_partnerships': 'Partnerlik',
      'view_order_history': 'Sipariş Geçmişi',
      'manage_orders': 'Sipariş Yönetimi',
      'manage_products': 'Ürün Yönetimi',
      'view_financial_reports': 'Mali Raporlar',
      'manage_employees': 'Çalışan Yönetimi',
    };

    final colors = {
      'view_budget': Colors.blue,
      'approve_partnerships': Colors.orange,
      'view_order_history': Colors.purple,
      'manage_orders': Colors.green,
      'manage_products': Colors.teal,
      'view_financial_reports': Colors.red,
      'manage_employees': Colors.indigo,
    };

    final label = permissionLabels[permission] ?? permission;
    final color = colors[permission] ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    // Şimdilik placeholder - gerçek veriler ileride eklenecek
    return _buildEmptyState(
      icon: Icons.pending_actions_outlined,
      title: 'Bekleyen İstek Yok',
      subtitle: 'Çalışan kayıt istekleri burada görünecek.',
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
}
