import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pinyin_hangul_map.dart';
import 'pinyin_util.dart';

/// 병음 → 한글독음 변환 + 전역 표시 설정.
class KoReading {
  KoReading._();

  static int? _maxKeyLen;

  /// 성조 병음 문자열을 한글독음으로 변환.
  /// 'Nǐ hǎo ma？' → '니 하오 마？'
  static String convert(String pinyin) {
    _maxKeyLen ??= pinyinHangulMap.keys
        .fold<int>(0, (m, k) => k.length > m ? k.length : m);
    final buf = StringBuffer();
    // 단어 단위(공백/어포스트로피 구분) 처리, 나머지 문자는 그대로 통과
    final tokens = pinyin.split(RegExp(r"[\s'’]+"));
    var first = true;
    for (final token in tokens) {
      if (token.isEmpty) continue;
      if (!first) buf.write(' ');
      first = false;
      buf.write(_convertWord(token));
    }
    return buf.toString();
  }

  static String _convertWord(String word) {
    // 성조 제거 + ü→v 정규화 + 숫자 성조(ni3) 제거.
    // 라틴 이외 문자(문장부호 등)는 그대로 통과
    final base = PinyinUtil.stripTones(word)
        .replaceAll('u:', 'v')
        .replaceAll('ü', 'v')
        .replaceAll(RegExp(r'[1-5]'), '');
    final buf = StringBuffer();
    var i = 0;
    while (i < base.length) {
      final c = base[i];
      if (!RegExp(r'[a-z]').hasMatch(c)) {
        buf.write(c);
        i++;
        continue;
      }
      // 최장 일치 음절 탐색
      var matched = false;
      final maxLen = _maxKeyLen!;
      for (var len = maxLen; len >= 1; len--) {
        if (i + len > base.length) continue;
        final seg = base.substring(i, i + len);
        final ko = pinyinHangulMap[seg];
        if (ko != null) {
          buf.write(ko);
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        buf.write(c);
        i++;
      }
    }
    return buf.toString();
  }
}

/// 한글독음 표시/숨김 전역 설정 (모든 메뉴 공용).
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

/// 앱바용 한글독음 토글 버튼 — 모든 메뉴 공통.
class KoReadingToggleAction extends StatelessWidget {
  const KoReadingToggleAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, on, _) => IconButton(
        tooltip: on ? '한글독음 숨기기' : '한글독음 표시',
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
            '한',
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

/// 병음 아래 붙는 독음 텍스트 — show가 꺼져 있으면 빈 위젯.
class KoReadingText extends StatelessWidget {
  const KoReadingText(this.pinyin, {super.key, this.style});

  final String pinyin;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: KoReadingPrefs.show,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        return Text(
          KoReading.convert(pinyin),
          style: style ??
              TextStyle(fontSize: 11, color: Colors.brown.shade400),
        );
      },
    );
  }
}
