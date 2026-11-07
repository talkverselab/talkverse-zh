import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/hanzi_cliff.dart';
import 'app_database.dart';

class SeedLoader {
  final AppDatabase db;
  SeedLoader(this.db);

  /// 번들 `assets/data/version.json` 의 `db`(업데이트 번호)와 저장된 번호가 다르면 DB 를 전부 다시 채운다(사용자 지시 2026-11-04).
  /// 옛 키(`db_seeded_v7`)는 더 쓰지 않는다 — 번호는 version.json 한 곳에서만 올린다.
  static const _kDbVersion = 'db_version';

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bundled = await bundledVersion();
    if (prefs.getInt(_kDbVersion) == bundled) return;

    await _seedHanzi();
    await db.delete(db.words).go(); // 순위가 기본키라 덮어쓰기만으로는 빠진 단어가 남는다
    await _seedWords();
    await _seedTurns();

    await prefs.setInt(_kDbVersion, bundled);
  }

  static Future<int> bundledVersion() async {
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/version.json')) as Map<String, dynamic>;
      return (j['db'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// 한자 2,000자 — 절벽 재산출표(`tools/hanzi_cliff_build.py`): 순위·글자·빈도·누적%·HSK. phase = 절벽 구간(HanziCliff).
  Future<void> _seedHanzi() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/cliff/hanzi_cliff_zh.tsv');
    final batch = <Insertable<HanziRow>>[];
    for (final line in raw.split('\n')) {
      final parts = line.trim().split('\t');
      if (parts.length < 5) continue;
      final rank = int.tryParse(parts[0]) ?? 0;
      batch.add(HanziCompanion.insert(
        char: parts[1],
        rank: Value(rank),
        freq: Value(int.tryParse(parts[2]) ?? 0),
        hskLevel: Value(parts[4] == '-' ? null : parts[4]),
        phase: Value(HanziCliff.phaseOf(rank)),
      ));
    }
    await db.delete(db.hanzi).go(); // 옛 500자표의 순위가 남지 않게
    await db.batch((b) => b.insertAllOnConflictUpdate(db.hanzi, batch));
  }

  Future<void> _seedWords() async {
    final raw = await rootBundle.loadString('assets/data/freq/lang_zh_with_regions.csv');
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    final batch = <Insertable<WordRow>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      batch.add(WordsCompanion.insert(
        rank: Value(int.tryParse('${row[0]}') ?? 0),
        word: '${row[1]}',
        freq: Value(double.tryParse('${row[2]}')),
        cumPct: Value(double.tryParse('${row[3]}')),
        region: Value('${row[4]}'),
      ));
    }
    await db.batch((b) => b.insertAllOnConflictUpdate(db.words, batch));
  }

  /// L1~L3 전체 턴 시딩. L1은 'episodes', L2/L3은 'dialogues' 키 사용.
  Future<void> _seedTurns() async {
    final batch = <Insertable<TurnRow>>[];
    for (final level in ['L1', 'L2', 'L3', 'L4']) {
      final Map<String, dynamic> data;
      try {
        final raw = await rootBundle
            .loadString('assets/data/dialogues/north/$level.json');
        data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final units =
          (data['episodes'] as List?) ?? (data['dialogues'] as List?) ?? [];
      for (final ep in units) {
        final epMap = ep as Map<String, dynamic>;
        final epId = epMap['id'] as String?;
        final turns = (epMap['turns'] as List?) ?? [];
        for (final t in turns) {
          final m = t as Map<String, dynamic>;
          batch.add(TurnsCompanion.insert(
            level: level,
            dialect: const Value('north'),
            episodeId: Value(epId),
            num: m['num'] as int,
            speaker: m['speaker'] as String,
            zh: m['zh'] as String,
            pinyin: Value(m['pinyin'] as String?),
            ko: Value(m['ko'] as String?),
            tones: Value(m['tones'] as String?),
            note: Value(m['note'] as String?),
            tagsJson: Value(m['tags'] != null ? json.encode(m['tags']) : null),
          ));
        }
      }
    }
    if (batch.isNotEmpty) {
      // 재시딩: 이전 버전 턴·진행 기록 제거 후 삽입 (turnId 재발급)
      await db.delete(db.userProgress).go();
      await db.delete(db.turns).go();
      await db.batch((b) => b.insertAll(db.turns, batch));
    }
  }

  Future<int> turnCount() => db.turns.count().getSingle();
  Future<int> hanziCount() => db.hanzi.count().getSingle();
  Future<int> wordCount() => db.words.count().getSingle();
}
