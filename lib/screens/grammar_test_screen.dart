import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/cedict_service.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';

class GrammarTestScreen extends StatefulWidget {
  const GrammarTestScreen({super.key});

  @override
  State<GrammarTestScreen> createState() => _GrammarTestScreenState();
}

class _Card {
  final String patternId;
  final String patternKey;
  final String patternLabel;
  final String zh;
  final String pinyin;
  final String ko;
  final List? tokens;
  _Card({
    required this.patternId,
    required this.patternKey,
    required this.patternLabel,
    required this.zh,
    required this.pinyin,
    required this.ko,
    required this.tokens,
  });
}

class _Hint {
  final String text; // zh token
  final String meaning; // ko
  final String? pinyin;
  final bool compound;
  _Hint({required this.text, required this.meaning, required this.compound, this.pinyin});
}

class _GrammarTestScreenState extends State<GrammarTestScreen> {
  List<_Card> _cards = [];
  Map<String, dynamic>? _chunks;
  Map<String, dynamic>? _hanziInfo;
  bool _loading = true;
  int _idx = 0;
  bool _revealed = false;
  int _know = 0;
  int _soso = 0;
  int _dunno = 0;

  /// 사용자가 X 로 제거한 힌트 (token text 기준). 세션 전체 유지.
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/grammar/lesson1.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _chunks = (data['chunks'] as Map?)?.cast<String, dynamic>();
    final patterns = (data['patterns'] as List?) ?? [];
    final cards = <_Card>[];
    for (final p in patterns) {
      final pm = p as Map<String, dynamic>;
      final examples = (pm['examples'] as List?) ?? [];
      for (final e in examples) {
        final em = e as Map<String, dynamic>;
        cards.add(_Card(
          patternId: pm['id'] as String? ?? '',
          patternKey: pm['key'] as String? ?? '',
          patternLabel: pm['label'] as String? ?? '',
          zh: em['zh'] as String? ?? '',
          pinyin: em['pinyin'] as String? ?? '',
          ko: em['ko'] as String? ?? '',
          tokens: em['tokens'] as List?,
        ));
      }
    }
    cards.shuffle(Random());

    // hanzi_info 로드 (단일 한자 뜻)
    final hRaw = await rootBundle.loadString('assets/data/grammar/hanzi_info.json');
    _hanziInfo = json.decode(hRaw) as Map<String, dynamic>;

    // cedict 로드 (단일 한자 병음용)
    await CedictService.instance.ensureLoaded();

    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  List<_Hint> _hintsFor(_Card card) {
    final hints = <_Hint>[];
    final seen = <String>{};
    final tokens = card.tokens ?? [];
    for (final raw in tokens) {
      final t = raw as Map;
      final txt = t['text'] as String? ?? '';
      final compound = (t['compound'] as bool?) ?? false;
      if (txt.isEmpty) continue;
      // CJK 만
      if (!_isCjk(txt[0])) continue;
      if (seen.contains(txt)) continue;
      seen.add(txt);

      String? meaning;
      String? pinyin;
      if (compound) {
        final c = _chunks?[txt];
        if (c is Map) {
          meaning = c['ko'] as String?;
          if (meaning == null || meaning.isEmpty) {
            final m = (c['meanings'] as List?)?.cast<String>() ?? const [];
            if (m.isNotEmpty) meaning = m.first;
          }
          pinyin = (c['pinyin'] as String?)?.trim();
        }
        // fallback to cedict
        if (pinyin == null || pinyin.isEmpty) {
          pinyin = CedictService.instance.lookup(txt)?.pinyin;
        }
      } else {
        final h = _hanziInfo?[txt];
        if (h is Map) meaning = h['meaning'] as String?;
        pinyin = CedictService.instance.lookup(txt)?.pinyin;
      }
      if (meaning == null || meaning.isEmpty) continue;
      hints.add(_Hint(text: txt, meaning: meaning, pinyin: pinyin, compound: compound));
    }
    return hints;
  }

  bool _isCjk(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code >= 0x4E00 && code <= 0x9FFF;
  }

