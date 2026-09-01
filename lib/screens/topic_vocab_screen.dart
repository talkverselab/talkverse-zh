import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/cedict_service.dart';
import '../services/chunk_index_service.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';

/// co-Trip 여행 중국어 — 주제별 단어장.
class VocabWord {
  final String ko;
  final String zh;
  final String rd; // 한국 독음
  final String? ic; // 아이콘 이모지
  VocabWord(this.ko, this.zh, this.rd, {this.ic});
}

class VocabSection {
  final String title;
  final List<VocabWord> words;
  VocabSection(this.title, this.words);
}

class VocabTheme {
  final String id;
  final String title;
  final String emoji;
  final List<VocabSection> sections;
  VocabTheme(this.id, this.title, this.emoji, this.sections);

  int get wordCount => sections.fold(0, (s, x) => s + x.words.length);
}

class VocabCatalog {
  VocabCatalog._();
  static final VocabCatalog instance = VocabCatalog._();

  final Map<String, List<VocabTheme>> _byAsset = {};

  List<VocabTheme> themesFor(String asset) => _byAsset[asset] ?? const [];

  Future<void> ensureLoaded(String asset) async {
    if (_byAsset.containsKey(asset)) return;
    final raw = await rootBundle.loadString(asset);
    final data = json.decode(raw) as Map<String, dynamic>;
    _byAsset[asset] = [
      for (final t in (data['themes'] as List).whereType<Map>())
        VocabTheme(
          t['id'] as String,
          t['title'] as String,
          t['emoji'] as String? ?? '📚',
          [
            for (final s in (t['sections'] as List).whereType<Map>())
              VocabSection(
                s['title'] as String,
                [
                  for (final w in (s['words'] as List).whereType<Map>())
                    VocabWord(
                      w['ko'] as String? ?? '',
                      w['zh'] as String? ?? '',
                      w['rd'] as String? ?? '',
                      ic: w['ic'] as String?,
                    ),
                ],
              ),
          ],
        ),
    ];
  }

  final Map<String, String> _gloss = {};
  bool _glossLoaded = false;

  /// zh → 한국어 뜻 (여행 단어·표현에서 수집).
  String? koFor(String zh) => _gloss[zh];

  Future<void> ensureGloss() async {
    if (_glossLoaded) return;
    for (final asset in [
      'assets/data/vocab/travel_words.json',
      'assets/data/vocab/travel_expressions.json',
    ]) {
      await ensureLoaded(asset);
      for (final t in themesFor(asset)) {
        for (final s in t.sections) {
          for (final w in s.words) {
            if (w.ko.isNotEmpty) _gloss.putIfAbsent(w.zh, () => w.ko);
          }
        }
      }
    }
    _glossLoaded = true;
  }

  /// 회화 핵심어휘 (FINAL wordset TSV) → 동적 테마.
  Future<VocabTheme> loadCoreWordset() async {
    const key = '_core_wordset';
    if (_byAsset.containsKey(key)) return _byAsset[key]!.first;
    final raw = await rootBundle
        .loadString('assets/data/freq/FINAL_wordset_for_conversation_app.tsv');
    final words = <VocabWord>[];
    final lines = raw.split('\n');
    for (var i = 1; i < lines.length; i++) {
      final c = lines[i].split('\t');
      if (c.length < 3 || c[0].trim().isEmpty) continue;
      words.add(VocabWord('', c[0].trim(), ''));
    }
    final theme = VocabTheme('core', '회화 핵심어휘', '💬',
        [VocabSection('회화 핵심어휘', words)]);
    _byAsset[key] = [theme];
    return theme;
  }
}

/// 주제 목록 화면 — 단어(words)·표현(expressions) 겸용.
class TopicVocabScreen extends StatefulWidget {
  final String title;
  final String asset;
  final bool includeCoreWordset; // 회화 핵심어휘 테마 추가 여부

