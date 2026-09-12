import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import 'episode_screen.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

/// 카드 학습 상태: 몰라요 / 공부중 / 알아요.
/// DB 매핑: 알아요=learned true · 공부중=learned false+reviewCount>0 ·
/// 몰라요=learned false+reviewCount 0.
enum CardState { unknown, studying, known }

/// 회화 문장 플래시카드.
/// - 기본: 한국어 앞면 → 뒤집으면 중국어 (방향 토글 가능, 설정 저장)
/// - 한국어 앞면에는 병음 힌트 표시 (힌트 토글 가능, 설정 저장)
/// - [meta] 있으면 해당 에피소드 전체 턴, 없으면 전 레벨 랜덤 20문장
/// - [initialIndex]로 특정 턴부터 시작 (에피소드 버블 탭 진입)
class SentenceFlashcardScreen extends StatefulWidget {
  final EpisodeMeta? meta;
  final int initialIndex;
  const SentenceFlashcardScreen({super.key, this.meta, this.initialIndex = 0});

  @override
  State<SentenceFlashcardScreen> createState() =>
      _SentenceFlashcardScreenState();
}

class _SentenceFlashcardScreenState extends State<SentenceFlashcardScreen> {
  static const _kKoFirst = 'flash_ko_first';
  static const _kShowHint = 'flash_show_hint';

  List<TurnRow> _cards = [];
  final Map<int, CardState> _states = {}; // turnId → 상태
  bool _loading = true;
  int _index = 0;
  bool _flipped = false;
  bool _koFirst = true;
  bool _showHint = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _koFirst = _prefs!.getBool(_kKoFirst) ?? true;
    _showHint = _prefs!.getBool(_kShowHint) ?? true;

