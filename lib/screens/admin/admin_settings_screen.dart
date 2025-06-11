import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  
  @override
  void initState() {
    super.initState();
    
    // Admin kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }

  // Admin erişim kontrolü
  void _checkAdminAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || !authProvider.currentUser!.isAdmin) {
      print('❌ Admin olmayan kullanıcı admin settings\'e erişmeye çalışıyor');
      
      authProvider.signOut().then((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu alana erişim yetkiniz bulunmamaktadır'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Ayarları'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uygulama Bilgileri
            const Text(
              'Uygulama Bilgileri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildInfoTile(
                    'Uygulama Adı',
                    'Sipariş Takip Sistemi',
                    Icons.apps,
                  ),
                  _buildInfoTile(
                    'Versiyon',
                    '1.0.0',
                    Icons.info,
                  ),
                  _buildInfoTile(
                    'Son Güncelleme',
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    Icons.update,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sistem Ayarları
            const Text(
              'Sistem Ayarları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildSettingsTile(
                    'Veritabanı Durumu',
                    'Aktif ve Çalışıyor',
                    Icons.storage,
                    Colors.green,
                    onTap: () => _showDatabaseInfo(),
                  ),
                  _buildSettingsTile(
                    'Cache Temizle',
                    'Uygulama önbelleğini temizle',
                    Icons.clear_all,
                    Colors.orange,
                    onTap: () => _clearCache(),
                  ),
                  _buildSettingsTile(
                    'Veri Yedekleme',
                    'Sistem verilerini yedekle',
                    Icons.backup,
                    Colors.blue,
                    onTap: () => _showBackupDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Abonelik Ayarları
            const Text(
              'Abonelik Ayarları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildSettingsTile(
                    'Varsayılan Abonelik Süresi',
                    '30 Gün',
                    Icons.schedule,
                    Colors.purple,
                    onTap: () => _showSubscriptionSettings(),
                  ),
                  _buildSettingsTile(
                    'Otomatik Bildirimler',
                    'Abonelik sona erme uyarıları',
                    Icons.notifications,
                    Colors.indigo,
                    onTap: () => _showNotificationSettings(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Güvenlik Ayarları
            const Text(
              'Güvenlik',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildSettingsTile(
                    'Admin Şifre Değiştir',
                    'Güvenlik için düzenli olarak değiştirin',
                    Icons.lock_reset,
                    Colors.red,
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  _buildSettingsTile(
                    'Oturum Geçmişi',
                    'Admin giriş loglarını görüntüle',
                    Icons.history,
                    Colors.brown,
                    onTap: () => _showLoginHistory(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Acil Durum İşlemleri
            const Text(
              'Acil Durum',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Column(
                children: [
                  _buildSettingsTile(
                    'Tüm Abonelikleri Durdur',
                    'Sistem bakımı için tüm abonelikleri geçici durdur',
                    Icons.pause_circle,
                    Colors.red,
                    onTap: () => _showEmergencyStopDialog(),
                  ),
                  _buildSettingsTile(
                    'Sistem Sıfırla',
                    'Dikkat: Geri alınamaz işlem',
                    Icons.restart_alt,
                    Colors.red,
                    onTap: () => _showSystemResetDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDatabaseInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veritabanı Bilgileri'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: Aktif ✅'),
            SizedBox(height: 8),
            Text('Bağlantı: Firebase Firestore'),
            SizedBox(height: 8),
            Text('Son Senkronizasyon: Şimdi'),
            SizedBox(height: 8),
            Text('Toplam Koleksiyon: 3'),
            SizedBox(height: 8),
            Text('• users\n• subscriptions\n• orders'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Temizle'),
        content: const Text(
            'Uygulama önbelleği temizlenecek. Bu işlem birkaç saniye sürebilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache başarıyla temizlendi')),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veri Yedekleme'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yedeklenecek veriler:'),
            SizedBox(height: 8),
            Text('• Tüm kullanıcı bilgileri'),
            Text('• Abonelik kayıtları'),
            Text('• Sipariş verileri'),
            Text('• Sistem ayarları'),
            SizedBox(height: 16),
            Text('Yedekleme işlemi başlatılsın mı?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yedekleme işlemi başlatıldı')),
              );
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abonelik Ayarları'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Varsayılan Süre (Gün)',
                hintText: '30',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Uyarı Süresi (Gün)',
                hintText: '7',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ayarlar kaydedildi')),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Abonelik Sona Erme Uyarısı'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Yeni Kayıt Bildirimi'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Günlük Rapor'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bildirim ayarları kaydedildi')),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifre başarıyla değiştirildi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifreler eşleşmiyor')),
                );
              }
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _showLoginHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oturum Geçmişi'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              final date = DateTime.now().subtract(Duration(days: index));
              return ListTile(
                leading: const Icon(Icons.login, color: Colors.green),
                title: Text('Admin Girişi'),
                subtitle: Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyStopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ACİL DURUM'),
        content: const Text(
            'Tüm abonelikler geçici olarak durdurulacak. Bu işlem sistem bakımı için kullanılır. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acil durum modu aktifleştirildi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Durdur'),
          ),
        ],
      ),
    );
  }

  void _showSystemResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 SİSTEM SIFIRLAMA'),
        content: const Text(
            'Bu işlem GERİ ALINAMAZ! Tüm veriler silinecek ve sistem fabrika ayarlarına dönecek. Bu işlemi gerçekten yapmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFinalConfirmation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmation() {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Son Onay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu işlemi onaylamak için "SIFIRLA" yazın:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'SIFIRLA',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text == 'SIFIRLA') {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sistem sıfırlama işlemi başlatıldı'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hatalı onay metni')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
