import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/audio_service.dart';
import '../widgets/chinese_decor.dart';

class Hanzi209Screen extends StatefulWidget {
  const Hanzi209Screen({super.key});

  @override
  State<Hanzi209Screen> createState() => _Hanzi209ScreenState();
}

class _Hanzi209ScreenState extends State<Hanzi209Screen> {
  List<String> _chars = [];
  bool _loading = true;
  String? _playing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/hskk_209hanzi_distribution.tsv');
    final chars = <String>[];
    final lines = raw.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || i == 0) continue;
      final cols = line.split('\t');
      if (cols.isEmpty || cols[0].isEmpty) continue;
      chars.add(cols[0]);
    }
    await AudioService.instance.ensureLoaded();
    setState(() {
      _chars = chars;
      _loading = false;
    });
  }

  Future<void> _play(String char) async {
    setState(() => _playing = char);
    await AudioService.instance.playHanzi(char);
    if (mounted) setState(() => _playing = null);
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
        title: Text('회화 시작점 한자 ${_chars.length}자'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SealStamp(text: '⭐', size: 50, color: AppColors.jin),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '회화 청취 89% 커버',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.jinBright,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'opus zh_cn 88M tokens · CD-weighted\nPhase 2 sweet spot · 탭하면 발음 재생',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.xuanZhi.withValues(alpha: 0.9),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const GreekKeyDivider(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: _chars.length,
                    itemBuilder: (context, i) {
                      final char = _chars[i];
                      final has = AudioService.instance.hasHanzi(char);
                      final isPlaying = _playing == char;
                      return _CharTile(
                        char: char,
                        hasAudio: has,
                        isPlaying: isPlaying,
                        onTap: has ? () => _play(char) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CharTile extends StatelessWidget {
  final String char;
  final bool hasAudio;
  final bool isPlaying;
  final VoidCallback? onTap;

  const _CharTile({
    required this.char,
    required this.hasAudio,
    required this.isPlaying,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.zhuHong : AppColors.xuanZhi,
          border: Border.all(
            color: isPlaying ? AppColors.jin : AppColors.jin.withValues(alpha: 0.4),
            width: isPlaying ? 1.5 : 0.8,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: AppColors.zhuHong.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                char,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: isPlaying ? AppColors.xuanZhi : AppColors.mo,
                  height: 1,
                ),
              ),
            ),
            if (hasAudio)
              Positioned(
                top: 3,
                right: 3,
                child: Icon(
                  Icons.volume_up,
                  size: 10,
                  color: isPlaying ? AppColors.jinBright : AppColors.moLight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
