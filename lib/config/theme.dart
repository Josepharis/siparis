import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tema renkleri - daha modern renkler
  static const Color primaryColor = Color(0xFF7B61FF); // Mor tonu
  static const Color accentColor = Color(0xFFFF7F50); // Turuncu tonu
  static const Color backgroundColor = Color(0xFFF9FAFC);
  static const Color cardColor = Colors.white;
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color errorColor = Color(0xFFE53935);
  static const Color waitingColor = Color(0xFFEFEAFF); // Mor ton uyumlu
  static const Color processingColor = Color(0xFFFFF1EB); // Turuncu ton uyumlu
  static const Color completedColor = Color(0xFFEDF7ED);

  // Metin renkleri
  static const Color textPrimaryColor = Color(0xFF1D1D35);
  static const Color textSecondaryColor = Color(0xFF666687);
  static const Color textLightColor = Color(0xFF8E8EA9);

  // Işık Tema
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      background: backgroundColor,
      surface: cardColor,
      onSurface: textPrimaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cardColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryColor,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 15),
      hintStyle: TextStyle(
        color: textLightColor.withOpacity(0.8),
        fontSize: 15,
      ),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme.copyWith(
            displayLarge: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            displayMedium: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            displaySmall: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            headlineMedium: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: GoogleFonts.poppins(
              color: textSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            bodyMedium: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            bodySmall: GoogleFonts.poppins(
              color: textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            labelLarge: GoogleFonts.poppins(
              color: textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textLightColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      elevation: 8,
    ),
  );
}
