import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana Renkler
  static const Color primary = Color(0xFF0D47A1); // Koyu Mavi
  static const Color primaryVariant = Color(0xFF1565C0); // Orta Mavi
  static const Color secondary = Color(0xFF42A5F5); // Açık Mavi
  static const Color secondaryVariant = Color(0xFF90CAF9); // Çok Açık Mavi

  // Yardımcı Renkler
  static const Color background = Color(0xFFF4F6F8); // Açık Gri Arkaplan
  static const Color surface = Colors.white; // Kart ve Yüzey Rengi
  static const Color error = Color(0xFFD32F2F); // Kırmızı Hata Rengi
  static const Color success = Color(0xFF388E3C); // Yeşil Başarı Rengi
  static const Color warning = Color(0xFFFFA000); // Turuncu Uyarı Rengi
  static const Color info = Color(0xFF1976D2); // Bilgi Mavi

  // Metin Renkleri
  static const Color textPrimary = Color(0xFF212121); // Koyu Gri Ana Metin
  static const Color textSecondary = Color(0xFF757575); // Gri İkincil Metin
  static const Color textOnPrimary = Colors.white; // Ana Renk Üzeri Metin
  static const Color textOnSecondary = Colors.black; // İkincil Renk Üzeri Metin

  // Kenarlık ve Ayırıcı Renkleri
  static const Color border = Color(0xFFE0E0E0); // Açık Gri Kenarlık
  static const Color divider = Color(0xFFBDBDBD); // Gri Ayırıcı

  // Gölgeler
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // Genel Boyutlar
  static const double borderRadius = 12.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double iconSize = 24.0;

  // Yazı Tipleri
  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.roboto(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.25,
            color: textPrimary),
        displayMedium: GoogleFonts.roboto(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: textPrimary),
        displaySmall: GoogleFonts.roboto(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: textPrimary),
        headlineLarge: GoogleFonts.roboto(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: textPrimary),
        headlineMedium: GoogleFonts.roboto(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: textPrimary),
        headlineSmall: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: textPrimary),
        titleLarge: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: textPrimary),
        titleMedium: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: textPrimary),
        titleSmall: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: textPrimary),
        labelLarge: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: textOnPrimary), // Butonlar için
        labelMedium: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: textPrimary),
        labelSmall: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: textPrimary),
        bodyLarge: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: textPrimary),
        bodyMedium: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            color: textSecondary),
        bodySmall: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            color: textSecondary),
      );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      primaryColorDark: primaryVariant,
      primaryColorLight: secondary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: divider,
      disabledColor: textSecondary.withOpacity(0.5),
      splashColor: secondary.withOpacity(0.3),
      highlightColor: secondary.withOpacity(0.2),
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryVariant,
        secondary: secondary,
        secondaryContainer: secondaryVariant,
        surface: surface,
        background: background,
        error: error,
        onPrimary: textOnPrimary,
        onSecondary: textOnSecondary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle:
            _textTheme.headlineSmall?.copyWith(color: textOnPrimary),
        iconTheme: const IconThemeData(color: textOnPrimary, size: iconSize),
      ),
      cardTheme: CardTheme(
        elevation: 0, // Gölgeler BoxDecoration ile eklenecek
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(
            vertical: spacingSmall, horizontal: spacingMedium),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          padding: const EdgeInsets.symmetric(
              horizontal: spacingLarge, vertical: spacingMedium),
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
              horizontal: spacingMedium, vertical: spacingSmall),
          textStyle: _textTheme.labelLarge?.copyWith(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: _textTheme.bodyMedium
            ?.copyWith(color: textSecondary.withOpacity(0.7)),
        labelStyle: _textTheme.bodyMedium?.copyWith(color: textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMedium, vertical: spacingMedium),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        titleTextStyle: _textTheme.titleLarge,
        contentTextStyle: _textTheme.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondary.withOpacity(0.1),
        selectedColor: primary,
        secondarySelectedColor: primary,
        labelStyle: _textTheme.labelMedium?.copyWith(color: primary),
        secondaryLabelStyle:
            _textTheme.labelMedium?.copyWith(color: textOnPrimary),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingSmall, vertical: spacingSmall / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          side: BorderSide(color: primary.withOpacity(0.5)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: _textTheme.labelSmall?.copyWith(color: primary),
        unselectedLabelStyle:
            _textTheme.labelSmall?.copyWith(color: textSecondary),
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 2), // Yuvarlak
        ),
      ),
    );
  }
}
