import 'dart:math';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/tts_service.dart';

class HanziQuizScreen extends StatefulWidget {
  final int stage;
  final List allStages;

  const HanziQuizScreen({super.key, required this.stage, required this.allStages});

  @override
  State<HanziQuizScreen> createState() => _HanziQuizScreenState();
}

class _Q {
  final String char;
  final String meaning;
  final List<String> options; // 4 meanings, options[0] = correct
  final int correctIndex;
  _Q({
    required this.char,
    required this.meaning,
    required this.options,
    required this.correctIndex,
  });
}

class _HanziQuizScreenState extends State<HanziQuizScreen> {
  List<_Q> _questions = [];
  int _idx = 0;
  int? _selected;
  bool _revealed = false;
  int _correct = 0;
  int _wrong = 0;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    // 누적: stage 1..widget.stage 모든 한자가 출제 풀
    final pool = <Map>[]; // {char, meaning}
    for (final s in widget.allStages) {
      final sm = s as Map;
      if ((sm['stage'] as int) > widget.stage) break;
      for (final c in (sm['chars'] as List)) {
        pool.add(c as Map);
      }
    }
    // 현재 stage 한자만 출제 (누적은 distractor pool 로)
    final currentChars = <Map>[];
    for (final s in widget.allStages) {
      final sm = s as Map;
      if ((sm['stage'] as int) == widget.stage) {
        for (final c in (sm['chars'] as List)) {
          currentChars.add(c as Map);
        }
      }
    }

    final all = pool;
    final qs = <_Q>[];
    final shuffled = List<Map>.from(currentChars)..shuffle(_rand);
    for (final c in shuffled) {
      final correctChar = c['char'] as String;
      final correctMeaning = c['meaning'] as String;
      // distractor — 누적 pool 에서 자신 외 3개 뽑기
      final distractors = <String>[];
      final candidates = all.where((x) => x['char'] != correctChar).toList()..shuffle(_rand);
      for (final d in candidates) {
        final m = d['meaning'] as String;
        if (m == correctMeaning) continue;
        if (distractors.contains(m)) continue;
        distractors.add(m);
        if (distractors.length >= 3) break;
      }
      while (distractors.length < 3) {
        distractors.add('(...)');
      }
      // 옵션 4개: 정답 + distractor 3 → shuffle
      final options = [correctMeaning, ...distractors]..shuffle(_rand);
      final correctIndex = options.indexOf(correctMeaning);
      qs.add(_Q(
        char: correctChar,
        meaning: correctMeaning,
        options: options,
        correctIndex: correctIndex,
      ));
    }
    setState(() {
      _questions = qs;
    });
  }

  void _select(int i) {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
      if (i == _questions[_idx].correctIndex) {
        _correct++;
      } else {
        _wrong++;
      }
    });
    TtsService.instance.speak(_questions[_idx].char);
  }

  void _next() {
    if (_idx < _questions.length - 1) {
      setState(() {
        _idx++;
        _selected = null;
        _revealed = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final pct = (_correct / _questions.length * 100).round();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.xuanZhi,
        shape: const RoundedRectangleBorder(),
        title: Text(
          '🎉  단계 ${widget.stage} 완료',
          style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('정답', _correct, AppColors.feiCui),
            _row('오답', _wrong, const Color(0xFFE53935)),
            const Divider(),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.zhuHong,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('나가기', style: TextStyle(color: AppColors.moLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _idx = 0;
                _correct = 0;
                _wrong = 0;
                _selected = null;
                _revealed = false;
              });
              _build();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.zhuHong,
              foregroundColor: AppColors.xuanZhi,
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text('다시'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int n, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.mo))),
          Text('$n',
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('한자 단계 ${widget.stage}',
                style: const TextStyle(
                    color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            const Text('4지선다 · 누적',
                style: TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
      ),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final q = _questions[_idx];
    final total = _questions.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${_idx + 1} / $total',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.moLight, letterSpacing: 1)),
                  const Spacer(),
                  Text(
                    '✓ $_correct  ✗ $_wrong',
                    style: const TextStyle(fontSize: 11, color: AppColors.moLight),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.xuanZhiDeep,
                      border: Border.all(color: AppColors.jin.withValues(alpha: 0.4)),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (_idx + 1) / total,
                    child: Container(height: 6, color: AppColors.zhuHong),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 한자 카드
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.xuanZhi,
                    border: Border.all(color: AppColors.jin, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mo.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        q.char,
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          color: AppColors.zhuHong,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '뜻은?',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.moLight,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: q.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _OptionTile(
                      index: i,
                      text: q.options[i],
                      selected: _selected == i,
                      isCorrect: i == q.correctIndex,
                      revealed: _revealed,
                      onTap: () => _select(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _revealed ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.zhuHong,
                  foregroundColor: AppColors.xuanZhi,
                  disabledBackgroundColor: AppColors.moLight.withValues(alpha: 0.3),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                child: Text(
                  _idx == _questions.length - 1 ? '결과 보기' : '다음 →',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool selected;
  final bool isCorrect;
  final bool revealed;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.xuanZhi;
    Color border = AppColors.jin.withValues(alpha: 0.5);
    Color fg = AppColors.mo;
    IconData? icon;
    if (revealed) {
      if (isCorrect) {
        bg = AppColors.feiCui;
        border = AppColors.feiCui;
        fg = AppColors.xuanZhi;
        icon = Icons.check_circle;
      } else if (selected) {
        bg = const Color(0xFFE53935);
        border = const Color(0xFFE53935);
        fg = AppColors.xuanZhi;
        icon = Icons.cancel;
      }
    }
    const labels = ['A', 'B', 'C', 'D'];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: revealed && (isCorrect || selected) ? 1.5 : 0.8),
          boxShadow: revealed && isCorrect
              ? [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: revealed && (isCorrect || selected) ? AppColors.xuanZhi : AppColors.xuanZhiDeep,
                border: Border.all(color: fg.withValues(alpha: 0.3)),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: revealed && (isCorrect || selected) ? bg : AppColors.mo,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            if (icon != null) Icon(icon, color: fg),
          ],
        ),
      ),
    );
  }
}
