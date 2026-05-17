import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';

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
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: const Text('발음부 + 한국 한자음')),
      body: Stack(
        children: [
          const Positioned.fill(child: CloudPattern(opacity: 0.05)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ChineseCard(
                title: '발음부 + 한국 한자음 매핑',
                sealText: '声旁',
                accent: const Color(0xFF6A1B9A),
                child: Text(
                  '현대 상용 한자 90% 형성자.\n'
                  'L1 80자 실측 한국 한자음 ↔ 중국 발음 초성 정합 87.5%.\n'
                  '발음부 200 → HSK1-5 1500자 풀이 (압축 7.5× vs Heisig).',
                  style: TextStyle(color: AppColors.moLight, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              const BrushDivider(),
              const SizedBox(height: 14),
              Text(
                '발음부 샘플 16 (총 200 placeholder)',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                ),
                itemCount: _sample.length,
                itemBuilder: (context, i) => _RootCard(root: _sample[i]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.xuanZhiDeep,
                  border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '🔧 200개 전체 발음부 데이터셋 작업 중.\ncluster (木 25자 · 心 26자 · 口 34자 …) + 발음부별 mnemonic 25주 손작성 예정.',
                  style: const TextStyle(color: AppColors.moLight, fontSize: 11, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SealStamp(text: root.root, size: 52, color: AppColors.zhuHong),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      root.pinyin,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.mo,
                      ),
                    ),
                    Text(
                      root.koHanja,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.moLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.jin.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.jin),
                      ),
                      child: Text(
                        'cluster ${root.clusterCount}',
                        style: const TextStyle(fontSize: 9, color: AppColors.mo, fontWeight: FontWeight.w700),
                      ),
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