  void _grade(int score) {
    if (score == 2) _know++;
    if (score == 1) _soso++;
    if (score == 0) _dunno++;
    if (_idx < _cards.length - 1) {
      setState(() {
        _idx++;
        _revealed = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.xuanZhi,
        shape: const RoundedRectangleBorder(),
        title: const Text('🎉  세션 완료',
            style: TextStyle(color: AppColors.mo, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _resultRow('알아요', _know, AppColors.feiCui),
            _resultRow('보통', _soso, AppColors.jin),
            _resultRow('몰라요', _dunno, AppColors.zhuHong),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text(
              '정답률 ${(_know / _cards.length * 100).round()}%',
              style: const TextStyle(
                fontSize: 22,
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
                _know = 0;
                _soso = 0;
                _dunno = 0;
                _revealed = false;
                _cards.shuffle(Random());
              });
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

  Widget _resultRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.mo))),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('한 → 중 회상 테스트',
                style: TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15)),
            SizedBox(height: 2),
            Text('Korean → Chinese recall',
                style: TextStyle(color: AppColors.moLight, fontSize: 9, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        actions: [
          const KoReadingToggleAction(),
          if (_dismissed.isNotEmpty)
            IconButton(
              tooltip: '힌트 되돌리기 (${_dismissed.length})',
              icon: const Icon(Icons.replay),
              onPressed: () => setState(() => _dismissed.clear()),
            ),
        ],
      ),
      body: _loading || _cards.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final card = _cards[_idx];
    final total = _cards.length;
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
                  if (_know > 0 || _soso > 0 || _dunno > 0)
                    Text(
                      '✓ $_know  ◇ $_soso  ✗ $_dunno',
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
        Expanded(child: SingleChildScrollView(child: _buildCard(card))),
        _buildBottom(card),
      ],
    );
  }

  Widget _buildCard(_Card card) {
    final hints = _hintsFor(card).where((h) => !_dismissed.contains(h.text)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.mo.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 패턴 라벨
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.jin.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.jin),
                  ),
                  child: Text(
                    '${card.patternKey} · ${card.patternLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mo,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                card.ko,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.mo,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (!_revealed)
              const Center(
                child: Text(
                  '— 중국어로 말해보세요 —',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.moLight,
                    letterSpacing: 3,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // 힌트
            if (!_revealed && hints.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.xuanZhiDeep,
                  border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppColors.jin, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          '힌트 (기능어·단어)',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.zhuHong,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        if (_dismissed.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _dismissed.clear()),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.replay, size: 12, color: AppColors.moLight),
                                SizedBox(width: 3),
                                Text(
                                  '되돌리기',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.moLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hints.map((h) => _HintChip(
                            hint: h,
                            onDismiss: () => setState(() => _dismissed.add(h.text)),
                          )).toList(),
                    ),
                  ],
                ),
              ),
            ],
            // 정답 reveal
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _revealed
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Column(
                        children: [
                          const BrushDivider(),
                          const SizedBox(height: 14),
                          SelectableHanziText(
                            text: card.zh,
                            tokens: card.tokens,
                            chunks: _chunks,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.zhuHong,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.pinyin,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.moLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          KoReadingText(
                            card.pinyin,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.moLight,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => TtsService.instance.speak(card.zh),
                            icon: const Icon(Icons.volume_up, size: 18),
                            label: const Text('소리 듣기'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.zhuHong,
                              side: const BorderSide(color: AppColors.zhuHong),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(_Card card) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: !_revealed
            ? SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    TtsService.instance.speak(card.zh);
                    setState(() => _revealed = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.zhuHong,
                    foregroundColor: AppColors.xuanZhi,
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip),
                      SizedBox(width: 10),
                      Text('정답 확인',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    ],
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: _GradeBtn(
                      label: '몰라요',
                      color: const Color(0xFFE53935),
                      icon: Icons.close,
                      onTap: () => _grade(0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GradeBtn(
                      label: '보통',
                      color: AppColors.jin,
                      icon: Icons.refresh,
                      onTap: () => _grade(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GradeBtn(
                      label: '알아요',
                      color: AppColors.feiCui,
                      icon: Icons.check,
                      onTap: () => _grade(2),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }
}

class _HintChip extends StatelessWidget {
  final _Hint hint;
  final VoidCallback onDismiss;
  const _HintChip({required this.hint, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = hint.compound ? AppColors.jin : AppColors.zhuHong.withValues(alpha: 0.85);
    return Container(
      decoration: BoxDecoration(
        color: hint.compound
            ? AppColors.jin.withValues(alpha: 0.15)
            : AppColors.zhuHong.withValues(alpha: 0.08),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hint.meaning,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mo,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hint.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                    if (hint.pinyin != null && hint.pinyin!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        hint.pinyin!,
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color.withValues(alpha: 0.4))),
              ),
              child: const Icon(Icons.close, size: 12, color: AppColors.moLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _GradeBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.xuanZhi, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.xuanZhi,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
