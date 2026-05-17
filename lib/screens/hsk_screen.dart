import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/cedict_service.dart';
import '../widgets/chinese_decor.dart';

class HskScreen extends StatefulWidget {
  const HskScreen({super.key});

  @override
  State<HskScreen> createState() => _HskScreenState();
}

class _HskScreenState extends State<HskScreen> {
  static const List<_Level> _hanzi = [
    _Level('HSK 한자 1급', 'assets/data/hsk/HSK_hanzi_1.txt', '一', AppColors.zhuHong, _Kind.hanzi),
    _Level('HSK 한자 2급', 'assets/data/hsk/HSK_hanzi_2.txt', '二', AppColors.zhuHongLight, _Kind.hanzi),
    _Level('HSK 한자 3급', 'assets/data/hsk/HSK_hanzi_3.txt', '三', AppColors.jin, _Kind.hanzi),
    _Level('HSK 한자 4급', 'assets/data/hsk/HSK_hanzi_4.txt', '四', AppColors.jinDeep, _Kind.hanzi),
    _Level('HSK 한자 5급', 'assets/data/hsk/HSK_hanzi_5.txt', '五', AppColors.feiCui, _Kind.hanzi),
    _Level('HSK 한자 6급', 'assets/data/hsk/HSK_hanzi_6.txt', '六', AppColors.moLight, _Kind.hanzi),
    _Level('HSK 한자 7-9급', 'assets/data/hsk/HSK_hanzi_7-9.txt', '九', AppColors.mo, _Kind.hanzi),
  ];
  static const List<_Level> _vocab = [
    _Level('HSK 단어 1급', 'assets/data/hsk/HSK_1.txt', 'A', AppColors.zhuHong, _Kind.word),
    _Level('HSK 단어 2급', 'assets/data/hsk/HSK_2.txt', 'B', AppColors.zhuHongLight, _Kind.word),
    _Level('HSK 단어 3급', 'assets/data/hsk/HSK_3.txt', 'C', AppColors.jin, _Kind.word),
    _Level('HSK 단어 4급', 'assets/data/hsk/HSK_4.txt', 'D', AppColors.jinDeep, _Kind.word),
    _Level('HSK 단어 5급', 'assets/data/hsk/HSK_5.txt', 'E', AppColors.feiCui, _Kind.word),
    _Level('HSK 단어 6급', 'assets/data/hsk/HSK_6.txt', 'F', AppColors.moLight, _Kind.word),
    _Level('HSK 단어 7-9급', 'assets/data/hsk/HSK_7-9.txt', 'G', AppColors.mo, _Kind.word),
  ];

  _Level? _selected;
  List<String> _items = [];
  bool _loading = false;

  Future<void> _open(_Level level) async {
    setState(() {
      _selected = level;
      _loading = true;
      _items = [];
    });
    final raw = await rootBundle.loadString(level.asset);
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    CedictService.instance.ensureLoaded();
    setState(() {
      _items = lines;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(_selected?.title ?? 'HSK 분급'),
        leading: _selected != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selected = null;
                  _items = [];
                }),
              )
            : null,
      ),
      body: _selected == null ? _buildList() : _buildDetail(),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChineseCard(
          title: 'HSK · 한어수평고시',
          sealText: 'HSK',
          child: Text(
            '중국 국가한판 (国家汉办) 공식 분급.\n신HSK 2021 — 1급 ~ 7-9급. 한자·단어 별도 트랙.',
            style: TextStyle(color: AppColors.moLight, fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const SealStamp(text: '汉字', size: 22),
            const SizedBox(width: 8),
            Text('한자',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 8),
        ..._hanzi.map(_levelTile),
        const SizedBox(height: 18),
        Row(
          children: [
            const SealStamp(text: '词汇', size: 22),
            const SizedBox(width: 8),
            Text('단어',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 8),
        ..._vocab.map(_levelTile),
      ],
    );
  }

  Widget _levelTile(_Level level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _open(level),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.xuanZhi,
            border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                color: level.color,
                alignment: Alignment.center,
                child: SealStamp(text: level.seal, size: 36, color: level.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  level.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mo,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.chevron_right, color: AppColors.zhuHong, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.zhuHong));
    }
    final isHanzi = _selected!.kind == _Kind.hanzi;
    return Column(
      children: [
        Container(
          color: AppColors.xuanZhiDeep,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_items.length}개',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.zhuHong),
              ),
              const SizedBox(width: 8),
              Text(
                isHanzi ? '· 한자' : '· 단어',
                style: const TextStyle(fontSize: 11, color: AppColors.moLight, letterSpacing: 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) =>
                Container(height: 0.5, color: AppColors.jin.withValues(alpha: 0.3)),
            itemBuilder: (context, i) => _DictTile(text: _items[i], index: i + 1),
          ),
        ),
      ],
    );
  }
}

class _DictTile extends StatelessWidget {
  final String text;
  final int index;
  const _DictTile({required this.text, required this.index});

  void _openDef(BuildContext context) {
    final entry = CedictService.instance.lookup(text);
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
                  text,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: AppColors.zhuHong,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mo),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (entry != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.jin.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.jin),
                ),
                child: Text(
                  entry.pinyin,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.mo),
                ),
              ),
              const SizedBox(height: 14),
              ...entry.meanings.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('· ', style: TextStyle(color: AppColors.zhuHong, fontSize: 14)),
                        Expanded(
                          child: Text(
                            m.trim(),
                            style: const TextStyle(fontSize: 14, color: AppColors.mo, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else
              Text(
                '사전에 없음 (CC-CEDICT)',
                style: TextStyle(color: AppColors.moLight, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                '$index',
                style: const TextStyle(fontSize: 11, color: AppColors.moLight, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.mo),
              ),
            ),
            const Icon(Icons.translate, color: AppColors.jin, size: 16),
          ],
        ),
      ),
    );
  }
}

enum _Kind { hanzi, word }

class _Level {
  final String title;
  final String asset;
  final String seal;
  final Color color;
  final _Kind kind;
  const _Level(this.title, this.asset, this.seal, this.color, this.kind);
}
