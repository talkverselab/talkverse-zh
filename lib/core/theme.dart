import 'package:flutter/material.dart';
import 'embed_env.dart';

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

  // 일본어앱 구조를 옮기며 들인 화면 톤(2026-11-02) — 구리 → 황갈 포인트(버튼·성과·강조), 선·보조 글자.
  static const Color copper = Color(0xFFB77548);
  static const Color copperDeep = Color(0xFF9A5F38);
  static const Color tan = Color(0xFFC19E6D);
  static const Color line = Color(0xFFE6EBF1);
  static const Color muted = Color(0xFF6B7C93);

  /// 워드마크 그라데이션(왼쪽 구리 → 오른쪽 황갈). 제목 글자·구분선·편 끝 연출에 쓴다.
  static const LinearGradient wordmark = LinearGradient(colors: [copper, tan]);
}

/// 카드·타일 공통 그림자(사이트 `0 2px 5px -1px rgba(50,50,93,.1), 0 1px 3px -1px rgba(0,0,0,.1)`)
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x1A32325D), blurRadius: 5, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
];

/// 글꼴 「문체」 세트(2026-11-03 확정, zh04 제안보다 작은 크기).
///
/// Pretendard = 한글 UI·독음·번역(앱 기본), NotoSansSC = 중국어 본문(대사·단어),
/// LXGWWenKai = 큰 한자 자형(팝업·한자 배우기·패밀리 한자·단계 타일), NotoSans = 병음(성조 부호).
/// NotoSansSC·NotoSans 는 가변 글꼴이라 굵기를 `fontVariations` 로도 준다(FontWeight 만으로는 wght 축이 안 움직이는 플랫폼이 있다).
/// 테마 `fontFamilyFallback` 이 NotoSansSC 라 Pretendard 글자 속 중국어도 시스템 글꼴로 새지 않는다.
class AppFonts {
  AppFonts._();
  // 통합 앱(패키지)에서는 글꼴 이름에 packages/chinese_universe/ 가 붙는다(fontName, 2026-11-09)
  static String get ui => fontName('Pretendard');
  static String get zh => fontName('NotoSansSC');
  static String get glyph => fontName('LXGWWenKai');
  static String get pinyin => fontName('NotoSans');
  static List<String> get fallback => [zh];

  // 크기 표(논리 픽셀)
  static const double glyphBig = 60; // 팝업·한자 배우기 큰 자형
  static const double glyphTile = 30; // 패밀리·단계 타일 자형
  static const double title = 19; // 화면 제목(SemiBold)
  static const double lineNow = 23; // 지금 대사 중국어
  static const double line = 15.5; // 나머지 중국어 줄
  static const double py = 12.5; // 병음
  static const double reading = 13.5; // 한글 독음·번역
  static const double caption = 11.5; // 캡션·칩
  static const double rail = 10.5; // 레일·탭 라벨

  static List<FontVariation> _w(FontWeight w) => [FontVariation.weight(w.value.toDouble())];

  /// 중국어 본문(대사·단어).
  static TextStyle zhText({double size = line, FontWeight weight = FontWeight.w500, Color color = AppColors.mo, double height = 1.45}) =>
      TextStyle(fontFamily: zh, fontFamilyFallback: [ui], fontSize: size, fontWeight: weight, fontVariations: _w(weight), color: color, height: height);

  /// 큰 한자 자형(Medium 한 벌).
  static TextStyle glyphText({double size = glyphBig, Color color = AppColors.mo, double height = 1.1}) =>
      TextStyle(fontFamily: glyph, fontFamilyFallback: fallback, fontSize: size, fontWeight: FontWeight.w500, color: color, height: height);

  /// 병음(성조 부호).
  static TextStyle pinyinText({double size = py, FontWeight weight = FontWeight.w500, Color color = AppColors.muted, double height = 1.35}) =>
      TextStyle(fontFamily: pinyin, fontFamilyFallback: fallback, fontSize: size, fontWeight: weight, fontVariations: _w(weight), color: color, height: height);

  /// 한글 UI·독음·번역.
  static TextStyle uiText({double size = reading, FontWeight weight = FontWeight.w400, Color color = AppColors.moLight, double height = 1.4}) =>
      TextStyle(fontFamily: ui, fontFamilyFallback: fallback, fontSize: size, fontWeight: weight, color: color, height: height);

  /// 화면 제목.
  static TextStyle titleText({double size = title, Color color = AppColors.mo}) =>
      TextStyle(fontFamily: ui, fontFamilyFallback: fallback, fontSize: size, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.3, height: 1.25);

  /// 캡션·칩.
  static TextStyle captionText({double size = caption, FontWeight weight = FontWeight.w400, Color color = AppColors.muted}) =>
      TextStyle(fontFamily: ui, fontFamilyFallback: fallback, fontSize: size, fontWeight: weight, color: color, height: 1.3);
}

/// 두 화면(왼쪽 목록 | 오른쪽 내용) 기준 — 가로 720 논리픽셀 이상: 아이패드·안드로이드 태블릿·폴드 펼침.
/// 접은 폴드·일반 폰은 한 화면. 일본어앱·한자유니버스와 같은 기준.
const wideMin = 720.0;
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideMin;

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
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.fallback,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.moLight,
        displayColor: AppColors.mo,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.xuanZhi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.mo,
        shape: Border(bottom: BorderSide(color: AppColors.jin, width: 1)),
        titleTextStyle: TextStyle(
          color: AppColors.mo,
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 18,
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
            fontSize: AppFonts.rail,
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
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.fallback,
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
