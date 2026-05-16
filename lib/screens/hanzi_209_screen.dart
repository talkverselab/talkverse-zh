import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/audio_service.dart';

class Hanzi209Screen extends StatefulWidget {
  const Hanzi209Screen({super.key});

  @override
  State<Hanzi209Screen> createState() => _Hanzi209ScreenState();
}

class _Hanzi209ScreenState extends State<Hanzi209Screen> {
  List<_Hanzi209Entry> _items = [];
  bool _loading = true;
  String? _playing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/hskk_209hanzi_distribution.tsv');
    final entries = <_Hanzi209Entry>[];
    final lines = raw.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || i == 0) continue;
      final cols = line.split('\t');
      if (cols.isEmpty) continue;
      entries.add(_Hanzi209Entry(
        rank: i,
        char: cols[0],
        info: cols.length > 1 ? cols.sublist(1).join(' · ') : '',
      ));
    }
    await AudioService.instance.ensureLoaded();
    setState(() {
      _items = entries;
      _loading = false;
    });
  }

  Future<void> _play(String char) async {
    setState(() => _playing = char);
    await AudioService.instance.playHanzi(char);
    if (mounted) setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Phase 2 한자 ${_items.length}자'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: cs.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('회화 토큰 89% 청취 커버',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        'opus zh_cn 88M tokens CD-weighted. Phase 2 sweet spot — "들리고 표현 시작".\n탭하면 발음 재생.',
                        style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final has = AudioService.instance.hasHanzi(item.char);
                      final isPlaying = _playing == item.char;
                      return Card(
                        elevation: isPlaying ? 6 : 1,
                        color: isPlaying ? cs.primaryContainer : null,
                        child: InkWell(
                          onTap: has ? () => _play(item.char) : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  item.char,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (has)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.volume_up, size: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }
}

class _Hanzi209Entry {
  final int rank;
  final String char;
  final String info;
  _Hanzi209Entry({required this.rank, required this.char, required this.info});
}
