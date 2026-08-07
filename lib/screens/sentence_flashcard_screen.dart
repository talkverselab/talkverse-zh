import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import 'episode_screen.dart';

/// 회화 문장 플래시카드.
/// [meta]가 있으면 해당 에피소드 전체 턴, 없으면 전 레벨 랜덤 20문장.
/// '알아요'는 UserProgress.learned 에 반영된다.
class SentenceFlashcardScreen extends StatefulWidget {
  final EpisodeMeta? meta;
  const SentenceFlashcardScreen({super.key, this.meta});

  @override
  State<SentenceFlashcardScreen> createState() =>
      _SentenceFlashcardScreenState();
}

class _SentenceFlashcardScreenState extends State<SentenceFlashcardScreen> {
  List<TurnRow> _cards = [];
  bool _loading = true;
  int _index = 0;
  bool _flipped = false;
  int _known = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    if (!mounted) return;
    setState(() {
      _cards = turns;
      _loading = false;
    });
  }

  void _prev() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _flipped = false;
    });
  }

  Future<void> _answer({required bool known}) async {
    final turn = _cards[_index];
    if (known) {
      _known++;
      await appDb.into(appDb.userProgress).insertOnConflictUpdate(
            UserProgressCompanion(
              turnId: Value(turn.id),
              learned: const Value(true),
              lastReviewed: Value(DateTime.now()),
            ),
          );
    }
    if (!mounted) return;
    if (_index < _cards.length - 1) {
      setState(() {
        _index++;
        _flipped = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 완료! ${_cards.length}장 중 $_known장 알아요'),
          backgroundColor: AppColors.feiCui,
        ),
      );
      Navigator.pop(context);
    }
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
              meta == null ? '문장 플래시카드' : '${meta.emoji} ${meta.title} 카드',
              style: const TextStyle(
                  color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              meta == null ? '전 레벨 랜덤 20' : '${meta.level} 회화',
              style: TextStyle(
                  color: AppColors.moLight, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          if (_cards.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _cards.isEmpty
              ? const Center(
                  child: Text('카드가 없어요',
                      style: TextStyle(color: AppColors.moLight)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final turn = _cards[_index];
    final isA = turn.speaker == 'A';
    return Column(
      children: [
        const GreekKeyDivider(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _flipped ? AppColors.xuanZhiDeep : AppColors.xuanZhi,
                  border: Border.all(
                    color: _flipped ? AppColors.jin : AppColors.zhuHong,
                    width: 1.6,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 14),
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
                    if (_flipped) ...[
                      const SizedBox(height: 18),
                      if (turn.pinyin != null)
                        Text(
                          turn.pinyin!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            color: AppColors.zhuHong,
                          ),
                        ),
                      if (turn.ko != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          turn.ko!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mo,
                          ),
                        ),
                      ],
                      if (turn.note != null && turn.note!.isNotEmpty) ...[
                        const SizedBox(height: 14),
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
                    ] else ...[
                      const SizedBox(height: 18),
                      Text(
                        '탭해서 뜻 보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.moLight,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _index == 0 ? AppColors.moLight : AppColors.zhuHong,
                  side: BorderSide(
                      color: _index == 0
                          ? AppColors.moLight.withValues(alpha: 0.4)
                          : AppColors.zhuHong),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  minimumSize: const Size(0, 0),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: _index == 0 ? null : _prev,
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mo,
                    side: const BorderSide(color: AppColors.moLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () => _answer(known: false),
                  child: const Text('다시 볼래요',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.feiCui,
                    foregroundColor: AppColors.xuanZhi,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () => _answer(known: true),
                  child: const Text('알아요 ✓',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
