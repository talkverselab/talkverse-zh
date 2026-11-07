import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../main.dart';
import '../review/review_engine.dart';
import '../review/review_ui.dart';
import '../services/dialogue_service.dart';
import '../services/review_cards.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import 'about_screen.dart';
import 'chunk_search_screen.dart';
import 'custom_script_screen.dart';
import 'dialogue_screen.dart';
import 'episode_screen.dart';
import 'family_hanzi_screen.dart';
import 'flashcard_screen.dart';
import 'grammar_lesson_screen.dart';
import 'grammar_test_screen.dart';
import 'hanzi_stages_screen.dart';
import 'phonetic_roots_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'sentence_flashcard_screen.dart';
import 'speaking_practice_screen.dart';
import 'tone_matrix_screen.dart';
import 'tone_practice_screen.dart';
import 'topic_vocab_screen.dart';
import 'word_freq_screen.dart';

/// 메인 — 일본어앱 구조(2026-11-02): 탭 4개 배우기 · 복습 · 탐색 · 나.
/// 넓은 화면(isWide, 가로 720 이상): 앱바 아래 레일 + 왼쪽 칸(탭 목록) | 오른쪽 칸(연 화면, 자기 Navigator). 폰: 하단 탭.
/// 배우기 맨 위 = 회화 홈(「오늘의 컷 / 이어서 읽기」 → 맞춤 회화 → 레벨·주제). 중국어 전용 메뉴(성조·말하기·한자·발음부·문법·단어·청크 검색)는
/// 배우기·복습·탐색 탭의 줄 카드로 옮겼다. 학습 세션(문장 카드)은 openFull 로 전체 화면.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _pane = GlobalKey<NavigatorState>();

  static List<(IconData, IconData, String)> get _tabs => [
        (Icons.menu_book_outlined, Icons.menu_book, tr('배우기')),
        (Icons.style_outlined, Icons.style, tr('복습')),
        (Icons.explore_outlined, Icons.explore, tr('탐색')),
        (Icons.person_outline, Icons.person, tr('프로필')),
      ];

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      centerTitle: false,
      title: GradText(tr('중국어유니버스'), style: const TextStyle(fontSize: AppFonts.title, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
      actions: [
        IconButton(
          tooltip: tr('청크 검색'),
          icon: const Icon(Icons.search, color: AppColors.mo),
          onPressed: () => openPane(context, (_) => const ChunkSearchScreen()),
        ),
        const SizedBox(width: 4),
      ],
    );
    final stack = IndexedStack(index: _index, children: const [LearnTab(), ReviewTab(), ExploreTab(), MeTab()]);
    // 폰(한 화면): 하단 탭 + 내용 전체 화면
    if (!isWide(context)) {
      return Scaffold(
        appBar: appBar,
        body: stack,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: t.$3)],
        ),
      );
    }
    // 넓은 화면(아이패드·태블릿·폴드 펼침): 레일 + 왼쪽 칸 | 오른쪽 칸. 두 칸까지만.
    final w = MediaQuery.sizeOf(context).width;
    final left = (w * 0.34).clamp(300.0, 440.0);
    return Pane(
      navKey: _pane,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _pane.currentState?.maybePop(),
        child: Scaffold(
          appBar: appBar,
          body: Row(children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: w >= 900 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
              backgroundColor: AppColors.xuanZhi,
              indicatorColor: AppColors.xuanZhiDeep,
              minWidth: 64,
              selectedIconTheme: const IconThemeData(color: AppColors.zhuHong),
              unselectedIconTheme: const IconThemeData(color: AppColors.muted),
              selectedLabelTextStyle: const TextStyle(color: AppColors.zhuHong, fontSize: AppFonts.rail, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.muted, fontSize: AppFonts.rail, fontWeight: FontWeight.w500),
              destinations: [for (final t in _tabs) NavigationRailDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: Text(t.$3))],
              // 레일 맨 아래 ⓘ 「앱 소개」(절벽구간 설명) — 2026-11-07
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IconButton(
                      tooltip: tr('앱 소개'),
                      icon: const Icon(Icons.info_outline, color: AppColors.muted),
                      onPressed: () => openPane(context, (_) => const AboutScreen()),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: left, child: stack),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
            Expanded(
              child: ClipRect(
                child: Navigator(
                  key: _pane,
                  onGenerateInitialRoutes: (_, _) => [MaterialPageRoute(builder: (_) => const _PanePlaceholder())],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 오른쪽 칸이 비어 있을 때.
class _PanePlaceholder extends StatelessWidget {
  const _PanePlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.xuanZhi,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SealStamp(text: '学', size: 56),
            const SizedBox(height: 14),
            Text(
              tr('왼쪽에서 고르면 여기에 열립니다 · 문장 카드는 전체 화면'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      );
}

/// 탭 안의 한 줄 — 도장 + 제목·부제 + 꺾쇠. 시안 zh05: 카드 상자 없이 여백만. 누르면 오른쪽 칸(넓은 화면) 또는 push.
class _NavRow extends StatelessWidget {
  final String seal;
  final Color? sealColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavRow({required this.seal, this.sealColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(children: [
          SealStamp(text: seal, size: 32, color: sealColor ?? AppColors.zhuHong),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.uiText(size: 14.5, weight: FontWeight.w600, color: AppColors.mo)),
              const SizedBox(height: 1),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.captionText(size: 11.5)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.line, size: 18),
        ]),
      ),
    );
  }
}

/// 배우기 「기초」 한 줄 — 상자 없이 큰 자형 하나 + 작은 이름. 넘치면 옆으로 민다.
class _BasicsRow extends StatelessWidget {
  final List<(String, Color, String, VoidCallback)> items; // 자형 · 색 · 이름 · 동작
  const _BasicsRow({required this.items});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final (g, c, label, tap) in items)
            InkWell(
              onTap: tap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(g, style: AppFonts.glyphText(size: 26, color: c, height: 1.15)),
                    const SizedBox(height: 4),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppFonts.captionText(size: 11, color: AppColors.moLight)),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 4),
      child: Text(title, style: AppFonts.captionText(size: 12, weight: FontWeight.w600, color: AppColors.muted)),
    );

EdgeInsets _tabPadding(BuildContext context) => EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom);

