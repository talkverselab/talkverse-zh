import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../main.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/mascot.dart';
import '../widgets/today_mission.dart';
import 'chunk_search_screen.dart';
import 'conversation_screen.dart';
import 'episode_screen.dart';
import 'conversation_wordset_screen.dart';
import 'flashcard_screen.dart';
import 'grammar_lesson_screen.dart';
import 'hanzi_stages_screen.dart';
import 'phonetic_roots_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'tone_matrix_screen.dart';
import 'word_freq_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    LearnScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _tabs = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '학습'),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '진행'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      body: Stack(
        children: [
          const Positioned.fill(child: CloudPattern(opacity: 0.06)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '你好!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.zhuHong,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '한국 학습자, 오늘도 시작해요',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.moLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StreakChip(days: 1),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.xuanZhi,
                        border: Border.all(color: AppColors.jin),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.zhuHong, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  "오늘의 학습",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mo,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const _TodayMission(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const SealStamp(text: '学', size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '메인 메뉴',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mo,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MenuGrid(),
                const SizedBox(height: 28),
                const BrushDivider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '중국어유니버스 · 2026',
                    style: TextStyle(
                      color: AppColors.moLight,
                      fontSize: 11,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Builder(builder: (ctx) {
            return ChineseMascot(
              size: 110,
              initialPosition: const Offset(250, 540),
              emotion: MascotEmotion.excited,
              cycleOnTap: true,
              onTap: () {
                ScaffoldMessenger.of(ctx).clearSnackBars();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('🎭 다음 감정으로 — 탭 계속! 끌어서 이동도 가능'),
                    duration: Duration(milliseconds: 900),
                    backgroundColor: AppColors.zhuHongDeep,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

/// 홈 '오늘의 학습' — 첫 미완료 에피소드와 실제 진행도 연결.
class _TodayMission extends StatefulWidget {
  const _TodayMission();

  @override
  State<_TodayMission> createState() => _TodayMissionState();
}

class _TodayMissionState extends State<_TodayMission> {
  EpisodeMeta? _meta;
  int _learned = 0;
  int _total = 40;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final all = EpisodeCatalog.instance.all;
    if (all.isEmpty) return;
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds =
        progress.where((p) => p.learned).map((p) => p.turnId).toSet();
    for (final meta in all) {
      final epTurns = turns
          .where((t) =>
              t.level == meta.level &&
              t.dialect == 'north' &&
              t.episodeId == meta.id)
          .toList();
      final total = epTurns.length;
      final learned = epTurns.where((t) => learnedIds.contains(t.id)).length;
      if (total == 0 || learned < total || meta == all.last) {
        if (mounted) {
          setState(() {
            _meta = meta;
            _learned = learned;
            _total = total == 0 ? 40 : total;
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (meta == null) return const SizedBox(height: 120);
    return TodayMissionCard(
      level: meta.level == 'L1' ? 'BEGINNER 1' : meta.level,
      lessonTitle: '${meta.level} · ${meta.title}',
      lessonSubtitle: 'Mark & 小丽 스토리 ${meta.emoji}',
      progress: _learned,
      total: _total,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EpisodeScreen(meta: meta)),
        );
        _load();
      },
    );
  }
}

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(label: '회화', sub: 'Conversation', seal: '会话', color: AppColors.zhuHong,
        builder: (_) => const ConversationScreen()),
      _MenuItem(label: '문법 L1', sub: '기능어 40×3', seal: '文法', color: const Color(0xFF8B0000),
        builder: (_) => const GrammarLessonScreen(lessonNum: 1)),
      _MenuItem(label: '문법 L2', sub: '어기조사·부사·단어', seal: 'L2', color: const Color(0xFFAD1457),
        builder: (_) => const GrammarLessonScreen(lessonNum: 2)),
      _MenuItem(label: '한자 209', sub: '20×10 + 4지선다', seal: '209', color: const Color(0xFFC62828),
        builder: (_) => const HanziStagesScreen()),
      _MenuItem(label: '단어', sub: 'Vocabulary', seal: '词频', color: AppColors.feiCui,
        builder: (_) => const WordFreqScreen()),
      _MenuItem(label: '회화 어휘', sub: 'Conversation', seal: '会话', color: AppColors.jinDeep,
        builder: (_) => const ConversationWordsetScreen()),
      _MenuItem(label: '발음', sub: 'Pronunciation', seal: '声调', color: const Color(0xFF1565C0),
        builder: (_) => const ToneMatrixScreen()),
      _MenuItem(label: '발음부', sub: 'Phonetic', seal: '声旁', color: const Color(0xFF6A1B9A),
        builder: (_) => const PhoneticRootsScreen()),
      _MenuItem(label: '복습', sub: 'Flashcard', seal: '复习', color: AppColors.jin,
        builder: (_) => const FlashcardScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuItem {
  final String label;
  final String sub;
  final String seal;
  final Color color;
  final WidgetBuilder builder;
  _MenuItem({
    required this.label,
    required this.sub,
    required this.seal,
    required this.color,
    required this.builder,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: item.builder)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.mo.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SealStamp(text: item.seal, size: 44, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mo,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.moLight,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────── Learn 탭 ──────────

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _filter = '전체';
  final List<String> _filters = const ['전체', '회화', '한자', '발음', '단어', 'HSK'];
  List<_LessonItem> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds =
        progress.where((p) => p.learned).map((p) => p.turnId).toSet();

    final items = <_LessonItem>[];
    for (final level in ['L1', 'L2', 'L3']) {
      final metas = EpisodeCatalog.instance.forLevel(level);
      if (metas.isEmpty) continue;
      items.add(_LessonItem.header(
          EpisodeCatalog.levelLabels[level] ?? level, metas.length));
      var currentAssigned = false;
      for (var i = 0; i < metas.length; i++) {
        final meta = metas[i];
        final epTurns = turns
            .where((t) =>
                t.level == level &&
                t.dialect == 'north' &&
                t.episodeId == meta.id)
            .toList();
        final total = epTurns.length;
        final learned = epTurns.where((t) => learnedIds.contains(t.id)).length;
        final done = total > 0 && learned >= total;
        _LessonState state;
        if (done) {
          state = _LessonState.done;
        } else if (!currentAssigned) {
          state = _LessonState.current;
          currentAssigned = true;
        } else {
          state = _LessonState.locked;
        }
        items.add(_LessonItem(
          '${level == 'L1' ? 'EP' : 'D'}${i + 1}',
          '${meta.emoji} ${meta.title}',
          state,
          meta: meta,
          learned: learned,
          total: total,
        ));
      }
    }
    if (mounted) setState(() => _lessons = items);
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        title: const Text('학습', style: TextStyle(color: AppColors.mo)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.mo),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChunkSearchScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.zhuHong : AppColors.xuanZhi,
                      border: Border.all(
                        color: selected ? AppColors.zhuHong : AppColors.jin.withValues(alpha: 0.6),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f,
                      style: TextStyle(
                        color: selected ? AppColors.xuanZhi : AppColors.mo,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const GreekKeyDivider(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _LessonRow(
                lesson: lessons[i],
                onReturn: _loadLessons,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LessonState { done, current, locked }

class _LessonItem {
  final String id;
  final String title;
  final _LessonState state;
  final EpisodeMeta? meta;
  final int learned;
  final int total;
  final bool isHeader;
  _LessonItem(
    this.id,
    this.title,
    this.state, {
    required this.meta,
    required this.learned,
    required this.total,
  }) : isHeader = false;

  _LessonItem.header(this.title, int count)
      : id = '',
        state = _LessonState.locked,
        meta = null,
        learned = 0,
        total = count,
        isHeader = true;
}

class _LessonRow extends StatelessWidget {
  final _LessonItem lesson;
  final VoidCallback onReturn;
  const _LessonRow({required this.lesson, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    if (lesson.isHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 2),
        child: Row(
          children: [
            const SealStamp(text: '册', size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mo,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Text(
              '${lesson.total}편',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.zhuHong,
              ),
            ),
          ],
        ),
      );
    }
    Color bg;
    Color border;
    Color textColor;
    Widget trailing;
    switch (lesson.state) {
      case _LessonState.done:
        bg = AppColors.xuanZhi;
        border = AppColors.feiCui;
        textColor = AppColors.mo;
        trailing = const Icon(Icons.check_circle, color: AppColors.feiCui);
        break;
      case _LessonState.current:
        bg = AppColors.zhuHong;
        border = AppColors.zhuHongDeep;
        textColor = AppColors.xuanZhi;
        trailing = const Icon(Icons.arrow_forward, color: AppColors.xuanZhi);
        break;
      case _LessonState.locked:
        bg = AppColors.xuanZhiDeep;
        border = AppColors.jin.withValues(alpha: 0.3);
        textColor = AppColors.moLight;
        trailing = const Icon(Icons.lock, color: AppColors.moLight, size: 18);
        break;
    }
    return InkWell(
      onTap: lesson.state == _LessonState.locked || lesson.meta == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EpisodeScreen(meta: lesson.meta!)),
              );
              onReturn();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: lesson.state == _LessonState.current ? 1.5 : 0.8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                lesson.id,
                style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.75)),
              ),
            ),
            Expanded(
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (lesson.total > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${lesson.learned}/${lesson.total}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            trailing,
          ],
        ),
      ),
    );
  }
}
