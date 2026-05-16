import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    'ALL': _Region('전체', Colors.grey, 0, 2500),
    'R1': _Region('R1 (1-433)', Colors.green, 1, 433),
    'R2': _Region('R2 (434-616)', Colors.lightBlue, 434, 616),
    'R3': _Region('R3 (617-1238)', Colors.amber, 617, 1238),
    'R4': _Region('R4 (1239-2500)', Colors.deepOrange, 1239, 2500),
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
    final cs = Theme.of(context).colorScheme;
    final filtered = _filter == 'ALL'
        ? _words
        : _words.where((w) => w.region == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 빈도 2500'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: _regions.entries.map((e) {
                      final selected = _filter == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value.label),
                          selected: selected,
                          selectedColor: e.value.color.withValues(alpha: 0.3),
                          onSelected: (_) => setState(() => _filter = e.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final w = filtered[i];
                      final region = _regions[w.region];
                      return ListTile(
                        leading: SizedBox(
                          width: 48,
                          child: Text(
                            '#${w.rank}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        title: Text(
                          w.word,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('누적 ${w.cumPct.toStringAsFixed(2)}%'),
                        trailing: region == null
                            ? null
                            : Chip(
                                label: Text(w.region, style: const TextStyle(fontSize: 11)),
                                backgroundColor: region.color.withValues(alpha: 0.2),
                                visualDensity: VisualDensity.compact,
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
