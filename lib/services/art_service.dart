import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'content_sync.dart';
import 'learner_prefs.dart';

/// 단어 그림(talkverse.uk 공용 그림 저장소) — 일본어앱 `art_service.dart` 를 옮김(2026-11-02).
///
/// talkverse.uk 세션이 Cloudflare 에 올린 공개 API(인증 없음):
/// - 목록 `GET https://auth.talkverse.uk/art/zh/manifest?level=R1` (level 생략 = 전체, word = 중국어 간체 단어)
///   → `{lang, level, count, base, items:[{id, rank, level, word, reading, ko, en, pos, key_1024, key_512}]}`
/// - 그림 = `base + key` (512·1024 webp, 1년 캐시). 한·중·일은 같은 그림을 쓰고 앱이 톤만 바꾼다.
/// 매니페스트는 SharedPreferences 에 하루 캐시하고, 없거나 비어 있으면(2026-11-02 현재 zh 는 0개) 그림 없이 카드가 그대로 나온다.
class ArtService {
  ArtService._();
  static final ArtService instance = ArtService._();

  static const manifestUrl = 'https://auth.talkverse.uk/art/zh/manifest';
  static const _prefKey = 'art_manifest_zh_v1';
  static const _prefAt = 'art_manifest_zh_at';
  static const _ttl = Duration(hours: 24);

  String _base = '';
  final Map<String, String> _byWord = {}; // word → key_512
  final Map<int, String> _byRank = {}; // rank → key_512
  final Map<String, int> _rankByWord = {}; // word → rank
  Future<void>? _loading;
  bool get isLoaded => _byWord.isNotEmpty;

  /// 단어(표제어) 또는 빈도 순위로 512px 그림 주소. 없으면 null.
  Future<String?> urlFor(String word, {int? rank}) async {
    await _ensure();
    final key = _byWord[word] ?? (rank != null ? _byRank[rank] : null);
    if (key == null || _base.isEmpty) return null;
    return _base.endsWith('/') ? '$_base$key' : '$_base/$key';
  }

  /// 이 한자를 품은 단어의 그림(한자 팝업용): 빈도 순위가 가장 높은 단어 하나. 없으면 null.
  Future<MapEntry<String, String>?> wordArtForHanzi(String ch) async {
    await _ensure();
    if (_base.isEmpty) return null;
    String? bestWord;
    int bestRank = 1 << 30;
    for (final e in _byWord.entries) {
      if (!e.key.contains(ch)) continue;
      final r = _rankByWord[e.key] ?? (1 << 29);
      if (r < bestRank) {
        bestRank = r;
        bestWord = e.key;
      }
    }
    if (bestWord == null) return null;
    final key = _byWord[bestWord]!;
    return MapEntry(bestWord, _base.endsWith('/') ? '$_base$key' : '$_base/$key');
  }

  /// 문장 안에 들어 있는 그림 단어(2자 이상) 중 가장 긴 것의 그림. 새 단어·핵심 표현에 그림이 없을 때의 보조.
  Future<MapEntry<String, String>?> urlInText(String text) async {
    await _ensure();
    if (_base.isEmpty || text.isEmpty) return null;
    String? best;
    for (final w in _byWord.keys) {
      if (w.length < 2 || !text.contains(w)) continue;
      if (best == null || w.length > best.length) best = w;
    }
    if (best == null) return null;
    final key = _byWord[best]!;
    return MapEntry(best, _base.endsWith('/') ? '$_base$key' : '$_base/$key');
  }

  /// 로드 없이 즉시 조회(이미 받아 둔 경우만).
  String? urlForSync(String word, {int? rank}) {
    final key = _byWord[word] ?? (rank != null ? _byRank[rank] : null);
    if (key == null || _base.isEmpty) return null;
    return _base.endsWith('/') ? '$_base$key' : '$_base/$key';
  }

