import 'package:flutter/material.dart';

class PhoneticRootsScreen extends StatelessWidget {
  const PhoneticRootsScreen({super.key});

  static const List<_Root> _sample = [
    _Root('巴', 'bā', '파(巴)', 13),
    _Root('青', 'qīng', '청(青)', 11),
    _Root('马', 'mǎ', '마(馬)', 9),
    _Root('生', 'shēng', '생(生)', 14),
    _Root('白', 'bái', '백(白)', 12),
    _Root('王', 'wáng', '왕(王)', 16),
    _Root('木', 'mù', '목(木)', 25),
    _Root('心', 'xīn', '심(心)', 26),
    _Root('口', 'kǒu', '구(口)', 34),
    _Root('土', 'tǔ', '토(土)', 18),
    _Root('日', 'rì', '일(日)', 15),
    _Root('月', 'yuè', '월(月)', 10),
    _Root('又', 'yòu', '우(又)', 9),
    _Root('力', 'lì', '력(力)', 7),
    _Root('刀', 'dāo', '도(刀)', 6),
    _Root('火', 'huǒ', '화(火)', 11),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('발음부 (성부)'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: cs.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('한자 발음부 + 한국 한자음 매핑',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onTertiaryContainer,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    '현대 상용 한자 90%가 형성자.\n'
                    'L1 80자 실측 한국 한자음 ↔ 중국 발음 초성 정합 87.5%.\n'
                    '발음부 200개 → HSK1-5 1500자 풀이 (압축률 7.5× vs Heisig).',
                    style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '샘플 발음부 (총 200 — placeholder)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: _sample.length,
            itemBuilder: (context, i) => _RootCard(root: _sample[i]),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '🔧 200개 전체 발음부 데이터셋 작업 중 (옛 phonetic_roots_200.json 필요).\n'
                '각 발음부 cluster (예: 木 계열 25자, 心 계열 26자, 口 계열 34자) 의 한자 풀이 + mnemonic 25주 작업 예정.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Root {
  final String root;
  final String pinyin;
  final String koHanja;
  final int clusterCount;
  const _Root(this.root, this.pinyin, this.koHanja, this.clusterCount);
}

class _RootCard extends StatelessWidget {
  final _Root root;
  const _RootCard({required this.root});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  root.root,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${root.pinyin} · ${root.koHanja}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'cluster ${root.clusterCount}자',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
