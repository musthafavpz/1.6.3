import 'package:flutter/material.dart';
import '../constants.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFFF8FAFD),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      background: Color(0xFFF8FAFD),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Color(0xFF333333),
      onSurface: Color(0xFF333333),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF333333)),
      bodyMedium: TextStyle(color: Color(0xFF666666)),
      bodySmall: TextStyle(color: Color(0xFF999999)),
      titleLarge: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF333333)),
      titleTextStyle: TextStyle(
        color: Color(0xFF333333),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      shadowColor: Colors.black12,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF6366F1),
      selectionColor: Color(0x336366F1),
      selectionHandleColor: Color(0xFF6366F1),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF5F5F5),
      hintStyle: TextStyle(color: Colors.grey),
      labelStyle: TextStyle(color: Colors.black87),
      floatingLabelStyle: TextStyle(color: Color(0xFF6366F1)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6366F1)),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      background: Color(0xFF121212),
      surface: Color(0xFF222222),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      surfaceTint: Color(0xFF2D2D2D),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
      bodySmall: TextStyle(color: Color(0xFFAAAAAA)),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF2D2D2D),
      shadowColor: Colors.black54,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF8B5CF6),
      selectionColor: Color(0x338B5CF6),
      selectionHandleColor: Color(0xFF8B5CF6),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2D2D2D),
      hintStyle: TextStyle(color: Color(0xFF999999)),
      labelStyle: TextStyle(color: Color(0xFFCCCCCC)),
      floatingLabelStyle: TextStyle(color: Color(0xFF8B5CF6)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF8B5CF6)),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF444444)),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF333333),
      thickness: 1,
    ),
  );
} 