import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFF121212);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentRed = Color(0xFFFF3D00);
  
  static const Color glassFill = Color(0x0AFFFFFF); // white with 4% opacity
  static const Color glassBorder = Color(0x14FFFFFF); // white with 8% opacity
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF666666);
  
  static const Color warningOrange = Color(0xFFFF9100);
  static const Color successGreen = Color(0xFF00E676);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      primaryColor: AppColors.accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentCyan,
        secondary: AppColors.accentCyan,
        error: AppColors.accentRed,
        background: AppColors.backgroundStart,
        surface: AppColors.backgroundEnd,
      ),
      fontFamily: 'Outfit', // A premium typography feel, falls back to system font if not imported
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: AppColors.accentCyan),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.accentCyan,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static BoxDecoration get backgroundDecoration {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.backgroundStart,
          AppColors.backgroundEnd,
        ],
      ),
    );
  }
}
