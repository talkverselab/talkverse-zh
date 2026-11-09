import 'package:flutter/material.dart';
import '../core/prefs.dart';
import '../core/l10n.dart';

/// 읽기 보조(성조 병음·한글 독음) 표시/숨김 전역 설정 — 모든 메뉴 공용. **기본 미표시**(2026-11-07, 일본어앱 §6 — 후리가나 토글의 중국어판).
/// 표시로 켤 때는 스낵바 「힘들어도 병음을 보지 않고 익혀보세요」(사용자 지시). (구 한글독음 토글: 2026-09-03 성조 병음으로 전환)
class KoReadingPrefs {
  KoReadingPrefs._();

  static const _key = 'show_reading_aid'; // 옛 키(show_ko_reading, 기본 켬)와 분리 — 기본값이 바뀌었으므로
  static final ValueNotifier<bool> show = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final p = await Prefs.getInstance();
    show.value = p.getBool(_key) ?? false;
  }

  static Future<void> set(bool v) async {
    show.value = v;
    final p = await Prefs.getInstance();
    await p.setBool(_key, v);
  }

  static Future<void> toggle() => set(!show.value);

  /// 화면에서 토글 — 켤 때 안내 스낵바.
  static Future<void> toggleWithHint(BuildContext context) async {
    final turningOn = !show.value;
    await toggle();
    if (turningOn && context.mounted) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tr('힘들어도 병음을 보지 않고 익혀보세요')), duration: const Duration(seconds: 2)));
    }
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
        tooltip: on ? tr('병음 숨기기') : tr('병음 표시'),
        onPressed: () => KoReadingPrefs.toggleWithHint(context),
        icon: Builder(builder: (context) {
          // 앱바 전경색(밝은 앱바 = 먹색, 짙은 앱바 = 흰색)에 맞춘다
          final fg = AppBarTheme.of(context).foregroundColor ?? IconTheme.of(context).color ?? Colors.white;
          final c = on ? fg : fg.withValues(alpha: 0.38);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(border: Border.all(color: c, width: 1.2), borderRadius: BorderRadius.circular(6)),
            child: Text('拼', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c, decoration: on ? null : TextDecoration.lineThrough)),
          );
        }),
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
