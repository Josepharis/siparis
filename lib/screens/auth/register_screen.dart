import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:siparis/customer/screens/customer_home_screen.dart';
import 'package:siparis/screens/home/home_screen.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/auth_provider.dart';

enum UserRole { producer, customer }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Seçilen role göre string değer belirle
      String roleString =
          _selectedRole == UserRole.producer ? 'producer' : 'customer';

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        companyName: _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : null,
        companyAddress: _companyAddressController.text.trim().isNotEmpty
            ? _companyAddressController.text.trim()
            : null,
        role: roleString,
      );

      if (success && mounted) {
        final user = authProvider.currentUser;

        if (user != null) {
          if (user.isProducer) {
            // Üretici ise screens/home/home_screen.dart'a git
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          } else {
            // Müşteri ise customer/screens/customer_home_screen.dart'a git
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const CustomerHomeScreen(),
              ),
            );
          }
        }
      } else if (mounted) {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Kayıt başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kullanım şartlarını kabul etmelisiniz',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 48.0 : 24.0;
    final formPadding = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              const Color(0xFF0D47A1).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Geri butonu ve başlık
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: isSmallScreen ? 8.0 : 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 16),
                    Text(
                      'Kayıt Ol',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              const Color(0xFF0D47A1),
                            ],
                          ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                          ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: isSmallScreen ? 8.0 : 12.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Alt başlık - Kompakt
                        Text(
                          'Firma bilgilerinizle kayıt olun',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 15,
                            color: const Color(0xFF666666),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Rol seçimi
                        Container(
                          padding: EdgeInsets.all(formPadding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 2,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    color: AppTheme.primaryColor,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  Text(
                                    'Giriş Türü',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleOption(
                                      role: UserRole.producer,
                                      icon: Icons.factory,
                                      label: 'Üretici',
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  Expanded(
                                    child: _buildRoleOption(
                                      role: UserRole.customer,
                                      icon: Icons.store,
                                      label: 'Müşteri',
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Kayıt formu
                        Container(
                          padding: EdgeInsets.all(formPadding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 2,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Firma Bilgileri',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                _buildResponsiveInputField(
                                  controller: _companyNameController,
                                  label: 'Firma Adı',
                                  hint: 'Firma adınızı girin',
                                  icon: Icons.business,
                                  isSmallScreen: isSmallScreen,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Firma adı gerekli';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildResponsiveInputField(
                                  controller: _nameController,
                                  label: 'Yetkili Kişi Ad Soyad',
                                  hint: 'Yetkili kişinin adını girin',
                                  icon: Icons.person_outlined,
                                  isSmallScreen: isSmallScreen,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Yetkili kişi adı gerekli';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildResponsiveInputField(
                                  controller: _phoneController,
                                  label: 'Telefon Numarası',
                                  hint: '0555 123 45 67',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  isSmallScreen: isSmallScreen,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Telefon numarası gerekli';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildResponsiveInputField(
                                  controller: _companyAddressController,
                                  label: 'Firma Adresi',
                                  hint: 'Firmanızın tam adresini girin',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                  isSmallScreen: isSmallScreen,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Firma adresi gerekli';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildResponsiveInputField(
                                  controller: _emailController,
                                  label: 'E-posta',
                                  hint: 'ornek@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  isSmallScreen: isSmallScreen,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'E-posta adresi gerekli';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Geçerli bir e-posta adresi girin';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildResponsiveInputField(
                                  controller: _passwordController,
                                  label: 'Şifre',
                                  hint: '••••••',
                                  icon: Icons.lock_outline,
                                  obscureText: !_isPasswordVisible,
                                  isSmallScreen: isSmallScreen,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTheme.primaryColor,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Şifre gerekli';
                                    }
                                    if (value.length < 6) {
                                      return 'Şifre en az 6 karakter olmalı';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildResponsiveInputField(
                                  controller: _confirmPasswordController,
                                  label: 'Şifre Tekrar',
                                  hint: '••••••',
                                  icon: Icons.lock_outline,
                                  obscureText: !_isConfirmPasswordVisible,
                                  isSmallScreen: isSmallScreen,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTheme.primaryColor,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Şifre tekrarı gerekli';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Şifreler eşleşmiyor';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Kullanım şartları
                        Container(
                          padding: EdgeInsets.all(formPadding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: isSmallScreen ? 0.9 : 1.0,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Kullanım şartlarını ve gizlilik politikasını kabul ediyorum',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: const Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 20 : 24),

                        // Kayıt ol butonu
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Container(
                              width: double.infinity,
                              height: isSmallScreen ? 48 : 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryColor,
                                    const Color(0xFF0D47A1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    authProvider.isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        width: isSmallScreen ? 20 : 24,
                                        height: isSmallScreen ? 20 : 24,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Kayıt Ol',
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Giriş yap linki
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Zaten hesabınız var mı? ',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    const Color(0xFF0D47A1),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'Giriş Yap',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required IconData icon,
    required String label,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedRole == role
              ? AppTheme.primaryColor
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        color: _selectedRole == role
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  _selectedRole == role ? AppTheme.primaryColor : Colors.grey,
              size: isSmallScreen ? 16 : 20,
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: _selectedRole == role
                    ? AppTheme.primaryColor
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isSmallScreen = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: isSmallScreen ? 14 : 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: isSmallScreen ? 20 : 24,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
          labelStyle: GoogleFonts.poppins(
            color: const Color(0xFF666666),
            fontSize: isSmallScreen ? 12 : 14,
          ),
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF999999),
            fontSize: isSmallScreen ? 12 : 14,
          ),
          errorStyle: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.red.shade600,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 12 : 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