  Future<void> _ensure() => _loading ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final at = prefs.getInt(_prefAt) ?? 0;
    final cached = prefs.getString(_prefKey);
    final fresh = DateTime.now().millisecondsSinceEpoch - at < _ttl.inMilliseconds;
    if (cached != null && fresh && _apply(cached)) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(manifestUrl));
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        if (_apply(body)) {
          await prefs.setString(_prefKey, body);
          await prefs.setInt(_prefAt, DateTime.now().millisecondsSinceEpoch);
          client.close();
          return;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('ArtService: manifest 실패 $e');
    }
    if (cached != null) _apply(cached); // 오래된 캐시라도 쓴다
  }

  bool _apply(String body) {
    try {
      final j = json.decode(body) as Map<String, dynamic>;
      final base = j['base'] as String? ?? '';
      final items = j['items'] as List<dynamic>? ?? const [];
      if (base.isEmpty || items.isEmpty) return false;
      _base = base;
      _byWord.clear();
      _byRank.clear();
      _rankByWord.clear();
      for (final it in items) {
        final m = it as Map<String, dynamic>;
        final key = m['key_512'] as String? ?? m['key_1024'] as String?;
        if (key == null) continue;
        final w = m['word'] as String?;
        if (w != null && w.isNotEmpty) _byWord[w] = key;
        final r = m['rank'];
        final rank = r is int ? r : (r is String ? int.tryParse(r) : null);
        if (rank != null) {
          _byRank[rank] = key;
          if (w != null && w.isNotEmpty) _rankByWord[w] = rank;
        }
      }
      return _byWord.isNotEmpty;
    } catch (e) {
      debugPrint('ArtService: manifest 파싱 실패 $e');
      return false;
    }
  }
}

/// 회화 장면 컷 — A·B 대화 한 쌍 = 컷 1장(2026-11-02). talkverse.uk 가 저장소 `talkverse_art/scene/zh/<편id>/cut<N>.jpg` 를 올려
/// `GET /art/zh/scene/manifest` → {base, items:[{episode, cut, key_1168, key_584}]} 로 준다. 없거나 실패하면 null(화면은 단어 그림·장면 카드로).
class SceneArtService {
  SceneArtService._();
  static final SceneArtService instance = SceneArtService._();

  static const manifestUrl = 'https://auth.talkverse.uk/art/zh/scene/manifest';
  static const _prefKey = 'scene_manifest_zh_v1';
  static const _prefAt = 'scene_manifest_zh_at';
  static const _ttl = Duration(hours: 1); // 컷이 계속 늘어나므로 자주 갱신

  final Map<String, String> _byCut = {}; // '<편id>#<컷>' → key
  String _base = '';
  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  /// 턴 번호 순서(0부터)로 컷을 찾는다: 턴 0·1 = 컷 1, 턴 2·3 = 컷 2 …
  /// 학습자가 여자로 설정돼 있으면 여자판 컷(`<편id>_f`)을 먼저 — 없으면 기본 컷(2026-11-04).
  Future<String?> urlFor(String episode, int turnIndex) async {
    final n = turnIndex ~/ 2 + 1;
    if (LearnerPrefs.isFemale) {
      final f = await _cut('${episode}_f', n);
      if (f != null) return f;
    }
    return _cut(episode, n);
  }

  Future<String?> _cut(String episode, int n) async {
    // 시작 때 받아 둔 전체 장면 매니페스트(ContentSync) — 편마다 네트워크를 타지 않는다
    final idx = ContentSync.instance.sceneIndex[episode];
    if (idx != null && idx.isNotEmpty) {
      final k = idx[n];
      return k == null ? null : '${ContentSync.instance.base}/$k';
    }
    await ensureLoaded();
    final key = _byCut['$episode#$n'];
    return key == null ? null : _base + key;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final at = prefs.getInt(_prefAt) ?? 0;
    final cached = prefs.getString(_prefKey);
    final fresh = DateTime.now().millisecondsSinceEpoch - at < _ttl.inMilliseconds;
    if (cached != null && fresh && _apply(cached)) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final res = await (await client.getUrl(Uri.parse(manifestUrl))).close().timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        if (_apply(body)) {
          await prefs.setString(_prefKey, body);
          await prefs.setInt(_prefAt, DateTime.now().millisecondsSinceEpoch);
          client.close();
          return;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('SceneArtService: manifest 실패 $e');
    }
    if (cached != null) _apply(cached);
  }

  bool _apply(String body) {
    try {
      final j = json.decode(body) as Map<String, dynamic>;
      final base = j['base'] as String? ?? '';
      final items = j['items'] as List<dynamic>? ?? const [];
      if (base.isEmpty || items.isEmpty) return false;
      _base = base;
      _byCut.clear();
      for (final it in items) {
        final m = it as Map<String, dynamic>;
        final key = m['key_1168'] as String? ?? m['key_584'] as String?;
        final ep = m['episode'] as String?;
        final cut = m['cut'];
        if (key == null || ep == null || cut == null) continue;
        _byCut['$ep#$cut'] = key;
      }
      return _byCut.isNotEmpty;
    } catch (e) {
      debugPrint('SceneArtService: manifest 파싱 실패 $e');
      return false;
    }
  }
}
