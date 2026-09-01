import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'cedict_service.dart';
import 'pinyin_util.dart';

/// 인덱싱된 문장 하나. 앱의 모든 문장 소스(문법 예문·대화)를 통합한 단위.
class IndexedSentence {
  final String zh;
  final String? pinyin;
  final String? ko;
  final String source; // 예: '문법 L1', '회화 (LCCC)', '대화 L1'
  final String? speaker; // 'A'(남) | 'B'(여) | null
  final List<Map<String, dynamic>> tokens; // [{text, compound}]

  IndexedSentence({
    required this.zh,
    this.pinyin,
    this.ko,
    required this.source,
    this.speaker,
    required this.tokens,
  });
}

/// 검색 결과의 청크 하나 + 그 청크가 등장하는 문장들.
class ChunkHit {
  final String chunk;
  final String? pinyin;
  final String? ko;
  final List<String> meanings; // CC-CEDICT
  final List<IndexedSentence> sentences;

  ChunkHit({
    required this.chunk,
    this.pinyin,
    this.ko,
    this.meanings = const [],
    required this.sentences,
  });
}

/// 앱의 모든 문장을 청크(단어) 기준으로 역인덱싱해 검색 제공.
///
/// - 토큰이 있는 문장(문법 예문)은 그대로 사용.
/// - 없는 문장(대화)은 CC-CEDICT 최장일치(4→2자)로 분절.
/// - 검색: 한자 / 병음(성조 무시: keai→可爱) / 한국어 뜻.
class ChunkIndexService {
  ChunkIndexService._();
  static final ChunkIndexService instance = ChunkIndexService._();

  final List<IndexedSentence> _sentences = [];
  final Map<String, List<int>> _byChunk = {}; // chunk → sentence indices
  final Map<String, Map<String, dynamic>> _chunkDict = {}; // 문법 chunks dict 병합
  bool _loaded = false;
  bool _loading = false;

  Map<String, Map<String, dynamic>> get chunkDict => _chunkDict;
  int get sentenceCount => _sentences.length;
  int get chunkCount => _byChunk.length;

  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    _loading = true;
    await CedictService.instance.ensureLoaded();

    await _loadGrammarLessons();
    await _loadDialogues();
    await _loadConvLccc();

