import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';
import 'episode_screen.dart';
import 'grammar_lesson_screen.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _category = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/dialogues/conv_lccc.json');
    await EpisodeCatalog.instance.ensureLoaded();
    setState(() {
      _data = json.decode(raw) as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('회화', style: TextStyle(color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('Conversation', style: TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final dialogues = (_data?['dialogues'] as List?) ?? [];
    final categories = (_data?['categories'] as List?)?.cast<String>() ?? [];
    final categoryLabels =
        (_data?['category_labels'] as Map?)?.cast<String, dynamic>() ?? {};

    final filtered = _category == 'ALL'
        ? dialogues
        : dialogues.where((d) => (d as Map)['category'] == _category).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _storyHub()),
        SliverToBoxAdapter(child: _grammarHub()),
        SliverToBoxAdapter(child: _lcccHeader(dialogues.length)),
        SliverToBoxAdapter(child: _categoryChips(categories, categoryLabels)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final d = filtered[i] as Map<String, dynamic>;
                return _DialogueCard(dialogue: d, index: i + 1);
              },
              childCount: filtered.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _storyHub() {
    final catalog = EpisodeCatalog.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final level in ['L1', 'L2', 'L3'])
            if (catalog.forLevel(level).isNotEmpty) ...[
              Row(
                children: [
                  SealStamp(text: level, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${EpisodeCatalog.levelLabels[level]} · ${catalog.forLevel(level).length}편',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mo,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: catalog.forLevel(level).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final meta = catalog.forLevel(level)[i];
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EpisodeScreen(meta: meta)),
                      ),
                      child: Container(
                        width: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.xuanZhi,
                          border: Border.all(color: AppColors.zhuHong, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(meta.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              '${i + 1}. ${meta.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.mo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _grammarHub() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SealStamp(text: '学', size: 22),
              const SizedBox(width: 8),
              Text(
                '우리 콘텐츠 (자체 제작)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mo,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HubCard(
                  title: '문법 L1',
                  sub: '기능어 40 × 3',
                  seal: 'L1',
                  color: const Color(0xFF8B0000),
                  builder: (_) => const GrammarLessonScreen(lessonNum: 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HubCard(
                  title: '문법 L2',
                  sub: '어기조사·부사·단어',
                  seal: 'L2',
                  color: const Color(0xFFAD1457),
                  builder: (_) => const GrammarLessonScreen(lessonNum: 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lcccHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          const SealStamp(text: '聊', size: 22),
          const SizedBox(width: 8),
          Text(
            '실제 챗 다이얼로그',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.mo,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: AppColors.feiCui.withValues(alpha: 0.2),
            child: Text(
              'LCCC · $total',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.feiCui,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '실측 Weibo 친구톡',
            style: TextStyle(fontSize: 10, color: AppColors.moLight),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips(List<String> categories, Map<String, dynamic> labels) {
    final all = ['ALL', ...categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = all[i];
          final lbl = c == 'ALL' ? '전체' : (labels[c] as String? ?? c);
          final selected = c == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? AppColors.zhuHong : AppColors.xuanZhi,
                border: Border.all(
                  color: selected ? AppColors.zhuHongDeep : AppColors.jin.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                lbl,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.xuanZhi : AppColors.mo,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String sub;
  final String seal;
  final Color color;
  final WidgetBuilder builder;

  const _HubCard({
    required this.title,
    required this.sub,
    required this.seal,
    required this.color,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          children: [
            SealStamp(text: seal, size: 40, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.moLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogueCard extends StatelessWidget {
  final Map<String, dynamic> dialogue;
  final int index;
  const _DialogueCard({required this.dialogue, required this.index});

  @override
  Widget build(BuildContext context) {
    final turns = (dialogue['turns'] as List?) ?? [];
    final catLabel = dialogue['category_label'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              color: AppColors.xuanZhiDeep,
              child: Row(
                children: [
                  Text(
                    '#$index',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.zhuHong,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    catLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${turns.length}턴',
                    style: const TextStyle(fontSize: 10, color: AppColors.moLight),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                children: turns.map((t) {
                  final tm = t as Map<String, dynamic>;
                  final isA = (tm['speaker'] as String?) == 'A';
                  return _ChatBubble(turn: tm, isA: isA);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> turn;
  final bool isA;
  const _ChatBubble({required this.turn, required this.isA});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isA ? AppColors.zhuHong : AppColors.jin;
    final bubbleText = isA ? AppColors.xuanZhi : AppColors.mo;
    final zh = turn['zh'] as String? ?? '';

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bubbleColor,
        border: Border.all(color: AppColors.jinDeep, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableHanziText(
                  text: zh,
                  tokens: turn['tokens'] as List?,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: bubbleText,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => TtsService.instance.speak(zh),
                child: Icon(Icons.volume_up, size: 16, color: bubbleText.withValues(alpha: 0.85)),
              ),
            ],
          ),
          if (turn['pinyin'] != null) ...[
            const SizedBox(height: 3),
            Text(
              turn['pinyin'] as String,
              style: TextStyle(
                fontSize: 11,
                color: bubbleText.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (turn['ko'] != null) ...[
            const SizedBox(height: 4),
            Container(height: 0.5, color: bubbleText.withValues(alpha: 0.3)),
            const SizedBox(height: 4),
            Text(
              turn['ko'] as String,
              style: TextStyle(fontSize: 12, color: bubbleText.withValues(alpha: 0.95)),
            ),
          ],
        ],
      ),
    );

    final avatar = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bubbleColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isA ? 'A' : 'B',
        style: const TextStyle(
          color: AppColors.xuanZhi,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isA ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isA
            ? [avatar, const SizedBox(width: 6), Flexible(child: bubble)]
            : [Flexible(child: bubble), const SizedBox(width: 6), avatar],
      ),
    );
  }
}