// ────────── 배우기 ──────────

/// 배우기 — 시안 zh05 ③: 「이어서 읽기」 카드 하나가 주인공 → 기초(자형 한 줄) → 회화(맞춤 회화·레벨·주제, 상자 없이) → 옛 스토리.
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // 사이트 첫 화면처럼 위쪽만 파스텔 메시, 아래는 흰 바탕
      const Positioned(top: 0, left: 0, right: 0, height: 160, child: MeshBackdrop()),
      ListView(padding: _tabPadding(context), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('你好', style: AppFonts.zhText(size: AppFonts.title, weight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(child: Text(tr('한국 학습자, 오늘도 시작해요'), style: AppFonts.captionText(size: 12.5, color: AppColors.moLight))),
          ]),
        ),
        ContinueReadingCard(level: DialogueService.instance.startLevel),
        const SizedBox(height: 10),
        _section(tr('기초')),
        _BasicsRow(items: [
          ('声', AppColors.tone4, tr('성조연습'), () => openPane(context, (_) => const TonePracticeScreen())),
          ('四', AppColors.tone1, tr('4성 매트릭스'), () => openPane(context, (_) => const ToneMatrixScreen())),
          ('说', AppColors.zhuHongDeep, tr('말하기'), () => openPane(context, (_) => const SpeakingPracticeScreen())),
          ('字', AppColors.copper, tr('한자 배우기'), () => openPane(context, (_) => const HanziHubScreen(learn: true))),
        ]),
        _section(tr('문법')),
        _NavRow(
          seal: '法',
          sealColor: AppColors.moLight,
          title: tr('문법'),
          subtitle: tr('기능어 · 문형'),
          onTap: () => openPane(context, (_) => const GrammarMenuScreen()),
        ),
        _section(tr('회화')),
        const DialogueHomeScreen(embedded: true),
        _section(tr('단어')),
        _NavRow(
          seal: '崖',
          sealColor: AppColors.copper,
          title: tr('절벽 단어 R1~R4'),
          subtitle: tr('영화·드라마 대사 빈도 2,500어 · 20어 단원 · 회화 단어 포함'),
          onTap: () => openPane(context, (_) => const WordFreqScreen()),
        ),
        _NavRow(
          seal: 'HSK',
          sealColor: AppColors.feiCui,
          title: tr('HSK 단어'),
          subtitle: 'HSK1 506 · HSK2 750 · HSK3 953 · HSK4 972 · HSK5 1,059',
          onTap: () => openPane(context, (_) => TopicVocabScreen(title: tr('HSK 단어'), asset: 'assets/data/vocab/hsk_words.json')),
        ),
        _section(tr('에피소드')),
        _NavRow(
          seal: '会话',
          title: tr('스토리 에피소드'),
          subtitle: tr('L1~L4 단원 · 진행 기록'),
          onTap: () => openPane(context, (_) => const LearnScreen()),
        ),
        _section(tr('참고')),
        _NavRow(
          seal: '青',
          sealColor: AppColors.tan,
          title: tr('패밀리 한자'),
          subtitle: tr('소리 부품이 같은 한자 가족 · 병음·성조'),
          onTap: () => openPane(context, (_) => const FamilyHanziScreen())
        ),
      ]),
    ]);
  }
}

