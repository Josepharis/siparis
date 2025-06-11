import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/subscription.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
    
    // Admin kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }

  // Admin erişim kontrolü
  void _checkAdminAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || !authProvider.currentUser!.isAdmin) {
      print('❌ Admin olmayan kullanıcı subscription management\'e erişmeye çalışıyor');
      
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

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);

    try {
      // Tüm kullanıcıları getir
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> users = [];

      for (var userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(userData, userDoc.id);

          // Kullanıcının abonelik durumunu kontrol et
          final QuerySnapshot subscriptionSnapshot = await FirebaseFirestore
              .instance
              .collection('subscriptions')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          Subscription? subscription;
          if (subscriptionSnapshot.docs.isNotEmpty) {
            try {
              final subDoc = subscriptionSnapshot.docs.first;
              subscription = Subscription.fromMap(
                subDoc.data() as Map<String, dynamic>,
                subDoc.id,
              );
            } catch (e) {
              print('⚠️ Abonelik parsing hatası: $e');
            }
          }

          users.add({
            'user': user,
            'subscription': subscription,
          });
        } catch (e) {
          print('⚠️ Kullanıcı parsing hatası: $e');
          // Hatalı kullanıcıları atla, devam et
        }
      }

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Kullanıcıları yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcılar yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;

    return _allUsers.where((item) {
      final user = item['user'] as UserModel;
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelik Yönetimi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAllUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Bilgilendirme Banner'ı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ÜRETİCİLER abonelik gerektirmez, her zaman erişim hakkına sahiptir. Sadece MÜŞTERİLER abonelik alır.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // İstatistik kartları
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Kullanıcı',
                    _allUsers.length.toString(),
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Müşteri (Abonelik)',
                    _allUsers
                        .where((item) =>
                            (item['user'] as UserModel).role == 'customer')
                        .length
                        .toString(),
                    Colors.orange,
                    Icons.shopping_cart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Üretici (Serbest)',
                    _allUsers
                        .where((item) =>
                            (item['user'] as UserModel).role == 'producer')
                        .length
                        .toString(),
                    Colors.green,
                    Icons.business,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktif Abonelik',
                    _allUsers
                        .where((item) {
                          final user = item['user'] as UserModel;
                          final subscription =
                              item['subscription'] as Subscription?;
                          return user.role == 'customer' &&
                              subscription != null &&
                              subscription.isValid;
                        })
                        .length
                        .toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),

          // Kullanıcı listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Kullanıcı bulunamadı',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final item = _filteredUsers[index];
                            final user = item['user'] as UserModel;
                            final subscription =
                                item['subscription'] as Subscription?;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user.role == 'producer'
                                      ? Colors.green[100]
                                      : subscription?.isValid == true
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                  child: user.role == 'producer'
                                      ? Icon(Icons.business,
                                          color: Colors.green[700])
                                      : subscription?.isValid == true
                                          ? Icon(Icons.check,
                                              color: Colors.green[700])
                                          : Icon(Icons.close,
                                              color: Colors.red[700]),
                                ),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.role == 'producer'
                                          ? 'Üretici • Abonelik Gerektirmez'
                                          : subscription?.isValid == true
                                              ? 'Aktif • ${subscription!.remainingDays} gün kaldı'
                                              : 'Abonelik Yok',
                                      style: TextStyle(
                                        color: user.role == 'producer'
                                            ? Colors.green[700]
                                            : subscription?.isValid == true
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'activate':
                                        _showActivateDialog(
                                            user.uid, user.name);
                                        break;
                                      case 'deactivate':
                                        if (subscription != null) {
                                          _showDeactivateDialog(
                                              user.uid, user.name);
                                        }
                                        break;
                                      case 'details':
                                        if (subscription != null) {
                                          _showDetailsDialog(subscription,
                                              user.name, user.email);
                                        }
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    // Üreticiler için abonelik işlemleri gösterilmez
                                    if (user.role != 'producer') ...[
                                      const PopupMenuItem(
                                        value: 'activate',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Aktifleştir'),
                                          ],
                                        ),
                                      ),
                                      if (subscription != null)
                                        const PopupMenuItem(
                                          value: 'deactivate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel,
                                                  color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Pasifleştir'),
                                            ],
                                          ),
                                        ),
                                      if (subscription != null)
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: Row(
                                            children: [
                                              Icon(Icons.info,
                                                  color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Detaylar'),
                                            ],
                                          ),
                                        ),
                                    ] else ...[
                                      // Üreticiler için sadece bilgi menüsü
                                      PopupMenuItem(
                                        enabled: false,
                                        child: Row(
                                          children: [
                                            Icon(Icons.info,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 8),
                                            Text('Abonelik gerektirmez',
                                                style: TextStyle(
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAddDialog,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Hızlı Abonelik Ekle',
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog() {
    if (_allUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz kullanıcı bulunamadı')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hızlı Abonelik Ekle'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final item = _allUsers[index];
              final user = item['user'] as UserModel;
              final subscription = item['subscription'] as Subscription?;

              // Zaten aktif aboneliği olanları filtrele
              if (subscription?.isValid == true) return Container();

              // Üreticileri filtrele - onlar abonelik gerektirmez
              if (user.role == 'producer') return Container();

              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Navigator.of(context).pop();
                  _showActivateDialog(user.uid, user.name);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(String userId, String userName) {
    final TextEditingController daysController =
        TextEditingController(text: '30');
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$userName - Abonelik Aktifleştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Süre (Gün)',
                hintText: 'Örn: 30',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Not (Opsiyonel)',
                hintText: 'Ödeme bilgileri, vb.',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final days = int.tryParse(daysController.text) ?? 30;
              final now = DateTime.now();
              final endDate = now.add(Duration(days: days));

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUser;

              final subscriptionProvider =
                  Provider.of<SubscriptionProvider>(context, listen: false);

              final success =
                  await subscriptionProvider.createOrUpdateSubscription(
                userId: userId,
                isActive: true,
                startDate: now,
                endDate: endDate,
                notes:
                    notesController.text.isEmpty ? null : notesController.text,
                activatedBy: currentUser?.name ?? 'Admin',
              );

              if (success) {
                Navigator.of(context).pop();
                _loadAllUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Abonelik başarıyla aktifleştirildi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hata oluştu')),
                );
              }
            },
            child: const Text('Aktifleştir'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(String userId, String userName) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$userName - Abonelik İptal Et'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'İptal Nedeni',
            hintText: 'Ödeme yapılmadı, talep üzerine, vb.',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUser;

              final subscriptionProvider =
                  Provider.of<SubscriptionProvider>(context, listen: false);

              final success = await subscriptionProvider.cancelSubscription(
                userId,
                currentUser?.name ?? 'Admin',
                reasonController.text,
              );

              if (success) {
                Navigator.of(context).pop();
                _loadAllUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Abonelik başarıyla iptal edildi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hata oluştu')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(
      Subscription subscription, String userName, String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$userName - Abonelik Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('E-mail', userEmail),
            _buildDetailRow('Durum', subscription.isValid ? 'Aktif' : 'Pasif'),
            if (subscription.startDate != null)
              _buildDetailRow(
                  'Başlangıç', _formatDate(subscription.startDate!)),
            if (subscription.endDate != null)
              _buildDetailRow('Bitiş', _formatDate(subscription.endDate!)),
            if (subscription.isValid)
              _buildDetailRow(
                  'Kalan Süre', '${subscription.remainingDays} gün'),
            if (subscription.notes != null && subscription.notes!.isNotEmpty)
              _buildDetailRow('Not', subscription.notes!),
            if (subscription.activatedBy != null)
              _buildDetailRow('Aktifleştiren', subscription.activatedBy!),
            _buildDetailRow('Oluşturulma', _formatDate(subscription.createdAt)),
            if (subscription.updatedAt != null)
              _buildDetailRow(
                  'Güncellenme', _formatDate(subscription.updatedAt!)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
