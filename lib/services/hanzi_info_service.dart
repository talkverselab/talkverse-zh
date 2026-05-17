import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HanziInfo {
  final String char;
  final String? meaning;
  final String? phonetic;
  final String? phoneticPinyin;
  final String? semantic;

  HanziInfo({
    required this.char,
    this.meaning,
    this.phonetic,
    this.phoneticPinyin,
    this.semantic,
  });

  bool get isPhonosemantic => phonetic != null && phoneticPinyin != null;
}

class HanziInfoService {
  HanziInfoService._();
  static final HanziInfoService instance = HanziInfoService._();

  Map<String, HanziInfo> _map = {};
  /// 발음부 → 그 발음부를 공유하는 한자 리스트
  Map<String, List<String>> _byPhonetic = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/grammar/hanzi_info.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final m = <String, HanziInfo>{};
    final family = <String, List<String>>{};
    data.forEach((k, v) {
      if (k.startsWith('_') || v is! Map) return;
      final info = HanziInfo(
        char: k,
        meaning: v['meaning'] as String?,
        phonetic: v['phonetic'] as String?,
        phoneticPinyin: v['phonetic_pinyin'] as String?,
        semantic: v['semantic'] as String?,
      );
      m[k] = info;
      if (info.phonetic != null) {
        family.putIfAbsent(info.phonetic!, () => []).add(k);
      }
    });
    _map = m;
    _byPhonetic = family;
    _loaded = true;
  }

  HanziInfo? lookup(String c) => _map[c];

  /// 발음부 X 를 공유하는 모든 한자 (자식들).
  /// X 자체는 family 에 포함되지 않음 (필요 시 호출 측에서 추가).
  List<String> charsSharing(String phonetic) {
    return List<String>.from(_byPhonetic[phonetic] ?? const []);
  }
}
