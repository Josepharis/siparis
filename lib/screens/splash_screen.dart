import 'package:flutter/material.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Ana ekrana geçiş için zamanlayıcı
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(skipLoading: false),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.9),
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Arkaplan partikül efektleri
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 20,
              child: _buildGlowingCircle(40, Colors.white.withOpacity(0.1)),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              right: 40,
              child: _buildGlowingCircle(60, Colors.white.withOpacity(0.08)),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2,
              left: 50,
              child: _buildGlowingCircle(80, Colors.white.withOpacity(0.06)),
            ),

            // Ana içerik
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Stack(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 90,
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.4),
                                      ),
                                      Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 80,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Uygulama adı
                              ShaderMask(
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                child: const Text(
                                  'SİPARİŞ TAKİP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Alt başlık
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Text(
                                  'Pastane ve Fırın Yönetimi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 60),

                              // Yükleniyor indikatörü
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.9),
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Animation.fromValueListenable(
                        _controller,
                        transformer:
                            (value) => value > 0.6 ? (value - 0.6) * 2.5 : 0,
                      ),
                      child: const Text(
                        'v1.0.0',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: size / 2,
            spreadRadius: size / 10,
          ),
        ],
      ),
    );
  }
}
