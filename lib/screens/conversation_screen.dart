import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/dialogues/north/L1.json');
    setState(() {
      _data = json.decode(raw) as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Text('核心会话 · L1'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_data == null) return const Center(child: Text('데이터 없음'));

    final episodes = (_data!['episodes'] as List?) ?? [];
    final kpi = (_data!['kpi'] as Map?) ?? {};
    final progress = (kpi['turns_total_current'] as int?) ?? 0;
    final target = (kpi['turns_total_target'] as int?) ?? 200;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChineseCard(
          title: 'L1 · 매칭 narrative 200 turn',
          sealText: 'L1',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _data!['description'] as String? ?? '',
                style: const TextStyle(color: AppColors.mo, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.xuanZhiDeep,
                      border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress / target,
                    child: Container(
                      height: 8,
                      color: AppColors.zhuHong,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '进度 $progress / $target',
                style: const TextStyle(fontSize: 11, color: AppColors.moLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...episodes.map((ep) => _EpisodeCard(episode: ep as Map<String, dynamic>)),
        const SizedBox(height: 12),
        const BrushDivider(),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final Map<String, dynamic> episode;
  const _EpisodeCard({required this.episode});

  @override
  Widget build(BuildContext context) {
    final turns = (episode['turns'] as List?) ?? [];
    final epId = episode['id'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.6)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          collapsedBackgroundColor: AppColors.xuanZhi,
          backgroundColor: AppColors.xuanZhi,
          leading: SealStamp(text: epId.replaceAll('ep', ''), size: 36),
          title: Text(
            '${episode['title']} ${episode['emoji'] ?? ''}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.mo,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            '${turns.length} / 40 turn',
            style: const TextStyle(color: AppColors.moLight, fontSize: 11),
          ),
          initiallyExpanded: turns.isNotEmpty,
          children: turns.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Text(
                      episode['todo'] as String? ?? '미작성',
                      style: const TextStyle(color: AppColors.moLight, fontSize: 12),
                    ),
                  ),
                ]
              : turns.map((t) => _TurnTile(turn: t as Map<String, dynamic>)).toList(),
        ),
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  final Map<String, dynamic> turn;
  const _TurnTile({required this.turn});

  @override
  Widget build(BuildContext context) {
    final speaker = turn['speaker'] as String? ?? '?';
    final isA = speaker == 'A';
    final bubbleColor = isA ? AppColors.zhuHong : AppColors.jin;
    final bubbleText = isA ? AppColors.xuanZhi : AppColors.mo;
    final align = isA ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isA) SealStamp(text: isA ? '马' : '丽', size: 18, color: bubbleColor),
              if (!isA) Container(),
              const SizedBox(width: 6),
              Text(
                '${turn['num']} · ${isA ? 'Mark 马克' : 'Lily 小丽'}',
                style: const TextStyle(fontSize: 10, color: AppColors.moLight, letterSpacing: 1),
              ),
              const SizedBox(width: 6),
              if (!isA) SealStamp(text: '丽', size: 18, color: bubbleColor),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              border: Border.all(color: AppColors.jinDeep, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: bubbleColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turn['zh'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: bubbleText,
                    height: 1.4,
                  ),
                ),
                if (turn['pinyin'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    turn['pinyin'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: bubbleText.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  height: 0.5,
                  color: bubbleText.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  turn['ko'] as String? ?? '',
                  style: TextStyle(fontSize: 13, color: bubbleText.withValues(alpha: 0.95)),
                ),
                if (turn['note'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '💡 ${turn['note']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: bubbleText.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
