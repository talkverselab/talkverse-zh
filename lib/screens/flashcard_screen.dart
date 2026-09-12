import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/audio_service.dart';
import '../widgets/chinese_decor.dart';
import '../core/l10n.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<_Card> _cards = [];
  bool _loading = true;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/cliff/hanzi_top500_final.txt');
    final cards = <_Card>[];
    for (final line in raw.split('\n').take(40)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 4) continue;
      cards.add(_Card(
        rank: int.tryParse(parts[0]) ?? 0,
        char: parts[1],
        hsk: parts[3],
      ));
    }
    await AudioService.instance.ensureLoaded();
    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  void _answer(int weight) {
    if (_index < _cards.length - 1) {
      setState(() => _index++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('🎉 복습 세션 완료!')),
          backgroundColor: AppColors.feiCui,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('복습 카드'), style: TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 2),
            Text('Flashcards', style: TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_outline, color: AppColors.mo), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: _loading || _cards.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final card = _cards[_index];
    final total = _cards.length;
    final has = AudioService.instance.hasHanzi(card.char);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_index + 1} / $total',
                style: const TextStyle(fontSize: 11, color: AppColors.moLight, letterSpacing: 1),
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
                    widthFactor: (_index + 1) / total,
                    child: Container(height: 6, color: AppColors.zhuHong),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(40),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      InkWell(
                        onTap: has ? () => AudioService.instance.playHanzi(card.char) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            card.char,
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.w900,
                              color: AppColors.zhuHong,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      if (has)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(Icons.volume_up, size: 20,
                              color: AppColors.zhuHong.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.jin.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.jin),
                    ),
                    child: Text(
                      'HSK · ${card.hsk}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mo,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: AppColors.xuanZhiDeep,
                    child: Text(
                      'rank #${card.rank}',
                      style: const TextStyle(fontSize: 11, color: AppColors.moLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const BrushDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SrsButton(
                icon: Icons.close,
                label: tr('몰라요'),
                color: const Color(0xFFE53935),
                onTap: () => _answer(0),
              ),
              _SrsButton(
                icon: Icons.refresh,
                label: tr('보통이에요'),
                color: AppColors.jin,
                onTap: () => _answer(1),
              ),
              _SrsButton(
                icon: Icons.check,
                label: tr('알아요'),
                color: AppColors.feiCui,
                onTap: () => _answer(2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card {
  final int rank;
  final String char;
  final String hsk;
  _Card({required this.rank, required this.char, required this.hsk});
}

class _SrsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SrsButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.xuanZhi, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.mo,
          ),
        ),
      ],
    );
  }
}
