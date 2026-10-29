import 'package:flutter/material.dart';

/// 앱 전체 테마 정의 및 테마 확장 색상
class AppTheme {
  const AppTheme._();

  // --- 다크 모드 색상 팔레트 ---
  static const Color darkScaffoldBg = Color(0xFF121418);
  static const Color darkCardBg = Color(0xFF1E222B);
  static const Color darkBorder = Color(0xFF2C3240);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF90A4AE);
  static const Color darkPrimary = Color(0xFF00E5FF);
  static const Color darkSecondary = Color(0xFF00FF88);
  static const Color darkInputBg = Color(0xFF121418);

  // --- 라이트 모드 (일반 모드) 색상 팔레트 ---
  static const Color lightScaffoldBg = Color(0xFFF4F6F9);
  static const Color lightCardBg = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightPrimary = Color(0xFF0097A7);
  static const Color lightSecondary = Color(0xFF00A86B);
  static const Color lightInputBg = Color(0xFFF8FAFC);

  /// 다크 테마 ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffoldBg,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkCardBg,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardBg,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 라이트 테마 ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightScaffoldBg,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightCardBg,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCardBg,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// 화면 위젯에서 손쉽게 현재 테마 색상에 접근하기 위한 Helper Extension
extension AppThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg =>
      isDarkMode ? AppTheme.darkScaffoldBg : AppTheme.lightScaffoldBg;
  Color get cardBg => isDarkMode ? AppTheme.darkCardBg : AppTheme.lightCardBg;
  Color get cardBorder =>
      isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get textPrimary =>
      isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get textSecondary =>
      isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get primaryAccent =>
      isDarkMode ? AppTheme.darkPrimary : AppTheme.lightPrimary;
  Color get secondaryAccent =>
      isDarkMode ? AppTheme.darkSecondary : AppTheme.lightSecondary;
  Color get warningAccent =>
      isDarkMode ? const Color(0xFFFF9100) : const Color(0xFFE65100);
  Color get inputBg => isDarkMode ? AppTheme.darkInputBg : AppTheme.lightInputBg;
  Color get dividerColor =>
      isDarkMode ? const Color(0xFF2C3240) : const Color(0xFFE2E8F0);
}
