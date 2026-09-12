import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/speak_match.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import 'episode_screen.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

const _kLimits = [10, 5, 2]; // 단계별 제한 초
const _kBatch = 4; // 한 번에 테스트하는 문장 수
const _kStagePref = 'speak_stage';
const _kShowHint = 'speak_show_hint';
const _kBestPrefix = 'speak_best_';

/// 말하기 연습 목록 — 학습한 회화(에피소드 화면에서 체크한 턴이 있는 회화)를 보여주고,
/// 탭하면 바로 테스트가 시작된다.
class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _EpisodeEntry {
  final EpisodeMeta meta;
  final List<TurnRow> turns; // 학습한 턴만 (없으면 전체)
  final int total;
  final int passed3; // 3단계 통과 문장 수
  _EpisodeEntry(this.meta, this.turns, this.total, this.passed3);
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  bool _loading = true;
  bool _anyLearned = false;
  int _stage = 0;
  List<_EpisodeEntry> _entries = [];
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _stage = (_prefs!.getInt(_kStagePref) ?? 0).clamp(0, _kLimits.length - 1);
    await EpisodeCatalog.instance.ensureLoaded();
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds = {
      for (final p in progress)
        if (p.learned || p.reviewCount > 0) p.turnId
    };
    _anyLearned = learnedIds.isNotEmpty;
    final entries = <_EpisodeEntry>[];
    for (final meta in EpisodeCatalog.instance.all) {
      final ep = turns
          .where((t) =>
              t.level == meta.level &&
              t.dialect == 'north' &&
              t.episodeId == meta.id)
          .toList()
        ..sort((a, b) => a.num.compareTo(b.num));
      if (ep.isEmpty) continue;
      final learned = ep.where((t) => learnedIds.contains(t.id)).toList();
      if (_anyLearned && learned.isEmpty) continue;
      final use = _anyLearned ? learned : ep;
      final p3 = use
          .where((t) => (_prefs!.getInt('$_kBestPrefix${t.id}') ?? 0) >= 3)
          .length;
      entries.add(_EpisodeEntry(meta, use, ep.length, p3));
    }
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _open(_EpisodeEntry e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpeakingTestScreen(
          title: '${e.meta.level} · ${e.meta.title}',
          turns: e.turns,
          stage: _stage,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('말하기 연습'))),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.zhuHong))
            : Column(
                children: [
                  _stagePicker(),
                  const GreekKeyDivider(),
                  Expanded(
                    child: _entries.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(tr('회화 데이터가 없어요.'),
                                textAlign: TextAlign.center),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _entries.length + 1,
                            itemBuilder: (context, i) {
                              if (i == 0) return _headerNote();
                              final e = _entries[i - 1];
                              return _EpisodeTile(
                                entry: e,
                                onTap: () => _open(e),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _headerNote() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        _anyLearned
            ? tr('회화 화면에서 학습 체크한 문장을 4개씩 테스트해요. 탭하면 바로 시작됩니다.')
            : tr('아직 학습 체크한 문장이 없어 전체 회화를 보여줘요. 회화 화면에서 문장을 체크하면 그 문장만 나옵니다.'),
        style: const TextStyle(
            fontSize: 12, color: AppColors.moLight, height: 1.5),
      ),
    );
  }

  Widget _stagePicker() {
    return Container(
      color: AppColors.xuanZhiDeep,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < _kLimits.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() => _stage = i);
                  _prefs?.setInt(_kStagePref, i);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: i == _stage ? AppColors.zhuHong : AppColors.xuanZhi,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color:
                            i == _stage ? Colors.transparent : AppColors.jin),
                  ),
                  child: Text(
                    trf('{0}단계 · {1}초', [i + 1, _kLimits[i]]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color:
                          i == _stage ? AppColors.xuanZhi : AppColors.moLight,
                    ),
                  ),
                ),
              ),
            ),
            if (i < _kLimits.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final _EpisodeEntry entry;
  final VoidCallback onTap;
  const _EpisodeTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
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
          child: Row(
            children: [
              Text(e.meta.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.meta.level} · ${e.meta.title}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mo),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trf('학습 {0}/{1}문장 · 3단계 통과 {2}', [e.turns.length, e.total, e.passed3]),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.moLight),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.mic, color: AppColors.zhuHong),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

enum _Phase { preview, starting, listening, judging, shown, batchDone, allDone }

/// 테스트 화면 — 들어오자마자 시작. 문장마다 자동 녹음·판정, 4문장 뒤 '계속'.
class SpeakingTestScreen extends StatefulWidget {
  final String title;
  final List<TurnRow> turns;
  final int stage; // 0..2
  const SpeakingTestScreen({
    super.key,
    required this.title,
    required this.turns,
    required this.stage,
  });

  @override
  State<SpeakingTestScreen> createState() => _SpeakingTestScreenState();
}

