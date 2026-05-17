import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';

class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordEntry> _words = [];
  bool _loading = true;
  String _filter = 'ALL';

  static const Map<String, _Region> _regions = {
    'ALL': _Region('全部', AppColors.mo, 0, 2500),
    'R1': _Region('R1 · 1-433', AppColors.zhuHong, 1, 433),
    'R2': _Region('R2 · 434-616', AppColors.zhuHongLight, 434, 616),
    'R3': _Region('R3 · 617-1238', AppColors.jin, 617, 1238),
    'R4': _Region('R4 · 1239-2500', AppColors.feiCui, 1239, 2500),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/freq/lang_zh_with_regions.csv');
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    final entries = <WordEntry>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      entries.add(WordEntry(
        rank: int.tryParse('${row[0]}') ?? 0,
        word: '${row[1]}',
        freq: double.tryParse('${row[2]}') ?? 0,
        cumPct: double.tryParse('${row[3]}') ?? 0,
        region: '${row[4]}',
      ));
    }
    setState(() {
      _words = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'ALL'
        ? _words
        : _words.where((w) => w.region == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: const Text('词频 2500')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : Column(
              children: [
                Container(
                  color: AppColors.xuanZhiDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _regions.entries.map((e) {
                        final selected = _filter == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? e.value.color : AppColors.xuanZhi,
                                border: Border.all(
                                  color: e.value.color,
                                  width: selected ? 1.5 : 0.8,
                                ),
                              ),
                              child: Text(
                                e.value.label,
                                style: TextStyle(
                                  color: selected ? AppColors.xuanZhi : e.value.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const GreekKeyDivider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 0.5, color: AppColors.jin.withValues(alpha: 0.3)),
                    itemBuilder: (context, i) {
                      final w = filtered[i];
                      final region = _regions[w.region];
                      return Container(
                        color: AppColors.xuanZhi,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '#${w.rank}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.moLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.word,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.mo,
                                    ),
                                  ),
                                  Text(
                                    '累计 ${w.cumPct.toStringAsFixed(2)}%',
                                    style: const TextStyle(fontSize: 10, color: AppColors.moLight),
                                  ),
                                ],
                              ),
                            ),
                            if (region != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: region.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  w.region,
                                  style: const TextStyle(
                                    color: AppColors.xuanZhi,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class WordEntry {
  final int rank;
  final String word;
  final double freq;
  final double cumPct;
  final String region;
  WordEntry({
    required this.rank,
    required this.word,
    required this.freq,
    required this.cumPct,
    required this.region,
  });
}

class _Region {
  final String label;
  final Color color;
  final int start;
  final int end;
  const _Region(this.label, this.color, this.start, this.end);
}
