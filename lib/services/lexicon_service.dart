import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../main.dart' show appDb;
import 'pinyin_util.dart';

class LexEntry {
  final String simp;
  final String pinyin; // 성조 부호 병음
  final List<String> meanings; // 한국어 뜻
  LexEntry({required this.simp, required this.pinyin, required this.meanings});
}

/// 앱 안 단어·글자 사전 — 앱 자체 자료(HSK 단어장 한국어 뜻, 한자 1,500·209 단계)로 만든다.
/// 외부 사전 파일은 쓰지 않는다(2026-11-02 사용자 지시: 라이선스 붙은 자료 제외).
class LexiconService {
  LexiconService._();
  static final LexiconService instance = LexiconService._();

  final Map<String, LexEntry> _bySimp = {};
  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    // 글자: 단계 자료의 병음이 단어장보다 정확하므로 먼저 넣는다.
    for (final asset in ['assets/data/hanzi/hanzi_stages.json', 'assets/data/hanzi/hanzi_hsk1500.json']) {
      try {
        final j = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
        for (final st in j['stages'] as List) {
          for (final c in (st as Map)['chars'] as List) {
            final ch = c['char'] as String;
            final raw = c['pinyin_raw'] as String?;
            final mean = c['meaning'] as String?;
            if (raw == null || raw.isEmpty) continue;
            _bySimp.putIfAbsent(ch, () => LexEntry(simp: ch, pinyin: PinyinUtil.toTonedPinyin(raw), meanings: [if (mean != null && mean.isNotEmpty) mean]));
          }
        }
      } catch (_) {}
    }
    try {
      final j = jsonDecode(await rootBundle.loadString('assets/data/vocab/hsk_words.json')) as Map<String, dynamic>;
      for (final t in j['themes'] as List) {
        for (final s in (t as Map)['sections'] as List) {
          for (final w in (s as Map)['words'] as List) {
            final zh = w['zh'] as String;
            _bySimp.putIfAbsent(zh, () => LexEntry(simp: zh, pinyin: (w['rd'] as String?) ?? '', meanings: [if (w['ko'] != null) w['ko'] as String]));
          }
        }
      }
    } catch (_) {}
    // 회화 레마 보충 단어(단어장 미수록분, uk 세션 2026-11-04) — 레마 칩이 회색으로 남지 않게.
    try {
      final j = jsonDecode(await rootBundle.loadString('assets/data/vocab/conv_extra.json')) as Map<String, dynamic>;
      for (final w in j['words'] as List) {
        final zh = (w as Map)['zh'] as String;
        _bySimp.putIfAbsent(zh, () => LexEntry(simp: zh, pinyin: (w['pinyin'] as String?) ?? '', meanings: [if (w['ko'] != null) w['ko'] as String]));
      }
    } catch (_) {}
  }

  LexEntry? lookup(String simp) => _bySimp[simp];

  int get size => _bySimp.length;

  /// 문장 레마(기본형) → 단어장 항목 — 레마 칩용(2026-11-04). 앱 사전(뜻 있음) 또는 빈도 단어표(`words`) 에 있으면 "단어장에 있음".
  /// 뜻은 앱 사전에 있을 때만(없으면 null — 칩은 글자만).
  Future<Map<String, LemmaHit>> byLemmas(Iterable<String> bases) async {
    final keys = bases.toSet().where((b) => b.isNotEmpty).toList();
    if (keys.isEmpty) return const {};
    await ensureLoaded();
    final out = <String, LemmaHit>{};
    for (final b in keys) {
      final e = _bySimp[b];
      if (e != null) out[b] = LemmaHit(b, e.meanings.isEmpty ? null : e.meanings.first, e.pinyin);
    }
    final rest = keys.where((b) => !out.containsKey(b)).toList();
    if (rest.isNotEmpty) {
      try {
        final rows = await (appDb.select(appDb.words)..where((w) => w.word.isIn(rest))).get();
        for (final r in rows) {
          out.putIfAbsent(r.word, () => LemmaHit(r.word, null, null, rank: r.rank));
        }
      } catch (_) {}
    }
    return out;
  }
}

/// 레마 칩이 쓰는 단어장 조회 결과 — 뜻(앱 사전에 있을 때)·병음·빈도 순위.
class LemmaHit {
  final String word;
  final String? gloss;
  final String? pinyin;
  final int? rank;
  const LemmaHit(this.word, this.gloss, this.pinyin, {this.rank});
}
