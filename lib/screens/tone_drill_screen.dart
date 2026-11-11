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

/// 성조연습(2026-11-11 사용자 지시, 옛 「4성 매트릭스」 자리).
/// - 메뉴 = 성조 조합(「1성 1성 / 1성 2성 / 이렇게 메뉴를 구성해」), 조합마다 낱말 12개 = 묶음 3개(낱말 4 + 문장).
/// - 묶음 안: 「두 낱말만 놓고 반복 → 세 낱말 → 네 낱말」「그다음엔 문장」. 말하고 나면 바로 다음 낱말(「하고나면 바로 다음 단어로」).
/// - 판정은 참고용 — 「학습자에게 스트레스를 주진 않을 거야… 연습을 몇 번 했다는 것으로 진도… 한 단어당 5번, 5일에 나누어서 5번을 하면 완료」.
/// 채점은 talkverse_pitch(uk 담당 — 여기서 고치지 말 것). 자료 tools/build_tone_drill.py.
class ToneDrillHubScreen extends StatefulWidget {
  const ToneDrillHubScreen({super.key});

  @override
  State<ToneDrillHubScreen> createState() => _ToneDrillHubScreenState();
}

class _ToneDrillHubScreenState extends State<ToneDrillHubScreen> {
  ToneDrillData? _d;
  final Map<String, int> _days = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final d = await PitchCoach.instance.data();
    for (final c in d.combos) {
      for (final w in c.words) {
        _days[w.zh] = await PitchCoach.instance.days(w.zh);
      }
    }
    if (mounted) setState(() => _d = d);
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
                  tr('성조 조합을 골라 2글자 낱말을 따라 말해요. 처음엔 2개만 번갈아 나오고, 몇 번 말하면 하나씩 늘어나요. 마지막엔 문장이에요.\n곡선과 판정은 참고용이에요. 낱말마다 하루 한 번씩, 5일 동안 말해 보면 완료예요.\n녹음은 이 기기 안에서만 분석해요.'),
                  style: const TextStyle(color: AppColors.moLight, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _badge('0', AppColors.toneNeutral),
                title: Text(tr('준비: 한 글자 성조'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mo)),
                subtitle: Text(tr('ma·ba… 한 글자로 네 성조 익히기'), style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const TonePracticeScreen()),
              ),
              const BrushDivider(),
              for (final c in d.combos) _comboTile(c),
              const SizedBox(height: 24),
            ]),
        ]),
      ),
    );
  }

  Widget _comboTile(DrillCombo c) {
    final ws = c.words;
    final done = ws.where((w) => (_days[w.zh] ?? 0) >= PitchCoach.daysToFinish).length;
    final a = int.parse(c.cell[0]), b = int.parse(c.cell[2]);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [toneColor(a).withValues(alpha: 0.35), toneColor(b == 0 ? null : b).withValues(alpha: 0.35)]),
          border: Border.all(color: done == ws.length ? AppColors.feiCui : AppColors.jin, width: done == ws.length ? 2 : 1),
        ),
        child: done == ws.length
            ? const Icon(Icons.check, color: AppColors.feiCui)
            : Text(_cellLabel(c.cell), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mo)),
      ),
      title: Text(comboName(c.cell), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo)),
      subtitle: Text('${ws.take(4).map((w) => w.zh).join(' · ')} …  ${trf('완료 {0}/{1}', [done, ws.length])}', style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(ToneComboScreen(combo: c)),
    );
  }
}

/// '1-2' → 「1성 2성」, '3-0' → 「3성 경성」.
String comboName(String k) => '${_toneName(int.parse(k[0]))} ${_toneName(int.parse(k[2]))}';
String _cellLabel(String k) => k.endsWith('-0') ? trf('{0}·경', [k[0]]) : k.replaceAll('-', '·');

Widget _badge(String s, Color c) => CircleAvatar(
      radius: 15,
      backgroundColor: c.withValues(alpha: 0.15),
      child: Text(s, style: TextStyle(color: c, fontWeight: FontWeight.w800)),
    );

