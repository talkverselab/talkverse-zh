import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talkverse_pitch/talkverse_pitch.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/dialogue_audio.dart';
import '../services/pitch_coach.dart';
import '../services/tone_analyzer.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import 'tone_practice_screen.dart';

/// 성조연습(2026-11-11 사용자 지시, 옛 「4성 매트릭스」 자리) — 「두 낱말만 놓고 반복 → 세 낱말 → 네 낱말」「그다음엔 문장」.
/// 묶음 10개(낱말 4 + 문장 1, tools/build_tone_drill.py). 채점은 talkverse_pitch(uk 담당 — 여기서 고치지 말 것).
/// 단계 잠금 없이 권장 순서만 보여 준다. 4×4+경성 격자는 진도 지도(통과한 칸 표시, 누르면 듣기).
class ToneDrillHubScreen extends StatefulWidget {
  const ToneDrillHubScreen({super.key, this.onPick});

  /// 바로 연습 화면에서 열었으면 묶음을 고를 때 그 화면으로 돌아가 바꾼다.
  final void Function(int index)? onPick;

  @override
  State<ToneDrillHubScreen> createState() => _ToneDrillHubScreenState();
}

class _ToneDrillHubScreenState extends State<ToneDrillHubScreen> {
  ToneDrillData? _d;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final d = await PitchCoach.instance.data();
    final done = await PitchCoach.instance.doneKeys();
    if (mounted) setState(() => (_d = d, _done = done));
  }

  Future<void> _open(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('성조연습'))),
      body: SafeArea(
        top: false,
        child: Stack(children: [
          const Positioned.fill(child: CloudPattern(opacity: 0.05)),
          if (d == null)
            const Center(child: CircularProgressIndicator())
          else
            ListView(padding: const EdgeInsets.all(16), children: [
              ChineseCard(
                title: tr('낱말 2개 → 3개 → 4개 → 문장'),
                sealText: '调',
                child: Text(
                  tr('한 묶음은 2글자 낱말 4개와 문장 하나예요. 처음엔 낱말 2개만 번갈아 말하고, 둘 다 3번 연속 통과하면 하나씩 늘어나요. 마지막엔 문장을 기준 음성과 겹쳐 봐요.\n녹음은 이 기기 안에서만 분석해요.'),
                  style: const TextStyle(color: AppColors.moLight, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _badge('0', AppColors.toneNeutral, false),
                title: Text(tr('준비: 한 글자 성조'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mo)),
                subtitle: Text(tr('ma·ba… 한 글자로 네 성조 익히기'), style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const TonePracticeScreen()),
              ),
              const BrushDivider(),
              const SizedBox(height: 8),
              Text(tr('묶음'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2)),
              for (var i = 0; i < d.rounds.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _badge('${i + 1}', AppColors.zhuHong, _done.contains('round:$i')),
                  title: Text(d.rounds[i].words.map((w) => w.zh).join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mo, fontSize: 16)),
                  subtitle: Text(d.rounds[i].words.map((w) => _cellLabel(w.cell)).join('  '), style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (widget.onPick != null) {
                      widget.onPick!(i);
                      Navigator.pop(context);
                    } else {
                      _open(ToneRoundScreen(index: i, round: d.rounds[i]));
                    }
                  },
                ),
              const SizedBox(height: 12),
              const BrushDivider(),
              const SizedBox(height: 8),
              Text(tr('진도 지도'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(tr('통과한 성조 조합에 ✓ — 칸을 누르면 들어요'), style: const TextStyle(fontSize: 11, color: AppColors.moLight)),
              const SizedBox(height: 8),
              _grid([for (var r = 1; r <= 4; r++) for (var c = 1; c <= 4; c++) '$r-$c'], d),
              const SizedBox(height: 8),
              _grid(['1-0', '2-0', '3-0', '4-0'], d),
              const SizedBox(height: 24),
            ]),
        ]),
      ),
    );
  }

  Widget _grid(List<String> keys, ToneDrillData d) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.1,
        children: [for (final k in keys) _cell(k, d.cells[k] ?? const [])],
      );

  Widget _cell(String k, List<DrillWord> ws) {
    final a = int.parse(k[0]), b = int.parse(k[2]);
    final done = _done.contains('cell:$k');
    final w = ws.isEmpty ? null : ws.first;
    return InkWell(
      onTap: w == null ? null : () => TtsService.instance.speak(w.zh),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            toneColor(a).withValues(alpha: done ? 0.55 : 0.18),
            toneColor(b == 0 ? null : b).withValues(alpha: done ? 0.55 : 0.18),
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: done ? AppColors.feiCui : AppColors.jin, width: done ? 2 : 1),
        ),
        child: Stack(children: [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_cellLabel(k), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.mo)),
              if (w != null) Text(w.zh, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.mo)),
              if (w != null) Text(w.rd, style: const TextStyle(fontSize: 9, color: AppColors.moLight, fontStyle: FontStyle.italic)),
            ]),
          ),
          if (done) const Positioned(right: 3, top: 2, child: Icon(Icons.check_circle, size: 13, color: AppColors.feiCui)),
        ]),
      ),
    );
  }
}

