import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/employee_provider.dart';
import 'package:siparis/models/employee.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Employee employee;

  const EditEmployeeScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  late Map<String, bool> _permissions;

  @override
  void initState() {
    super.initState();
    // Mevcut yetkileri kopyala
    _permissions = Map<String, bool>.from(widget.employee.permissions);

    // Eksik yetkileri varsayılan false değeriyle ekle
    final defaultPermissions = {
      'view_budget': false,
      'approve_partnerships': false,
      'view_companies': false,
      'manage_orders': true,
      'manage_products': false,
    };

    // Eksik olan yetkileri ekle
    for (var permission in defaultPermissions.keys) {
      _permissions[permission] ??= defaultPermissions[permission]!;
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yetki Düzenleme',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              widget.employee.name,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Çalışan bilgi kartı
          _buildEmployeeInfoCard(),

          // Yetki düzenleme alanı
          Expanded(
            child: _buildPermissionsSection(),
          ),

          // Alt güncelleme butonu
          _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              widget.employee.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  widget.employee.position,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.employee.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yetkilendirme',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Çalışanın erişebileceği sayfa ve özellikleri güncelleyin.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildPermissionSection(
            'Ana Özellikler',
            [
              _buildPermissionTile(
                'view_budget',
                'Bütçe Sekmesi',
                'Mali raporlar ve bütçe bilgilerini görüntüleyebilir',
                Icons.analytics,
              ),
              _buildPermissionTile(
                'manage_orders',
                'Sipariş Yönetimi',
                'Sipariş oluşturma, düzenleme ve durum güncelleme',
                Icons.receipt_long,
              ),
              _buildPermissionTile(
                'manage_products',
                'Ürün Yönetimi',
                'Ürün ekleme, düzenleme ve stok işlemleri',
                Icons.inventory,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPermissionSection(
            'Özel Yetkiler',
            [
              _buildPermissionTile(
                'approve_partnerships',
                'Partnerlik Onayı',
                'Çalışma isteklerini onaylayabilir/reddedebilir',
                Icons.handshake,
              ),
              _buildPermissionTile(
                'view_companies',
                'Firmalar Sekmesini Görebilir',
                'Firmalara ait geçmiş siparişlere erişebilir',
                Icons.business,
              ),
            ],
          ),
          const SizedBox(height: 100), // Alt buton için boşluk
        ],
      ),
    );
  }

  Widget _buildPermissionSection(String title, List<Widget> permissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...permissions,
      ],
    );
  }

  Widget _buildPermissionTile(
      String key, String title, String description, IconData icon) {
    // Null value kontrolü ekle
    final bool isEnabled = _permissions[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? Colors.green.shade300 : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: isEnabled,
        onChanged: (value) {
          setState(() {
            _permissions[key] = value;
          });
        },
        secondary: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isEnabled ? Colors.green : Colors.grey).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.green : Colors.grey.shade600,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        activeColor: Colors.green,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Consumer<EmployeeProvider>(
          builder: (context, employeeProvider, child) {
            return ElevatedButton(
              onPressed: employeeProvider.isLoading ? null : _updatePermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: employeeProvider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Yetkileri Güncelle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  void _updatePermissions() async {
    final employeeProvider =
        Provider.of<EmployeeProvider>(context, listen: false);

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    try {
      // Güncellenmiş employee nesnesi oluştur
      final updatedEmployee = widget.employee.copyWith(
        permissions: _permissions,
      );

      final success = await employeeProvider.updateEmployee(updatedEmployee);

      // Loading dialog'u kapat
      Navigator.of(context).pop();

      if (success) {
        // Başarı dialog'u
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            title: const Text('Başarılı'),
            content: Text(
              '${widget.employee.name} adlı çalışanın yetkileri başarıyla güncellendi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                  Navigator.of(context)
                      .pop(true); // Bu ekranı kapat ve yenileme sinyali gönder
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat
      Navigator.of(context).pop();

      print('❌ Yetki güncelleme hatası: $e');

      // Hata dialog'u
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          title: const Text('Hata'),
          content: Text(
            'Yetki güncelleme sırasında bir hata oluştu: ${e.toString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
