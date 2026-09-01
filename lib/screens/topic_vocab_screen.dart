import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/chunk_index_service.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';

/// co-Trip 여행 중국어 — 주제별 단어장.
class VocabWord {
  final String ko;
  final String zh;
  final String rd; // 한국 독음
  VocabWord(this.ko, this.zh, this.rd);
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

  List<VocabTheme> _themes = [];
  bool _loaded = false;

  List<VocabTheme> get themes => _themes;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw =
        await rootBundle.loadString('assets/data/vocab/travel_topics.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _themes = [
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
                    ),
                ],
              ),
          ],
        ),
    ];
    _loaded = true;
  }
}

/// 주제 목록 화면.
class TopicVocabScreen extends StatefulWidget {
  const TopicVocabScreen({super.key});

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    VocabCatalog.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = VocabCatalog.instance.themes;
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
            const Text('주제별 단어',
                style: TextStyle(
                    color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('여행 중국어 · $total단어',
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
                              builder: (_) => _ThemeDetailScreen(theme: t)),
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

/// 주제 상세 — 섹션 펼침 목록.
class _ThemeDetailScreen extends StatefulWidget {
  final VocabTheme theme;
  const _ThemeDetailScreen({required this.theme});

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
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: t.sections.length,
        itemBuilder: (context, i) {
          final s = t.sections[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.xuanZhi,
              border: Border.all(color: AppColors.jin.withValues(alpha: 0.6)),
            ),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: t.sections.length == 1,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                iconColor: AppColors.zhuHong,
                collapsedIconColor: AppColors.moLight,
                title: Text(
                  s.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mo,
                  ),
                ),
                subtitle: Text(
                  '${s.words.length}단어',
                  style: const TextStyle(fontSize: 11, color: AppColors.moLight),
                ),
                children: [
                  for (final w in s.words)
                    _WordRow(word: w, chunkReady: _chunkReady),
                ],
              ),
            ),
          );
        },
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
                Text(
                  word.rd,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.jinDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  word.ko,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mo,
                  ),
                ),
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
