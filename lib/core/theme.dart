import 'package:flutter/material.dart';

/// 中国风 컬러 팔레트
class AppColors {
  // 主色 — 朱红 (vermilion, 国旗·宫墙·灯笼)
  static const Color zhuHong = Color(0xFFDE2910);
  static const Color zhuHongDeep = Color(0xFFA8200C);
  static const Color zhuHongLight = Color(0xFFF45D44);

  // 副色 — 金 (帝王金, 璧, 印章 인주)
  static const Color jin = Color(0xFFD4A12C);
  static const Color jinBright = Color(0xFFF5C842);
  static const Color jinDeep = Color(0xFF8B6914);

  // 墨 (먹, 서예)
  static const Color mo = Color(0xFF1C1A18);
  static const Color moLight = Color(0xFF4A4540);

  // 宣纸 (paper, 부드러운 미색 배경)
  static const Color xuanZhi = Color(0xFFFAF3E0);
  static const Color xuanZhiDeep = Color(0xFFF0E5C8);

  // 翡翠 (jade, 보조 강조)
  static const Color feiCui = Color(0xFF00A86B);

  // 4성 컬러 (시각 학습용)
  static const Color tone1 = Color(0xFFE53935); // 1성 高平 — 빨강
  static const Color tone2 = Color(0xFFFB8C00); // 2성 上升 — 주황
  static const Color tone3 = Color(0xFF43A047); // 3성 V — 초록
  static const Color tone4 = Color(0xFF1E88E5); // 4성 下降 — 파랑
  static const Color toneNeutral = Color(0xFF8E8579); // 경성 — 회색

  // brand alias
  static const Color brand = zhuHong;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.zhuHong,
        onPrimary: AppColors.xuanZhi,
        primaryContainer: AppColors.zhuHongLight,
        onPrimaryContainer: AppColors.mo,
        secondary: AppColors.jin,
        onSecondary: AppColors.mo,
        secondaryContainer: AppColors.jinBright,
        onSecondaryContainer: AppColors.mo,
        tertiary: AppColors.feiCui,
        onTertiary: AppColors.xuanZhi,
        tertiaryContainer: const Color(0xFFB7E4C7),
        onTertiaryContainer: AppColors.mo,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.xuanZhi,
        onSurface: AppColors.mo,
        surfaceContainerHighest: AppColors.xuanZhiDeep,
        onSurfaceVariant: AppColors.moLight,
        outline: AppColors.jinDeep,
        outlineVariant: const Color(0xFFD8C9A8),
      ),
      scaffoldBackgroundColor: AppColors.xuanZhi,
      fontFamily: 'Pretendard',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.zhuHong,
        foregroundColor: AppColors.xuanZhi,
        titleTextStyle: TextStyle(
          color: AppColors.xuanZhi,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.xuanZhi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.jin, width: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.mo,
        indicatorColor: AppColors.zhuHong,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.jinBright : AppColors.xuanZhiDeep,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.xuanZhi : AppColors.xuanZhiDeep,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.xuanZhiDeep,
        labelStyle: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.jin),
        selectedColor: AppColors.zhuHong,
        secondaryLabelStyle: const TextStyle(color: AppColors.xuanZhi),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.jin,
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.zhuHong,
        textColor: AppColors.mo,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.zhuHong,
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
