import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/episode_play_pane.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22).
/// 레벨 고르기 → 코스(편 3·5·10 고르기) → 편마다 듣기·따라 말하기·확인 문제 → 코스 시험 80% 통과 → 다음 코스.

CurriculumService get _cs => CurriculumService.instance;

String _levelName(String lv) => '$lv ${tr(DialogueService.levelKo[lv] ?? '')}';

const _goalKo = {'light': '가볍게', 'normal': '보통', 'focus': '집중'};

/// 홈(배우기 탭) 카드 — 「오늘: 복습 N · 새 편 N」과 진행 막대, 다 하면 「오늘 분량 끝」·연속 일수.
class CurriculumHomeCard extends StatefulWidget {
  const CurriculumHomeCard({super.key});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  @override
  void initState() {
    super.initState();
    _cs.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _cs,
        builder: (context, _) {
          final s = _cs.state;
          final today = _cs.today;
          final started = s.level != null;
          final done = started && s.doneToday(today);
          final streak = s.streakShown(today);
          final sub = !started
              ? tr('레벨에서 회화를 골라 매일 연습하고, 80% 넘으면 다음 코스로')
              : done
                  ? (streak > 0 ? trf('오늘 분량 끝 · 연속 {0}일', [streak]) : tr('오늘 분량 끝'))
                  : trf('오늘: 복습 {0} · 새 편 {1}', [s.dueOn(today).length, s.newLeft(today)]);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openPane(context, (_) => const CurriculumScreen()),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(color: AppColors.xuanZhi, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
              child: Row(children: [
                const SealStamp(text: '课程', size: 36, color: AppColors.zhuHong),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('토크버스 커리큘럼'), style: AppFonts.uiText(size: 14.5, weight: FontWeight.w600, color: AppColors.mo)),
                    const SizedBox(height: 2),
                    Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.captionText(size: 11.5, color: done ? AppColors.feiCui : AppColors.muted)),
                    if (started) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: s.progress(today), minHeight: 5, backgroundColor: AppColors.line, color: done ? AppColors.feiCui : AppColors.zhuHong),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppColors.line, size: 18),
              ]),
            ),
          );
        },
      );
}

