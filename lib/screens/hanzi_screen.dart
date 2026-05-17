import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Text('常用汉字 Top 500'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
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
    Color hskBg(String h) {
      switch (h) {
        case 'HSK1':
          return AppColors.zhuHong.withValues(alpha: 0.92);
        case 'HSK2':
          return AppColors.zhuHongLight.withValues(alpha: 0.85);
        case 'HSK3':
          return AppColors.jin.withValues(alpha: 0.85);
        case 'HSK4':
          return AppColors.jinBright.withValues(alpha: 0.75);
        case 'HSK5':
          return AppColors.feiCui.withValues(alpha: 0.7);
        case 'HSK6':
          return AppColors.moLight.withValues(alpha: 0.5);
        default:
          return AppColors.xuanZhiDeep;
      }
    }

    Color hskFg(String h) {
      switch (h) {
        case 'HSK1':
        case 'HSK2':
        case 'HSK6':
          return AppColors.xuanZhi;
        default:
          return AppColors.mo;
      }
    }

    final has = AudioService.instance.hasHanzi(entry.char);
    final bg = hskBg(entry.hsk);
    final fg = hskFg(entry.hsk);

    return GestureDetector(
      onTap: has ? () => AudioService.instance.playHanzi(entry.char) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: AppColors.jinDeep.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.char,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${entry.rank} · ${entry.hsk}',
                    style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            if (has)
              Positioned(
                top: 3,
                right: 3,
                child: Icon(Icons.volume_up, size: 10, color: fg.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }
}
