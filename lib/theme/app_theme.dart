import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4F46E5); // Deeper Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF312E81);
  static const Color accentColor = Color(0xFFF43F5E);
  static const Color goldColor = Color(0xFFFBBF24); 
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  
  static const Color backgroundDark = Color(0xFF020617); // Deeper Dark
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  static const Color textDark = Color(0xFFF8FAFC); // High contrast text
  static const Color textLight = Color(0xFF0F172A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const BorderRadius smallBorderRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius mediumBorderRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius largeBorderRadius = BorderRadius.all(Radius.circular(32));

  static TextTheme get _baseTextTheme => GoogleFonts.outfitTextTheme();
  static TextTheme get _bodyTextTheme => GoogleFonts.interTextTheme();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceDark,
        background: backgroundDark,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: mediumBorderRadius,
          side: const BorderSide(color: Colors.white10),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textDark,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      textTheme: _baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textDark),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textDark),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textDark),
      ).merge(_bodyTextTheme.apply(bodyColor: textDark, displayColor: textDark)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceLight,
        background: backgroundLight,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: mediumBorderRadius,
          side: BorderSide(color: Colors.grey.withAlpha(20)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.outfit(
          color: textLight,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      textTheme: _baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textLight),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textLight),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textLight),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textLight),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textLight),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textLight),
      ).merge(_bodyTextTheme.apply(bodyColor: textLight, displayColor: textLight)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}
