import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

class SeedLoader {
  // v5: 대화문 전수 검수 반영 (논리·난이도·자연스러움 34건 + 문장부호 통일)
  static const _kSeededKey = 'db_seeded_v5';

  final AppDatabase db;
  SeedLoader(this.db);

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSeededKey) == true) return;

    await _seedHanzi();
    await _seedWords();
    await _seedTurns();

    await prefs.setBool(_kSeededKey, true);
  }

  Future<void> _seedHanzi() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/cliff/hanzi_top500_final.txt');
    final batch = <Insertable<HanziRow>>[];
    final lines = raw.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 4) continue;
      final rank = int.tryParse(parts[0]) ?? 0;
      final char = parts[1];
      final freq = int.tryParse(parts[2]) ?? 0;
      final hsk = parts[3];
      batch.add(HanziCompanion.insert(
        char: char,
        rank: Value(rank),
        freq: Value(freq),
        hskLevel: Value(hsk),
      ));
    }
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
    for (final level in ['L1', 'L2', 'L3']) {
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
