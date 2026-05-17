import 'package:flutter/services.dart' show rootBundle;

import 'pinyin_util.dart';

class CedictEntry {
  final String trad;
  final String simp;
  final String pinyin; // 이미 변환된 toned pinyin
  final List<String> meanings;
  CedictEntry({
    required this.trad,
    required this.simp,
    required this.pinyin,
    required this.meanings,
  });
}

/// CC-CEDICT 사전 — lazy load + simp 기준 lookup.
class CedictService {
  CedictService._();
  static final CedictService instance = CedictService._();

  final Map<String, CedictEntry> _bySimp = {};
  bool _loaded = false;
  bool _loading = false;

  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    _loading = true;
    final raw = await rootBundle.loadString('assets/data/hsk/cedict.txt');
    final reg = RegExp(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$');
    for (final line in raw.split('\n')) {
      if (line.startsWith('#') || line.isEmpty) continue;
      final m = reg.firstMatch(line.trimRight());
      if (m == null) continue;
      final simp = m.group(2)!;
      // 첫 lookup 만 보존 (동음이의 시 첫 정의)
      _bySimp.putIfAbsent(
        simp,
        () => CedictEntry(
          trad: m.group(1)!,
          simp: simp,
          pinyin: PinyinUtil.toTonedPinyin(m.group(3)!),
          meanings: m.group(4)!.split('/').where((s) => s.isNotEmpty).toList(),
        ),
      );
    }
    _loaded = true;
    _loading = false;
  }

  CedictEntry? lookup(String simp) => _bySimp[simp];

  int get size => _bySimp.length;
}
