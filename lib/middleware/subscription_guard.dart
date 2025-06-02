import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';

class SubscriptionGuard extends StatelessWidget {
  final Widget child;
  final Widget? noSubscriptionWidget;

  const SubscriptionGuard({
    Key? key,
    required this.child,
    this.noSubscriptionWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, AuthProvider>(
      builder: (context, subscriptionProvider, authProvider, _) {
        // Admin rolü varsa kontrol yapma
        if (authProvider.currentUser?.role == 'admin') {
          return child;
        }

        // ÜRETİCİ rolü varsa kontrol yapma - üreticiler her zaman erişebilir
        if (authProvider.currentUser?.role == 'producer') {
          return child;
        }

        // Çalışan girişi kontrolü
        if (authProvider.isEmployeeLogin &&
            authProvider.currentEmployee != null) {
          final employee = authProvider.currentEmployee!;

          // Çalışanın bağlı olduğu firma var mı?
          if (employee.companyId.isNotEmpty) {
            // Firma abonelik kontrolü yap
            return FutureBuilder<void>(
              future: subscriptionProvider
                  .loadCompanySubscription(employee.companyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Firma aboneliği var mı kontrol et
                if (subscriptionProvider.hasActiveSubscription) {
                  return child;
                } else {
                  return noSubscriptionWidget ??
                      NoSubscriptionScreen(
                        isEmployee: true,
                        companyName: employee.companyId,
                      );
                }
              },
            );
          } else {
            // Çalışan firma bağlantısı yoksa erişim engelle
            return noSubscriptionWidget ??
                NoSubscriptionScreen(
                  isEmployee: true,
                  companyName: "Bağlı firma bulunamadı",
                );
          }
        }

        // MÜŞTERİ girişi kontrolü - sadece müşteriler abonelik kontrolüne tabi
        if (authProvider.currentUser != null) {
          // Sadece customer rolü için abonelik kontrolü yap
          if (authProvider.currentUser?.role == 'customer') {
            if (!subscriptionProvider.hasActiveSubscription) {
              return noSubscriptionWidget ?? const NoSubscriptionScreen();
            }
          }
        }

        return child;
      },
    );
  }
}

class NoSubscriptionScreen extends StatelessWidget {
  final bool isEmployee;
  final String? companyName;

  const NoSubscriptionScreen({
    Key? key,
    this.isEmployee = false,
    this.companyName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEmployee ? Icons.business : Icons.payment,
                  size: 60,
                  color: Colors.orange[700],
                ),
              ),

              const SizedBox(height: 32),

              // Başlık
              Text(
                isEmployee ? 'Firma Aboneliği Gerekli' : 'Abonelik Gerekli',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Açıklama
              Text(
                isEmployee
                    ? 'Bu özelliği kullanabilmek için bağlı olduğunuz firmanın aktif aboneliği olması gerekmektedir.'
                    : 'Bu özelliği kullanabilmek için aktif bir aboneliğiniz olması gerekmektedir.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                isEmployee
                    ? 'Lütfen firma sahibinizle iletişime geçin veya başka bir hesapla giriş yapmayı deneyin.'
                    : 'Abonelik satın almak için bizimle iletişime geçin veya başka bir hesapla giriş yapmayı deneyin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),

              if (isEmployee && companyName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'Bağlı Firma: $companyName',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // İletişim Butonu (sadece firma sahipleri için)
              if (!isEmployee)
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // İletişim bilgilerini göster
                      _showContactDialog(context);
                    },
                    icon: const Icon(Icons.phone, size: 20),
                    label: const Text(
                      'İletişime Geç',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),

              if (!isEmployee) const SizedBox(height: 16),

              // Çıkış Yap Butonu - İyileştirilmiş görsel
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    side: BorderSide(
                      color: Colors.red[700]!,
                      width: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    // Çıkış onay dialog'u göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
            'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // AuthProvider'dan çıkış yap
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // Ana sayfaya yönlendir
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.contact_phone, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('İletişim Bilgileri'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abonelik satın almak için bizimle iletişime geçin:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 24, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telefon',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '0538 890 40 81',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, size: 24, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E-mail',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'yftsoftware@gmail.com',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
