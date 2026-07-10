import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFFF4F7FA);
  static const Color backgroundEnd = Color(0xFFFFFFFF);
  
  static const Color accentBlue = Color(0xFF007AFF); // Clean Apple-style light blue
  static const Color accentCyan = Color(0xFF007AFF); // Map Cyan to Clean Light Blue
  static const Color accentRed = Color(0xFFEF4444);  // Soft alert red
  
  static const Color glassFill = Color(0xCCFFFFFF); // 80% white opacity
  static const Color glassBorder = Color(0x33007AFF); // light blue with 20% opacity
  
  static const Color textPrimary = Color(0xFF1E293B);   // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400
  
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500
  static const Color successGreen = Color(0xFF10B981);  // Emerald 500
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      primaryColor: AppColors.accentBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentBlue,
        error: AppColors.accentRed,
        background: AppColors.backgroundStart,
        surface: AppColors.backgroundEnd,
      ),
      fontFamily: 'Outfit',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.accentBlue),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
