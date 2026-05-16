import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

class SeedLoader {
  static const _kSeededKey = 'db_seeded_v1';

  final AppDatabase db;
  SeedLoader(this.db);

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSeededKey) == true) return;

    await _seedHanzi();
    await _seedWords();
    await _seedTurnsFromL1();

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

  Future<void> _seedTurnsFromL1() async {
    final raw = await rootBundle.loadString('assets/data/dialogues/north/L1.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final episodes = (data['episodes'] as List?) ?? [];
    final batch = <Insertable<TurnRow>>[];
    for (final ep in episodes) {
      final epMap = ep as Map<String, dynamic>;
      final epId = epMap['id'] as String?;
      final turns = (epMap['turns'] as List?) ?? [];
      for (final t in turns) {
        final m = t as Map<String, dynamic>;
        batch.add(TurnsCompanion.insert(
          level: 'L1',
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
    if (batch.isNotEmpty) {
      await db.batch((b) => b.insertAll(db.turns, batch));
    }
  }

  Future<int> turnCount() => db.turns.count().getSingle();
  Future<int> hanziCount() => db.hanzi.count().getSingle();
  Future<int> wordCount() => db.words.count().getSingle();
}
