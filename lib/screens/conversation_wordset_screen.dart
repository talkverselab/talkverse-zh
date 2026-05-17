import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/cedict_service.dart';
import '../widgets/chinese_decor.dart';

class ConversationWordsetScreen extends StatefulWidget {
  const ConversationWordsetScreen({super.key});

  @override
  State<ConversationWordsetScreen> createState() => _ConversationWordsetScreenState();
}

class _ConversationWordsetScreenState extends State<ConversationWordsetScreen> {
  List<_Entry> _all = [];
  bool _loading = true;
  String _tier = 'ALL';

  static const Map<String, _TierInfo> _tiers = {
    'ALL': _TierInfo('전체', AppColors.mo),
    'A_essential': _TierInfo('필수', AppColors.zhuHong),
    'B_common': _TierInfo('회화', AppColors.jin),
    'C_useful': _TierInfo('유용', AppColors.feiCui),
    'D_extra': _TierInfo('확장', AppColors.moLight),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/freq/FINAL_wordset_for_conversation_app.tsv');
    final lines = raw.split('\n').where((l) => l.isNotEmpty).toList();
    final entries = <_Entry>[];
    for (var i = 1; i < lines.length && i < 1200; i++) {
      final cols = lines[i].split('\t');
      if (cols.length < 9) continue;
      entries.add(_Entry(
        word: cols[0],
        opusRank: int.tryParse(cols[1]) ?? 0,
        hsk: cols[2],
        pos: cols[3],
        tier: cols[7],
        priority: int.tryParse(cols[8]) ?? 0,
      ));
    }
    CedictService.instance.ensureLoaded();
    setState(() {
      _all = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tier == 'ALL' ? _all : _all.where((e) => e.tier == _tier).toList();
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: const Text('회화 우선 어휘')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : Column(
              children: [
                Container(
                  color: AppColors.xuanZhiDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tiers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final entry = _tiers.entries.elementAt(i);
                        final selected = _tier == entry.key;
                        return GestureDetector(
                          onTap: () => setState(() => _tier = entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? entry.value.color : AppColors.xuanZhi,
                              border: Border.all(color: entry.value.color, width: selected ? 1.5 : 0.8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.value.label,
                              style: TextStyle(
                                color: selected ? AppColors.xuanZhi : entry.value.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const GreekKeyDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length}개',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.zhuHong, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· 회화 빈도 + HSK + dialog priority 통합',
                        style: const TextStyle(fontSize: 11, color: AppColors.moLight),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 0.5, color: AppColors.jin.withValues(alpha: 0.3)),
                    itemBuilder: (context, i) => _WordRow(entry: filtered[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Entry {
  final String word;
  final int opusRank;
  final String hsk;
  final String pos;
  final String tier;
  final int priority;
  _Entry({
    required this.word,
    required this.opusRank,
    required this.hsk,
    required this.pos,
    required this.tier,
    required this.priority,
  });
}

class _TierInfo {
  final String label;
  final Color color;
  const _TierInfo(this.label, this.color);
}

class _WordRow extends StatelessWidget {
  final _Entry entry;
  const _WordRow({required this.entry});

  void _openDef(BuildContext context) {
    final cedict = CedictService.instance.lookup(entry.word);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.xuanZhi,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.word,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: AppColors.zhuHong,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.jin.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.jin),
                  ),
                  child: Text(
                    entry.hsk,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mo),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.xuanZhiDeep,
                    border: Border.all(color: AppColors.moLight),
                  ),
                  child: Text(
                    entry.pos,
                    style: const TextStyle(fontSize: 11, color: AppColors.mo),
                  ),
                ),
              ],
            ),
            if (cedict != null) ...[
              const SizedBox(height: 10),
              Text(
                cedict.pinyin,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.moLight, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              ...cedict.meanings.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('· ', style: TextStyle(color: AppColors.zhuHong)),
                        Expanded(
                          child: Text(
                            m.trim(),
                            style: const TextStyle(fontSize: 13, color: AppColors.mo, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else
              Text(
                '사전에 없음',
                style: TextStyle(color: AppColors.moLight, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 10),
            Text(
              'opus rank #${entry.opusRank} · ${_HskColor.priorityLabel(entry.priority)}',
              style: const TextStyle(fontSize: 11, color: AppColors.moLight),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color hskColor(String h) {
      switch (h) {
        case 'HSK1':
          return AppColors.zhuHong;
        case 'HSK2':
          return AppColors.zhuHongLight;
        case 'HSK3':
          return AppColors.jin;
        case 'HSK4':
          return AppColors.jinDeep;
        case 'HSK5':
          return AppColors.feiCui;
        case 'HSK6':
          return AppColors.mo;
        default:
          return AppColors.moLight;
      }
    }

    return InkWell(
      onTap: () => _openDef(context),
      child: Container(
        color: AppColors.xuanZhi,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '#${entry.opusRank}',
                style: const TextStyle(fontSize: 11, color: AppColors.moLight, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.word,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.mo),
                  ),
                  Text(
                    '${entry.pos} · ${_HskColor.priorityLabel(entry.priority)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.moLight),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hskColor(entry.hsk),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                entry.hsk,
                style: const TextStyle(
                  color: AppColors.xuanZhi,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HskColor {
  static String priorityLabel(int p) {
    switch (p) {
      case 1:
        return '우선 1';
      case 2:
        return '우선 2';
      case 3:
        return '우선 3';
      default:
        return '확장';
    }
  }
}