String _cellLabel(String k) => k.endsWith('-0') ? trf('{0}·경', [k[0]]) : k.replaceAll('-', '·');

Widget _badge(String s, Color c, bool done) => CircleAvatar(
      radius: 15,
      backgroundColor: done ? AppColors.feiCui : c.withValues(alpha: 0.15),
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(s, style: TextStyle(color: c, fontWeight: FontWeight.w800)),
    );

const _good = Color(0xFF2E7D32), _close = Color(0xFFF9A825), _off = Color(0xFFD32F2F);
Color _vColor(ToneVerdict v) => switch (v) { ToneVerdict.good => _good, ToneVerdict.close => _close, ToneVerdict.off => _off };
String _vLabel(ToneVerdict v) => switch (v) { ToneVerdict.good => tr('통과'), ToneVerdict.close => tr('거의'), ToneVerdict.off => tr('다시') };
String _hint(String k) => switch (k) {
      'keep_level' => tr('끝까지 평평하게'),
      'higher' => tr('더 높게'),
      'end_higher' => tr('끝을 더 올려요'),
      'middle_lower' => tr('가운데를 더 낮게'),
      'fall_more' => tr('더 확 떨어뜨려요'),
      'start_higher' => tr('더 높은 데서 시작'),
      _ => k,
    };
String _toneName(int t) => t == 0 ? tr('경성') : trf('{0}성', [t]);

/// 메뉴 「성조연습」 = 바로 연습(2026-11-11 사용자 지시 「성조연습 누르면 바로 듣기가 나오게」) — 안 끝낸 첫 묶음을 열고 낱말 소리부터 들려준다.
/// 묶음 목록·진도 지도는 위 버튼으로.
class ToneDrillStartScreen extends StatefulWidget {
  const ToneDrillStartScreen({super.key});

  @override
  State<ToneDrillStartScreen> createState() => _ToneDrillStartScreenState();
}

class _ToneDrillStartScreenState extends State<ToneDrillStartScreen> {
  int? _i;
  ToneDrillData? _d;

  @override
  void initState() {
    super.initState();
    () async {
      final d = await PitchCoach.instance.data();
      final done = await PitchCoach.instance.doneKeys();
      var i = 0;
      while (i < d.rounds.length - 1 && done.contains('round:$i')) {
        i++;
      }
      if (mounted) setState(() => (_d = d, _i = i));
    }();
  }

  @override
  Widget build(BuildContext context) {
    final d = _d, i = _i;
    if (d == null || i == null) return const Scaffold(backgroundColor: AppColors.xuanZhi, body: Center(child: CircularProgressIndicator()));
    return ToneRoundScreen(key: ValueKey(i), index: i, round: d.rounds[i], fromMenu: true, onPick: (n) => setState(() => _i = n));
  }
}

/// 묶음 하나: 낱말 2개 → 3개 → 4개(각자 3번 연속 통과하면 하나 추가) → 문장.
class ToneRoundScreen extends StatefulWidget {
  const ToneRoundScreen({super.key, required this.index, required this.round, this.fromMenu = false, this.onPick});
  final int index;
  final DrillRound round;

  /// 메뉴에서 바로 연 화면이면 위에 「묶음 목록」 버튼, 끝내면 다음 묶음으로.
  final bool fromMenu;
  final void Function(int index)? onPick;

  @override
  State<ToneRoundScreen> createState() => _ToneRoundScreenState();
}

class _ToneRoundScreenState extends State<ToneRoundScreen> {
  static const _need = 3; // 연속 통과 수
  final _rnd = math.Random();
  int _active = 2;
  late final List<int> _streak = List.filled(widget.round.words.length, 0);
  late final List<int> _miss = List.filled(widget.round.words.length, 0);
  int _cur = 0;
  int? _last;
  bool _sentence = false;
  bool _recording = false;
  double _level = 0;
  SequenceScore? _score;
  SentenceResult? _sres;
  String? _note;

