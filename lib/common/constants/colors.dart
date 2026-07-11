import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- BRAND COLORS (Consistent in both themes) ---
  static const Color primaryDarkGreen = Color(0xFF0B8457); // Turf Green
  static const Color primaryLightGreen = Color(0xFF4CAF50); // Vibrant Green
  static const Color accentOrange = Color(0xFFFF9800); // CTA / Highlights
  static const Color goldenYellow = Color(0xFFFFD600); // Advance Paid / Ratings

  // --- LIGHT THEME COLORS ---
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF616161);
  static const Color borderLight = Color(0xFFEEEEEE);

  // --- DARK THEME COLORS ---
  static const Color bgDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFECEFF1);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);
  static const Color borderDark = Color(0xFF2C2C2C);

  // --- SLOT STATUS COLORS ---
  static const Color slotAvailable = Color(0xFF4CAF50);
  static const Color slotBooked = Color(0xFFE53935);
  static const Color slotSelected = Color(0xFFFF9800);
  static const Color slotBlocked = Color(0xFFBDBDBD);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF2E7D32);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color ratingAmber = Color(0xFFFFC107);

  // --- SEMANTIC TOKENS ---
  static const Color slotAvailableBorder = Color(0xFF00C897);
  static const Color slotAvailableBg = Color(0xFFE8F5E9);
  static const Color slotBookedBg = Color(0xFFFEEBEE);

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimaryLight,
        displayColor: textPrimaryLight,
      ),
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryDarkGreen,
        secondary: accentOrange,
        surface: surfaceLight,
        error: error,
        onPrimary: white,
        onSurface: textPrimaryLight,
        onSecondary: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
            color: textPrimaryLight, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shadowColor: Color(0x0D000000), // Colors.black.withValues(alpha: 0.05) equivalent
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkGreen,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDarkGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondaryLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryDarkGreen,
        unselectedItemColor: textSecondaryLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: borderLight,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimaryDark,
        displayColor: textPrimaryDark,
      ),
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkGreen,
        secondary: accentOrange,
        surface: surfaceDark,
        error: error,
        onPrimary: white,
        onSurface: textPrimaryDark,
        onSecondary: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
            color: textPrimaryDark, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: borderDark, width: 1)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkGreen,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDarkGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondaryDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryDarkGreen,
        unselectedItemColor: textSecondaryDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: borderDark,
    );
  }
}
