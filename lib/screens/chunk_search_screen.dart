import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/chunk_index_service.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';

/// 청크(단어) 기준 문장 검색.
/// 예: '可爱' / 'keai' / '귀엽' → 청크 목록 → 청크별 문장 → 문장 안 청크·한자 탐색.
class ChunkSearchScreen extends StatefulWidget {
  const ChunkSearchScreen({super.key});

  @override
  State<ChunkSearchScreen> createState() => _ChunkSearchScreenState();
}

class _ChunkSearchScreenState extends State<ChunkSearchScreen> {
  final _controller = TextEditingController();
  bool _ready = false;
  List<ChunkHit> _hits = [];
  List<IndexedSentence> _koFallback = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    ChunkIndexService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    final svc = ChunkIndexService.instance;
    final hits = svc.search(q);
    setState(() {
      _lastQuery = q.trim();
      _hits = hits;
      // 한국어 질의인데 청크 매치가 빈약하면 문장 번역 직접 검색도 함께
      _koFallback = RegExp(r'[가-힣]').hasMatch(q) ? svc.searchSentencesByKo(q) : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        title: const Text('청크 검색', style: TextStyle(color: AppColors.mo)),
        centerTitle: true,
        actions: const [KoReadingToggleAction()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _search,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.mo,
              ),
              decoration: InputDecoration(
                hintText: '可爱 · keai · 귀엽다',
                hintStyle: const TextStyle(color: AppColors.moLight, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: AppColors.zhuHong),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.moLight),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.xuanZhiDeep,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.jin),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.zhuHong, width: 1.5),
                ),
              ),
            ),
          ),
          const GreekKeyDivider(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_ready) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.zhuHong),
            SizedBox(height: 12),
            Text('사전·문장 인덱스 준비 중…',
                style: TextStyle(color: AppColors.moLight, fontSize: 13)),
          ],
        ),
      );
    }
    if (_lastQuery.isEmpty) {
      final svc = ChunkIndexService.instance;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SealStamp(text: '搜', size: 56),
            const SizedBox(height: 16),
            Text(
              '문장 ${svc.sentenceCount}개 · 청크 ${svc.chunkCount}개 인덱스',
              style: const TextStyle(color: AppColors.moLight, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              '한자·병음·한국어로 검색하세요',
              style: TextStyle(
                color: AppColors.mo,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (_hits.isEmpty && _koFallback.isEmpty) {
      return const Center(
        child: Text('일치하는 청크가 없어요',
            style: TextStyle(color: AppColors.moLight, fontSize: 14)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ..._hits.take(50).map((h) => _ChunkCard(hit: h, key: ValueKey('c:${h.chunk}'))),
        if (_koFallback.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            '문장 번역 일치',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.zhuHong,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          ..._koFallback.take(30).map((s) => _SentenceTile(sentence: s)),
        ],
      ],
    );
  }
}

class _ChunkCard extends StatefulWidget {
  final ChunkHit hit;
  const _ChunkCard({required this.hit, super.key});

  @override
  State<_ChunkCard> createState() => _ChunkCardState();
}

class _ChunkCardState extends State<_ChunkCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    final firstMeaning =
        h.ko ?? (h.meanings.isNotEmpty ? h.meanings.first : null);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.xuanZhiDeep,
        border: Border.all(
          color: _expanded ? AppColors.zhuHong : AppColors.jin.withValues(alpha: 0.6),
          width: _expanded ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // 청크 자체 — 탭하면 청크 정보 시트 (구성 한자 → 한자 탐색)
                  SelectableHanziText(
                    text: h.chunk,
                    tokens: [
                      {'text': h.chunk, 'compound': h.chunk.length > 1}
                    ],
                    chunks: ChunkIndexService.instance.chunkDict,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mo,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (h.pinyin != null)
                          Text(
                            h.pinyin!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              color: AppColors.zhuHong,
                            ),
                          ),
                        if (firstMeaning != null)
                          Text(
                            firstMeaning,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.moLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 20, color: AppColors.zhuHong),
                    onPressed: () => TtsService.instance.speak(h.chunk),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.jin.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.jin),
                    ),
                    child: Text(
                      '문장 ${h.sentences.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mo,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.moLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.jin),
            ...h.sentences.take(30).map(
                  (s) => _SentenceTile(sentence: s, highlight: h.chunk),
                ),
          ],
        ],
      ),
    );
  }
}

class _SentenceTile extends StatelessWidget {
  final IndexedSentence sentence;
  final String? highlight;
  const _SentenceTile({required this.sentence, this.highlight});

  @override
  Widget build(BuildContext context) {
    final s = sentence;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.jin.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableHanziText(
                  text: s.zh,
                  tokens: s.tokens,
                  chunks: ChunkIndexService.instance.chunkDict,
                  highlightText: highlight,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mo,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 18, color: AppColors.zhuHong),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => s.speaker == null
                    ? TtsService.instance.speak(s.zh)
                    : TtsService.instance.speakAs(s.zh,
                        gender: s.speaker == 'A' ? 'male' : 'female'),
              ),
            ],
          ),
          if (s.pinyin != null) ...[
            Text(
              s.pinyin!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.moLight,
              ),
            ),
            KoReadingText(
              s.pinyin!,
              style: const TextStyle(fontSize: 11, color: AppColors.moLight),
            ),
          ],
          if (s.ko != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                s.ko!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mo,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              s.source,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.moLight,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
