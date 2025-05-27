import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/providers/order_provider.dart';
import 'package:siparis/screens/home/home_screen.dart';
import 'package:siparis/screens/splash_screen.dart';
import 'package:siparis/screens/budget_screen.dart';
import 'package:siparis/providers/stock_provider.dart';
import 'package:siparis/providers/company_provider.dart';
import 'package:siparis/customer/screens/customer_home_screen.dart';
import 'package:siparis/providers/cart_provider.dart';
import 'package:siparis/customer/screens/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Sipariş Takip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/customer',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
            case '/customer':
              return MaterialPageRoute(
                builder: (_) => const CustomerHomeScreen(),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
            case '/cart':
              return MaterialPageRoute(
                builder: (_) => const CartScreen(),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const CustomerHomeScreen(),
              );
          }
        },
      ),
    );
  }
}
