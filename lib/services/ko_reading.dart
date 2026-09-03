import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 발음 표기(성조 병음) 표시/숨김 전역 설정 — 모든 메뉴 공용.
/// (구 한글독음 토글: 2026-09-03 사용자 요청으로 표기를 성조 병음으로 전환)
class KoReadingPrefs {
  KoReadingPrefs._();

  static const _key = 'show_ko_reading';
  static final ValueNotifier<bool> show = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    show.value = p.getBool(_key) ?? true;
  }

  static Future<void> toggle() async {
    show.value = !show.value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, show.value);
  }
}

/// 앱바용 병음 토글 버튼 — 모든 메뉴 공통.
class KoReadingToggleAction extends StatelessWidget {
  const KoReadingToggleAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, on, _) => IconButton(
        tooltip: on ? '병음 숨기기' : '병음 표시',
        onPressed: KoReadingPrefs.toggle,
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: on ? Colors.white : Colors.white38,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '拼',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white : Colors.white38,
              decoration: on ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

/// 발음 표기(병음) 텍스트 — 전역 설정이 꺼져 있으면 빈 위젯.
class KoReadingText extends StatelessWidget {
  const KoReadingText(
    this.reading, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String reading;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        return Text(reading,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            style: style);
      },
    );
  }
}
