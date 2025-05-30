import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siparis/providers/order_provider.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  bool _notificationsEnabled = true;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final employee = authProvider.currentEmployee;
          final isEmployee = authProvider.isEmployeeLogin;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern Header
              SliverToBoxAdapter(
                child: _buildHeader(user, employee, isEmployee),
              ),

              // Profile Info Card
              SliverToBoxAdapter(
                child: _buildProfileCard(user, employee, isEmployee),
              ),

              // Quick Settings
              SliverToBoxAdapter(
                child: _buildQuickSettings(),
              ),

              // Account Actions
              SliverToBoxAdapter(
                child: _buildAccountActions(authProvider),
              ),

              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(user, employee, bool isEmployee) {
    final name = isEmployee ? employee?.name : user?.name;
    final role = isEmployee ? employee?.position : 'Firma Sahibi';
    final companyName = isEmployee
        ? (employee?.companyId ?? 'Bağlı Firma')
        : (user?.companyName ?? 'Firma Adı Belirtilmemiş');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                name?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim ve Rol yan yana
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name ?? 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Firma Adı
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (isEmployee) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Çalışan Hesabı',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(user, employee, bool isEmployee) {
    final email = isEmployee ? employee?.email : user?.email;
    final phone = isEmployee ? employee?.phone : user?.phone;
    final company = isEmployee ? 'Bağlı Firma' : user?.companyName;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Kişisel Bilgiler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              // Düzenle butonu - sadece sahip için
              if (!isEmployee)
                IconButton(
                  onPressed: () => _showEditProfileDialog(user),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Email
          _buildInfoRow(
            Icons.email_outlined,
            'E-posta',
            email ?? 'Belirtilmemiş',
          ),

          // Phone
          if (phone != null && phone.isNotEmpty)
            _buildInfoRow(
              Icons.phone_outlined,
              'Telefon',
              phone,
            ),

          // Company
          if (company != null && company.isNotEmpty)
            _buildInfoRow(
              Icons.business_outlined,
              isEmployee ? 'Bağlı Firma' : 'Firma',
              company,
            ),

          // Address - sadece sahip için ve adres varsa
          if (!isEmployee &&
              user?.companyAddress != null &&
              user!.companyAddress!.isNotEmpty)
            _buildInfoRow(
              Icons.location_on_outlined,
              'Firma Adresi',
              user!.companyAddress!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Hızlı Ayarlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Notifications Toggle
          _buildSettingToggle(
            Icons.notifications_outlined,
            'Bildirimler',
            'Sipariş güncellemelerini al',
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.primaryColor : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // App Info
          _buildActionTile(
            Icons.info_outline_rounded,
            'Uygulama Bilgisi',
            'Sürüm 1.0.0',
            () {
              _showAppInfoDialog();
            },
            Colors.blue,
          ),

          const SizedBox(height: 12),

          // Logout
          _buildActionTile(
            Icons.logout_rounded,
            'Çıkış Yap',
            'Hesabınızdan güvenli çıkış',
            () {
              _showLogoutDialog(authProvider);
            },
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            const Text('Uygulama Bilgisi'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sipariş Takip Uygulaması'),
            SizedBox(height: 8),
            Text('Sürüm: 1.0.0'),
            SizedBox(height: 8),
            Text('Modern sipariş yönetimi çözümü'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 12),
            Text('Çıkış Yap'),
          ],
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(user) {
    // Form değerlerini doldur
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _companyController.text = user?.companyName ?? '';
    _addressController.text = user?.companyAddress ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
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
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profili Düzenle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Firma ve kişisel bilgilerinizi güncelleyin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Firma Bilgileri
                    const Text(
                      'Firma Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildEditField(
                      controller: _companyController,
                      label: 'Firma Adı',
                      icon: Icons.business_rounded,
                      hint: 'Firma adınızı girin',
                    ),

                    const SizedBox(height: 20),

                    _buildEditField(
                      controller: _addressController,
                      label: 'Firma Adresi',
                      icon: Icons.location_on_rounded,
                      hint: 'Firmanızın tam adresini girin',
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Kişisel Bilgiler
                    const Text(
                      'Kişisel Bilgiler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildEditField(
                      controller: _nameController,
                      label: 'Ad Soyad',
                      icon: Icons.person_rounded,
                      hint: 'Adınızı ve soyadınızı girin',
                    ),

                    const SizedBox(height: 20),

                    _buildEditField(
                      controller: _emailController,
                      label: 'E-posta',
                      icon: Icons.email_rounded,
                      hint: 'ornek@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: false, // Email değiştirilemez
                    ),

                    const SizedBox(height: 20),

                    _buildEditField(
                      controller: _phoneController,
                      label: 'Telefon',
                      icon: Icons.phone_rounded,
                      hint: '0555 123 45 67',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _saveProfile(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Değişiklikleri Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: enabled ? AppTheme.textPrimaryColor : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: enabled ? AppTheme.primaryColor : Colors.grey.shade400,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }

  void _saveProfile(AuthProvider authProvider) async {
    // Form validasyonu
    if (_nameController.text.trim().isEmpty ||
        _companyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen zorunlu alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Güncellenmiş kullanıcı verisi oluştur
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        // Eski firma adını kaydet (sipariş güncellemesi için)
        final oldCompanyName = currentUser.companyName;
        final newCompanyName = _companyController.text.trim();

        final updatedUser = currentUser.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          companyName: newCompanyName,
          companyAddress: _addressController.text.trim(),
        );

        // Güncellemeyi kaydet
        final success = await authProvider.updateUserData(updatedUser);

        if (success) {
          // Eğer firma adı değiştiyse, siparişleri de güncelle
          if (oldCompanyName != null && oldCompanyName != newCompanyName) {
            await _updateCustomerOrdersAfterProfileChange(
              oldCompanyName,
              newCompanyName,
              _phoneController.text.trim(),
              _addressController.text.trim(),
            );
          }

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profil başarıyla güncellendi!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Güncelleme başarısız oldu'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Hata: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Profil değiştiğinde sipariş müşteri bilgilerini güncelle
  Future<void> _updateCustomerOrdersAfterProfileChange(
    String oldCompanyName,
    String newCompanyName,
    String newPhone,
    String newAddress,
  ) async {
    try {
      print('🔄 Sipariş müşteri bilgileri güncelleniyor...');
      print('   Eski firma adı: $oldCompanyName');
      print('   Yeni firma adı: $newCompanyName');

      // Firebase'den eski firma adıyla kayıtlı siparişleri bul
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('customer.name', isEqualTo: oldCompanyName)
          .get();

      print('   Güncellenecek sipariş sayısı: ${querySnapshot.docs.length}');

      // Batch güncelleme hazırla
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        // Sipariş verisini al
        final orderData = doc.data() as Map<String, dynamic>;

        // Müşteri bilgilerini güncelle
        orderData['customer']['name'] = newCompanyName;
        orderData['customer']['phoneNumber'] = newPhone;
        orderData['customer']['address'] = newAddress;

        // Batch'e ekle
        batch.update(doc.reference, orderData);
      }

      // Batch'i çalıştır
      await batch.commit();

      print('✅ ${querySnapshot.docs.length} sipariş güncellendi');

      // OrderProvider'ı yeniden yükle
      if (mounted) {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.loadOrders();
      }
    } catch (e) {
      print('❌ Sipariş güncelleme hatası: $e');
      // Hata olsa da profil güncellemesini engellemiyoruz
    }
  }
}