  List<DrillWord> get _ws => widget.round.words;
  DrillWord get _w => _ws[_cur];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  /// 낱말이 바뀔 때마다 먼저 들려준다.
  void _say() {
    if (mounted && !_sentence && !_recording) TtsService.instance.speak(_w.zh);
  }

  @override
  void dispose() {
    ToneAnalyzer.instance.cancel();
    DialogueAudio.instance.stop();
    super.dispose();
  }

  /// 앞 낱말도 계속 섞고, 틀린 낱말·아직 안정 안 된 낱말을 더 자주.
  int _pick() {
    final idx = [for (var i = 0; i < _active; i++) if (i != _last || _active == 1) i];
    final wt = [for (final i in idx) 1.0 + 2 * _miss[i] + (_streak[i] < _need ? 2 : 0)];
    var x = _rnd.nextDouble() * wt.reduce((a, b) => a + b);
    for (var k = 0; k < idx.length; k++) {
      x -= wt[k];
      if (x <= 0) return idx[k];
    }
    return idx.last;
  }

  void _next() {
    setState(() {
      _last = _cur;
      _cur = _pick();
      _score = null;
    });
    _say();
  }

  void _advance({bool manual = false}) {
    if (_active < _ws.length) {
      setState(() {
        _active++;
        _last = _cur;
        _cur = _active - 1; // 새 낱말을 먼저 한 번
        _score = null;
        _note = trf('새 낱말 추가 — 이제 {0}개', [_active]);
      });
      _say();
    } else {
      setState(() {
        _sentence = true;
        _note = null;
      });
      _playSentence();
    }
  }

