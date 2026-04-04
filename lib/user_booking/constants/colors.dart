import 'package:flutter/material.dart';

class AppColors {
  // --- BRAND COLORS (Consistent in both themes) ---
  static const Color primaryDarkGreen = Color(0xFF0B8457); // Turf Green
  static const Color primaryLightGreen = Color(0xFF4CAF50); // Vibrant Green
  static const Color accentOrange = Color(0xFFFF9800); // CTA / Highlights
  static const Color goldenYellow = Color(0xFFFFD600); // Advance Paid / Ratings

  // --- LIGHT THEME COLORS ---
  static const Color bgLight = Color(0xFFF5F7FA); // App Background
  static const Color surfaceLight =
      Color(0xFFFFFFFF); // Card & Modal Background
  static const Color textPrimaryLight = Color(0xFF212121); // Headings
  static const Color textSecondaryLight = Color(0xFF616161); // Subtitles/Body
  static const Color borderLight = Color(0xFFEEEEEE); // Dividers/Borders

  // --- DARK THEME COLORS ---
  static const Color bgDark = Color(0xFF121212); // App Background
  static const Color surfaceDark = Color(0xFF1E1E1E); // Card & Modal Background
  static const Color textPrimaryDark = Color(0xFFECEFF1); // Headings
  static const Color textSecondaryDark = Color(0xFFB0BEC5); // Subtitles/Body
  static const Color borderDark = Color(0xFF2C2C2C); // Dividers/Borders

  // --- SLOT STATUS COLORS (Semantics) ---
  static const Color slotAvailable = Color(0xFF4CAF50); // Green
  static const Color slotBooked = Color(0xFFE53935); // Red
  static const Color slotSelected = Color(0xFFFF9800); // Orange
  static const Color slotBlocked = Color(0xFFBDBDBD); // Grey

  // --- FUNCTIONAL COLORS ---
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF2E7D32);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