/// 커리큘럼 첫 화면: 레벨이 없으면 레벨 고르기, 있으면 코스 화면.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  bool _ready = false;
  bool _pickLevel = false;
  bool _picking = false; // 새 코스 고르기 화면
  bool _confirmDrop = false; // 진행 중 코스를 버릴지 묻는 칸
  int _size = 5;
  final List<String> _chosen = [];

  @override
  void initState() {
    super.initState();
    () async {
      await Future.wait([_cs.load(), DialogueService.instance.ensureLoaded()]);
      if (mounted) setState(() => _ready = true);
    }();
  }

  List<Dialogue> get _levelList => DialogueService.instance.list(region: _cs.state.level);

  List<String> get _levels => [for (final lv in DialogueService.levels) if (DialogueService.instance.count(lv) > 0) lv];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: SafeArea(
        top: false,
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(listenable: _cs, builder: (context, _) => _body()),
      ),
    );
  }

  Widget _body() {
    final s = _cs.state;
    if (s.level == null || _pickLevel) return _levelPicker();
    final c = s.course;
    if (c == null || c.passed || _picking) return _coursePicker();
    return _courseView(c);
  }

  // ── 레벨 고르기 ──
  Widget _levelPicker() {
    final levels = _levels;
    final rec = levels.isEmpty ? null : levels.first;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(tr('레벨 고르기'), style: AppFonts.titleText()),
      const SizedBox(height: 4),
      Text(tr('회화 레벨이에요. 처음이면 가장 낮은 레벨부터 권해요.'), style: AppFonts.captionText(size: 12.5)),
      const SizedBox(height: 12),
      for (final lv in levels)
        Card(
          elevation: 0,
          color: _cs.state.level == lv ? AppColors.xuanZhiDeep : AppColors.xuanZhi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
          child: ListTile(
            title: Text(_levelName(lv), style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.mo)),
            subtitle: Text(trf('{0}편 · 통과 {1}', [DialogueService.instance.count(lv), DialogueService.instance.list(region: lv).where((d) => _cs.state.passedDialogues.contains(d.id)).length])),
            trailing: lv == rec && _cs.state.level == null ? Chip(label: Text(tr('추천'))) : const Icon(Icons.chevron_right),
            onTap: () async {
              await _cs.setLevel(lv);
              setState(() {
                _pickLevel = false;
                _chosen.clear();
              });
            },
          ),
        ),
    ]);
  }

  // ── 위쪽: 레벨·하루 목표·오늘 분량 ──
  Widget _header() {
    final s = _cs.state;
    final today = _cs.today;
    final due = s.dueOn(today).length;
    final done = s.doneToday(today);
    final streak = s.streakShown(today);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(_levelName(s.level!), style: AppFonts.titleText())),
        TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
      ]),
      Wrap(spacing: 6, children: [
        for (final g in kDailyGoals.keys)
          ChoiceChip(
            label: Text(trf('{0} · 새 편 {1}', [tr(_goalKo[g]!), kDailyGoals[g]])),
            selected: s.dailyGoal == g,
            onSelected: (_) => _cs.setDailyGoal(g),
          ),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            done ? (streak > 0 ? trf('오늘 분량 끝 · 연속 {0}일', [streak]) : tr('오늘 분량 끝')) : trf('오늘: 복습 {0} · 새 편 {1}', [due, s.newLeft(today)]),
            style: AppFonts.uiText(size: 14, weight: FontWeight.w600, color: done ? AppColors.feiCui : AppColors.mo),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: s.progress(today), minHeight: 6, backgroundColor: AppColors.line, color: done ? AppColors.feiCui : AppColors.zhuHong),
          ),
          if (due > 0) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _startReview,
              icon: const Icon(Icons.replay),
              label: Text(trf('복습 {0}줄 먼저', [due])),
            ),
          ],
        ]),
      ),
    ]);
  }

  Future<void> _startReview() async {
    final due = _cs.dueTurns();
    final pool = _levelList.isEmpty ? DialogueService.instance.all : _levelList;
    final qs = buildQuestions(due, [...pool, for (final x in due) x.$1], limit: 20);
    if (qs.isEmpty) return;
    await openFull(context, (_) => CurriculumQuizScreen(
          title: tr('오늘 복습'),
          questions: qs,
          onAnswer: (q, ok) => _cs.reviewDone(q.lineId, ok),
        ));
    if (mounted) setState(() {});
  }

  // ── 코스 고르기 ──
  Widget _coursePicker() {
    final s = _cs.state;
    final list = _levelList;
    final passed = s.passedDialogues.toSet();
    final prev = s.course;
    final active = prev != null && !prev.passed;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), children: [
          _header(),
          if (prev != null && prev.passed) ...[
            const SizedBox(height: 12),
            Text(trf('지난 코스 통과 · {0}%', [prev.examScores.isEmpty ? 0 : prev.examScores.last]), style: AppFonts.uiText(color: AppColors.feiCui, weight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          Text(tr('새 코스 — 연습할 회화 고르기'), style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.mo)),
          const SizedBox(height: 6),
          Row(children: [
            for (final n in kCourseSizes)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(trf('{0}편', [n])),
                  selected: _size == n,
                  onSelected: (_) => setState(() {
                    _size = n;
                    if (_chosen.length > n) _chosen.removeRange(n, _chosen.length);
                  }),
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                final r = recommend(list, passed, _chosen, _size);
                _chosen
                  ..clear()
                  ..addAll(r);
              }),
              child: Text(tr('추천으로 채우기')),
            ),
          ]),
          Text(trf('{0}/{1} 고름', [_chosen.length, _size]), style: AppFonts.captionText()),
          const SizedBox(height: 4),
          for (final d in list)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _chosen.contains(d.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  if (_chosen.length < _size) _chosen.add(d.id);
                } else {
                  _chosen.remove(d.id);
                }
              }),
              title: Text('${d.emoji} ${d.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.uiText(size: 14, color: AppColors.mo)),
              subtitle: Text(tr(DialogueService.islandKo[d.island] ?? d.island), style: AppFonts.captionText()),
              secondary: passed.contains(d.id) ? Text(tr('통과'), style: AppFonts.captionText(color: AppColors.feiCui, weight: FontWeight.w600)) : null,
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: _confirmDrop
            ? _dropConfirm(onYes: _start)
            : Row(children: [
                if (_picking)
                  TextButton(onPressed: () => setState(() => _picking = false), child: Text(tr('지금 코스로'))),
                const Spacer(),
                FilledButton(
                  onPressed: _chosen.isEmpty ? null : () => active ? setState(() => _confirmDrop = true) : _start(),
                  child: Text(trf('코스 시작 · {0}편', [_chosen.length])),
                ),
              ]),
      ),
    ]);
  }

  Widget _dropConfirm({required VoidCallback onYes}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('지금 코스를 그만두고 새 코스를 시작할까요? 지금 코스의 연습 표시는 사라져요(복습 줄은 남아요).'), style: AppFonts.uiText(color: AppColors.mo)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => setState(() => _confirmDrop = false), child: Text(tr('취소'))),
            FilledButton(onPressed: onYes, child: Text(tr('새 코스 시작'))),
          ]),
        ]),
      );

  Future<void> _start() async {
    await _cs.startCourse([..._chosen]);
    setState(() {
      _chosen.clear();
      _picking = false;
      _confirmDrop = false;
    });
  }

  // ── 진행 중 코스 ──
  Widget _courseView(Course c) {
    final svc = DialogueService.instance;
    final ds = [for (final id in c.dialogueIds) ?svc.byId(id)];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      _header(),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Text(trf('지금 코스 · {0}/{1}편 연습', [c.practiced.where(c.dialogueIds.contains).length, c.dialogueIds.length]), style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.mo))),
        TextButton(onPressed: () => setState(() => _picking = true), child: Text(tr('새 코스 고르기'))),
      ]),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(trf('지난 시험 {0}% — 80% 넘으면 통과. 틀린 편만 다시 연습해요.', [c.examScores.last]), style: AppFonts.captionText(size: 12, color: AppColors.hanyu)),
        ),
      for (final d in ds)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
          child: ListTile(
            leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.uiText(size: 14, weight: FontWeight.w600, color: AppColors.mo)),
            subtitle: Text(c.practiced.contains(d.id) ? tr('연습 끝') : tr('연습 전'), style: AppFonts.captionText(color: c.practiced.contains(d.id) ? AppColors.feiCui : AppColors.muted)),
            trailing: Icon(c.practiced.contains(d.id) ? Icons.check_circle : Icons.play_circle_outline, color: c.practiced.contains(d.id) ? AppColors.feiCui : AppColors.zhuHong),
            onTap: () async {
              await openFull(context, (_) => CurriculumPracticeScreen(dialogue: d));
              if (mounted) setState(() {});
            },
          ),
        ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: c.allPracticed ? () => _exam(ds) : null,
        icon: const Icon(Icons.flag),
        label: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 코스 시험이 열려요')),
      ),
    ]);
  }

  Future<void> _exam(List<Dialogue> ds) async {
    final qs = examQuestions(ds, [..._levelList, ...ds]);
    if (qs.isEmpty) return;
    await openFull(context, (_) => CurriculumQuizScreen(
          title: tr('코스 시험'),
          questions: qs,
          exam: true,
          onFinish: (correct, total, wrong) => _cs.examDone(correct, total, {for (final q in wrong) q.dialogueId}),
        ));
    if (mounted) setState(() {});
  }
}