  Future<bool> _mic() async {
    if (await ToneAnalyzer.instance.hasPermission()) return true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('마이크 권한이 필요해요.')), backgroundColor: AppColors.zhuHongDeep));
    }
    return false;
  }

  Future<void> _recordWord() async {
    if (_recording || !await _mic()) return;
    await TtsService.instance.stop();
    setState(() => (_recording = true, _score = null, _note = null));
    SequenceScore r;
    try {
      r = await PitchCoach.instance.scoreWord(_w, onLevel: (l) => mounted ? setState(() => _level = l) : null);
    } catch (_) {
      r = const SequenceScore([], 0);
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _score = r;
      if (!r.valid) {
        _note = tr('소리를 잘 못 들었어요 — 또렷하게 다시 말해 봐요');
        return;
      }
      if (r.passed) {
        _streak[_cur]++;
        if (_streak[_cur] == _need) PitchCoach.instance.markDone('cell:${_w.cell}');
      } else {
        _streak[_cur] = 0;
        _miss[_cur]++;
      }
    });
    if (r.valid && [for (var i = 0; i < _active; i++) _streak[i]].every((s) => s >= _need)) {
      _advance();
    } else if (r.passed) {
      await Future.delayed(const Duration(milliseconds: 1200)); // 판정을 잠깐 보여 준 뒤 다음 낱말
      if (mounted && !_recording) _next();
    }
  }

  Future<void> _recordSentence() async {
    if (_recording || !await _mic()) return;
    await DialogueAudio.instance.stop();
    setState(() => (_recording = true, _sres = null));
    SentenceResult r;
    try {
      r = await PitchCoach.instance.scoreSentence(widget.round.sentence, onLevel: (l) => mounted ? setState(() => _level = l) : null);
    } catch (_) {
      r = SentenceResult(null, null);
    }
    if (mounted) setState(() => (_recording = false, _sres = r));
  }

  Future<void> _playSentence() async {
    final s = widget.round.sentence;
    if (!await DialogueAudio.instance.play(s.ep, s.turn)) await TtsService.instance.speak(s.zh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(trf('성조연습 · 묶음 {0}', [widget.index + 1])),
        actions: [
          if (widget.fromMenu)
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ToneDrillHubScreen(onPick: widget.onPick)));
              },
              icon: const Icon(Icons.grid_on, size: 16),
              label: Text(tr('묶음 목록')),
              style: TextButton.styleFrom(foregroundColor: AppColors.mo),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _steps(),
          const SizedBox(height: 12),
          if (_note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_note!, style: const TextStyle(color: AppColors.zhuHongDeep, fontWeight: FontWeight.w700)),
            ),
          if (!_sentence) ..._wordView() else ..._sentenceView(),
        ]),
      ),
    );
  }

  Widget _steps() {
    final labels = [tr('낱말 2개'), tr('3개'), tr('4개'), tr('문장')];
    final at = _sentence ? 3 : _active - 2;
    return Row(children: [
      for (var i = 0; i < 4; i++) ...[
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i < at ? AppColors.feiCui.withValues(alpha: 0.15) : i == at ? AppColors.zhuHong.withValues(alpha: 0.15) : AppColors.xuanZhiDeep,
              border: Border.all(color: i == at ? AppColors.zhuHong : AppColors.line),
            ),
            child: Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: i == at ? FontWeight.w800 : FontWeight.w500, color: AppColors.mo)),
          ),
        ),
        if (i < 3) const SizedBox(width: 4),
      ],
    ]);
  }

  List<Widget> _wordView() {
    final w = _w;
    final r = _score;
    final targets = surfaceTones(w.tones, hanzi: w.zh.split(''));
    final chars = w.zh.split('');
    return [
      // 지금 낱말들의 연속 통과
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var i = 0; i < _active; i++)
          Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: i == _cur ? AppColors.zhuHong.withValues(alpha: 0.12) : AppColors.xuanZhiDeep,
            label: Text('${_ws[i].zh}  ${'●' * math.min(_streak[i], _need)}${'○' * math.max(0, _need - _streak[i])}',
                style: const TextStyle(fontSize: 12, color: AppColors.mo)),
          ),
      ]),
      const SizedBox(height: 14),
      Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < chars.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(chars[i],
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: r != null && r.valid ? _vColor(r.syllables[i].verdict) : toneColor(targets[i].shown == 0 ? null : targets[i].shown),
                  )),
            ),
        ]),
      ),
      Center(child: Text(w.rd, style: const TextStyle(fontSize: 18, color: AppColors.moLight, fontStyle: FontStyle.italic))),
      Center(child: Text(w.ko, style: const TextStyle(fontSize: 13, color: AppColors.moLight))),
      const SizedBox(height: 12),
      SizedBox(height: 150, child: CustomPaint(painter: _SylPainter(targets, r), size: Size.infinite)),
      const SizedBox(height: 4),
      Text(tr('점선 = 목표 · 실선 = 내 소리(평소 내 음높이 기준)'), style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
      const SizedBox(height: 8),
      if (r != null && r.valid) ...[
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < r.syllables.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _vColor(r.syllables[i].verdict).withValues(alpha: 0.12), border: Border.all(color: _vColor(r.syllables[i].verdict))),
              child: Text(
                '${chars[i]} ${_vLabel(r.syllables[i].verdict)}'
                '${r.syllables[i].tone != null && r.syllables[i].verdict != ToneVerdict.good ? ' · ${trf('{0}처럼 들려요', [_toneName(r.syllables[i].tone!.heard)])}' : ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _vColor(r.syllables[i].verdict)),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        for (var i = 0; i < r.syllables.length; i++)
          if ((r.syllables[i].tone?.hints ?? const []).isNotEmpty)
            Text('${chars[i]}: ${r.syllables[i].tone!.hints.map(_hint).join(' · ')}', style: const TextStyle(fontSize: 13, color: AppColors.mo)),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _recording ? null : () => TtsService.instance.speak(w.zh),
            icon: const Icon(Icons.volume_up),
            label: Text(tr('듣기')),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _recording ? AppColors.zhuHongDeep : AppColors.zhuHong),
            onPressed: _recording ? null : _recordWord,
            icon: Icon(_recording ? Icons.graphic_eq : Icons.mic),
            label: Text(_recording ? tr('말하세요…') : tr('따라 말하기')),
          ),
        ),
      ]),
      if (_recording) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: (_level * 6).clamp(0.0, 1.0))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _recording ? null : _next, child: Text(tr('다음 낱말'))),
        TextButton(onPressed: _recording ? null : () => _advance(manual: true), child: Text(_active < _ws.length ? tr('낱말 하나 더') : tr('문장으로'))),
      ]),
    ];
  }

  List<Widget> _sentenceView() {
    final s = widget.round.sentence;
    final r = _sres;
    return [
      ChineseCard(
        title: tr('문장'),
        sealText: '句',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.zh, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.mo)),
          const SizedBox(height: 4),
          Text(s.pinyin, style: const TextStyle(fontSize: 14, color: AppColors.moLight, fontStyle: FontStyle.italic)),
          Text(s.ko, style: const TextStyle(fontSize: 13, color: AppColors.moLight)),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(height: 150, child: CustomPaint(painter: _SentPainter(s.ref, r?.mine), size: Size.infinite)),
      const SizedBox(height: 4),
      Text(tr('회색 = 기준 음성 · 색 = 내 소리 — 문장은 판정 없이 겹쳐 보기만 해요'), style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
      if (r != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            r.match == null ? tr('소리를 잘 못 들었어요 — 또렷하게 다시 말해 봐요') : trf('참고 점수 {0}', [(r.match!.score * 100).round()]),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.mo),
          ),
        ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _recording ? null : _playSentence, icon: const Icon(Icons.volume_up), label: Text(tr('듣기')))),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _recording ? AppColors.zhuHongDeep : AppColors.zhuHong),
            onPressed: _recording ? null : _recordSentence,
            icon: Icon(_recording ? Icons.graphic_eq : Icons.mic),
            label: Text(_recording ? tr('말하세요…') : tr('따라 말하기')),
          ),
        ),
      ]),
      if (_recording) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: (_level * 6).clamp(0.0, 1.0))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _recording ? null : () => setState(() => (_sentence = false, _sres = null)), child: Text(tr('낱말로 돌아가기'))),
        FilledButton(
          onPressed: _recording
              ? null
              : () async {
                  await PitchCoach.instance.markDone('round:${widget.index}');
                  if (!mounted) return;
                  if (widget.onPick != null) {
                    widget.onPick!((widget.index + 1) % 10);
                  } else {
                    Navigator.pop(context);
                  }
                },
          child: Text(tr('묶음 끝내기')),
        ),
      ]),
    ];
  }
}

