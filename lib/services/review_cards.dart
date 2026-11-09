import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/services.dart' show rootBundle;

/// 라이트너 「오늘의 복습」 카드 = HSK 1·2급 단어(`assets/data/vocab/hsk_words.json`, 한국어 뜻 자체 작성본).
/// 일본어앱은 절벽 R1 덱을 쓰지만 중국어앱에는 덱 파일이 없어서 이미 있는 단어장을 그대로 카드로 쓴다(새 콘텐츠 없음).
class ReviewCard {
  final String id; // 'hsk:<간체>'
  final String zh;
  final String pinyin;
  final String ko;
  const ReviewCard({required this.id, required this.zh, required this.pinyin, required this.ko});
}

class ReviewCards {
  ReviewCards._();
  static final ReviewCards instance = ReviewCards._();

  static const asset = 'assets/data/vocab/hsk_words.json';
  static const themes = ['hsk1', 'hsk2'];

  final Map<String, ReviewCard> byId = {};
  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final j = json.decode(await rootBundle.loadString(assetPath(asset))) as Map<String, dynamic>;
      for (final t in (j['themes'] as List).whereType<Map>()) {
        if (!themes.contains(t['id'])) continue;
        for (final s in (t['sections'] as List).whereType<Map>()) {
          for (final w in (s['words'] as List).whereType<Map>()) {
            final zh = (w['zh'] as String? ?? '').trim();
            final ko = (w['ko'] as String? ?? '').trim();
            if (zh.isEmpty || ko.isEmpty) continue;
            final id = 'hsk:$zh';
            byId.putIfAbsent(id, () => ReviewCard(id: id, zh: zh, pinyin: w['rd'] as String? ?? '', ko: ko));
          }
        }
      }
    } catch (_) {}
  }
}