// 판정은 참고용 — 빨강·「다시」 없이.
const _good = Color(0xFF2E7D32), _close = Color(0xFFF9A825), _off = Color(0xFF78909C);
Color _vColor(ToneVerdict v) => switch (v) { ToneVerdict.good => _good, ToneVerdict.close => _close, ToneVerdict.off => _off };
String _vLabel(ToneVerdict v) => switch (v) { ToneVerdict.good => tr('좋아요'), ToneVerdict.close => tr('거의'), ToneVerdict.off => tr('다르게 들려요') };
String _hint(String k) => switch (k) {
      'keep_level' => tr('끝까지 평평하게'),
      'end_higher' => tr('끝을 더 올려요'),
      'middle_lower' => tr('가운데를 더 낮게'),
      'fall_more' => tr('더 확 떨어뜨려요'),
      _ => k,
    };
String _toneName(int t) => t == 0 ? tr('경성') : trf('{0}성', [t]);

/// 조합 하나: 아직 완료 안 된 낱말이 있는 첫 묶음부터 바로 시작(낱말 소리부터 — 「성조연습 누르면 바로 듣기가 나오게」).
class ToneComboScreen extends StatefulWidget {
  const ToneComboScreen({super.key, required this.combo});
  final DrillCombo combo;

  @override
  State<ToneComboScreen> createState() => _ToneComboScreenState();
}

class _ToneComboScreenState extends State<ToneComboScreen> {
  int? _i;

  @override
  void initState() {
    super.initState();
    () async {
      final rs = widget.combo.rounds;
      var i = 0;
      for (; i < rs.length; i++) {
        var open = false;
        for (final w in rs[i].words) {
          if (await PitchCoach.instance.days(w.zh) < PitchCoach.daysToFinish) open = true;
        }
        if (open) break;
      }
      if (mounted) setState(() => _i = i < rs.length ? i : 0);
    }();
  }

  @override
  Widget build(BuildContext context) {
    final i = _i;
    if (i == null) return const Scaffold(backgroundColor: AppColors.xuanZhi, body: Center(child: CircularProgressIndicator()));
    final n = widget.combo.rounds.length;
    return ToneRoundScreen(
      key: ValueKey(i),
      title: '${comboName(widget.combo.cell)} · ${trf('묶음 {0}/{1}', [i + 1, n])}',
      round: widget.combo.rounds[i],
      last: i == n - 1,
      onNext: () => setState(() => _i = (i + 1) % n),
    );
  }
}

/// 묶음 하나: 낱말 2개 → 3개 → 4개(낱말마다 이번에 [_perStep]번 말하면 하나 추가) → 문장.
class ToneRoundScreen extends StatefulWidget {
  const ToneRoundScreen({super.key, required this.title, required this.round, required this.onNext, this.last = false});
  final String title;
  final DrillRound round;
  final VoidCallback onNext;
  final bool last;

  @override
  State<ToneRoundScreen> createState() => _ToneRoundScreenState();
}

class _ToneRoundScreenState extends State<ToneRoundScreen> {
  static const _perStep = 3; // 이번 연습에서 낱말마다 이만큼 말하면 다음 낱말을 넣는다(판정과 무관)
  final _rnd = math.Random();
  int _active = 2;
  late final List<int> _tries = List.filled(widget.round.words.length, 0);
  final Map<String, int> _days = {};
  int _cur = 0;
  int? _last;
  bool _sentence = false;
  bool _recording = false;
  double _level = 0;
  DrillWord? _prevWord;
  SequenceScore? _prev;
  SentenceResult? _sres;
  String? _note;

  List<DrillWord> get _ws => widget.round.words;
  DrillWord get _w => _ws[_cur];

