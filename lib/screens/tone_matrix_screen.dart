import 'package:flutter/material.dart';

import '../core/theme.dart';

class ToneMatrixScreen extends StatelessWidget {
  const ToneMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('성조 매트릭스'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('4×4 성조 조합', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '2 자 단어의 성조 패턴 16 칸 + 경성 4 칸 = 20 셀.\n'
                    '셀 당 10 단어 예시. 총 160 단어 학습 트랙.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ToneLegend(),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: 16,
            itemBuilder: (context, i) {
              final r = i ~/ 4 + 1;
              final c = i % 4 + 1;
              return _ToneCell(row: r, col: c);
            },
          ),
          const SizedBox(height: 16),
          Text('경성 (Neutral)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: 4,
            itemBuilder: (context, i) {
              return _ToneCell(row: i + 1, col: 0);
            },
          ),
        ],
      ),
    );
  }
}

class _ToneLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legend(context, 1, '1성 高平 mā'),
        _legend(context, 2, '2성 上升 má'),
        _legend(context, 3, '3성 V mǎ'),
        _legend(context, 4, '4성 下降 mà'),
        _legend(context, 0, '경성 ma'),
      ],
    );
  }

  Widget _legend(BuildContext c, int tone, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: toneColor(tone), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(c).textTheme.bodySmall),
      ],
    );
  }
}

class _ToneCell extends StatelessWidget {
  final int row;
  final int col;
  const _ToneCell({required this.row, required this.col});

  static const Map<String, List<List<String>>> _samples = {
    '1-1': [['妈妈', 'māma', '엄마']],
    '1-2': [['今天', 'jīntiān', '오늘']],
    '1-3': [['身体', 'shēntǐ', '몸']],
    '1-4': [['工作', 'gōngzuò', '일']],
    '2-1': [['昨天', 'zuótiān', '어제']],
    '2-2': [['学习', 'xuéxí', '학습하다']],
    '2-3': [['学校', 'xuéxiào', '학교']],
    '2-4': [['国家', 'guójiā', '국가']],
    '3-1': [['老师', 'lǎoshī', '선생님']],
    '3-2': [['你好', 'nǐ hǎo', '안녕']],
    '3-3': [['可以', 'kěyǐ', '가능']],
    '3-4': [['请坐', 'qǐng zuò', '앉으세요']],
    '4-1': [['再见', 'zàijiàn', '안녕히']],
    '4-2': [['现在', 'xiànzài', '지금']],
    '4-3': [['对不', 'duìbù', '미안']],
    '4-4': [['谢谢', 'xièxie', '감사']],
    '1-0': [['妈', 'ma', '조사']],
    '2-0': [['朋友', 'péngyou', '친구']],
    '3-0': [['好的', 'hǎode', '좋아']],
    '4-0': [['爸爸', 'bàba', '아빠']],
  };

  @override
  Widget build(BuildContext context) {
    final key = '$row-$col';
    final sample = _samples[key]?.first;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            toneColor(row).withValues(alpha: 0.25),
            toneColor(col == 0 ? null : col).withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                col == 0 ? '$row·0' : '$row·$col',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              if (sample != null) ...[
                Text(
                  sample[0],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  sample[1],
                  style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
