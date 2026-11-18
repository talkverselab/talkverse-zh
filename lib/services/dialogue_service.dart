import 'dart:async';
import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../core/prefs.dart';

import '../core/l10n.dart';
import 'learner_prefs.dart';
import 'pinyin_hangul.dart';
import 'script_sync.dart';

/// 새 회화(R0~R4, 주제별 JSON) 로더 — 일본어앱 구조를 옮김(2026-11-02).
///
/// 파일: `assets/data/dialogues/R<레벨>/<주제>/<편id>.json` (`tool/convert_dialogues_r.py` 가 만든 모양).
/// 턴 필드: `zh`(목표어) · `pinyin`(성조 병음) · `ko`. 한글 독음 `rd` 는 JSON 에 없으면 병음에서 만든다([PinyinHangul]).
/// 레벨: R0 왕초보 · R1 초보 · R2 중급 · R3 고급 · R4 최상급. 사용자 레벨 모드(`dialogue_level`): 기본 R1, "너무 힘들면" R0.
/// 지금은 R0·R1 이 비어 있어(새 회화 작성 전) 「오늘의 컷」은 편이 있는 가장 낮은 레벨부터 보여 준다([startLevel]).
/// 문장 내용어 한 개: 표면형(文中)·기본형(사전형, 중국어는 대개 같음)·병음 읽기. `tools/add_lemmas.py` 가 채운다(2026-11-04).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A(학습자)·B·C·D
  final String zh;
  final String pinyin;
  final String rd; // 한글 독음
  final String ko;
  final String note;
  final List<String> tags;
  final List<String> newWords;
  final String? at; // 채팅 시각
  final String? stamp; // 채팅 스탬프 이모지
  final bool bubble; // 채팅 말풍선 표시
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어(표면형·기본형·병음) — 단어장 연결(2026-11-04)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.zh,
    required this.pinyin,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    required this.newWords,
    this.at,
    this.stamp,
    this.bubble = false,
    this.art,
    this.lemmas = const [],
  });
  factory DialogueTurn.fromJson(Map<String, dynamic> j) {
    final pinyin = j['pinyin'] as String? ?? '';
    final rd = j['rd'] as String?;
    return DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        zh: j['zh'] as String? ?? '',
        pinyin: pinyin,
        rd: (rd == null || rd.isEmpty) ? PinyinHangul.convert(pinyin) : rd,
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        newWords: (j['new'] as List?)?.cast<String>() ?? const [],
        at: j['at'] as String?,
        stamp: j['stamp'] as String?,
        bubble: j['ui'] == 'bubble',
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );
  }

  /// 그림 조회용 핵심 단어 후보: new → expr 태그 → 없음.
  List<String> get pictureWords {
    final out = <String>[...newWords];
    for (final t in tags) {
      if (t.startsWith('expr:')) out.add(t.substring(5).replaceAll(RegExp(r'[?？!！〜~…]'), ''));
    }
    return out;
  }
}

