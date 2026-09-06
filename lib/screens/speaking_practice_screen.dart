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

/// 말하기 연습 — 한국어 문장을 보고 중국어로 말한다.
///
/// 1단계 10초 · 2단계 5초 · 3단계 2초 안에 문장 전체를 말하면 PASS.
/// - TEST 를 누르는 즉시 녹음, 부분 인식 결과마다 바로 판정 (성조·병음 무시).
/// - 제한 시간이 끝나면 녹음을 닫고 마지막 인식 결과로 판정.
/// - 힌트(한자+병음)는 토글로 켜고 끌 수 있으며 설정이 저장된다.
class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

enum _Phase { idle, starting, listening, judging, pass, fail }

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen>
    with SingleTickerProviderStateMixin {
  static const _kShowHint = 'speak_show_hint';
  static const _kMaxLen = 'speak_max_len';
  static const _kBestPrefix = 'speak_best_';
  static const _sessionSize = 10;
  static const _limits = [10, 5, 2]; // 초, 단계별

  SharedPreferences? _prefs;
  List<TurnRow> _items = [];
  bool _loading = true;
  bool _sttReady = true;
  bool _showHint = true;
  int _maxLen = 12;

  int _index = 0;
  int _stage = 0; // 0..2
  _Phase _phase = _Phase.idle;
  String _heard = '';
  double _lastScore = 0;
  final Map<int, int> _sessionBest = {}; // turnId → 통과 단계 수 (0..3)

  late final AnimationController _timer;
  Completer<void>? _finalDone;
  int _attemptSeq = 0;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onTimeUp();
      });
    _load();
  }

  @override
  void dispose() {
    _timer.dispose();
    SpeechService.instance.cancel();
    SpeechService.instance.onStatus = null;
    super.dispose();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _showHint = _prefs!.getBool(_kShowHint) ?? true;
    _maxLen = _prefs!.getInt(_kMaxLen) ?? 12;
    _sttReady = await SpeechService.instance.init();
    await _buildSession();
  }

  Future<void> _buildSession() async {
    final all = await appDb.select(appDb.turns).get();
    final pool = all.where((t) {
      final n = SpeakMatch.syllables(t.zh).length;
      return n >= 2 && n <= _maxLen && (t.ko ?? '').trim().isNotEmpty;
    }).toList()
      ..shuffle();
    if (!mounted) return;
    setState(() {
      _items = pool.take(_sessionSize).toList();
      _index = 0;
      _stage = 0;
      _phase = _Phase.idle;
      _heard = '';
      _sessionBest.clear();
      _loading = false;
    });
  }

  TurnRow get _cur => _items[_index];
  int get _limit => _limits[_stage];

  // ── 테스트 흐름 ──────────────────────────────────────────────

  Future<void> _startTest() async {
    if (_phase == _Phase.listening || _phase == _Phase.starting) return;
    final seq = ++_attemptSeq;
    setState(() {
      _phase = _Phase.starting;
      _heard = '';
      _lastScore = 0;
    });
    _finalDone = Completer<void>();
    final target = _cur.zh;
    final ok = await SpeechService.instance.listen(
      maxFor: Duration(seconds: _limit + 3),
      onResult: (words, isFinal) {
        if (seq != _attemptSeq) return;
        _heard = words;
        _lastScore = SpeakMatch.score(target, words);
        if (_phase == _Phase.listening && SpeakMatch.pass(target, words)) {
          _finish(true); // 부분 결과에서 바로 PASS
          return;
        }
        if (isFinal && !(_finalDone?.isCompleted ?? true)) {
          _finalDone!.complete();
        }
        if (mounted) setState(() {});
      },
    );
    if (!mounted || seq != _attemptSeq) return;
    if (!ok) {
      setState(() {
        _phase = _Phase.fail;
        _heard = '';
      });
      _snack('마이크/음성 인식을 시작할 수 없어요. 권한과 Google 음성 서비스를 확인하세요.');
      return;
    }
    setState(() => _phase = _Phase.listening);
    _timer
      ..duration = Duration(seconds: _limit)
      ..forward(from: 0);
  }

  Future<void> _onTimeUp() async {
    if (_phase != _Phase.listening) return;
    final seq = _attemptSeq;
    setState(() => _phase = _Phase.judging);
    await SpeechService.instance.stop();
    // 최종 결과가 도착할 시간을 잠깐만 준다 (인식 지연은 학습자 책임이 아님)
    final done = _finalDone;
    if (done != null && !done.isCompleted) {
      await done.future.timeout(const Duration(milliseconds: 1200),
          onTimeout: () {});
    }
    if (!mounted || seq != _attemptSeq || _phase != _Phase.judging) return;
    _finish(SpeakMatch.pass(_cur.zh, _heard));
  }

  void _finish(bool passed) {
    _attemptSeq++; // 이후 도착하는 결과 무시
    _timer.stop();
    SpeechService.instance.cancel();
    if (!mounted) return;
    if (passed) {
      final stageDone = _stage + 1;
      final id = _cur.id;
      if ((_sessionBest[id] ?? 0) < stageDone) _sessionBest[id] = stageDone;
      final prevBest = _prefs?.getInt('$_kBestPrefix$id') ?? 0;
      if (stageDone > prevBest) _prefs?.setInt('$_kBestPrefix$id', stageDone);
    }
    setState(() => _phase = passed ? _Phase.pass : _Phase.fail);
    if (passed) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || _phase != _Phase.pass) return;
        if (_stage < _limits.length - 1) {
          setState(() {
            _stage++;
            _phase = _Phase.idle;
            _heard = '';
          });
        } else {
          _next();
        }
      });
    }
  }

  void _next() {
    if (_index >= _items.length - 1) {
      _showSummary();
      return;
    }
    setState(() {
      _index++;
      _stage = 0;
      _phase = _Phase.idle;
      _heard = '';
    });
  }

  void _skip() {
    _attemptSeq++;
    _timer.stop();
    SpeechService.instance.cancel();
    _next();
  }

  Future<void> _cancelTest() async {
    _attemptSeq++;
    _timer.stop();
    await SpeechService.instance.cancel();
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  void _showSummary() {
    final cleared = _sessionBest.values.where((v) => v >= 3).length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.xuanZhi,
        title: const Text('🎉 세션 완료'),
        content: Text(
          '${_items.length}문장 중 3단계 통과 $cleared문장\n'
          '${_items.map((t) => '${'★' * (_sessionBest[t.id] ?? 0)}${'☆' * (3 - (_sessionBest[t.id] ?? 0))}  ${t.zh}').join('\n')}',
          style: const TextStyle(fontSize: 12, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.zhuHong),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              _buildSession();
            },
            child: const Text('새 세션'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHint() async {
    setState(() => _showHint = !_showHint);
    await _prefs?.setBool(_kShowHint, _showHint);
  }

  Future<void> _setMaxLen(int n) async {
    _maxLen = n;
    await _prefs?.setInt(_kMaxLen, n);
    _attemptSeq++;
    _timer.stop();
    await SpeechService.instance.cancel();
    if (!mounted) return;
    setState(() => _loading = true);
    await _buildSession();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.zhuHongDeep),
    );
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Text('말하기 연습'),
        actions: [
          IconButton(
            tooltip: _showHint ? '힌트 숨기기' : '힌트 보기',
            onPressed: _toggleHint,
            icon: Icon(_showHint ? Icons.lightbulb : Icons.lightbulb_outline),
          ),
          const KoReadingToggleAction(),
          PopupMenuButton<int>(
            tooltip: '문장 길이',
            onSelected: _setMaxLen,
            itemBuilder: (_) => [
              for (final n in const [8, 12, 20])
                CheckedPopupMenuItem(
                  value: n,
                  checked: _maxLen == n,
                  child: Text(n == 20 ? '긴 문장까지' : '$n음절 이하'),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _items.isEmpty
              ? const Center(child: Text('연습할 문장이 없어요.'))
              : _body(),
    );
  }

  Widget _body() {
    final t = _cur;
    final listening =
        _phase == _Phase.listening || _phase == _Phase.starting;
    return Column(
      children: [
        _stageBar(),
        const GreekKeyDivider(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_index + 1} / ${_items.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.moLight,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                // 한국어 문장 (문제)
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
                // 힌트: 한자 + 병음
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showHint
                      ? Container(
                          key: const ValueKey('hint'),
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
                                        fontSize: 13,
                                        color: AppColors.moLight),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          key: const ValueKey('nohint'),
                          onPressed: _toggleHint,
                          icon: const Icon(Icons.lightbulb_outline, size: 16),
                          label: const Text('힌트 보기'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.moLight),
                        ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: listening
                        ? null
                        : () => TtsService.instance.speak(t.zh),
                    icon: const Icon(Icons.volume_up, size: 18),
                    label: const Text('원어민 발음 듣기'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.zhuHong),
                  ),
                ),
                const SizedBox(height: 14),
                _resultPanel(),
              ],
            ),
          ),
        ),
        _bottomBar(listening),
      ],
    );
  }

  Widget _stageBar() {
    return Container(
      color: AppColors.xuanZhiDeep,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < _limits.length; i++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: i == _stage
                      ? AppColors.zhuHong
                      : i < _stage
                          ? AppColors.feiCui
                          : AppColors.xuanZhi,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: i <= _stage ? Colors.transparent : AppColors.jin),
                ),
                child: Text(
                  i < _stage ? '✓ ${i + 1}단계' : '${i + 1}단계 · ${_limits[i]}초',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: i <= _stage ? AppColors.xuanZhi : AppColors.moLight,
                  ),
                ),
              ),
            ),
            if (i < _limits.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _resultPanel() {
    switch (_phase) {
      case _Phase.idle:
        return Text(
          _stage == 0
              ? 'TEST 를 누르면 바로 녹음이 시작돼요.\n$_limit초 안에 문장 전체를 중국어로 말하세요.'
              : '${_stage + 1}단계 — 이번엔 $_limit초!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.moLight, height: 1.5),
        );
      case _Phase.starting:
        return const Text('🎙 마이크 여는 중…',
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
                          ? '판정 중…'
                          : '${remain.toStringAsFixed(1)}초',
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
                        color: remain < 1.5
                            ? AppColors.zhuHong
                            : AppColors.jin,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              _heard.isEmpty ? '🎙 듣고 있어요…' : _heard,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.mo,
                  fontWeight: FontWeight.w600),
            ),
          ],
        );
      case _Phase.pass:
        return Column(
          children: [
            const Text('PASS',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.feiCui,
                    letterSpacing: 4)),
            if (_heard.isNotEmpty)
              Text(_heard,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.moLight)),
          ],
        );
      case _Phase.fail:
        return Column(
          children: [
            const Text('FAIL',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.zhuHong,
                    letterSpacing: 4)),
            const SizedBox(height: 4),
            Text(
              _heard.isEmpty
                  ? (SpeechService.instance.lastError == null
                      ? '아무 말도 인식되지 않았어요.'
                      : '인식 실패: ${SpeechService.instance.lastError}')
                  : '인식: $_heard  (${(_lastScore * 100).round()}%)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.moLight),
            ),
            const SizedBox(height: 4),
            Text(
              '정답: ${_cur.zh}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.zhuHongDeep, fontWeight: FontWeight.w700),
            ),
          ],
        );
    }
  }

  Widget _bottomBar(bool listening) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border(top: BorderSide(color: AppColors.jin.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: listening ? _cancelTest : _skip,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.moLight,
                side: const BorderSide(color: AppColors.jin),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(listening ? '취소' : '건너뛰기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed:
                  (!_sttReady || listening || _phase == _Phase.judging || _phase == _Phase.pass)
                      ? null
                      : _startTest,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.zhuHong,
                foregroundColor: AppColors.xuanZhi,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              icon: const Icon(Icons.mic),
              label: Text(!_sttReady
                  ? '음성 인식 불가'
                  : _phase == _Phase.fail
                      ? '다시 TEST'
                      : 'TEST'),
            ),
          ),
        ],
      ),
    );
  }
}
