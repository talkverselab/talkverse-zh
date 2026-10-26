import 'package:flutter/material.dart';

/// 컬러 팔레트 — talkverse.uk 톤(2026-10-26).
///
/// 흰 바탕 + 남색 글자 + 인디고 포인트 하나, 그 밖의 색은 절제한다.
/// 이름(zhuHong·jin·mo·xuanZhi…)은 옛 中国风 팔레트에서 온 것이라 화면 코드가 그대로 쓰고,
/// 값만 사이트 토큰(`--ink`·`--body`·`--accent`…)에 맞췄다. 4성 색은 학습용이라 그대로.
class AppColors {
  // 주색 — 사이트 `--accent` 인디고 (옛 朱红 자리)
  static const Color zhuHong = Color(0xFF635BFF);
  static const Color zhuHongDeep = Color(0xFF4B44D6); // `--accent-ink`
  static const Color zhuHongLight = Color(0xFFA9A4FF);

  // 보조 — 옛 금색 자리. 테두리는 사이트 `--line` 계열, 밝은 강조는 히어로 피치
  static const Color jin = Color(0xFFDDE3EC);
  static const Color jinBright = Color(0xFFFFD39B);
  static const Color jinDeep = Color(0xFF6B7C93); // `--muted`

  // 글자 — `--ink` / `--body` (옛 墨 자리)
  static const Color mo = Color(0xFF0A2540);
  static const Color moLight = Color(0xFF425466);

  // 바탕 — 흰색 / `--soft` (옛 宣纸 자리)
  static const Color xuanZhi = Color(0xFFFFFFFF);
  static const Color xuanZhiDeep = Color(0xFFF6F9FC);

  // 보조 강조 — 차분한 청록(완료·학습됨, 옛 翡翠 자리)
  static const Color feiCui = Color(0xFF0E7C8C);

  // 중국어 카드색 — talkverse.uk 언어 카드의 `--c`
  static const Color hanyu = Color(0xFFE86A8C);

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
        onPrimary: Colors.white,
        primaryContainer: AppColors.zhuHongLight,
        onPrimaryContainer: AppColors.mo,
        secondary: AppColors.mo,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.jinBright,
        onSecondaryContainer: AppColors.mo,
        tertiary: AppColors.feiCui,
        onTertiary: AppColors.xuanZhi,
        tertiaryContainer: const Color(0xFFCDEFF2),
        onTertiaryContainer: AppColors.mo,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.xuanZhi,
        onSurface: AppColors.mo,
        surfaceContainerHighest: AppColors.xuanZhiDeep,
        onSurfaceVariant: AppColors.moLight,
        outline: AppColors.jinDeep,
        outlineVariant: AppColors.jin,
      ),
      scaffoldBackgroundColor: AppColors.xuanZhi,
      fontFamily: 'Pretendard',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.moLight,
        displayColor: AppColors.mo,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.xuanZhi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.mo,
        shape: Border(bottom: BorderSide(color: AppColors.jin, width: 1)),
        titleTextStyle: TextStyle(
          color: AppColors.mo,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.xuanZhi,
        shadowColor: const Color(0x1A32325D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.jin, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.xuanZhi,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFEFEEFE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.zhuHong : AppColors.jinDeep,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.zhuHong : AppColors.jinDeep,
            size: 24,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mo,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mo,
          side: const BorderSide(color: AppColors.jin),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.xuanZhiDeep,
        labelStyle: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.jin),
        shape: const StadiumBorder(),
        selectedColor: AppColors.zhuHong,
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.jin,
        thickness: 1,
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
