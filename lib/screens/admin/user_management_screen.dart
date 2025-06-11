import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../models/subscription.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'Tümü';

  @override
  void initState() {
    super.initState();
    
    // Admin kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
    
    _loadAllUsers();
  }

  // Admin erişim kontrolü
  void _checkAdminAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || !authProvider.currentUser!.isAdmin) {
      print('❌ Admin olmayan kullanıcı user management\'e erişmeye çalışıyor');
      
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

  // Güvenli tarih dönüştürme helper metodu
  DateTime? _safeToDate(dynamic dateValue) {
    try {
      if (dateValue == null) return null;

      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }
    } catch (e) {
      print('⚠️ Tarih dönüştürme hatası: $e');
    }
    return null;
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);

    try {
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
    List<Map<String, dynamic>> filtered = _allUsers;

    // Rol filtresi
    if (_selectedRole != 'Tümü') {
      filtered = filtered.where((item) {
        final user = item['user'] as UserModel;
        return user.role == _selectedRole.toLowerCase();
      }).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final user = item['user'] as UserModel;
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Responsive değerler
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth > 768;
    final padding = isMobile ? 12.0 : 16.0;
    final fontSize = isMobile ? 18.0 : 20.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kullanıcı Yönetimi',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
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
          // Arama ve filtre
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Arama çubuğu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: isMobile ? 12 : 16),
                
                // Filtre dropdown - responsive
                isMobile
                    ? SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Rol Filtresi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: ['Tümü', 'Producer', 'Customer', 'Admin']
                              .map((filter) => DropdownMenuItem(
                                    value: filter,
                                    child: Text(filter),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            'Rol Filtresi:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              items: ['Tümü', 'Producer', 'Customer', 'Admin']
                                  .map((filter) => DropdownMenuItem(
                                        value: filter,
                                        child: Text(filter),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          
          // Kullanıcı listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: isMobile ? 60 : 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'Kullanıcı bulunamadı',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(padding),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final userItem = _filteredUsers[index];
                          final user = userItem['user'] as UserModel;
                          final subscription = userItem['subscription'] as Subscription?;
                          
                          return _buildUserCard(user, subscription, isMobile);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, Subscription? subscription, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Icon(
            _getRoleIcon(user.role),
            color: Colors.white,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleName(user.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (subscription != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: subscription.isValid ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subscription.isValid ? 'Aktif' : 'Pasif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showUserDetails(user, subscription),
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'producer':
        return Colors.green;
      case 'customer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'producer':
        return Icons.business;
      case 'customer':
        return Icons.shopping_cart;
      default:
        return Icons.person;
    }
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'producer':
        return 'Üretici';
      case 'customer':
        return 'Müşteri';
      default:
        return 'Bilinmiyor';
    }
  }

  void _showUserDetails(UserModel user, Subscription? subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name} - Kullanıcı Detayları'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Ad Soyad', user.name),
              _buildDetailRow('E-mail', user.email),
              _buildDetailRow('Rol', _getRoleName(user.role)),
              _buildDetailRow('Telefon', user.phone ?? 'Belirtilmemiş'),
              if (user.role == 'producer') ...[
                const Divider(),
                const Text('Şirket Bilgileri:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDetailRow(
                    'Şirket Adı', user.companyName ?? 'Belirtilmemiş'),
              ],
              if (subscription != null) ...[
                const Divider(),
                const Text('Abonelik Bilgileri:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDetailRow(
                    'Durum', subscription.isValid ? 'Aktif' : 'Pasif'),
                if (subscription.isValid)
                  _buildDetailRow(
                      'Kalan Süre', '${subscription.remainingDays} gün'),
                if (subscription.endDate != null)
                  _buildDetailRow(
                      'Bitiş Tarihi', _formatDate(subscription.endDate!)),
              ],
              const Divider(),
              _buildDetailRow('Kayıt Tarihi', _formatDate(user.createdAt)),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
