import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';

class HskScreen extends StatefulWidget {
  const HskScreen({super.key});

  @override
  State<HskScreen> createState() => _HskScreenState();
}

class _HskScreenState extends State<HskScreen> {
  final List<_Level> _levels = const [
    _Level('HSK 汉字 一级', 'assets/data/hsk/HSK_hanzi_1.txt', '一', AppColors.zhuHong),
    _Level('HSK 汉字 二级', 'assets/data/hsk/HSK_hanzi_2.txt', '二', AppColors.zhuHongLight),
    _Level('HSK 汉字 三级', 'assets/data/hsk/HSK_hanzi_3.txt', '三', AppColors.jin),
    _Level('HSK 词汇 一级', 'assets/data/hsk/HSK_1.txt', 'A', AppColors.feiCui),
    _Level('HSK 词汇 二级', 'assets/data/hsk/HSK_2.txt', 'B', AppColors.jinDeep),
    _Level('HSK 词汇 三级', 'assets/data/hsk/HSK_3.txt', 'C', AppColors.moLight),
  ];

  String? _selectedAsset;
  List<String> _items = [];
  bool _loading = false;

  Future<void> _open(String assetPath) async {
    setState(() {
      _selectedAsset = assetPath;
      _loading = true;
      _items = [];
    });
    final raw = await rootBundle.loadString(assetPath);
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
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
        title: Text(_selectedAsset == null
            ? 'HSK 等级'
            : _levels.firstWhere((l) => l.asset == _selectedAsset).title),
        leading: _selectedAsset != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedAsset = null;
                  _items = [];
                }),
              )
            : null,
      ),
      body: _selectedAsset == null ? _buildList() : _buildDetail(),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ChineseCard(
          title: 'HSK · 新汉语水平考试',
          sealText: 'HSK',
          child: Text(
            '中华人民共和国 国家汉办 시험 분급.\n신HSK 2021 — 一级 ~ 七至九级.',
            style: TextStyle(color: AppColors.moLight, fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        ..._levels.map((level) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _open(level.asset),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.xuanZhi,
                    border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        color: level.color,
                        alignment: Alignment.center,
                        child: SealStamp(text: level.seal, size: 40, color: level.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          level.title,
                          style: const TextStyle(
                            fontSize: 15,
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
            )),
      ],
    );
  }

  Widget _buildDetail() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.zhuHong));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) =>
          Container(height: 0.5, color: AppColors.jin.withValues(alpha: 0.3)),
      itemBuilder: (context, i) {
        return Container(
          color: AppColors.xuanZhi,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.moLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _items[i],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mo,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Level {
  final String title;
  final String asset;
  final String seal;
  final Color color;
  const _Level(this.title, this.asset, this.seal, this.color);
}
