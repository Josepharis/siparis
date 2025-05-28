import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siparis/customer/screens/customer_home_screen.dart';
import 'package:siparis/config/theme.dart';

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
  bool _isLoading = false;
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
      setState(() {
        _isLoading = true;
      });

      // Simüle edilmiş kayıt işlemi
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // Ana ekrana yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CustomerHomeScreen(),
          ),
        );
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kullanım şartlarını kabul etmelisiniz'),
          backgroundColor: Colors.red.shade400,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;

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
              // AppBar - Kompakt
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    // Başlığı AppBar'a taşı
                    Expanded(
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              const Color(0xFF0D47A1),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Hesap Oluştur',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Boş alan (simetri için)
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 20.0,
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

                        // Rol seçimi - Responsive
                        Container(
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
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      color: AppTheme.primaryColor,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Text(
                                      'Firma Türü',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedRole ==
                                                    UserRole.producer
                                                ? AppTheme.primaryColor
                                                : Colors.grey.withOpacity(0.3),
                                            width: 2,
                                          ),
                                          color:
                                              _selectedRole == UserRole.producer
                                                  ? AppTheme.primaryColor
                                                      .withOpacity(0.1)
                                                  : Colors.transparent,
                                        ),
                                        child: RadioListTile<UserRole>(
                                          value: UserRole.producer,
                                          groupValue: _selectedRole,
                                          onChanged: (UserRole? value) {
                                            setState(() {
                                              _selectedRole = value!;
                                            });
                                          },
                                          title: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.factory,
                                                color: _selectedRole ==
                                                        UserRole.producer
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey,
                                                size: isSmallScreen ? 16 : 20,
                                              ),
                                              SizedBox(
                                                  width: isSmallScreen ? 4 : 8),
                                              Flexible(
                                                child: Text(
                                                  'Üretici',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isSmallScreen ? 12 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _selectedRole ==
                                                            UserRole.producer
                                                        ? AppTheme.primaryColor
                                                        : const Color(
                                                            0xFF1A1A1A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          activeColor: AppTheme.primaryColor,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedRole ==
                                                    UserRole.customer
                                                ? AppTheme.primaryColor
                                                : Colors.grey.withOpacity(0.3),
                                            width: 2,
                                          ),
                                          color:
                                              _selectedRole == UserRole.customer
                                                  ? AppTheme.primaryColor
                                                      .withOpacity(0.1)
                                                  : Colors.transparent,
                                        ),
                                        child: RadioListTile<UserRole>(
                                          value: UserRole.customer,
                                          groupValue: _selectedRole,
                                          onChanged: (UserRole? value) {
                                            setState(() {
                                              _selectedRole = value!;
                                            });
                                          },
                                          title: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.store,
                                                color: _selectedRole ==
                                                        UserRole.customer
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey,
                                                size: isSmallScreen ? 16 : 20,
                                              ),
                                              SizedBox(
                                                  width: isSmallScreen ? 4 : 8),
                                              Flexible(
                                                child: Text(
                                                  'Müşteri',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isSmallScreen ? 12 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _selectedRole ==
                                                            UserRole.customer
                                                        ? AppTheme.primaryColor
                                                        : const Color(
                                                            0xFF1A1A1A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          activeColor: AppTheme.primaryColor,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Kayıt formu - Responsive
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Firma Adı
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

                              // Yetkili Kişi
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

                              // Telefon
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

                              // E-posta
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

                              // Firma Adresi
                              _buildResponsiveInputField(
                                controller: _companyAddressController,
                                label: 'Firma Adresi',
                                hint: 'Firma adresinizi girin',
                                icon: Icons.location_on_outlined,
                                maxLines: isSmallScreen ? 2 : 3,
                                isSmallScreen: isSmallScreen,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Firma adresi gerekli';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: isSmallScreen ? 12 : 16),

                              // Şifre
                              _buildResponsiveInputField(
                                controller: _passwordController,
                                label: 'Şifre',
                                hint: 'Şifrenizi girin',
                                icon: Icons.lock_outlined,
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
                                      _isPasswordVisible = !_isPasswordVisible;
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

                              // Şifre Tekrar
                              _buildResponsiveInputField(
                                controller: _confirmPasswordController,
                                label: 'Şifre Tekrar',
                                hint: 'Şifrenizi tekrar girin',
                                icon: Icons.lock_outlined,
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

                              SizedBox(height: isSmallScreen ? 16 : 20),

                              // Kullanım şartları checkbox - Responsive
                              Container(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                                    Checkbox(
                                      value: _acceptTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _acceptTerms = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            color: const Color(0xFF666666),
                                          ),
                                          children: [
                                            const TextSpan(
                                                text: 'Kabul ediyorum '),
                                            TextSpan(
                                              text: 'Kullanım Şartları',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const TextSpan(text: ' ve '),
                                            TextSpan(
                                              text: 'Gizlilik Politikası',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 16 : 20),

                              // Kayıt ol butonu - Responsive
                              Container(
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
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: isSmallScreen ? 20 : 24,
                                          height: isSmallScreen ? 20 : 24,
                                          child:
                                              const CircularProgressIndicator(
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
                              ),

                              SizedBox(height: isSmallScreen ? 16 : 20),

                              // Giriş yap linki - Responsive
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
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
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
                            ],
                          ),
                        ),
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
