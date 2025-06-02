import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/providers/auth_provider.dart';
import 'package:siparis/providers/subscription_provider.dart';
import 'package:siparis/screens/home/home_screen.dart';
import 'package:siparis/screens/splash_screen.dart';
import 'package:siparis/screens/budget_screen.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/providers/company_provider.dart';
import 'package:siparis/providers/work_request_provider.dart';
import 'package:siparis/customer/screens/customer_home_screen.dart';
import 'package:siparis/providers/cart_provider.dart';
import 'package:siparis/customer/screens/cart_screen.dart';
import 'package:siparis/providers/employee_provider.dart';
import 'package:siparis/screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sistem UI ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Ekran yönlendirmesi
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Text rendering optimizasyonları
  assert(() {
    // Debug modda text rendering sorunlarını minimize et
    return true;
  }());

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Global lifecycle observer'ı ekle
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Global lifecycle observer'ı temizle
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('🌟 Global - Uygulama ön plana geldi');
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        print('⏸️ Global - Uygulama arka plana gitti');
        _handleAppPause();
        break;
      case AppLifecycleState.detached:
        print('🚪 Global - Uygulama kapatıldı');
        break;
      case AppLifecycleState.inactive:
        print('💤 Global - Uygulama inactive durumda');
        break;
      case AppLifecycleState.hidden:
        print('🫥 Global - Uygulama gizlendi');
        break;
    }
  }

  void _handleAppResume() {
    // Uygulamanın ön plana gelmesi durumunda
    try {
      // Text rendering problemlerini çözmek için sistem UI'ını yenile
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      // Ekran yönlendirmesini yeniden ayarla
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      print('❌ Global UI yenileme hatası: $e');
    }
  }

  void _handleAppPause() {
    // Uygulamanın arka plana gitmesi durumunda
    // Gerekirse memory cleanup yapılabilir
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, authProvider, orderProvider) {
            orderProvider!.setCurrentUser(authProvider.currentUser);
            return orderProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, authProvider, subscriptionProvider) {
            // Kullanıcı değiştiğinde abonelik durumunu yükle
            if (authProvider.currentUser != null) {
              // Normal kullanıcı abonelik kontrolü
              subscriptionProvider!
                  .loadUserSubscription(authProvider.currentUser!.uid);
            } else if (authProvider.currentEmployee != null &&
                authProvider.currentEmployee!.companyId.isNotEmpty) {
              // Çalışan için firma abonelik kontrolü
              subscriptionProvider!.loadCompanySubscription(
                  authProvider.currentEmployee!.companyId);
            } else {
              subscriptionProvider!.clearSubscription();
            }
            return subscriptionProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => WorkRequestProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: MaterialApp(
        title: 'Sipariş Takip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
        ],
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const SplashScreen(),
              );
            case '/customer':
              return MaterialPageRoute(
                builder: (_) => const CustomerHomeScreen(),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
            case '/admin':
              return MaterialPageRoute(
                builder: (_) => const AdminHomeScreen(),
              );
            case '/cart':
              return MaterialPageRoute(
                builder: (_) => const CartScreen(),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const SplashScreen(),
              );
          }
        },
      ),
    );
  }
}
