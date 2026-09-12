import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/tone_analyzer.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import 'tone_matrix_screen.dart';
import '../core/l10n.dart';

/// 성조 연습 — 목표 성조를 듣고 따라 말하면 피치 곡선을 추적해 4성 판정.
class TonePracticeScreen extends StatefulWidget {
  const TonePracticeScreen({super.key});

  @override
  State<TonePracticeScreen> createState() => _TonePracticeScreenState();
}

/// 음절 세트: 4성 각각의 한자·병음.
class _SylSet {
  final String syl;
  final List<String> hanzi; // 1~4성
  final List<String> pinyin;
  final List<String> ko;
  const _SylSet(this.syl, this.hanzi, this.pinyin, this.ko);
}

List<_SylSet> get _sets => <_SylSet>[
  _SylSet('ma', ['妈', '麻', '马', '骂'], ['mā', 'má', 'mǎ', 'mà'], [tr('엄마'), tr('삼베'), tr('말'), tr('욕하다')]),
  _SylSet('ba', ['八', '拔', '把', '爸'], ['bā', 'bá', 'bǎ', 'bà'], [tr('여덟'), tr('뽑다'), tr('잡다'), tr('아빠')]),
  _SylSet('yi', ['衣', '疑', '椅', '意'], ['yī', 'yí', 'yǐ', 'yì'], [tr('옷'), tr('의심'), tr('의자'), tr('뜻')]),
  _SylSet('wu', ['屋', '无', '五', '物'], ['wū', 'wú', 'wǔ', 'wù'], [tr('집'), tr('없다'), tr('다섯'), tr('물건')]),
  _SylSet('shi', ['诗', '十', '史', '是'], ['shī', 'shí', 'shǐ', 'shì'], [tr('시'), tr('열'), tr('역사'), tr('~이다')]),
  _SylSet('tang', ['汤', '糖', '躺', '烫'], ['tāng', 'táng', 'tǎng', 'tàng'], [tr('국'), tr('설탕'), tr('눕다'), tr('뜨겁다')]),
  _SylSet('mai', ['埋', '买', '买', '卖'], ['māi', 'mái', 'mǎi', 'mài'], [tr('(연습)'), tr('묻다'), tr('사다'), tr('팔다')]),
  _SylSet('wen', ['温', '文', '吻', '问'], ['wēn', 'wén', 'wěn', 'wèn'], [tr('따뜻하다'), tr('글'), tr('입맞춤'), tr('묻다')]),
];

class _TonePracticeScreenState extends State<TonePracticeScreen> {
  int _set = 0;
  int _tone = 1;
  bool _recording = false;
  bool _analyzing = false;
  double _level = 0;
  ToneResult? _result;
  final Map<int, List<bool>> _history = {1: [], 2: [], 3: [], 4: []};

  _SylSet get _cur => _sets[_set];

