import 'package:flutter/material.dart';

class AppColors {
  static const Color brand = Color(0xFFDE2910);
  static const Color tone1 = Color(0xFFE53935);
  static const Color tone2 = Color(0xFFFB8C00);
  static const Color tone3 = Color(0xFF43A047);
  static const Color tone4 = Color(0xFF1E88E5);
  static const Color toneNeutral = Color(0xFF9E9E9E);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
      ),
      fontFamily: 'Pretendard',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Pretendard',
    );
  }
}

Color toneColor(int? tone) {
  switch (tone) {
    case 1:
      return AppColors.tone1;
    case 2:
      return AppColors.tone2;
    case 3:
      return AppColors.tone3;
    case 4:
      return AppColors.tone4;
    default:
      return AppColors.toneNeutral;
  }
}
