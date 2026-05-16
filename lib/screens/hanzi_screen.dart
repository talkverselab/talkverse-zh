import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/audio_service.dart';

class HanziScreen extends StatefulWidget {
  const HanziScreen({super.key});

  @override
  State<HanziScreen> createState() => _HanziScreenState();
}

class _HanziScreenState extends State<HanziScreen> {
  List<HanziEntry> _hanzi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/cliff/hanzi_top500_final.txt');
    final entries = <HanziEntry>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 4) continue;
      entries.add(HanziEntry(
        rank: int.tryParse(parts[0]) ?? 0,
        char: parts[1],
        freq: int.tryParse(parts[2]) ?? 0,
        hsk: parts[3],
      ));
    }
    await AudioService.instance.ensureLoaded();
    setState(() {
      _hanzi = entries;
      _loading = false;
    });
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('한자 Top 500'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: _hanzi.length,
              itemBuilder: (context, i) => _HanziCard(entry: _hanzi[i]),
            ),
    );
  }
}

class HanziEntry {
  final int rank;
  final String char;
  final int freq;
  final String hsk;
  HanziEntry({required this.rank, required this.char, required this.freq, required this.hsk});
}

class _HanziCard extends StatelessWidget {
  final HanziEntry entry;
  const _HanziCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color hskColor(String h) {
      switch (h) {
        case 'HSK1':
          return Colors.green.shade100;
        case 'HSK2':
          return Colors.lightGreen.shade100;
        case 'HSK3':
          return Colors.lime.shade100;
        case 'HSK4':
          return Colors.amber.shade100;
        case 'HSK5':
          return Colors.orange.shade100;
        case 'HSK6':
          return Colors.deepOrange.shade100;
        default:
          return cs.surfaceContainerHighest;
      }
    }

    final has = AudioService.instance.hasHanzi(entry.char);
    return Card(
      color: hskColor(entry.hsk),
      child: InkWell(
        onTap: has ? () => AudioService.instance.playHanzi(entry.char) : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.char,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${entry.rank} · ${entry.hsk}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (has)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(Icons.volume_up, size: 11, color: Colors.black54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
