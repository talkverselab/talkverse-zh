import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_universe/data/usage_pages.dart';

/// 화면 열람 기록 — 앱이 보내는 ID 와 화면 목록(tool/usage_catalog.json)의 page 가 글자까지 같은지.
void main() {
  final re = RegExp(r'^[\w./:#-]{1,120}$');

  test('ID 모양', () {
    expect(UsagePages.conv('r2_love_a2'), 'conv/r2_love_a2');
    expect(UsagePages.grammar(3), 'grammar/step3');
    expect(UsagePages.sense('L1-talk'), 'sense/L1-talk');
    expect(UsagePages.vocab('hsk4'), 'vocab/hsk4');
  });

  test('화면 목록이 같은 규칙을 따른다', () {
    final f = File('tool/usage_catalog.json');
    if (!f.existsSync()) return;
    final pages = ((json.decode(f.readAsStringSync()) as Map)['pages'] as List).cast<Map>();
    expect(pages, isNotEmpty);
    for (final p in pages) {
      final id = '${p['page']}';
      expect(re.hasMatch(id), isTrue, reason: id);
      expect(['free', 'pro', 'exam'], contains(p['tier']), reason: id);
      expect(RegExp(r'^(conv/[^/]+|grammar/step\d+|sense/[^/]+|vocab/[^/]+)$').hasMatch(id), isTrue, reason: id);
      if (id.startsWith('vocab/')) expect(p['tier'], const {'vocab/hsk4', 'vocab/hsk5'}.contains(id) ? 'exam' : 'free');
      if (id.startsWith('conv/r1_')) expect(p['tier'], 'free');
    }
  });
}