  Future<void> _record() async {
    if (_recording || _analyzing) return;
    final ok = await ToneAnalyzer.instance.hasPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('마이크 권한이 필요해요.')), backgroundColor: AppColors.zhuHongDeep));
      return;
    }
    setState(() {
      _recording = true;
      _result = null;
      _level = 0;
    });
    ToneResult r;
    try {
      r = await ToneAnalyzer.instance.recordAndAnalyze(
        seconds: 1.6,
        onLevel: (l) {
          if (mounted && _recording) setState(() => _level = l);
        },
      );
    } catch (_) {
      r = const ToneResult(contour: [], tone: 0, distances: [9, 9, 9, 9], voicedSec: 0);
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _analyzing = false;
      _result = r;
      if (r.valid) _history[_tone]!.add(r.tone == _tone);
    });
  }

  @override
  void dispose() {
    ToneAnalyzer.instance.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _cur;
    final r = _result;
    final pass = r != null && r.valid && r.tone == _tone;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(tr('성조 연습')),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ToneMatrixScreen())),
            icon: const Icon(Icons.grid_on, size: 16),
            label: Text(tr('4성 매트릭스')),
            style: TextButton.styleFrom(foregroundColor: AppColors.mo),
          ),
        ],
      ),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: Stack(
          children: [
            const Positioned.fill(child: CloudPattern(opacity: 0.05)),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 음절 선택
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => ChoiceChip(
                      label: Text(_sets[i].syl),
                      selected: _set == i,
                      selectedColor: AppColors.zhuHong,
                      labelStyle: TextStyle(
                          color: _set == i ? AppColors.xuanZhi : AppColors.mo,
                          fontWeight: FontWeight.w800),
                      onSelected: (_) => setState(() {
                        _set = i;
                        _result = null;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 성조 4개 선택
                Row(
                  children: [
                    for (var t = 1; t <= 4; t++) ...[
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _tone = t;
                            _result = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _tone == t
                                  ? toneColor(t).withValues(alpha: 0.2)
                                  : AppColors.xuanZhi,
                              border: Border.all(
                                  color: _tone == t ? toneColor(t) : AppColors.jin.withValues(alpha: 0.5),
                                  width: _tone == t ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Text(s.hanzi[t - 1],
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: toneColor(t))),
                                Text(s.pinyin[t - 1],
                                    style: const TextStyle(fontSize: 12, color: AppColors.mo)),
                                Text(trf('{0}성 · {1}', [t, s.ko[t - 1]]),
                                    style: const TextStyle(fontSize: 9, color: AppColors.moLight)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (t < 4) const SizedBox(width: 6),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // 곡선 그래프
                ChineseCard(
                  title: trf('{0}성 {1}  —  {2}', [_tone, s.pinyin[_tone - 1], _toneName(_tone)]),
                  sealText: '调',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: CustomPaint(
                          painter: _ContourPainter(
                            target: ToneAnalyzer.interpolate(ToneAnalyzer.templates[_tone]!, 20),
                            targetColor: toneColor(_tone),
                            user: r?.contour,
                            userColor: r == null
                                ? AppColors.mo
                                : pass
                                    ? AppColors.feiCui
                                    : AppColors.zhuHong,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _legend(toneColor(_tone), tr('목표 (Chao 5도)')),
                          const SizedBox(width: 12),
                          _legend(pass ? AppColors.feiCui : AppColors.zhuHong, tr('내 발음')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _resultBox(r, pass),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _recording ? null : () => TtsService.instance.speak(s.hanzi[_tone - 1]),
                        icon: const Icon(Icons.volume_up),
                        label: Text(tr('듣기')),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.mo,
                            side: const BorderSide(color: AppColors.jin),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _recording ? null : _record,
                        icon: Icon(_recording ? Icons.graphic_eq : Icons.mic),
                        label: Text(_recording ? tr('말하세요… (1.6초)') : tr('따라 말하기')),
                        style: FilledButton.styleFrom(
                          backgroundColor: _recording ? AppColors.jinDeep : AppColors.zhuHong,
                          foregroundColor: AppColors.xuanZhi,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_recording) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_level * 6).clamp(0.02, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.xuanZhiDeep,
                      color: AppColors.jin,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _scoreboard(),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 18, height: 3, color: c),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
        ],
      );

  Widget _resultBox(ToneResult? r, bool pass) {
    if (_recording) {
      return Text(tr('🎙 지금 한 음절만 또렷하게 말하세요'),
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.moLight));
    }
    if (r == null) {
      return Text(tr('듣기 → 따라 말하기. 한 음절을 길게(0.5초 이상) 말하면 곡선이 잡혀요.'),
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.moLight, height: 1.5));
    }
    if (!r.valid) {
      return Text(tr('목소리가 잘 안 잡혔어요. 마이크 가까이에서 조금 더 길게 말해 보세요.'),
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.zhuHongDeep, height: 1.5));
    }
    final conf = r.distances[r.tone - 1];
    return Column(
      children: [
        Text(pass ? 'PASS' : 'FAIL',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: pass ? AppColors.feiCui : AppColors.zhuHong)),
        Text(
          pass
              ? trf('{0}성으로 잘 들렸어요 (유성 {1}초)', [_tone, r.voicedSec.toStringAsFixed(2)])
              : trf('{0}성({1})처럼 들렸어요 → 목표 {2}성 {3}', [r.tone, _toneName(r.tone), _tone, _hint(_tone)]),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.moLight, height: 1.5),
        ),
        Text(trf('오차 {0}', [conf.toStringAsFixed(2)]),
            style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
      ],
    );
  }

  Widget _scoreboard() {
    return Row(
      children: [
        for (var t = 1; t <= 4; t++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: toneColor(t).withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  Text(trf('{0}성', [t]), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: toneColor(t))),
                  Text(
                    _history[t]!.isEmpty
                        ? '—'
                        : '${_history[t]!.where((b) => b).length}/${_history[t]!.length}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mo),
                  ),
                ],
              ),
            ),
          ),
          if (t < 4) SizedBox(width: 6),
        ],
      ],
    );
  }

  static String _toneName(int t) => {1: tr('높고 평평하게 55'), 2: tr('올라가게 35'), 3: tr('내렸다 올리기 214'), 4: tr('뚝 떨어지게 51')}[t]!;
  static String _hint(int t) => {
        1: tr('— 처음부터 끝까지 높은 음을 유지하세요'),
        2: tr('— 낮은 데서 시작해 끝을 확실히 올리세요'),
        3: tr('— 낮게 눌렀다가 끝에서 살짝 올리세요'),
        4: tr('— 높은 데서 시작해 단숨에 떨어뜨리세요'),
      }[t]!;
}

class _ContourPainter extends CustomPainter {
  final List<double> target;
  final List<double>? user;
  final Color targetColor;
  final Color userColor;
  _ContourPainter({required this.target, required this.targetColor, this.user, required this.userColor});

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    final grid = Paint()
      ..color = AppColors.jin.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final label = TextPainter(textDirection: TextDirection.ltr);
    for (var lv = 1; lv <= 5; lv++) {
      final y = pad + h - (lv - 1) / 4 * h;
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), grid);
      label.text = TextSpan(text: '$lv', style: const TextStyle(fontSize: 9, color: AppColors.moLight));
      label.layout();
      label.paint(canvas, Offset(0, y - 6));
    }
    void drawLine(List<double> pts, Color c, double sw, {bool dashed = false}) {
      final p = Paint()
        ..color = c
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = pad + w * i / (pts.length - 1);
        final y = pad + h - (pts[i] - 1) / 4 * h;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      if (dashed) {
        final metrics = path.computeMetrics();
        for (final m in metrics) {
          var d = 0.0;
          while (d < m.length) {
            final next = math.min(m.length, d + 8);
            canvas.drawPath(m.extractPath(d, next), p);
            d = next + 6;
          }
        }
      } else {
        canvas.drawPath(path, p);
      }
    }
    drawLine(target, targetColor, 5, dashed: true);
    if (user != null && user!.isNotEmpty) drawLine(user!, userColor, 3.5);
  }

  @override
  bool shouldRepaint(covariant _ContourPainter old) =>
      old.target != target || old.user != user || old.userColor != userColor;
}