/// 목표 성조 곡선(평소 음높이 기준 반음, 20점) — 그림용 대표 모양.
List<double> _ideal(SyllableTarget t) {
  double lerp(List<double> k, double x) {
    final p = x * (k.length - 1), i = p.floor().clamp(0, k.length - 2);
    return k[i] + (k[i + 1] - k[i]) * (p - i);
  }

  final k = t.neutral
      ? [-1.0, -2.0]
      : t.half
          ? [-2.0, -4.5, -5.0]
          : switch (t.shown) { 1 => [3.0, 3.0], 2 => [-1.0, -0.5, 3.5], 3 => [-1.0, -4.0, -5.0, -2.0], _ => [4.0, 1.0, -4.0] };
  return [for (var i = 0; i < 20; i++) lerp(k, i / 19)];
}

const _yMax = 8.0;
double _y(double st, Size s) => s.height / 2 - (st.clamp(-_yMax, _yMax) / _yMax) * (s.height / 2 - 6);

void _frame(Canvas c, Size s) {
  c.drawRect(Offset.zero & s, Paint()..color = AppColors.xuanZhiDeep);
  c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), Paint()..color = AppColors.line..strokeWidth = 1);
}

void _curve(Canvas c, List<double> v, Rect box, Size s, Paint p, {bool dashed = false}) {
  if (v.length < 2) return;
  final pts = [for (var i = 0; i < v.length; i++) Offset(box.left + box.width * i / (v.length - 1), _y(v[i], s))];
  for (var i = 0; i + 1 < pts.length; i++) {
    if (dashed && i.isOdd) continue;
    c.drawLine(pts[i], pts[i + 1], p);
  }
}

class _SylPainter extends CustomPainter {
  _SylPainter(this.targets, this.score);
  final List<SyllableTarget> targets;
  final SequenceScore? score;

  @override
  void paint(Canvas c, Size s) {
    _frame(c, s);
    final n = targets.length, w = s.width / n;
    for (var i = 0; i < n; i++) {
      final box = Rect.fromLTWH(i * w + 8, 0, w - 16, s.height);
      if (i > 0) c.drawLine(Offset(i * w, 0), Offset(i * w, s.height), Paint()..color = AppColors.line);
      final tone = targets[i].shown;
      _curve(c, _ideal(targets[i]), box, s,
          Paint()
            ..color = toneColor(tone == 0 ? null : tone).withValues(alpha: 0.6)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
          dashed: true);
      final sc = score;
      if (sc != null && sc.valid && sc.syllables[i].contour != null) {
        _curve(c, sc.syllables[i].contour!.st, box, s,
            Paint()
              ..color = _vColor(sc.syllables[i].verdict)
              ..strokeWidth = 3.5
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SylPainter o) => o.score != score || o.targets != targets;
}

class _SentPainter extends CustomPainter {
  _SentPainter(this.ref, this.mine);
  final Contour ref;
  final Contour? mine;

  @override
  void paint(Canvas c, Size s) {
    _frame(c, s);
    final box = Rect.fromLTWH(8, 0, s.width - 16, s.height);
    _curve(c, ref.centered().st, box, s, Paint()..color = AppColors.muted.withValues(alpha: 0.7)..strokeWidth = 3..strokeCap = StrokeCap.round);
    final m = mine;
    if (m != null) _curve(c, m.centered().st, box, s, Paint()..color = AppColors.zhuHong..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _SentPainter o) => o.mine != mine;
}
