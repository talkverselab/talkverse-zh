import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/pinyin_hangul.dart';

/// 성조 부호 → 성조 번호(1~4). 부호가 없으면 0(경성).
int toneOfSyllable(String syl) {
  for (final ch in syl.split('')) {
    final t = _toneMarks[ch];
    if (t != null) return t;
  }
  return 0;
}

const Map<String, int> _toneMarks = {
  'ā': 1, 'ē': 1, 'ī': 1, 'ō': 1, 'ū': 1, 'ǖ': 1, 'Ā': 1, 'Ē': 1, 'Ī': 1, 'Ō': 1, 'Ū': 1,
  'á': 2, 'é': 2, 'í': 2, 'ó': 2, 'ú': 2, 'ǘ': 2, 'Á': 2, 'É': 2, 'Í': 2, 'Ó': 2, 'Ú': 2, 'ń': 2,
  'ǎ': 3, 'ě': 3, 'ǐ': 3, 'ǒ': 3, 'ǔ': 3, 'ǚ': 3, 'Ǎ': 3, 'Ě': 3, 'Ǐ': 3, 'Ǒ': 3, 'Ǔ': 3, 'ň': 3,
  'à': 4, 'è': 4, 'ì': 4, 'ò': 4, 'ù': 4, 'ǜ': 4, 'À': 4, 'È': 4, 'Ì': 4, 'Ò': 4, 'Ù': 4, 'ǹ': 4,
};

final _word = RegExp(r"[A-Za-zāáǎàēéěèêīíǐìōóǒòūúǔùǖǘǚǜüÜńňǹḿĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙ]+");

/// 병음 문장을 (글자, 성조) 조각으로 — 음절마다 성조 하나. 낱말이 아닌 조각(공백·문장부호)은 성조 null.
/// 음절로 나눌 수 없는 낱말은 통째로, 첫 성조 부호의 성조로.
List<(String, int?)> pinyinRuns(String s) {
  final out = <(String, int?)>[];
  var i = 0;
  for (final m in _word.allMatches(s)) {
    if (m.start > i) out.add((s.substring(i, m.start), null));
    final w = m.group(0)!;
    final syl = PinyinHangul.splitSyllables(w);
    if (syl == null) {
      out.add((w, toneOfSyllable(w)));
    } else {
      for (final p in syl) {
        out.add((p, toneOfSyllable(p)));
      }
    }
    i = m.end;
  }
  if (i < s.length) out.add((s.substring(i), null));
  return out;
}

/// 음절마다 성조 색을 입힌 병음(1성 빨강 · 2성 주황 · 3성 초록 · 4성 파랑 · 경성 회색).
class TonePinyinText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final TextAlign? textAlign;
  final int? maxLines;
  const TonePinyinText(this.text, {super.key, this.size = AppFonts.py, this.weight = FontWeight.w500, this.textAlign, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final base = AppFonts.pinyinText(size: size, weight: weight);
    return Text.rich(
      TextSpan(children: [
        for (final (t, tone) in pinyinRuns(text)) TextSpan(text: t, style: tone == null ? null : TextStyle(color: toneColor(tone))),
      ]),
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
