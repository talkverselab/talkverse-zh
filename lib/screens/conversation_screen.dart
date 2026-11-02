import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../widgets/chinese_decor.dart';
import 'episode_screen.dart';
import 'grammar_lesson_screen.dart';
import 'sentence_flashcard_screen.dart';
import '../core/l10n.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('회화'), style: TextStyle(color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('Conversation', style: TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
        actions: const [KoReadingToggleAction()],
      ),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _storyHub()),
        SliverToBoxAdapter(child: _grammarHub()),
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
          for (final level in EpisodeCatalog.levels)
            if (catalog.forLevel(level).isNotEmpty) ...[
              Row(
                children: [
                  SealStamp(text: level, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trf('{0} · {1}편', [EpisodeCatalog.levelLabels[level], catalog.forLevel(level).length]),
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
                tr('우리 콘텐츠 (자체 제작)'),
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
                  title: tr('문법 L1'),
                  sub: tr('기능어 40 × 3'),
                  seal: 'L1',
                  color: const Color(0xFF8B0000),
                  builder: (_) => const GrammarLessonScreen(lessonNum: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HubCard(
            title: tr('문장 플래시카드'),
            sub: tr('전 레벨 랜덤 20문장 · 뜻 뒤집기 · 남/녀 음성'),
            seal: '复习',
            color: AppColors.feiCui,
            builder: (_) => const SentenceFlashcardScreen(),
          ),
        ],
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