// ────────── 복습 ──────────

/// 복습: 오늘의 복습(라이트너) · 문장 카드 · 복습 덱 · 한자 퀴즈 · 문법 테스트.
class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: _tabPadding(context), children: [
      _section(tr('오늘의 복습')),
      const _TodayReview(),
      const SizedBox(height: 12),
      _section(tr('복습')),
      _NavRow(
        seal: '文',
        title: tr('문장 플래시카드'),
        subtitle: tr('전 레벨 랜덤 20'),
        onTap: () => openFull(context, (_) => const SentenceFlashcardScreen()),
      ),
      _NavRow(
        seal: '复习',
        sealColor: AppColors.tan,
        title: tr('복습 덱'),
        subtitle: 'Flashcard',
        onTap: () => openPane(context, (_) => const FlashcardScreen()),
      ),
      _NavRow(
        seal: '汉字',
        sealColor: const Color(0xFFC62828),
        title: tr('한자 퀴즈'),
        subtitle: tr('회화 209 · HSK 1500'),
        onTap: () => openPane(context, (_) => const HanziHubScreen()),
      ),
      _NavRow(
        seal: '测试',
        sealColor: const Color(0xFF8B0000),
        title: tr('문법 테스트'),
        subtitle: tr('L1 기능어'),
        onTap: () => openPane(context, (_) => const GrammarTestScreen()),
      ),
    ]);
  }
}

/// 라이트너 7단계 복습(공용 엔진 `lib/review`) — 카드 = HSK 1·2급 단어(앞면 한국어 뜻, 뒷면 중국어 + 병음).
/// 하루 새 카드 20장, 정답→승급·오답→1단계, 틀린 카드는 세션 끝에 다시.
class _TodayReview extends StatefulWidget {
  const _TodayReview();
  @override
  State<_TodayReview> createState() => _TodayReviewState();
}