    List<TurnRow> turns;
    final meta = widget.meta;
    if (meta != null) {
      turns = await (appDb.select(appDb.turns)
            ..where((t) =>
                t.level.equals(meta.level) &
                t.dialect.equals('north') &
                t.episodeId.equals(meta.id))
            ..orderBy([(t) => OrderingTerm.asc(t.num)]))
          .get();
    } else {
      turns = await appDb.select(appDb.turns).get();
      turns.shuffle();
      turns = turns.take(20).toList();
    }
    final progress = await appDb.select(appDb.userProgress).get();
    final byId = {for (final p in progress) p.turnId: p};
    if (!mounted) return;
    setState(() {
      _cards = turns;
      for (final t in turns) {
        final p = byId[t.id];
        _states[t.id] = p == null
            ? CardState.unknown
            : p.learned
                ? CardState.known
                : (p.reviewCount > 0 ? CardState.studying : CardState.unknown);
      }
      _index =
          turns.isEmpty ? 0 : widget.initialIndex.clamp(0, turns.length - 1);
      _loading = false;
    });
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _cards.length) return;
    setState(() {
      _index = next;
      _flipped = false;
    });
  }

  Future<void> _mark(CardState state) async {
    final turn = _cards[_index];
    setState(() => _states[turn.id] = state);
    await appDb.into(appDb.userProgress).insertOnConflictUpdate(
          UserProgressCompanion(
            turnId: Value(turn.id),
            learned: Value(state == CardState.known),
            reviewCount: Value(state == CardState.unknown ? 0 : 1),
            lastReviewed: Value(DateTime.now()),
          ),
        );
    if (!mounted) return;
    if (_index < _cards.length - 1) {
      _go(1);
    } else {
      final known =
          _states.values.where((s) => s == CardState.known).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trf('🎉 마지막 카드! {0}장 중 알아요 {1}장', [_cards.length, known])),
          backgroundColor: AppColors.feiCui,
        ),
      );
    }
  }

  Future<void> _toggleDirection() async {
    setState(() {
      _koFirst = !_koFirst;
      _flipped = false;
    });
    await _prefs?.setBool(_kKoFirst, _koFirst);
  }

  Future<void> _toggleHint() async {
    setState(() => _showHint = !_showHint);
    await _prefs?.setBool(_kShowHint, _showHint);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
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
            Text(
              meta == null ? tr('문장 플래시카드') : trf('{0} {1} 카드', [meta.emoji, meta.title]),
              style: const TextStyle(
                  color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              meta == null ? tr('전 레벨 랜덤 20') : trf('{0} 회화', [meta.level]),
              style: TextStyle(
                  color: AppColors.moLight, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: _koFirst ? tr('한국어 먼저 (탭: 중국어 먼저)') : tr('중국어 먼저 (탭: 한국어 먼저)'),
            onPressed: _toggleDirection,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.zhuHong),
                color: AppColors.zhuHong.withValues(alpha: 0.08),
              ),
              child: Text(
                _koFirst ? tr('한→中') : tr('中→한'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.zhuHong,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _showHint ? tr('힌트 켜짐') : tr('힌트 꺼짐'),
            onPressed: _toggleHint,
            icon: Icon(
              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showHint ? AppColors.jinDeep : AppColors.moLight,
              size: 22,
            ),
          ),
          if (_cards.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${_index + 1}/${_cards.length}',
                  style: const TextStyle(
                    color: AppColors.zhuHong,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
            : _cards.isEmpty
                ? Center(
                    child: Text(tr('카드가 없어요'),
                        style: TextStyle(color: AppColors.moLight)))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final turn = _cards[_index];
    final isA = turn.speaker == 'A';
    final state = _states[turn.id] ?? CardState.unknown;
    // 앞면/뒷면 내용 결정
    final showZhSide = _koFirst ? _flipped : !_flipped;

    return Column(
      children: [
        const GreekKeyDivider(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: showZhSide ? AppColors.xuanZhiDeep : AppColors.xuanZhi,
                  border: Border.all(
                    color: switch (state) {
                      CardState.known => AppColors.feiCui,
                      CardState.studying => AppColors.jinDeep,
                      CardState.unknown => AppColors.zhuHong,
                    },
                    width: 1.6,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isA ? AppColors.zhuHong : AppColors.jin,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              isA ? 'M' : '丽',
                              style: const TextStyle(
                                color: AppColors.xuanZhi,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StateChip(state: state),
                          if (showZhSide)
                            IconButton(
                              icon: const Icon(Icons.volume_up,
                                  color: AppColors.zhuHong),
                              onPressed: () => TtsService.instance.speakAs(
                                turn.zh,
                                gender: isA ? 'male' : 'female',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (showZhSide) ...[
                        // ── 중국어 면 ──
                        Text(
                          turn.zh,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mo,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (turn.pinyin != null)
                          KoReadingText(
                            turn.pinyin!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              color: AppColors.zhuHong,
                            ),
                          ),
                        if (_flipped && turn.ko != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            turn.ko!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.moLight,
                            ),
                          ),
                        ],
                      ] else ...[
                        // ── 한국어 면 ──
                        Text(
                          turn.ko ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mo,
                            height: 1.4,
                          ),
                        ),
                        if (_koFirst && _showHint && turn.pinyin != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.jin.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: AppColors.jin.withValues(alpha: 0.7)),
                            ),
                            child: Text(
                              '💡 ${turn.pinyin}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                color: AppColors.jinDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (_flipped &&
                          turn.note != null &&
                          turn.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.jin.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.jin),
                          ),
                          child: Text(
                            '💡 ${turn.note}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mo,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        _flipped ? tr('탭해서 앞면 보기') : tr('탭해서 뒤집기'),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.moLight,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── 이전/다음 이동 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _NavButton(
                icon: Icons.arrow_back,
                label: tr('이전'),
                enabled: _index > 0,
                onTap: () => _go(-1),
              ),
              const Spacer(),
              _NavButton(
                icon: Icons.arrow_forward,
                label: tr('다음'),
                trailingIcon: true,
                enabled: _index < _cards.length - 1,
                onTap: () => _go(1),
              ),
            ],
          ),
        ),
        // ── 3단계 평가 ──
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 26 + bottomInset(context)),
          child: Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  label: tr('몰라요'),
                  color: AppColors.zhuHong,
                  selected: state == CardState.unknown,
                  onTap: () => _mark(CardState.unknown),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AnswerButton(
                  label: tr('공부중'),
                  color: AppColors.jinDeep,
                  selected: state == CardState.studying,
                  onTap: () => _mark(CardState.studying),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AnswerButton(
                  label: tr('알아요 ✓'),
                  color: AppColors.feiCui,
                  selected: state == CardState.known,
                  onTap: () => _mark(CardState.known),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final CardState state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      CardState.known => (tr('알아요'), AppColors.feiCui),
      CardState.studying => (tr('공부중'), AppColors.jinDeep),
      CardState.unknown => (tr('몰라요'), AppColors.moLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool trailingIcon;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.mo : AppColors.moLight.withValues(alpha: 0.5);
    final children = [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    ];
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: enabled
                ? AppColors.jin
                : AppColors.moLight.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 0),
        shape: const RoundedRectangleBorder(),
      ),
      onPressed: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailingIcon ? children.reversed.toList() : children,
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.xuanZhi,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: onTap,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: onTap,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          );
  }
}
