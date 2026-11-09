import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/prefs.dart';

import '../review/review_service.dart';
import 'dialogue_service.dart';
import 'review_cards.dart';

/// 성과 기록·집계 — 일본어앱 `achievement_service.dart` 를 옮김(시안 02 §5, 2026-11-02).
///
/// **센다**: 편 완주(「모든 문장 듣기」 끝까지) · 라이트너 단계/졸업(ReviewService) · 핵심 표현(그림 카드 맞음/틀림) · 한자 팝업으로 본 글자 수 · 빈도 커버율.
/// **안 센다**: 앱 오픈·스트릭·포인트·순위. 저장은 Prefs `achievements_v1`(JSON 하나).
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();
  static const _key = 'achievements_v1';

  final Map<String, String> _episodes = {}; // 편 id → 완주 날짜(yyyy-mm-dd, 처음)
  final Set<String> _kanji = {}; // 팝업으로 본 한자
  final Map<String, List<int>> _cards = {}; // 편 id → [맞음, 전체] (마지막 세션)
  final Map<String, Map<String, int>> _daily = {}; // 날짜 → {episodes, cards, kanji}
  final ValueNotifier<int> changes = ValueNotifier(0);
  bool _loaded = false;
  Map<String, double>? _freq; // 단어 → 빈도(0~1)

  String get today => _ymd(DateTime.now());
  static String _ymd(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = (await Prefs.getInstance()).getString(_key);
      if (raw != null) {
        final j = json.decode(raw) as Map<String, dynamic>;
        (j['episodes'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _episodes[k] = v.toString());
        _kanji.addAll((j['kanji'] as List? ?? const []).cast<String>());
        (j['cards'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _cards[k] = (v as List).cast<int>());
        (j['daily'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _daily[k] = (v as Map).map((a, b) => MapEntry(a.toString(), (b as num).toInt())));
      }
    } catch (e) {
      debugPrint('Achievement: load 실패 $e');
    }
    _loaded = true;
  }

  Future<void> _save() async {
    changes.value++;
    final data = json.encode({'episodes': _episodes, 'kanji': _kanji.toList(), 'cards': _cards, 'daily': _daily});
    (await Prefs.getInstance()).setString(_key, data);
  }

  void _bump(String what, [int n = 1]) {
    final d = _daily.putIfAbsent(today, () => {});
    d[what] = (d[what] ?? 0) + n;
  }

  // ── 이벤트 ──────────────────────────────────────────
  /// 편을 끝까지 들었다. 처음 완주한 날만 기록(반복 횟수는 세지 않는다).
  Future<bool> markEpisodeDone(String id) async {
    await load();
    final first = !_episodes.containsKey(id);
    if (first) {
      _episodes[id] = today;
      _bump('episodes');
      await _save();
    }
    return first;
  }

  /// 한자 팝업을 열어 본 글자.
  Future<void> markHanziSeen(String ch) async {
    await load();
    if (_kanji.add(ch)) {
      _bump('kanji');
      await _save();
    }
  }

  /// 그림 카드 세션 결과(편별 마지막 세션).
  Future<void> markCards(String episodeId, int right, int total) async {
    await load();
    _cards[episodeId] = [right, total];
    _bump('cards', right);
    await _save();
  }

  // ── 집계 ──────────────────────────────────────────
  bool isDone(String id) => _episodes.containsKey(id);
  int get episodesDone => _episodes.length;
  int get hanziSeen => _kanji.length;
  List<int>? cardsOf(String id) => _cards[id];

  /// 주제·레벨별 완주 수 / 전체 수.
  (int, int) progress({required String island, required String region}) {
    final all = DialogueService.instance.list(region: region, island: island);
    final done = all.where((d) => _episodes.containsKey(d.id)).length;
    return (done, all.length);
  }

  /// 최근 7일(오늘 포함, 오래된 날부터) 완주 편 수.
  List<(String, int)> week() {
    final now = DateTime.now();
    return [for (var i = 6; i >= 0; i--) (_ymd(now.subtract(Duration(days: i))), _daily[_ymd(now.subtract(Duration(days: i)))]?['episodes'] ?? 0)];
  }

  Map<String, int> get thisWeek {
    final out = {'episodes': 0, 'cards': 0, 'kanji': 0};
    for (final (d, _) in week()) {
      final m = _daily[d];
      if (m == null) continue;
      for (final k in out.keys) {
        out[k] = out[k]! + (m[k] ?? 0);
      }
    }
    return out;
  }

  /// 라이트너 분포(1~7단계, 8 = 졸업).
  Map<int, int> leitnerLevels() {
    final m = <int, int>{};
    for (final it in ReviewService.instance.items.values) {
      if (it.level <= 0) continue;
      final lv = it.level >= 8 ? 8 : it.level;
      m[lv] = (m[lv] ?? 0) + 1;
    }
    return m;
  }

  /// 중국어 빈도 절벽(`lang_zh_with_regions.csv` 의 R1~R4 끝 순위).
  static const cliffs = [433, 616, 1238, 2500];

  /// 빈도 커버율: 라이트너 3단계 이상(4일 이상 기억)인 단어 카드가 중국어 사용 빈도의 몇 %를 덮는가 + 다음 절벽까지 남은 단어 수.
  Future<({double pct, int known, int nextCliff, int toNext})> coverage() async {
    await _loadFreq();
    await ReviewCards.instance.ensureLoaded();
    final fronts = <String, String>{}; // 카드 id → 중국어
    for (final c in ReviewCards.instance.byId.values) {
      fronts[c.id] = c.zh;
    }
    double sum = 0;
    final knownWords = <String>{};
    for (final it in ReviewService.instance.items.values) {
      if (it.level < 3) continue;
      final w = fronts[it.id];
      if (w == null || knownWords.contains(w)) continue;
      final f = _freq![w];
      if (f == null) continue;
      knownWords.add(w);
      sum += f;
    }
    final next = cliffs.firstWhere((c) => c > knownWords.length, orElse: () => 2500);
    return (pct: sum * 100, known: knownWords.length, nextCliff: next, toNext: (next - knownWords.length).clamp(0, 9999));
  }

  Future<void> _loadFreq() async {
    if (_freq != null) return;
    final freq = <String, double>{};
    try {
      final raw = await rootBundle.loadString(assetPath('assets/data/freq/lang_zh_with_regions.csv'));
      for (final line in raw.split('\n').skip(1)) {
        final p = line.trim().split(',');
        if (p.length < 4) continue;
        final w = p[1];
        freq[w] = double.tryParse(p[2]) ?? 0;
      }
    } catch (e) {
      debugPrint('Achievement: 빈도표 실패 $e');
    }
    _freq = freq;
  }

  /// 이번 주 한 줄(숫자보다 문장).
  String weekSentence() {
    final w = thisWeek;
    final e = w['episodes'] ?? 0, c = w['cards'] ?? 0, k = w['kanji'] ?? 0;
    if (e == 0 && c == 0 && k == 0) return '';
    // 가장 많이 완주한 주제
    String? bestIsland;
    var best = 0;
    final counts = <String, int>{};
    for (final (d, _) in week()) {
      for (final e in _episodes.entries) {
        if (e.value != d) continue;
        final dlg = DialogueService.instance.byId(e.key);
        if (dlg == null) continue;
        counts[dlg.island] = (counts[dlg.island] ?? 0) + 1;
      }
    }
    counts.forEach((k, v) {
      if (v > best) {
        best = v;
        bestIsland = k;
      }
    });
    return bestIsland == null ? '' : bestIsland!;
  }
}