class _TodayReviewState extends State<_TodayReview> {
  List<ReviewCandidate> _cands = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ReviewCards.instance.ensureLoaded();
    final cands = [for (final c in ReviewCards.instance.byId.values) ReviewCandidate(c.id, category: 'hsk', soundKey: c.zh)];
    if (mounted) setState(() => _cands = cands);
  }

  ReviewFace? _resolve(String id) {
    final c = ReviewCards.instance.byId[id];
    if (c == null) return null;
    return ReviewFace(prompt: c.ko, target: c.zh, reading: c.pinyin);
  }

  @override
  Widget build(BuildContext context) {
    if (_cands.isEmpty) return const SizedBox.shrink();
    return ReviewTodayCard(
      candidates: _cands,
      resolve: _resolve,
      speak: (id, face) => TtsService.instance.speak(face.target),
      title: tr('오늘의 복습'),
    );
  }
}

// ────────── 탐색 ──────────

/// 탐색: 청크 검색 · 한자(발음부·패밀리) · 단어(HSK·주제별 표현).
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: _tabPadding(context), children: [
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openPane(context, (_) => const ChunkSearchScreen()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.zhuHong, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(tr('한자·병음·한국어로 검색하세요'), style: const TextStyle(color: AppColors.muted, fontSize: 14))),
          ]),
        ),
      ),
      _section(tr('한자')),
      _NavRow(
        seal: '声旁',
        sealColor: const Color(0xFF6A1B9A),
        title: tr('발음부'),
        subtitle: tr('발음부 + 한국 한자음'),
        onTap: () => openPane(context, (_) => const PhoneticRootsScreen()),
      ),
      _NavRow(
        seal: '家族',
        sealColor: AppColors.tan,
        title: tr('패밀리 한자'),
        subtitle: tr('소리 부품이 같은 한자 가족 · 병음·성조'),
        onTap: () => openPane(context, (_) => const FamilyHanziScreen()),
      ),
      _section(tr('단어')),
      _NavRow(
        seal: '词汇',
        sealColor: AppColors.feiCui,
        title: tr('주제별 단어'),
        subtitle: tr('여행 · 생활 주제별'),
        onTap: () => openPane(context, (_) => const TopicVocabScreen()),
      ),
      _NavRow(
        seal: '表达',
        sealColor: AppColors.jinDeep,
        title: tr('표현'),
        subtitle: tr('Expression · 필수표현'),
        onTap: () => openPane(context, (_) => TopicVocabScreen(title: tr('주제별 표현'), asset: 'assets/data/vocab/travel_expressions.json')),
      ),
      _NavRow(
        seal: '✨',
        sealColor: AppColors.copper,
        title: tr('맞춤 회화 만들기'),
        subtitle: tr('준비 중'),
        onTap: () => openPane(context, (_) => const CustomScriptScreen()),
      ),
    ]);
  }
}

// ────────── 나 ──────────

/// 프로필: 진행 + 프로필(계정·성과·학습자 프로필·설정·정보). 「앱 업데이트」 타일은 2026-11-07 삭제(배포는 Zealot·TestFlight).
class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: _tabPadding(context), children: [
      _section(tr('진행')),
      _NavRow(
        seal: '进',
        title: tr('진행'),
        subtitle: tr('학습 기록 · 달성률'),
        onTap: () => openPane(context, (_) => const ProgressScreen()),
      ),
      _section(tr('프로필 · 설정')),
      const ProfileScreen(embedded: true),
    ]);
  }
}

// ────────── 옛 스토리 에피소드(L1~L4) ──────────

/// 옛 「학습」 탭 — 스토리 에피소드 단원 목록(DB 진행도). 새 구조에서는 배우기 탭 「스토리 에피소드」로 들어온다.

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _filter = tr('전체');
  final List<String> _filters = [tr('전체'), tr('회화'), tr('한자'), tr('발음'), tr('단어'), 'HSK'];
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
    for (final level in EpisodeCatalog.levels) {
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
        title: Text(tr('스토리 에피소드'), style: TextStyle(color: AppColors.mo)),
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
      body: SafeArea(
        top: false,
        child: Column(
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
              trf('{0}편', [lesson.total]),
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
