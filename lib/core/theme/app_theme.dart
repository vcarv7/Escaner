import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF0000);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF000000);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF000000);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFFFFFFF);

  static ThemeData getTheme(bool isDark) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: primary,
          onPrimary: onPrimary,
          surface: isDark ? darkSurface : lightSurface,
          onSurface: isDark ? darkOnSurface : lightOnSurface,
        ),
        scaffoldBackgroundColor: isDark ? darkBackground : lightBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? darkSurface : lightSurface,
          foregroundColor: primary,
          centerTitle: true,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: isDark ? darkSurface : lightSurface,
          indicatorColor: primary,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              color: isDark ? darkOnSurface : lightOnSurface,
              fontSize: 12,
            ),
          ),
        ),
      );
}