/// 편 하나 연습: ① 듣기·읽기 ② 따라 말하기(선택) ③ 확인 문제.
class CurriculumPracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  const CurriculumPracticeScreen({super.key, required this.dialogue});
  @override
  State<CurriculumPracticeScreen> createState() => _CurriculumPracticeScreenState();
}

class _CurriculumPracticeScreenState extends State<CurriculumPracticeScreen> {
  int _step = 0;
  int? _repeating; // 따라 말하기에서 반복 중인 턴 번호

  Dialogue get d => widget.dialogue;

  @override
  void dispose() {
    DialogueAudio.instance.stop();
    super.dispose();
  }

  Future<void> _repeat(DialogueTurn t) async {
    await DialogueAudio.instance.stop();
    setState(() => _repeating = t.num);
    for (var i = 0; i < 3 && mounted && _repeating == t.num; i++) {
      await speakTurn(d, t, rate: 0.85);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    if (mounted && _repeating == t.num) setState(() => _repeating = null);
  }

  Future<void> _quiz() async {
    await DialogueAudio.instance.stop();
    final pool = [...DialogueService.instance.list(region: d.region), d];
    final qs = practiceQuestions(d, pool);
    if (!mounted) return;
    if (qs.isEmpty) {
      await CurriculumService.instance.practiceDone(d, const {});
      if (mounted) Navigator.pop(context);
      return;
    }
    final nav = Navigator.of(context);
    await nav.push(MaterialPageRoute(
      builder: (_) => CurriculumQuizScreen(
        title: tr('확인 문제'),
        questions: qs,
        onFinish: (correct, total, wrong) => CurriculumService.instance.practiceDone(d, {for (final q in wrong) q.lineId}),
      ),
    ));
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [tr('듣기·읽기'), tr('따라 말하기'), tr('확인 문제')];
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: i == 2 ? _quiz : () => setState(() => _step = i),
                    child: Column(children: [
                      Text('${i + 1}. ${steps[i]}', style: AppFonts.uiText(size: 12.5, weight: _step == i ? FontWeight.w700 : FontWeight.w400, color: _step == i ? AppColors.zhuHong : AppColors.muted)),
                      const SizedBox(height: 4),
                      Container(height: 3, color: _step == i ? AppColors.zhuHong : AppColors.line),
                    ]),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: _step == 0
                ? EpisodePlayPane(key: ValueKey(d.id), dialogue: d, autoPlay: false)
                : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), children: [
                    Text(tr('줄을 누르면 세 번 들려줘요. 따라 말해 보세요(점수는 없어요).'), style: AppFonts.captionText(size: 12)),
                    const SizedBox(height: 6),
                    for (final t in d.turns)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _repeat(t),
                        leading: Icon(_repeating == t.num ? Icons.graphic_eq : Icons.repeat, color: _repeating == t.num ? AppColors.zhuHong : AppColors.muted),
                        title: Text(DialogueAudio.instance.textOf(d.id, t.num) ?? LearnerPrefs.fill(t.zh), style: AppFonts.zhText(size: 17, color: AppColors.mo)),
                        subtitle: Text(LearnerPrefs.fill(t.ko, ko: true), style: AppFonts.captionText(size: 12)),
                      ),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _step == 0 ? () => setState(() => _step = 1) : _quiz,
                child: Text(_step == 0 ? tr('다음: 따라 말하기') : tr('다음: 확인 문제')),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 4지선다 문제 화면(편 연습·복습·코스 시험 공용).
class CurriculumQuizScreen extends StatefulWidget {
  final String title;
  final List<CurriculumQuestion> questions;
  final bool exam;
  final void Function(CurriculumQuestion q, bool ok)? onAnswer;
  final Future<Object?> Function(int correct, int total, List<CurriculumQuestion> wrong)? onFinish;
  const CurriculumQuizScreen({super.key, required this.title, required this.questions, this.exam = false, this.onAnswer, this.onFinish});
  @override
  State<CurriculumQuizScreen> createState() => _CurriculumQuizScreenState();
}

class _CurriculumQuizScreenState extends State<CurriculumQuizScreen> {
  int _i = 0;
  int? _picked;
  int _correct = 0;
  final List<CurriculumQuestion> _wrong = [];
  bool _finished = false;
  bool? _passed;

  CurriculumQuestion get q => widget.questions[_i];

  void _pick(int k) {
    if (_picked != null) return;
    final ok = k == q.answer;
    setState(() {
      _picked = k;
      if (ok) {
        _correct++;
      } else {
        _wrong.add(q);
      }
    });
    widget.onAnswer?.call(q, ok);
  }

  Future<void> _next() async {
    if (_i + 1 < widget.questions.length) {
      setState(() {
        _i++;
        _picked = null;
      });
      return;
    }
    final r = await widget.onFinish?.call(_correct, widget.questions.length, _wrong);
    if (!mounted) return;
    setState(() {
      _finished = true;
      _passed = r is bool ? r : null;
    });
  }

  @override
  void dispose() {
    DialogueAudio.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(top: false, child: _finished ? _result(total) : _question(total)),
    );
  }

  Widget _result(int total) {
    final pct = scorePercent(_correct, total);
    final pass = pct >= kPassPercent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$pct%', style: AppFonts.titleText(size: 44, color: pass ? AppColors.feiCui : AppColors.hanyu)),
          const SizedBox(height: 6),
          Text(trf('{0}문제 중 {1}개 맞힘', [total, _correct]), style: AppFonts.uiText()),
          const SizedBox(height: 10),
          if (widget.exam)
            Text(_passed == true ? tr('코스 통과! 다음 코스를 골라요.') : tr('80%에 못 미쳤어요. 틀린 편만 다시 연습하고 다시 시험 봐요.'),
                textAlign: TextAlign.center, style: AppFonts.uiText(weight: FontWeight.w600, color: _passed == true ? AppColors.feiCui : AppColors.mo))
          else if (_wrong.isNotEmpty)
            Text(tr('틀린 줄은 내일 복습에 먼저 나와요'), style: AppFonts.captionText(size: 12.5)),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('마침'))),
        ]),
      ),
    );
  }

  Widget _question(int total) {
    final d = DialogueService.instance.byId(q.dialogueId);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      LinearProgressIndicator(value: (_i + 1) / total, minHeight: 4, backgroundColor: AppColors.line, color: AppColors.zhuHong),
      const SizedBox(height: 8),
      Text('${_i + 1} / $total · ${q.kind == 'blank' ? tr('빈칸에 들어갈 낱말은?') : tr('이 줄의 뜻은?')}', style: AppFonts.captionText(size: 12)),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(q.prompt, style: AppFonts.zhText(size: 22, weight: FontWeight.w600, color: AppColors.mo, height: 1.4))),
        if (d != null) IconButton(onPressed: () => speakTurn(d, q.turn), icon: const Icon(Icons.volume_up, color: AppColors.zhuHong)),
      ]),
      if (q.hint.isNotEmpty) Text(q.hint, style: AppFonts.uiText(size: 13.5)),
      if (_picked != null && q.kind == 'meaning') Text(q.turn.pinyin, style: AppFonts.pinyinText()),
      const SizedBox(height: 16),
      for (var k = 0; k < q.options.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: _picked == null
                  ? null
                  : k == q.answer
                      ? AppColors.feiCui.withValues(alpha: 0.12)
                      : (k == _picked ? AppColors.hanyu.withValues(alpha: 0.12) : null),
              side: BorderSide(color: _picked != null && k == q.answer ? AppColors.feiCui : AppColors.line),
            ),
            onPressed: () => _pick(k),
            child: Text(q.options[k], style: q.kind == 'blank' ? AppFonts.zhText(size: 18, color: AppColors.mo) : AppFonts.uiText(size: 14, color: AppColors.mo)),
          ),
        ),
      if (_picked != null) ...[
        const SizedBox(height: 8),
        FilledButton(onPressed: _next, child: Text(_i + 1 < total ? tr('다음') : tr('결과 보기'))),
      ],
    ]);
  }
}