    _buildIndex();
    _loaded = true;
    _loading = false;
  }

  Future<void> _loadGrammarLessons() async {
    for (final n in [1, 2]) {
      final Map<String, dynamic> data;
      try {
        final raw = await rootBundle.loadString('assets/data/grammar/lesson$n.json');
        data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final chunks = data['chunks'];
      if (chunks is Map) {
        for (final e in chunks.entries) {
          if (e.value is Map<String, dynamic>) {
            _chunkDict[e.key as String] = e.value as Map<String, dynamic>;
          }
        }
      }
      final patterns = (data['patterns'] as List?) ?? [];
      for (final p in patterns) {
        final examples = ((p as Map)['examples'] as List?) ?? [];
        for (final ex in examples) {
          final m = ex as Map<String, dynamic>;
          final zh = m['zh'] as String?;
          if (zh == null || zh.isEmpty) continue;
          final rawTokens = (m['tokens'] as List?)
              ?.whereType<Map>()
              .map((t) => t.cast<String, dynamic>())
              .toList();
          _sentences.add(IndexedSentence(
            zh: zh,
            pinyin: m['pinyin'] as String?,
            ko: m['ko'] as String?,
            source: '문법 L$n',
            tokens: rawTokens ?? _segment(zh),
          ));
        }
      }
    }
  }

  Future<void> _loadDialogues() async {
    for (final dialect in ['north', 'south']) {
      for (final level in ['L1', 'L2', 'L3', 'L4']) {
        final Map<String, dynamic> data;
        try {
          final raw =
              await rootBundle.loadString('assets/data/dialogues/$dialect/$level.json');
          data = json.decode(raw) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        final episodes = (data['episodes'] as List?) ?? [];
        for (final ep in episodes) {
          final turns = ((ep as Map)['turns'] as List?) ?? [];
          for (final t in turns) {
            final m = t as Map<String, dynamic>;
            final zh = m['zh'] as String?;
            if (zh == null || zh.isEmpty) continue;
            _sentences.add(IndexedSentence(
              zh: zh,
              pinyin: m['pinyin'] as String?,
              ko: m['ko'] as String?,
              source: '대화 $level${dialect == 'south' ? ' (남방)' : ''}',
              speaker: m['speaker'] as String?,
              tokens: _segment(zh),
            ));
          }
        }
      }
    }
  }

  Future<void> _loadConvLccc() async {
    final Map<String, dynamic> data;
    try {
      final raw = await rootBundle.loadString('assets/data/dialogues/conv_lccc.json');
      data = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final dialogues = (data['dialogues'] as List?) ?? [];
    for (final d in dialogues) {
      final m = d as Map<String, dynamic>;
      final label = m['category_label'] as String?;
      final turns = (m['turns'] as List?) ?? [];
      for (final t in turns) {
        final tm = t as Map<String, dynamic>;
        final zh = tm['zh'] as String?;
        if (zh == null || zh.isEmpty) continue;
        _sentences.add(IndexedSentence(
          zh: zh,
          pinyin: tm['pinyin'] as String?,
          ko: tm['ko'] as String?,
          source: label == null ? '회화 (LCCC)' : '회화 · $label',
          speaker: tm['speaker'] as String?,
          tokens: _segment(zh),
        ));
      }
    }
  }

  bool _isCjk(int code) => code >= 0x4E00 && code <= 0x9FFF;

  /// 외부용: 문장을 청크 토큰으로 분절. ensureLoaded 이후 사용.
  List<Map<String, dynamic>> tokensFor(String zh) => _segment(zh);

  /// CC-CEDICT + 문법 청크 사전 기준 최장일치 분절 (4→2자, 없으면 1자).
  List<Map<String, dynamic>> _segment(String zh) {
    final chars = zh.runes.map(String.fromCharCode).toList();
    final tokens = <Map<String, dynamic>>[];
    var i = 0;
    while (i < chars.length) {
      if (!_isCjk(chars[i].codeUnitAt(0))) {
        tokens.add({'text': chars[i], 'compound': false});
        i++;
        continue;
      }
      var matched = false;
      for (var len = 4; len >= 2; len--) {
        if (i + len > chars.length) continue;
        final cand = chars.sublist(i, i + len).join();
        if (cand.runes.any((c) => !_isCjk(c))) continue;
        if (CedictService.instance.lookup(cand) != null || _chunkDict.containsKey(cand)) {
          tokens.add({'text': cand, 'compound': true});
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        tokens.add({'text': chars[i], 'compound': false});
        i++;
      }
    }
    return tokens;
  }

  void _buildIndex() {
    for (var si = 0; si < _sentences.length; si++) {
      final seen = <String>{};
      for (final t in _sentences[si].tokens) {
        final txt = t['text'] as String? ?? '';
        if (txt.isEmpty || !_isCjk(txt.codeUnitAt(0))) continue;
        if (seen.contains(txt)) continue;
        seen.add(txt);
        _byChunk.putIfAbsent(txt, () => []).add(si);
      }
    }
  }

  ChunkHit _hitFor(String chunk) {
    final cedict = CedictService.instance.lookup(chunk);
    final dictData = _chunkDict[chunk];
    return ChunkHit(
      chunk: chunk,
      pinyin: cedict?.pinyin ?? dictData?['pinyin'] as String?,
      ko: dictData?['ko'] as String?,
      meanings: cedict?.meanings ??
          (dictData?['meanings'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      sentences: (_byChunk[chunk] ?? []).map((i) => _sentences[i]).toList(),
    );
  }

  static final _hangul = RegExp(r'[가-힣]');
  static final _cjk = RegExp(r'[一-鿿]');

  /// 청크 검색. 한자·병음·한국어 자동 판별.
  List<ChunkHit> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];

    final matches = <String>{};
    if (_cjk.hasMatch(q)) {
      // 한자: 청크에 부분일치
      for (final chunk in _byChunk.keys) {
        if (chunk.contains(q) || q.contains(chunk) && chunk.length >= 2) {
          matches.add(chunk);
        }
      }
    } else if (_hangul.hasMatch(q)) {
      // 한국어: 청크 뜻(ko) 부분일치
      for (final chunk in _byChunk.keys) {
        final ko = _chunkDict[chunk]?['ko'] as String?;
        if (ko != null && ko.contains(q)) matches.add(chunk);
      }
    } else {
      // 병음: 성조·공백·아포스트로피 무시 prefix/전체 일치
      final nq = PinyinUtil.stripTones(q).replaceAll(RegExp(r"[^a-zü]"), '');
      if (nq.isEmpty) return [];
      for (final chunk in _byChunk.keys) {
        final py = CedictService.instance.lookup(chunk)?.pinyin ??
            _chunkDict[chunk]?['pinyin'] as String?;
        if (py == null) continue;
        final np = PinyinUtil.stripTones(py).replaceAll(RegExp(r"[^a-zü]"), '');
        if (np == nq || np.startsWith(nq)) matches.add(chunk);
      }
    }

    final hits = matches.map(_hitFor).toList()
      // 다(多)문장 청크 우선, 그다음 짧은 청크 우선
      ..sort((a, b) {
        final c = b.sentences.length.compareTo(a.sentences.length);
        if (c != 0) return c;
        return a.chunk.length.compareTo(b.chunk.length);
      });
    return hits;
  }

  /// 한국어 질의가 청크 뜻에 없을 때 문장 번역(ko) 직접 검색 폴백.
  List<IndexedSentence> searchSentencesByKo(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    return _sentences
        .where((s) => s.ko != null && s.ko!.contains(q))
        .toList(growable: false);
  }
}
