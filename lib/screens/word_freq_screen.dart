import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/embed_env.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/theme.dart';
import '../main.dart' show appDb;
import '../services/art_service.dart';
import '../services/ko_reading.dart';
import '../services/lexicon_service.dart';
import '../services/tts_service.dart';
import '../widgets/selectable_hanzi.dart' show showChunkSheet;
import '../widgets/tone_pinyin.dart';

/// 절벽 단어 — 영화·드라마 대사 빈도 단어표(DB `words`, 2,500어, R1~R4)를 **20어 = 한 단원**, 네모 타일 격자로(2026-11-07, 일본어앱 §1).
/// 구간 칩 전체·R1~R4 · 버튼 「절벽구간 단어만」/「회화 단어 포함 (+N)」 — 포함이면 회화 전 편의 레마 중 빈도표 밖이면서 앱 사전에 있는 단어가
/// 「회화」 구간으로 뒤에 붙는다(`assets/data/freq/conv_words_zh.json`, `tools/freq/conv_words.py`). DB 는 합치지 않고 화면에서만 잇는다.
/// 중국어는 80% 지점이 2,500 안에 있지 않아(R4 = 1,239~2,500) R5 를 두지 않는다. 타일 탭 = 발음, 길게 = 단어창.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _Word {
  final int? rank; // 회화 단어는 null
  final String word;
  final String region; // R1~R4 | 회화
  String? pinyin;
  String? gloss;
  _Word(this.rank, this.word, this.region);
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  static const regions = ['R1', 'R2', 'R3', 'R4'];
  List<_Word> _cliff = const [];
  List<_Word> _conv = const [];
  String _region = ''; // '' = 전체
  bool _withConv = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    final cliff = [for (final r in rows) if (r.rank > 0 && (r.region ?? '').isNotEmpty) _Word(r.rank, r.word, r.region!)];
    final conv = <_Word>[];
    try {
      final j = jsonDecode(await rootBundle.loadString(assetPath('assets/data/freq/conv_words_zh.json'))) as Map<String, dynamic>;
      for (final w in j['words'] as List) {
        final m = w as Map;
        conv.add(_Word(null, m['word'] as String, tr('회화'))
          ..pinyin = m['pinyin'] as String?
          ..gloss = m['ko'] as String?);
      }
    } catch (_) {}
    // 뜻·병음은 앱 사전(표면형 일치)에서
    final hits = await LexiconService.instance.byLemmas(cliff.map((w) => w.word));
    for (final w in cliff) {
      final h = hits[w.word];
      w.pinyin = h?.pinyin;
      w.gloss = h?.gloss;
    }
    if (!mounted) return;
    setState(() {
      _cliff = cliff;
      _conv = conv;
      _loading = false;
    });
  }

  List<_Word> get _shown {
    final base = _region.isEmpty ? _cliff : (_region == tr('회화') ? const <_Word>[] : _cliff.where((w) => w.region == _region).toList());
    if (!_withConv) return base;
    if (_region.isEmpty || _region == tr('회화')) return [...base, ..._conv];
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final words = _shown;
    final cols = (MediaQuery.sizeOf(context).width ~/ 112).clamp(3, 8);
    final chips = ['', ...regions, if (_withConv) tr('회화')];
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(tr('절벽 단어')),
        actions: const [KoReadingToggleAction(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: [
                          ButtonSegment(value: false, label: Text(tr('절벽구간 단어만'), style: const TextStyle(fontSize: 12))),
                          ButtonSegment(value: true, label: Text(trf('회화 단어 포함 (+{0})', [_conv.length]), style: const TextStyle(fontSize: 12))),
                        ],
                        selected: {_withConv},
                        onSelectionChanged: (s) => setState(() {
                          _withConv = s.first;
                          if (!_withConv && _region == tr('회화')) _region = '';
                        }),
                      ),
                    ),
                  ]),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    itemCount: chips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final r = chips[i];
                      final on = r == _region;
                      final n = r.isEmpty ? _cliff.length : (r == tr('회화') ? _conv.length : _cliff.where((w) => w.region == r).length);
                      return ChoiceChip(
                        selected: on,
                        showCheckmark: false,
                        label: Text('${r.isEmpty ? tr('전체') : r} $n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? AppColors.xuanZhi : AppColors.mo)),
                        selectedColor: AppColors.zhuHong,
                        backgroundColor: AppColors.xuanZhiDeep,
                        side: BorderSide(color: on ? AppColors.zhuHong : AppColors.line),
                        onSelected: (_) => setState(() => _region = r),
                      );
                    },
                  ),
                ),
                Expanded(child: _Units(words: words, cols: cols)),
              ]),
      ),
    );
  }
}

/// 20어 단원 머리줄 + 격자.
class _Units extends StatelessWidget {
  final List<_Word> words;
  final int cols;
  const _Units({required this.words, required this.cols});

  @override
  Widget build(BuildContext context) {
    final units = <List<_Word>>[];
    for (var i = 0; i < words.length; i += 20) {
      units.add(words.sublist(i, (i + 20).clamp(0, words.length)));
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
      itemCount: units.length,
      itemBuilder: (context, u) {
        final unit = units[u];
        final a = unit.first, b = unit.last;
        final range = a.rank != null ? '#${a.rank}-${b.rank ?? a.rank}' : trf('회화 {0}-{1}', [u * 20 + 1, u * 20 + unit.length]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
            child: Text(trf('{0}단원 · {1} · {2}', [u + 1, range, a.region]), style: AppFonts.captionText(size: 12, weight: FontWeight.w600, color: AppColors.muted)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.82),
            itemCount: unit.length,
            itemBuilder: (_, i) => _Tile(w: unit[i]),
          ),
        ]);
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final _Word w;
  const _Tile({required this.w});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.xuanZhiDeep,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => TtsService.instance.speak(w.word),
        onLongPress: () => showChunkSheet(context, w.word, pinyin: w.pinyin),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(w.rank?.toString() ?? '会', style: AppFonts.captionText(size: 10, weight: FontWeight.w600, color: AppColors.muted)),
              const Spacer(),
              if (w.pinyin != null && w.pinyin!.isNotEmpty)
                Flexible(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: KoReadingPrefs.show,
                    builder: (_, on, _) => on ? TonePinyinText(w.pinyin!, size: 10, maxLines: 1) : const SizedBox.shrink(),
                  ),
                ),
            ]),
            Expanded(
              child: FutureBuilder<String?>(
                future: ArtService.instance.urlFor(w.word, rank: w.rank),
                builder: (_, snap) {
                  final url = snap.data;
                  return Center(
                    child: url == null
                        ? Text(w.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.zhText(size: w.word.length > 3 ? 16 : 20, weight: FontWeight.w600))
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()))),
                            const SizedBox(height: 2),
                            Text(w.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.zhText(size: 15, weight: FontWeight.w600)),
                          ]),
                  );
                },
              ),
            ),
            if (w.gloss != null && w.gloss!.isNotEmpty)
              Text(w.gloss!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppFonts.captionText(size: 10.5, color: AppColors.moLight)),
          ]),
        ),
      ),
    );
  }
}
