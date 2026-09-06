import 'package:lpinyin/lpinyin.dart';

/// 말하기 판정 — "문장 전체를 말했는가" 만 본다. 성조·권설음·n/l 은 무시.
///
/// 1. 한자 → 무성조 병음 (lpinyin, MIT)
/// 2. 음절 퍼지 정규화: zh/ch/sh→z/c/s, n→l(초성), r→l, ing/eng→in/en, ü→v
/// 3. 목표 음절열 대비 LCS 비율 ≥ [threshold] 이면 PASS
class SpeakMatch {
  static const double threshold = 0.7;

  static final _hanzi = RegExp(r'[一-鿿]');
  static final _digits = RegExp(r'\d+');

  static const _numZh = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  /// 아라비아 숫자 → 한자 수사 (인식기가 "3点" 처럼 내놓는 경우 대비).
  static String _digitsToZh(String s) {
    return s.replaceAllMapped(_digits, (m) {
      final n = int.tryParse(m.group(0)!) ?? 0;
      if (n >= 10 && n < 100) {
        final t = n ~/ 10, o = n % 10;
        return '${t == 1 ? '' : _numZh[t]}十${o == 0 ? '' : _numZh[o]}';
      }
      return m.group(0)!.split('').map((d) => _numZh[int.parse(d)]).join();
    });
  }

  /// 문장 → 퍼지 음절 리스트.
  static List<String> syllables(String text) {
    final zh = _digitsToZh(text);
    final only = _hanzi.allMatches(zh).map((m) => m.group(0)!).join();
    if (only.isEmpty) return const [];
    final py = PinyinHelper.getPinyinE(
      only,
      separator: ' ',
      defPinyin: '',
      format: PinyinFormat.WITHOUT_TONE,
    );
    return py
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map(fuzzy)
        .toList(growable: false);
  }

  /// 발음 차이를 뭉개는 정규화.
  static String fuzzy(String syl) {
    var s = syl.toLowerCase().replaceAll('ü', 'v').replaceAll('u:', 'v');
    if (s.startsWith('zh')) {
      s = 'z${s.substring(2)}';
    } else if (s.startsWith('ch')) {
      s = 'c${s.substring(2)}';
    } else if (s.startsWith('sh')) {
      s = 's${s.substring(2)}';
    } else if (s.startsWith('n') && s.length > 1) {
      s = 'l${s.substring(1)}';
    } else if (s.startsWith('r')) {
      s = 'l${s.substring(1)}';
    }
    if (s.endsWith('ing')) {
      s = '${s.substring(0, s.length - 3)}in';
    } else if (s.endsWith('eng')) {
      s = '${s.substring(0, s.length - 3)}en';
    }
    return s;
  }

  /// 목표 대비 일치율 0~1 (LCS / 목표 길이).
  static double score(String target, String heard) {
    final a = syllables(target);
    final b = syllables(heard);
    if (a.isEmpty) return 0;
    if (b.isEmpty) return 0;
    return _lcs(a, b) / a.length;
  }

  static bool pass(String target, String heard, {double? min}) {
    if (heard.trim().isEmpty) return false;
    final t = _hanzi.allMatches(target).map((m) => m.group(0)!).join();
    if (t.isNotEmpty && heard.replaceAll(RegExp(r'\s'), '').contains(t)) {
      return true; // 한자 그대로 일치 — 빠른 경로
    }
    final need = min ?? threshold;
    final a = syllables(target);
    // 아주 짧은 문장(≤3음절)은 전부 맞아야 통과
    final effective = a.length <= 3 ? 0.99 : need;
    return score(target, heard) >= effective;
  }

  static int _lcs(List<String> a, List<String> b) {
    final prev = List<int>.filled(b.length + 1, 0);
    final cur = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        cur[j] = a[i - 1] == b[j - 1]
            ? prev[j - 1] + 1
            : (prev[j] > cur[j - 1] ? prev[j] : cur[j - 1]);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = cur[j];
        cur[j] = 0;
      }
    }
    return prev[b.length];
  }
}
