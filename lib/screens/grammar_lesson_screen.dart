import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../core/theme.dart';
import '../services/memo_service.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/memo_toggle.dart';
import '../widgets/selectable_hanzi.dart';
import 'grammar_test_screen.dart';

class GrammarLessonScreen extends StatefulWidget {
  final int lessonNum;
  const GrammarLessonScreen({super.key, this.lessonNum = 1});

  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _speaking;
  int _stage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/grammar/lesson${widget.lessonNum}.json');
    setState(() {
      _data = json.decode(raw) as Map<String, dynamic>;
      _loading = false;
    });
  }

  Future<void> _speak(String zh) async {
    setState(() => _speaking = zh);
    await TtsService.instance.speak(zh);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (TtsService.instance.isSpeaking(zh) == false) {
        if (mounted) setState(() => _speaking = null);
      }
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _exportMemos() async {
    final memos = await MemoService.instance.all();
    if (memos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 메모 없음')),
      );
      return;
    }
    // 패턴별 정렬 + sentence 매핑
    final byPattern = <String, List<MemoEntry>>{};
    for (final m in memos) {
      byPattern.putIfAbsent(m.patternId, () => []).add(m);
    }

    final patterns = (_data?['patterns'] as List?) ?? [];
    final patternMap = {
      for (final p in patterns)
        p['id'] as String: p as Map<String, dynamic>
    };

    final buf = StringBuffer();
    buf.writeln('# 중국어유니버스 — 메모 ${memos.length}개');
    buf.writeln();
    final keys = byPattern.keys.toList()..sort();
    for (final pid in keys) {
      final p = patternMap[pid];
      if (p == null) continue;
      buf.writeln('## ${p['key']} — ${p['label']}');
      buf.writeln();
      final list = byPattern[pid]!..sort((a, b) => a.idx.compareTo(b.idx));
      final examples = (p['examples'] as List?) ?? [];
      for (final m in list) {
        if (m.idx >= examples.length) continue;
        final ex = examples[m.idx] as Map<String, dynamic>;
        buf.writeln('### ${m.idx + 1}. ${ex['zh']}');
        buf.writeln('- pinyin: `${ex['pinyin']}`');
        buf.writeln('- ko: ${ex['ko']}');
        buf.writeln('- **메모**: ${m.value}');
        buf.writeln();
      }
    }

    final text = buf.toString();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 메모 ${memos.length}개 클립보드 복사됨 — Claude 한테 paste!'),
        backgroundColor: AppColors.feiCui,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lesson ${widget.lessonNum}',
                style: const TextStyle(color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              widget.lessonNum == 1
                  ? 'S1+S2 기능어 패턴 40 × 3'
                  : '어기조사 · 부사 · 필수단어 (LCCC 실측)',
              style: const TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '플래시카드 테스트',
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrammarTestScreen()),
            ),
          ),
          IconButton(
            tooltip: '메모 내보내기',
            icon: const Icon(Icons.ios_share),
            onPressed: _exportMemos,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_data == null) return const Center(child: Text('데이터 없음'));
    final allPatterns = (_data!['patterns'] as List?) ?? [];
    final stages = (_data!['stages'] as List?) ?? [];
    final chunks = (_data!['chunks'] as Map?)?.cast<String, dynamic>();
    final filtered = allPatterns
        .where((p) => (p as Map)['stage'] == _stage)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _intro()),
        SliverToBoxAdapter(child: _stageTabs(stages)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final p = filtered[i] as Map<String, dynamic>;
              // 전역 index (filtered 안에서의 순서가 아니라 패턴 자체 위치)
              final globalIndex = allPatterns.indexOf(p) + 1;
              return _PatternBlock(
                index: globalIndex,
                pattern: p,
                chunks: chunks,
                speaking: _speaking,
                onSpeak: _speak,
              );
            },
            childCount: filtered.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _stageTabs(List stages) {
    if (stages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: stages.map<Widget>((s) {
          final stageNum = (s as Map)['stage'] as int;
          final title = s['title'] as String? ?? '';
          final selected = stageNum == _stage;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => setState(() => _stage = stageNum),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.zhuHong : AppColors.xuanZhi,
                    border: Border.all(
                      color: selected ? AppColors.zhuHongDeep : AppColors.jin.withValues(alpha: 0.5),
                      width: selected ? 1.5 : 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'S$stageNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: selected ? AppColors.xuanZhi : AppColors.mo,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          color: selected
                              ? AppColors.xuanZhi.withValues(alpha: 0.85)
                              : AppColors.moLight,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _intro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.jin, width: 1.2),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SealStamp(text: '${widget.lessonNum}', size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lessonNum == 1 ? '문법 패턴 드릴' : '어휘 + 어기조사 + 부사',
                        style: const TextStyle(
                          color: AppColors.jinBright,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (ctx) {
                        final pc = (_data?['pattern_count'] as int?) ??
                            ((_data?['patterns'] as List?)?.length ?? 0);
                        final sc = (_data?['sentence_count'] as int?) ??
                            (((_data?['patterns'] as List?) ?? [])
                                .map((p) => ((p as Map)['examples'] as List?)?.length ?? 0)
                                .fold<int>(0, (a, b) => a + b));
                        return Text(
                          '$pc 패턴 · $sc 문장',
                          style: const TextStyle(
                            color: AppColors.xuanZhi,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Text(
                        widget.lessonNum == 1
                            ? 'S1+S2 (159자) · 진짜 중국인 표현'
                            : '209자 · LCCC 실측 챗 기반',
                        style: TextStyle(
                          color: AppColors.xuanZhi.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 테스트 시작 큰 버튼
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrammarTestScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.xuanZhi,
                border: Border.all(color: AppColors.zhuHong, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.zhuHong.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.zhuHong,
                      border: Border.all(color: AppColors.jin),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.quiz, color: AppColors.xuanZhi, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '플래시카드 테스트',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.zhuHong,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '한국어 → 중국어 회상 (120 문장)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.moLight,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.zhuHong),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternBlock extends StatelessWidget {
  final int index;
  final Map<String, dynamic> pattern;
  final Map<String, dynamic>? chunks;
  final String? speaking;
  final Future<void> Function(String) onSpeak;

  const _PatternBlock({
    required this.index,
    required this.pattern,
    required this.chunks,
    required this.speaking,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final examples = (pattern['examples'] as List?) ?? [];
    final explanation = pattern['explanation'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header
            Container(
              color: AppColors.zhuHong,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.jinBright,
                      border: Border.all(color: AppColors.jin, width: 0.8),
                    ),
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: AppColors.mo,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    pattern['key'] as String? ?? '',
                    style: const TextStyle(
                      color: AppColors.xuanZhi,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pattern['label'] as String? ?? '',
                      style: TextStyle(
                        color: AppColors.xuanZhi.withValues(alpha: 0.9),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (explanation != null && explanation.isNotEmpty)
              Container(
                width: double.infinity,
                color: AppColors.xuanZhiDeep,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.moLight,
                    height: 1.55,
                  ),
                ),
              ),
            ...List.generate(examples.length, (i) {
              final e = examples[i] as Map<String, dynamic>;
              return _ExampleRow(
                index: i + 1,
                patternId: pattern['id'] as String? ?? '',
                exampleIdx: i,
                zh: e['zh'] as String? ?? '',
                tokens: e['tokens'] as List?,
                chunks: chunks,
                pinyin: e['pinyin'] as String? ?? '',
                ko: e['ko'] as String? ?? '',
                isLast: i == examples.length - 1,
                speaking: speaking == (e['zh'] as String?),
                onSpeak: () => onSpeak(e['zh'] as String? ?? ''),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final int index;
  final String patternId;
  final int exampleIdx;
  final String zh;
  final List? tokens;
  final Map<String, dynamic>? chunks;
  final String pinyin;
  final String ko;
  final bool isLast;
  final bool speaking;
  final VoidCallback onSpeak;

  const _ExampleRow({
    required this.index,
    required this.patternId,
    required this.exampleIdx,
    required this.zh,
    required this.tokens,
    required this.chunks,
    required this.pinyin,
    required this.ko,
    required this.isLast,
    required this.speaking,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.jin.withValues(alpha: 0.25))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.moLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableHanziText(text: zh, tokens: tokens, chunks: chunks),
                const SizedBox(height: 3),
                Text(
                  pinyin,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.moLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ko,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.zhuHongDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                MemoToggle(patternId: patternId, idx: exampleIdx, sentence: zh),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onSpeak,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: speaking ? AppColors.zhuHong : AppColors.zhuHong.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.zhuHong, width: 1),
              ),
              child: Icon(
                speaking ? Icons.graphic_eq : Icons.volume_up,
                color: speaking ? AppColors.xuanZhi : AppColors.zhuHong,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