  @override
  void initState() {
    super.initState();
    () async {
      for (final w in _ws) {
        _days[w.zh] = await PitchCoach.instance.days(w.zh);
      }
      if (mounted) setState(() {});
    }();
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

  /// 앞 낱말도 계속 섞되, 이번에 덜 말한 낱말을 더 자주.
  int _pick() {
    final idx = [for (var i = 0; i < _active; i++) if (i != _last || _active == 1) i];
    final wt = [for (final i in idx) 1.0 + 2 * math.max(0, _perStep - _tries[i])];
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
    });
    _say();
  }

  void _advance() {
    if (_active < _ws.length) {
      setState(() {
        _active++;
        _last = _cur;
        _cur = _active - 1; // 새 낱말을 먼저 한 번
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
    final w = _w;
    setState(() => (_recording = true, _note = null));
    SequenceScore r;
    try {
      r = await PitchCoach.instance.scoreWord(w, onLevel: (l) => mounted ? setState(() => _level = l) : null);
    } catch (_) {
      r = const SequenceScore([], 0);
    }
    if (!mounted) return;
    if (!r.valid) {
      setState(() => (_recording = false, _note = tr('소리를 잘 못 들었어요 — 또렷하게 다시 말해 봐요')));
      return;
    }
    await PitchCoach.instance.countPractice(w.zh); // 판정과 무관하게 연습으로 센다(하루 한 번)
    final days = await PitchCoach.instance.days(w.zh);
    if (!mounted) return;
    setState(() {
      _recording = false;
      _prevWord = w;
      _prev = r;
      _days[w.zh] = days;
      _tries[_cur]++;
    });
    if ([for (var i = 0; i < _active; i++) _tries[i]].every((t) => t >= _perStep)) {
      _advance();
    } else {
      _next(); // 말하고 나면 바로 다음 낱말
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
      appBar: AppBar(title: Text(widget.title)),
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
          child: InkWell(
            // 잠금 없음 — 단계를 눌러 옮겨 갈 수 있다
            onTap: _recording
                ? null
                : () => setState(() {
                      _sentence = i == 3;
                      if (i < 3) {
                        _active = i + 2;
                        if (_cur >= _active) _cur = 0;
                      } else {
                        _playSentence();
                      }
                    }),
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
        ),
        if (i < 3) const SizedBox(width: 4),
      ],
    ]);
  }

  /// 낱말 칩: 연습한 날 ●(5일이면 완료).
  Widget _wordChip(int i) {
    final w = _ws[i], d = _days[w.zh] ?? 0, n = PitchCoach.daysToFinish;
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: i == _cur ? AppColors.zhuHong.withValues(alpha: 0.12) : AppColors.xuanZhiDeep,
      label: Text(d >= n ? '${w.zh}  ✓' : '${w.zh}  ${'●' * d}${'○' * (n - d)}', style: const TextStyle(fontSize: 12, color: AppColors.mo)),
    );
  }

  List<Widget> _wordView() {
    final w = _w;
    final targets = surfaceTones(w.tones, hanzi: w.zh.split(''));
    final chars = w.zh.split('');
    return [
      Wrap(spacing: 6, runSpacing: 6, children: [for (var i = 0; i < _active; i++) _wordChip(i)]),
      const SizedBox(height: 4),
      Text(tr('● = 연습한 날(하루 한 번 셈) · 5일이면 완료'), style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
      const SizedBox(height: 14),
      Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < chars.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(chars[i],
                  style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: toneColor(targets[i].shown == 0 ? null : targets[i].shown))),
            ),
        ]),
      ),
      Center(child: Text(w.rd, style: const TextStyle(fontSize: 18, color: AppColors.moLight, fontStyle: FontStyle.italic))),
      Center(child: Text(w.ko, style: const TextStyle(fontSize: 13, color: AppColors.moLight))),
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
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _recording ? null : _next, child: Text(tr('다음 낱말'))),
        TextButton(onPressed: _recording ? null : _advance, child: Text(_active < _ws.length ? tr('낱말 하나 더') : tr('문장으로'))),
      ]),
      if (_prev != null && _prevWord != null) ..._prevView(_prevWord!, _prev!),
    ];
  }

  /// 방금 말한 낱말 — 참고용 곡선·판정.
  List<Widget> _prevView(DrillWord w, SequenceScore r) {
    final targets = surfaceTones(w.tones, hanzi: w.zh.split(''));
    final chars = w.zh.split('');
    return [
      const SizedBox(height: 8),
      const BrushDivider(),
      const SizedBox(height: 8),
      Row(children: [
        Text(trf('방금: {0}', [w.zh]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo)),
        const SizedBox(width: 8),
        Text(tr('(참고용)'), style: const TextStyle(fontSize: 11, color: AppColors.moLight)),
      ]),
      const SizedBox(height: 6),
      SizedBox(height: 120, child: CustomPaint(painter: _SylPainter(targets, r), size: Size.infinite)),
      const SizedBox(height: 4),
      Text(tr('점선 = 목표 · 실선 = 내 소리(평소 내 음높이 기준)'), style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
      const SizedBox(height: 6),
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
      const SizedBox(height: 4),
      for (var i = 0; i < r.syllables.length; i++)
        if ((r.syllables[i].tone?.hints ?? const []).isNotEmpty)
          Text('${chars[i]}: ${r.syllables[i].tone!.hints.map(_hint).join(' · ')}', style: const TextStyle(fontSize: 13, color: AppColors.mo)),
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
          onPressed: _recording ? null : widget.onNext,
          child: Text(widget.last ? tr('처음 묶음으로') : tr('다음 묶음')),
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
