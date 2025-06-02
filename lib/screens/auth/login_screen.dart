import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:siparis/screens/auth/register_screen.dart';
import 'package:siparis/customer/screens/customer_home_screen.dart';
import 'package:siparis/screens/home/home_screen.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/providers/auth_provider.dart';

enum UserRole { producer, customer }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // E-posta adresine göre otomatik giriş (çalışan vs sahip kontrolü AuthProvider'da)
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Giriş başarılı - kullanıcı tipine göre yönlendir
        if (authProvider.isEmployeeLogin) {
          // Çalışan girişi - HomeScreen'e git
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          // Normal kullanıcı girişi
          final user = authProvider.currentUser;
          if (user != null) {
            if (user.isProducer) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const CustomerHomeScreen(),
                ),
              );
            }
          }
        }
      } else if (mounted) {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Giriş başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen e-posta adresinizi girin',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success =
        await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Şifre sıfırlama e-postası gönderildi',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Şifre sıfırlama e-postası gönderilemedi',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildRoleSelector() {
    // Responsive boyutlar
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: isSmallScreen ? 6 : 10,
            offset: Offset(0, isSmallScreen ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppTheme.primaryColor,
                  size: isSmallScreen ? 18 : 20,
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
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: isSmallScreen ? 4.0 : 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 12),
                      border: Border.all(
                        color: _selectedRole == UserRole.producer
                            ? AppTheme.primaryColor
                            : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                      color: _selectedRole == UserRole.producer
                          ? AppTheme.primaryColor.withOpacity(0.1)
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
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.factory,
                                color: _selectedRole == UserRole.producer
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                size: isSmallScreen ? 16 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Flexible(
                                child: Text(
                                  'Üretici',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedRole == UserRole.producer
                                        ? AppTheme.primaryColor
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      activeColor: AppTheme.primaryColor,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4 : 8),
                      dense: isSmallScreen,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 12),
                      border: Border.all(
                        color: _selectedRole == UserRole.customer
                            ? AppTheme.primaryColor
                            : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                      color: _selectedRole == UserRole.customer
                          ? AppTheme.primaryColor.withOpacity(0.1)
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
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: _selectedRole == UserRole.customer
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                size: isSmallScreen ? 16 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Flexible(
                                child: Text(
                                  'Müşteri',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedRole == UserRole.customer
                                        ? AppTheme.primaryColor
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      activeColor: AppTheme.primaryColor,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4 : 8),
                      dense: isSmallScreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;
    final padding = isSmallScreen ? 16.0 : (isTablet ? 48.0 : 24.0);

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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height:
                            isVerySmallScreen ? 10 : (isSmallScreen ? 20 : 40)),

                    // Logo ve başlık
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: isVerySmallScreen
                                ? 60
                                : (isSmallScreen ? 70 : 100),
                          ),
                          SizedBox(
                              height: isVerySmallScreen
                                  ? 12
                                  : (isSmallScreen ? 16 : 24)),
                          Text(
                            'Hoş Geldiniz',
                            style: GoogleFonts.poppins(
                              fontSize: isVerySmallScreen
                                  ? 20
                                  : (isSmallScreen ? 24 : 32),
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
                          SizedBox(
                              height: isVerySmallScreen
                                  ? 4
                                  : (isSmallScreen ? 8 : 12)),
                          Text(
                            'Hesabınıza giriş yapın',
                            style: GoogleFonts.poppins(
                              fontSize: isVerySmallScreen
                                  ? 12
                                  : (isSmallScreen ? 14 : 16),
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                        height:
                            isVerySmallScreen ? 20 : (isSmallScreen ? 32 : 48)),

                    // Rol seçimi
                    _buildRoleSelector(),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Giriş formu
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // E-posta alanı
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 12 : 16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: isSmallScreen ? 6 : 10,
                                  offset: Offset(0, isSmallScreen ? 2 : 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                hintText: 'ornek@email.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryColor,
                                  size: isSmallScreen ? 18 : 24,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF666666),
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
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
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 20),

                          // Şifre alanı
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 12 : 16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: isSmallScreen ? 6 : 10,
                                  offset: Offset(0, isSmallScreen ? 2 : 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                hintText: '••••••',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.primaryColor,
                                  size: isSmallScreen ? 18 : 24,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.primaryColor,
                                    size: isSmallScreen ? 18 : 24,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF666666),
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
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
                          ),

                          SizedBox(height: isSmallScreen ? 12 : 16),

                          // Şifremi unuttum
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                'Şifremi Unuttum',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 11 : 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Giriş butonu
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Container(
                                width: double.infinity,
                                height: isSmallScreen ? 44 : 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor,
                                      const Color(0xFF0D47A1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: isSmallScreen ? 8 : 15,
                                      offset: Offset(0, isSmallScreen ? 4 : 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      authProvider.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 12 : 16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authProvider.isLoading
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
                                          'Giriş Yap',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 32),

                          // Ayırıcı - Telefonda daha kompakt
                          if (!isVerySmallScreen) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16),
                                  child: Text(
                                    'veya',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF666666),
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isSmallScreen ? 20 : 32),

                            // Google ile giriş - Telefonda daha kompakt
                            Container(
                              width: double.infinity,
                              height: isSmallScreen ? 44 : 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 16),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: isSmallScreen ? 6 : 10,
                                    offset: Offset(0, isSmallScreen ? 2 : 4),
                                  ),
                                ],
                              ),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Google ile giriş işlemi
                                },
                                icon: Container(
                                  width: isSmallScreen ? 20 : 24,
                                  height: isSmallScreen ? 20 : 24,
                                  decoration: BoxDecoration(
                                    color: Colors.red[600],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.white,
                                    size: isSmallScreen ? 16 : 20,
                                  ),
                                ),
                                label: Text(
                                  'Google ile Giriş Yap',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 13 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 12 : 16),
                                  ),
                                  side: BorderSide.none,
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 20 : 32),
                          ],

                          // Kayıt ol linki
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hesabınız yok mu? ',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      const Color(0xFF0D47A1),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Kayıt Ol',
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
                          SizedBox(height: isSmallScreen ? 16 : 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
