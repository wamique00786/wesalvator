// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightMode = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF0A3D62), // Deep luxurious blue
      secondary: Color(0xFFD4AF37), // Soft white background
      surface: Colors.white, // White surfaces
      onPrimary: Colors.white, // Text/icon color on primary
      onSecondary: Colors.black, // Dark gray text on background
      onSurface: Color(0xFF2D3142), // Dark gray text on surfaces
      error: Colors.redAccent, // For error states
    ),
    scaffoldBackgroundColor: Color(0xFFF8F1F1), // Background for whole app
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white, // Clean white app bar
      foregroundColor: Color(0xFF0A3D62), // Deep blue for app bar content
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0A3D62), // Deep blue for app bar title
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF0A3D62), // Deep blue for app bar icons
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0A3D62), // Primary button color (deep blue)
        foregroundColor: Colors.white, // Button text color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.15),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white, // Card background color
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: Color(0xFF2D3142), // Dark gray text for readability
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0A3D62), // Deep blue for main titles
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFFD4AF37), // Gold accent for section headings
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Color(0xFFEAEAEA), // Soft light gray for dividers
      thickness: 1.2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF0A3D62).withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF0A3D62).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF0A3D62), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFD4AF37), // Gold - Used for buttons, highlights
      secondary: Color(0xFF8D6E63), // Dark background
      surface: Color(0xFF1E1E1E), // Slightly lighter dark for components
      onPrimary: Colors.black, // Text/icon color on primary (gold buttons)
      onSecondary: Colors.white, // Off-white for text on dark mode
      onSurface: Color(0xFFF5F5F5), // Off-white for text on components
      error: Color(0xFFCF6679), // Material design dark theme error color
    ),
    scaffoldBackgroundColor: Color(0xFF121212), // Dark background for whole app
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E), // Dark app bar
      foregroundColor: Color(0xFFD4AF37), // Gold app bar content
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFFD4AF37), // Gold title for premium look
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFD4AF37), // Gold icons in app bar
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFD4AF37), // Gold button background
        foregroundColor: Colors.black, // Black text/icons on buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
    ),
    cardTheme: CardTheme(
      color: Color(0xFF1E1E1E), // Dark gray cards
      shadowColor: Colors.black.withOpacity(0.25),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: Color(0xFFF5F5F5), // Light text for dark mode
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFFD4AF37), // Gold for titles
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFFD4AF37), // Gold for section headings
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Color(0xFF2A2A2A), // Dark gray for dividers in dark mode
      thickness: 1.2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Color(0xFF262626),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      hintStyle: TextStyle(color: Color(0xFFF5F5F5).withOpacity(0.6)),
    ),
  );
}