class Dialogue {
  final String id;
  final String region; // R0..R4
  final String island; // survival friends love life travel culture work study
  final String kind; // survival short long chat
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final String register;
  final int twist;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? approved;
  final String? art; // 편 대표 장면 그림 URL(나중에 채움)
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.kind,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.register,
    required this.twist,
    required this.expressions,
    required this.turns,
    this.approved,
    this.art,
  });
  factory Dialogue.fromJson(Map<String, dynamic> j) => Dialogue(
        id: j['id'] as String,
        region: j['region'] as String? ?? 'R1',
        island: j['island'] as String? ?? '',
        kind: j['kind'] as String? ?? 'long',
        title: j['title'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '💬',
        scene: j['scene'] as String? ?? '',
        speakers: ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        register: j['register'] as String? ?? '',
        twist: j['twist'] as int? ?? 0,
        expressions: (j['expressions'] as List?)?.cast<String>() ?? const [],
        turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>)).toList(),
        approved: j['approved'] as String?,
        art: j['art'] as String?,
      );
  bool get isChat => kind == 'chat';
  /// 화자 표시 이름: `{name}`(학습자 자리) → 「나」, 그 밖의 중괄호는 뗀다.
  /// 화면에 보일 장면 설명 — 원고의 「학습자」를 이름(없으면 「나」)으로(일본어앱 빌드 111과 같음, 사용자 지시 2026-11-18 「일본어 앱만큼」).
  String get sceneShown => scene.contains('학습자') ? scene.replaceAllMapped(RegExp(r'학습자(이|가|은|는|을|를|와|과|의|에게|도|만)?'), (m) => _me(m.group(1))) : scene;

  /// 학습자 이름 + 그 이름에 맞는 조사. 이름이 없으면 「나」(나가→내가).
  String _me(String? j) {
    final n = LearnerPrefs.name.value.trim();
    if (n.isEmpty) {
      if (j == '가' || j == '이') return '내가';
      if (j == '의') return '나의';
      return '나${j == null ? '' : const {'은': '는', '을': '를', '과': '와'}[j] ?? j}';
    }
    if (j == null) return n;
    final c = n.codeUnitAt(n.length - 1);
    final hangul = c >= 0xAC00 && c <= 0xD7A3;
    final batchim = hangul ? (c - 0xAC00) % 28 != 0 : false;
    const pair = {'이': ['이', '가'], '가': ['이', '가'], '은': ['은', '는'], '는': ['은', '는'], '을': ['을', '를'], '를': ['을', '를'], '과': ['과', '와'], '와': ['과', '와']};
    final p = pair[j];
    if (p == null) return '$n$j';
    if (!hangul) return '$n${p[1] == '가' ? '이(가)' : p[1] == '는' ? '은(는)' : p[1] == '를' ? '을(를)' : '와(과)'}';
    return '$n${batchim ? p[0] : p[1]}';
  }

  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : tr('나');
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }
  /// 편 순서 키: survival → a → b → c, 번호 순.
  String get orderKey {
    final m = RegExp(r'_([abcs])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '직장', // '일'(요일 키)과 겹치지 않게
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4'];
  static const levelKo = {'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _prefLevel = 'dialogue_level';
  static const _prefLast = 'dialogue_last';
  String? _lastOpened;
  /// 마지막으로 연 편(홈 「이어서 읽기」).
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  final Map<String, Dialogue> _byId = {};
  bool _loaded = false;
  String _level = 'R1';

  /// 사용자 레벨 모드(R0 왕초보 / R1 초보). 기본 R1.
  String get level => _level;

  /// 홈이 처음 보여 줄 레벨: 사용자 모드에 편이 있으면 그것, 없으면 편이 있는 가장 낮은 레벨(없으면 모드 그대로).
  String get startLevel {
    if (count(_level) > 0) return _level;
    for (final lv in levels) {
      if (count(lv) > 0) return lv;
    }
    return _level;
  }
  Future<void> setLevel(String lv) async {
    _level = lv;
    (await Prefs.getInstance()).setString(_prefLevel, lv);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    // 편 JSON 을 읽는 동안 다른 화면이 또 부르면 같은 작업을 기다린다
    await (_loading ??= _load());
  }

  Future<void>? _loading;

  /// 시험용: 편 목록을 직접 넣는다(애셋을 읽지 않음).
  @visibleForTesting
  void debugSetDialogues(List<Dialogue> list) {
    _byId
      ..clear()
      ..addEntries(list.map((d) => MapEntry(d.id, d)));
    _loaded = true;
  }

  Future<void> _load() async {
    final prefs = await Prefs.getInstance();
    _level = prefs.getString(_prefLevel) ?? 'R1';
    _lastOpened = prefs.getString(_prefLast);
    await _readAll();
    _loaded = true;
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로) — 2026-11-18, docs/CONTENT_SYNC.md 원고 받기
    unawaited(ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    }));
  }

  /// 원고가 서버 판으로 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// 앱 안 편 + 서버에서 받은 새 편을 읽는다. 각 파일은 덮어쓴 판이 있으면 그것([ScriptSync]).
  Future<void> _readAll() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final pat = RegExp(r'^assets/data/dialogues/R[0-4]/[^/]+/[^/]+\.json$');
    // 매니페스트 키는 통합 앱이면 packages/chinese_universe/ 가 붙어 있다 — 접두를 떼고 견준다
    final rels = <String>{
      for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length),
      ...sync.added.where((p) => pat.hasMatch('assets/data/$p')),
    }..removeAll(sync.removed);
    final next = <String, Dialogue>{};
    for (final rel in rels) {
      try {
        final j = json.decode(await sync.load(rel)) as Map<String, dynamic>;
        if (j['draft'] == true) continue; // 초안(Grok 재작성·검수 전)은 앱에 안 보인다 — 2026-11-07
        final d = Dialogue.fromJson(j);
        if (d.turns.isNotEmpty) next[d.id] = d;
      } catch (_) {}
    }
    _byId
      ..clear()
      ..addAll(next);
  }

  bool get isLoaded => _loaded;

  Dialogue? byId(String id) => _byId[id];
  List<Dialogue> get all => _byId.values.toList();

  /// 레벨·주제의 편 목록(편 순서대로). R0/R1 은 사용자 모드로 묶어서 본다.
  List<Dialogue> list({String? region, String? island}) {
    final r = region ?? _level;
    final out = _byId.values.where((d) => d.region == r && (island == null || d.island == island)).toList();
    out.sort((a, b) => a.orderKey.compareTo(b.orderKey));
    return out;
  }

  /// 레벨별 주제 목록(편이 있는 주제만, 고정 순서).
  List<String> islandsOf(String region) {
    final has = _byId.values.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _byId.values.where((d) => d.region == region).length;
}
