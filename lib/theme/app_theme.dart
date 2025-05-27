import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4B89DC);
  static const Color secondaryBlue = Color(0xFF4267B2);
  static const Color lightBlue = Color(0xFFE6EEFF);
  static const Color darkBlue = Color(0xFF2C3E50);
  static const Color accentBlue = Color(0xFF00B4D8);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: secondaryBlue,
      surface: Colors.white,
      background: lightBlue,
    ),
    scaffoldBackgroundColor: lightBlue,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryBlue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentBlue,
      foregroundColor: Colors.white,
    ),
  );
} 