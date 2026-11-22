import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'script_sync.dart';

/// 문법 스텝(사용자 지시 2026-11-23 「스텝 10 까지 다 미리 만들어놓고 DB업데이트 하면서 업뎃되게」 → 같은 날 「스텝 15까지 하자 내용이 없으면 자동으로 안나타나게」).
/// 스텝 수는 코드에 박지 않는다 — 목록 파일에 있는 스텝만 그린다(지금 묶음 틀 1~15).
/// 틀만 코드에 두고, 스텝 목록·제목·순서·내용은 데이터 `grammar/steps.json` + 각 스텝 파일에서 읽는다.
/// 둘 다 [ScriptSync] 로 읽어서 서버 원고(https://auth.talkverse.uk/art/script/zh/)에 새 판이 있으면 그것, 없으면 앱에 묶은 것.
/// 내용 파일이 없거나 비어 있는 스텝은 목록에서 빠진다(「준비 중」을 보이지 않음) — 서버에 올라오면 저절로 나타난다.
class GrammarStep {
  final int step;
  final String title;
  final String subtitle;
  final String file; // assets/data/ 아래 경로
  const GrammarStep(this.step, this.title, this.subtitle, this.file);
}

class GrammarSteps {
  static const indexFile = 'grammar/steps.json';

  /// 시험용 — 파일 읽기를 바꿔 끼운다.
  @visibleForTesting
  static Future<String> Function(String rel)? debugLoad;

  static Future<String> _load(String rel) => (debugLoad ?? ScriptSync.instance.load)(rel);

  /// 스텝 파일에 내용이 있는가(문형·단계·문장 중 하나라도).
  static bool hasContent(Map<String, dynamic> j) {
    for (final k in ['patterns', 'stages', 'sentences', 'points']) {
      final v = j[k];
      if (v is List && v.isNotEmpty) return true;
    }
    return false;
  }

  /// 내용이 있는 스텝만, 스텝 번호 순서로.
  static Future<List<GrammarStep>> visible() async {
    List raw;
    try {
      raw = (json.decode(await _load(indexFile)) as Map<String, dynamic>)['steps'] as List? ?? const [];
    } catch (_) {
      raw = const [{'step': 1, 'title': '문법 L1', 'subtitle': '', 'file': 'grammar/lesson1.json'}];
    }
    final out = <GrammarStep>[];
    for (final e in raw.whereType<Map>()) {
      final n = (e['step'] as num?)?.toInt() ?? 0;
      final file = '${e['file'] ?? ''}';
      if (n < 1 || file.isEmpty) continue;
      try {
        final j = json.decode(await _load(file)) as Map<String, dynamic>;
        if (!hasContent(j)) continue;
        final title = '${e['title'] ?? ''}'.trim();
        out.add(GrammarStep(n, title.isEmpty ? '${j['title'] ?? 'L$n'}' : title, '${e['subtitle'] ?? j['subtitle'] ?? ''}', file));
      } catch (_) {
        // 파일이 아직 없음(앱에도 서버에도) — 숨김
      }
    }
    out.sort((a, b) => a.step.compareTo(b.step));
    return out;
  }

  /// 스텝 내용(JSON).
  static Future<Map<String, dynamic>> content(String file) async => json.decode(await _load(file)) as Map<String, dynamic>;
}
