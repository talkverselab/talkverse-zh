import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/lexicon_service.dart';
import 'selectable_hanzi.dart' show showChunkSheet, showHanziSheet;

/// 회화 문장을 **레마(내용어) 단위**로 쪼개 그린다(2026-11-07, 일본어앱 §6).
/// - 레마를 탭 → 단어창(`LexiconService.byLemmas`). 단어장에 없고 한 글자면 한자 시트, 여러 글자면 병음만 든 단어창.
/// - 레마 안 글자를 **길게 누르면** 그 한자의 시트. 레마 밖 한자는 탭 → 한자 시트(이전과 같음).
/// - 단어장에 있는 레마는 밑줄(금색), 없는 레마는 회색 밑줄.
/// 레마 표면형은 문장에서 왼쇽부터 겹치지 않게 찾는다(긴 것 먼저). 이름 자리는 채운 뒤 넘겨 받는다.
class LemmaText extends StatefulWidget {
  final String text; // 이름 자리를 채운 문장
  final List<Lemma> lemmas;
  final TextStyle style;
  const LemmaText({super.key, required this.text, required this.lemmas, required this.style});

  @override
  State<LemmaText> createState() => _LemmaTextState();
}

class _Seg {
  final String text;
  final Lemma? lemma;
  const _Seg(this.text, this.lemma);
}

class _LemmaTextState extends State<LemmaText> {
  Map<String, LemmaHit> _hits = const {};
  String? _focus; // 눌린 조각 키

  static bool _isCjk(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code >= 0x4E00 && code <= 0x9FFF;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LemmaText old) {
    super.didUpdateWidget(old);
    if (old.lemmas != widget.lemmas) _load();
  }

  Future<void> _load() async {
    final hits = await LexiconService.instance.byLemmas(widget.lemmas.map((l) => l.base));
    if (mounted) setState(() => _hits = hits);
  }

  /// 문장 → 조각(레마 | 그 밖). 레마는 긴 표면형부터, 각 표면형은 문장에서 앉은 자리마다.
  List<_Seg> _split() {
    final s = widget.text;
    final owner = List<Lemma?>.filled(s.length, null);
    final sorted = [...widget.lemmas]..sort((a, b) => b.surface.length.compareTo(a.surface.length));
    for (final l in sorted) {
      if (l.surface.isEmpty) continue;
      var from = 0;
      while (true) {
        final i = s.indexOf(l.surface, from);
        if (i < 0) break;
        final end = i + l.surface.length;
        var free = true;
        for (var k = i; k < end; k++) {
          if (owner[k] != null) {
            free = false;
            break;
          }
        }
        if (free) {
          for (var k = i; k < end; k++) {
            owner[k] = l;
          }
        }
        from = end;
      }
    }
    final out = <_Seg>[];
    var i = 0;
    while (i < s.length) {
      final l = owner[i];
      var j = i + 1;
      if (l != null) {
        while (j < s.length && owner[j] == l) {
          j++;
        }
        out.add(_Seg(s.substring(i, j), l));
      } else {
        // 레마 밖은 글자 하나씩(한자는 각각 탭)
        out.add(_Seg(s.substring(i, j), null));
      }
      i = j;
    }
    return out;
  }

  Future<void> _openLemma(Lemma l) async {
    final hit = _hits[l.base];
    if (hit == null && l.base.length == 1 && _isCjk(l.base)) {
      await showHanziSheet(context, l.base);
    } else {
      await showChunkSheet(context, l.base, pinyin: l.reading);
    }
    if (mounted) setState(() => _focus = null);
  }

  Future<void> _openChar(String ch) async {
    await showHanziSheet(context, ch);
    if (mounted) setState(() => _focus = null);
  }

  @override
  Widget build(BuildContext context) {
    final given = widget.style;
    final style = given.fontFamily != null
        ? given
        : given.copyWith(
            fontFamily: AppFonts.zh,
            fontFamilyFallback: const [AppFonts.ui],
            fontVariations: [FontVariation.weight((given.fontWeight ?? FontWeight.w400).value.toDouble())],
          );
    final segs = _split();
    final children = <Widget>[];
    for (var si = 0; si < segs.length; si++) {
      final seg = segs[si];
      final l = seg.lemma;
      if (l == null) {
        final ch = seg.text;
        if (!_isCjk(ch)) {
          children.add(Text(ch, style: style));
          continue;
        }
        final key = 'c$si';
        children.add(_Tap(
          focused: _focus == key,
          color: AppColors.zhuHong,
          onTap: () {
            setState(() => _focus = key);
            _openChar(ch);
          },
          child: Text(ch, style: style.copyWith(color: _focus == key ? AppColors.zhuHong : style.color)),
        ));
        continue;
      }
      final known = _hits.containsKey(l.base);
      final line = known ? AppColors.jin : AppColors.line;
      // 레마: 글자마다 길게 누르면 그 한자, 탭은 레마 전체(단어창)
      children.add(Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line, width: 1.6))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var ci = 0; ci < seg.text.length; ci++)
            _Tap(
              focused: _focus == 'l$si',
              color: AppColors.jin,
              onTap: () {
                setState(() => _focus = 'l$si');
                _openLemma(l);
              },
              onLongPress: _isCjk(seg.text[ci])
                  ? () {
                      setState(() => _focus = 'l$si');
                      _openChar(seg.text[ci]);
                    }
                  : null,
              child: Text(seg.text[ci], style: style.copyWith(color: _focus == 'l$si' ? AppColors.copperDeep : style.color)),
            ),
        ]),
      ));
    }
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }
}

class _Tap extends StatelessWidget {
  final bool focused;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  const _Tap({required this.focused, required this.color, required this.onTap, this.onLongPress, required this.child});

  @override
  Widget build(BuildContext context) => Material(
        color: focused ? color.withValues(alpha: 0.2) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1), child: child),
        ),
      );
}
