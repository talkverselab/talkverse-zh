import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('회화 200 — L1'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _data!['title'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _data!['description'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress / target,
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '$progress / $target turn',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...episodes.map((ep) => _EpisodeCard(episode: ep as Map<String, dynamic>)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Text(
          episode['emoji'] as String? ?? '📖',
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          'Ep ${episode['id']} — ${episode['title']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${turns.length} / 40 turn',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        initiallyExpanded: turns.isNotEmpty,
        children: turns.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    episode['todo'] as String? ?? '미작성',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ]
            : turns.map((t) => _TurnTile(turn: t as Map<String, dynamic>)).toList(),
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
    final cs = Theme.of(context).colorScheme;
    final bubbleColor = isA ? cs.primaryContainer : cs.surfaceContainerHighest;
    final align = isA ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            '${turn['num']}  ·  ${isA ? 'Mark' : '小丽'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turn['zh'] as String? ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (turn['pinyin'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    turn['pinyin'] as String,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  turn['ko'] as String? ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                if (turn['note'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '💡 ${turn['note']}',
                    style: TextStyle(fontSize: 11, color: cs.primary),
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