  const TopicVocabScreen({
    super.key,
    this.title = '주제별 단어',
    this.asset = 'assets/data/vocab/travel_words.json',
    this.includeCoreWordset = false,
  });

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen> {
  bool _loading = true;
  List<VocabTheme> _themes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VocabCatalog.instance.ensureLoaded(widget.asset);
    final list =
        List<VocabTheme>.from(VocabCatalog.instance.themesFor(widget.asset));
    if (widget.includeCoreWordset) {
      list.add(await VocabCatalog.instance.loadCoreWordset());
    }
    if (!mounted) return;
    setState(() {
      _themes = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = _themes;
    final total = themes.fold(0, (s, t) => s + t.wordCount);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('여행 중국어 · $total항목',
                style: TextStyle(
                    color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : Column(
              children: [
                const GreekKeyDivider(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: themes.length,
                    itemBuilder: (context, i) {
                      final t = themes[i];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _ThemeDetailScreen(
                                  theme: t,
                                  gridMode: widget.asset
                                      .contains('travel_words'))),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.xuanZhi,
                            border: Border.all(
                                color: AppColors.zhuHong.withValues(alpha: 0.7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 6),
                              Text(
                                t.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.mo,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.sections.length}편 · ${t.wordCount}단어',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.moLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// 주제 상세 — 단어는 1×1 그리드(아이콘), 표현은 목록.
class _ThemeDetailScreen extends StatefulWidget {
  final VocabTheme theme;
  final bool gridMode;
  const _ThemeDetailScreen({required this.theme, this.gridMode = false});

  @override
  State<_ThemeDetailScreen> createState() => _ThemeDetailScreenState();
}

class _ThemeDetailScreenState extends State<_ThemeDetailScreen> {
  bool _chunkReady = false;

  @override
  void initState() {
    super.initState();
    // 한자 탭 탐색용 (백그라운드 로드, 없어도 표시는 됨)
    ChunkIndexService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _chunkReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${t.emoji} ${t.title}',
                style: const TextStyle(
                    color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('${t.sections.length}편 · ${t.wordCount}단어',
                style: TextStyle(
                    color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: Builder(builder: (context) {
        // 세부분류 없이 주제의 전체 단어를 한 화면으로
        final words = [for (final s in t.sections) ...s.words];
        if (!widget.gridMode) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: words.length,
            itemBuilder: (context, i) =>
                _WordRow(word: words[i], chunkReady: _chunkReady),
          );
        }
        // 1×1 그리드 (메인 메뉴 스타일) — 단어별 아이콘
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 0.82,
          ),
          itemCount: words.length,
          itemBuilder: (context, i) => _WordTile(
            word: words[i],
            fallbackEmoji: t.emoji,
            chunkReady: _chunkReady,
          ),
        );
      }),
    );
  }
}

/// 1×1 단어 타일 — 아이콘 + 한자 + 독음 + 뜻. 탭 → 상세 시트(+TTS).
class _WordTile extends StatelessWidget {
  final VocabWord word;
  final String fallbackEmoji;
  final bool chunkReady;
  const _WordTile({
    required this.word,
    required this.fallbackEmoji,
    required this.chunkReady,
  });

  @override
  Widget build(BuildContext context) {
    var rd = word.rd;
    var ko = word.ko;
    if ((rd.isEmpty || ko.isEmpty) && chunkReady) {
      final ce = CedictService.instance.lookup(word.zh);
      if (rd.isEmpty) rd = ce?.pinyin ?? '';
      if (ko.isEmpty) {
        ko = VocabCatalog.instance.koFor(word.zh) ??
            (ce != null && ce.meanings.isNotEmpty ? ce.meanings.first : '');
      }
    }
    return InkWell(
      onTap: () {
        TtsService.instance.speak(word.zh);
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.xuanZhi,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
          ),
          builder: (_) => _WordDetailSheet(
            word: word,
            rd: rd,
            ko: ko,
            emoji: word.ic ?? fallbackEmoji,
            chunkReady: chunkReady,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(word.ic ?? fallbackEmoji,
                style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word.zh,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.mo,
                ),
              ),
            ),
            if (rd.isNotEmpty)
              Text(
                rd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.jinDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (ko.isNotEmpty)
              Text(
                ko,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mo,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 단어 상세 시트 — 큰 한자(청크·한자 탐색 가능) + TTS.
class _WordDetailSheet extends StatelessWidget {
  final VocabWord word;
  final String rd;
  final String ko;
  final String emoji;
  final bool chunkReady;
  const _WordDetailSheet({
    required this.word,
    required this.rd,
    required this.ko,
    required this.emoji,
    required this.chunkReady,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            chunkReady
                ? SelectableHanziText(
                    text: word.zh,
                    tokens: ChunkIndexService.instance.tokensFor(word.zh),
                    chunks: ChunkIndexService.instance.chunkDict,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mo,
                      height: 1.3,
                    ),
                  )
                : Text(
                    word.zh,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mo,
                    ),
                  ),
            if (rd.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                rd,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: AppColors.jinDeep,
                ),
              ),
            ],
            if (ko.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ko,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mo,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.zhuHong,
                foregroundColor: AppColors.xuanZhi,
                shape: const RoundedRectangleBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              ),
              onPressed: () => TtsService.instance.speak(word.zh),
              icon: const Icon(Icons.volume_up),
              label: const Text('다시 듣기',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final VocabWord word;
  final bool chunkReady;
  const _WordRow({required this.word, required this.chunkReady});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.jin.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chunkReady
                    ? SelectableHanziText(
                        text: word.zh,
                        tokens: ChunkIndexService.instance.tokensFor(word.zh),
                        chunks: ChunkIndexService.instance.chunkDict,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mo,
                          height: 1.3,
                        ),
                      )
                    : Text(
                        word.zh,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mo,
                          height: 1.3,
                        ),
                      ),
                const SizedBox(height: 2),
                Builder(builder: (context) {
                  var rd = word.rd;
                  var ko = word.ko;
                  if ((rd.isEmpty || ko.isEmpty) && chunkReady) {
                    final ce = CedictService.instance.lookup(word.zh);
                    if (rd.isEmpty) rd = ce?.pinyin ?? '';
                    if (ko.isEmpty) {
                      ko = VocabCatalog.instance.koFor(word.zh) ??
                          (ce != null && ce.meanings.isNotEmpty
                              ? ce.meanings.first
                              : '');
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rd.isNotEmpty)
                        Text(
                          rd,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.jinDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (ko.isNotEmpty)
                        Text(
                          ko,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mo,
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, size: 20, color: AppColors.zhuHong),
            onPressed: () => TtsService.instance.speak(word.zh),
          ),
        ],
      ),
    );
  }
}
