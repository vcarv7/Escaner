import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF0000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: primary,
          onPrimary: onPrimary,
          surface: surface,
          onSurface: onSurface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: primary,
          centerTitle: true,
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: primary,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: onSurface, fontSize: 12),
          ),
        ),
      );
}