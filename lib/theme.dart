import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: "Poppins",

    scaffoldBackgroundColor: Colors.black,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: "Poppins",
        fontWeight: FontWeight.w800,
        fontSize: 25,
        
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          fontFamily: "Poppins",
        ),
      ).copyWith(overlayColor: MaterialStateProperty.all(Colors.white24)),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(
          fontFamily: "Poppins",
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ).copyWith(overlayColor: MaterialStateProperty.all(Colors.white24)),
    ),

    // Input Field Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      hintStyle: const TextStyle(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.4),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white12,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          unselectedLabelStyle: TextStyle(fontFamily: "Poppins"),
          selectedLabelStyle: TextStyle(fontFamily: "Poppins"),
          elevation: 10,
          enableFeedback: false,
        ),
  );
}
