// lib/core/theme.dart

import 'package:flutter/material.dart';

class AppColors {
  // === Marca principal ===
  static const Color primary = Color(0xFF34D1B6);
  static const Color primaryHover = Color(0xFF2ABFA4);

  // === Fondos ===
  static const Color bg = Color(0xFF0B0F13);          // fondo principal
  static const Color bgHeader = Color(0xFF0E1217);    // header, barras
  static const Color bgSection = Color(0xFF11151B);   // secciones y tarjetas
  static const Color bgSoft = Color(0xFF12181F);      // cajas suaves, inputs

  // === Texto ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFFBBBBBB);
  static const Color textFaint = Color(0xFF777777);

  // === Estados ===
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

ThemeData buildBioAccessTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.bg,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primaryHover,
      background: AppColors.bg,
      surface: AppColors.bgSoft,
      error: AppColors.error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgHeader,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),

    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'Roboto',
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgSoft,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
  );
}
