import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HanziInfo {
  final String char;
  final String? meaning;
  final String? koHun; // 한국 훈음 (예: '셀 계')
  final String? phonetic;
  final String? phoneticPinyin;
  final String? semantic;

  HanziInfo({
    required this.char,
    this.meaning,
    this.koHun,
    this.phonetic,
    this.phoneticPinyin,
    this.semantic,
  });

  bool get isPhonosemantic => phonetic != null && phoneticPinyin != null;

  HanziInfo copyWith({String? koHun}) => HanziInfo(
        char: char,
        meaning: meaning,
        koHun: koHun ?? this.koHun,
        phonetic: phonetic,
        phoneticPinyin: phoneticPinyin,
        semantic: semantic,
      );
}

/// 발음부(声旁) 하나의 요약 정보.
class PhoneticRootInfo {
  final String root;
  final String pinyin; // 번호 성조 표기 (예: 'ma3')
  final String? ko; // 한국 한자음
  final int count;
  PhoneticRootInfo({
    required this.root,
    required this.pinyin,
    this.ko,
    required this.count,
  });
}

class HanziInfoService {
  HanziInfoService._();
  static final HanziInfoService instance = HanziInfoService._();

  Map<String, HanziInfo> _map = {};
  /// 발음부 → 그 발음부를 공유하는 한자 리스트
  Map<String, List<String>> _byPhonetic = {};
  final Map<String, PhoneticRootInfo> _roots = {};
  bool _loaded = false;

  /// 클러스터 크기순 발음부 전체 목록.
  List<PhoneticRootInfo> get allRoots {
    final list = _roots.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  /// HSK1-5 확장 데이터가 커버하는 한자 수.
  int get phonosemCharCount =>
      _byPhonetic.values.fold(0, (s, l) => s + l.length);

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

    // HSK1-5 발음부 확장 데이터 병합 (큐레이션 우선)
    try {
      final extRaw =
          await rootBundle.loadString('assets/data/hanzi/phonetic_ext.json');
      final ext = json.decode(extRaw) as Map<String, dynamic>;
      final chars = (ext['chars'] as Map?)?.cast<String, dynamic>() ?? {};
      chars.forEach((ch, v) {
        if (v is! Map) return;
        final existing = _map[ch];
        if (existing?.phonetic != null) return; // 큐레이션 유지
        final info = HanziInfo(
          char: ch,
          meaning: existing?.meaning,
          phonetic: v['phonetic'] as String?,
          phoneticPinyin: v['phonetic_pinyin'] as String?,
          semantic: existing?.semantic,
        );
        _map[ch] = info;
        if (info.phonetic != null) {
          final list = _byPhonetic.putIfAbsent(info.phonetic!, () => []);
          if (!list.contains(ch)) list.add(ch);
        }
      });
      final roots = (ext['roots'] as Map?)?.cast<String, dynamic>() ?? {};
      roots.forEach((p, v) {
        if (v is! Map) return;
        _roots[p] = PhoneticRootInfo(
          root: p,
          pinyin: (v['pinyin'] as String?) ?? '',
          ko: v['ko'] as String?,
          count: _byPhonetic[p]?.length ?? (v['count'] as int? ?? 0),
        );
      });
    } catch (_) {
      // 확장 데이터 없으면 큐레이션만 사용
      _byPhonetic.forEach((p, l) {
        _roots[p] = PhoneticRootInfo(root: p, pinyin: '', count: l.length);
      });
    }

    // 한국 훈음 (HSK1-5 전수)
    try {
      final koRaw =
          await rootBundle.loadString('assets/data/hanzi/hanzi_ko.json');
      final ko = json.decode(koRaw) as Map<String, dynamic>;
      ko.forEach((ch, v) {
        if (ch.startsWith('_') || v is! String || v.isEmpty) return;
        final existing = _map[ch];
        if (existing != null) {
          _map[ch] = existing.copyWith(koHun: v);
        } else {
          _map[ch] = HanziInfo(char: ch, koHun: v);
        }
      });
    } catch (_) {
      // 훈음 데이터 없으면 생략
    }
    _loaded = true;
  }

  HanziInfo? lookup(String c) => _map[c];

  /// 발음부 X 를 공유하는 모든 한자 (자식들).
  /// X 자체는 family 에 포함되지 않음 (필요 시 호출 측에서 추가).
  List<String> charsSharing(String phonetic) {
    return List<String>.from(_byPhonetic[phonetic] ?? const []);
  }
}