class _SpeakingTestScreenState extends State<SpeakingTestScreen>
    with SingleTickerProviderStateMixin {
  SharedPreferences? _prefs;
  bool _showHint = true;
  bool _sttReady = true;

  int _index = 0;
  _Phase _phase = _Phase.preview;
  String _heard = '';
  final Map<int, bool> _results = {}; // index → pass
  final Map<int, String> _heardBy = {};

  late final AnimationController _timer;
  Completer<void>? _finalDone;
  int _seq = 0;
  Timer? _delay;

  int get _limit => _kLimits[widget.stage];
  TurnRow get _cur => widget.turns[_index];
  int get _batchStart => (_index ~/ _kBatch) * _kBatch;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onTimeUp();
      });
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _showHint = _prefs!.getBool(_kShowHint) ?? true;
    _sttReady = await SpeechService.instance.init();
    if (!mounted) return;
    setState(() {});
    if (!_sttReady) {
      _snack(tr('음성 인식을 사용할 수 없어요. 마이크 권한과 Google 음성 서비스를 확인하세요.'));
      return;
    }
    _startSentence();
  }

  @override
  void dispose() {
    _seq++;
    _delay?.cancel();
    _timer.dispose();
    SpeechService.instance.cancel();
    super.dispose();
  }

  // ── 흐름 ──────────────────────────────────────────────────────

  void _startSentence() {
    _delay?.cancel();
    setState(() {
      _phase = _Phase.preview;
      _heard = '';
    });
    // 문장을 읽을 잠깐의 여유 뒤 자동 녹음
    _delay = Timer(const Duration(milliseconds: 1200), _record);
  }

  Future<void> _record() async {
    if (!mounted) return;
    final seq = ++_seq;
    setState(() => _phase = _Phase.starting);
    _finalDone = Completer<void>();
    final target = _cur.zh;
    final ok = await SpeechService.instance.listen(
      maxFor: Duration(seconds: _limit + 3),
      onResult: (words, isFinal) {
        if (seq != _seq) return;
        _heard = words;
        if (_phase == _Phase.listening && SpeakMatch.pass(target, words)) {
          _finish(true);
          return;
        }
        if (isFinal && !(_finalDone?.isCompleted ?? true)) {
          _finalDone!.complete();
        }
        if (mounted) setState(() {});
      },
    );
    if (!mounted || seq != _seq) return;
    if (!ok) {
      _finish(false);
      return;
    }
    setState(() => _phase = _Phase.listening);
    _timer
      ..duration = Duration(seconds: _limit)
      ..forward(from: 0);
  }

  Future<void> _onTimeUp() async {
    if (_phase != _Phase.listening) return;
    final seq = _seq;
    setState(() => _phase = _Phase.judging);
    await SpeechService.instance.stop();
    final done = _finalDone;
    if (done != null && !done.isCompleted) {
      await done.future
          .timeout(const Duration(milliseconds: 1200), onTimeout: () {});
    }
    if (!mounted || seq != _seq || _phase != _Phase.judging) return;
    _finish(SpeakMatch.pass(_cur.zh, _heard));
  }

  void _finish(bool passed) {
    _seq++;
    _timer.stop();
    SpeechService.instance.cancel();
    if (!mounted) return;
    _results[_index] = passed;
    _heardBy[_index] = _heard;
    if (passed) {
      final id = _cur.id;
      final stageDone = widget.stage + 1;
      if ((_prefs?.getInt('$_kBestPrefix$id') ?? 0) < stageDone) {
        _prefs?.setInt('$_kBestPrefix$id', stageDone);
      }
    }
    setState(() => _phase = _Phase.shown);
    _delay = Timer(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    final last = _index == widget.turns.length - 1;
    final batchEnd = (_index + 1) % _kBatch == 0;
    if (last) {
      setState(() => _phase = _Phase.allDone);
    } else if (batchEnd) {
      setState(() => _phase = _Phase.batchDone);
    } else {
      _index++;
      _startSentence();
    }
  }

  void _continue() {
    _index++;
    _startSentence();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.zhuHongDeep),
    );
  }

  Future<void> _toggleHint() async {
    setState(() => _showHint = !_showHint);
    await _prefs?.setBool(_kShowHint, _showHint);
  }

  // ── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: _showHint ? tr('힌트 숨기기') : tr('힌트 보기'),
            onPressed: _toggleHint,
            icon: Icon(_showHint ? Icons.lightbulb : Icons.lightbulb_outline),
          ),
          const KoReadingToggleAction(),
        ],
      ),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: switch (_phase) {
          _Phase.batchDone => _batchSummary(final_: false),
          _Phase.allDone => _batchSummary(final_: true),
          _ => _testBody(),
        },
      ),
    );
  }

  Widget _progressBar() {
    final total = widget.turns.length;
    return Container(
      color: AppColors.xuanZhiDeep,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            trf('{0}단계 · {1}초', [widget.stage + 1, _limit]),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.zhuHong),
          ),
          const Spacer(),
          for (var i = _batchStart;
              i < _batchStart + _kBatch && i < total;
              i++) ...[
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(left: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _results[i] == null
                    ? (i == _index ? AppColors.jin : AppColors.xuanZhi)
                    : _results[i]!
                        ? AppColors.feiCui
                        : AppColors.zhuHong,
                border: Border.all(color: AppColors.jin),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _results[i] == null && i != _index
                      ? AppColors.moLight
                      : AppColors.xuanZhi,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Text('${_index + 1}/$total',
              style: const TextStyle(fontSize: 11, color: AppColors.moLight)),
        ],
      ),
    );
  }

  Widget _testBody() {
    final t = _cur;
    return Column(
      children: [
        _progressBar(),
        const GreekKeyDivider(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomInset(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.ko ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mo,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                if (_showHint)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.xuanZhiDeep,
                      border: Border.all(
                          color: AppColors.jin.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          t.zh,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.zhuHongDeep),
                        ),
                        if (t.pinyin != null && t.pinyin!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: KoReadingText(
                              t.pinyin!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.moLight),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                _statusPanel(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPanel() {
    switch (_phase) {
      case _Phase.preview:
        return Text(tr('곧 녹음이 시작돼요…'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.moLight));
      case _Phase.starting:
        return Text(tr('🎙 마이크 여는 중…'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.moLight));
      case _Phase.listening:
      case _Phase.judging:
        return Column(
          children: [
            AnimatedBuilder(
              animation: _timer,
              builder: (_, _) {
                final remain = _limit * (1 - _timer.value);
                return Column(
                  children: [
                    Text(
                      _phase == _Phase.judging
                          ? tr('판정 중…')
                          : trf('{0}초', [remain.toStringAsFixed(1)]),
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.zhuHong),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1 - _timer.value,
                        minHeight: 8,
                        backgroundColor: AppColors.xuanZhiDeep,
                        color:
                            remain < 1.5 ? AppColors.zhuHong : AppColors.jin,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              _heard.isEmpty ? tr('🎙 중국어로 말하세요') : _heard,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.mo,
                  fontWeight: FontWeight.w600),
            ),
          ],
        );
      case _Phase.shown:
        final pass = _results[_index] ?? false;
        return Column(
          children: [
            Text(pass ? 'PASS' : 'FAIL',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: pass ? AppColors.feiCui : AppColors.zhuHong)),
            if (_heard.isNotEmpty)
              Text(_heard,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.moLight)),
          ],
        );
      case _Phase.batchDone:
      case _Phase.allDone:
        return const SizedBox.shrink();
    }
  }

  Widget _batchSummary({required bool final_}) {
    final start = _batchStart;
    final end = (_index + 1).clamp(0, widget.turns.length);
    final passedAll = _results.values.where((v) => v).length;
    final total = widget.turns.length;
    return Column(
      children: [
        _progressBar(),
        const GreekKeyDivider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                final_
                    ? trf('🎉 모든 문장 완료 — {0}문장 중 PASS {1}', [total, passedAll])
                    : trf('{0}~{1}번 문장 결과', [start + 1, end]),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mo),
              ),
              const SizedBox(height: 16),
              for (var i = final_ ? 0 : start; i < end; i++)
                _ResultRow(
                  index: i,
                  turn: widget.turns[i],
                  pass: _results[i] ?? false,
                  heard: _heardBy[i] ?? '',
                  showHint: _showHint,
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset(context)),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: AppColors.jin.withValues(alpha: 0.4))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.moLight,
                    side: const BorderSide(color: AppColors.jin),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(tr('목록으로')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: final_
                      ? () {
                          setState(() {
                            _index = 0;
                            _results.clear();
                            _heardBy.clear();
                          });
                          _startSentence();
                        }
                      : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.zhuHong,
                    foregroundColor: AppColors.xuanZhi,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2),
                  ),
                  icon: Icon(final_ ? Icons.replay : Icons.play_arrow),
                  label: Text(final_ ? tr('처음부터 다시') : tr('계속')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final int index;
  final TurnRow turn;
  final bool pass;
  final String heard;
  final bool showHint;
  const _ResultRow({
    required this.index,
    required this.turn,
    required this.pass,
    required this.heard,
    required this.showHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(
            color: (pass ? AppColors.feiCui : AppColors.zhuHong)
                .withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(pass ? Icons.check_circle : Icons.cancel,
              color: pass ? AppColors.feiCui : AppColors.zhuHong, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ${turn.ko ?? ''}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mo)),
                const SizedBox(height: 2),
                Text(turn.zh,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.zhuHongDeep)),
                if (turn.pinyin != null)
                  KoReadingText(turn.pinyin!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.moLight)),
                if (!pass && heard.isNotEmpty)
                  Text(trf('인식: {0}', [heard]),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.moLight)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up,
                size: 18, color: AppColors.zhuHong),
            onPressed: () => TtsService.instance.speak(turn.zh),
          ),
        ],
      ),
    );
  }
}
