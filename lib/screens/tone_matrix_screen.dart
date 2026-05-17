import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';

class ToneMatrixScreen extends StatelessWidget {
  const ToneMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: const Text('声调矩阵 4×4')),
      body: Stack(
        children: [
          const Positioned.fill(child: CloudPattern(opacity: 0.05)),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ChineseCard(
                title: '声调 (Tone) 4×4 + 轻声 4',
                sealText: '调',
                child: Text(
                  '2字 단어의 성조 조합 16 칸 + 경성 4 칸 = 20 셀.\n셀 당 10 단어 예시. 총 160 단어 학습 트랙.',
                  style: TextStyle(color: AppColors.moLight, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              _ToneLegend(),
              const SizedBox(height: 12),
              const BrushDivider(),
              const SizedBox(height: 14),
              Text('主矩阵 4×4',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemCount: 16,
                itemBuilder: (context, i) {
                  final r = i ~/ 4 + 1;
                  final c = i % 4 + 1;
                  return _ToneCell(row: r, col: c);
                },
              ),
              const SizedBox(height: 18),
              Text('轻声 (Neutral)',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mo, letterSpacing: 2)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemCount: 4,
                itemBuilder: (context, i) => _ToneCell(row: i + 1, col: 0),
              ),
              const SizedBox(height: 24),
            ],
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
      spacing: 10,
      runSpacing: 8,
      children: [
        _legend(1, '一声 高平 mā'),
        _legend(2, '二声 上升 má'),
        _legend(3, '三声 V  mǎ'),
        _legend(4, '四声 下降 mà'),
        _legend(0, '轻声 ma'),
      ],
    );
  }

  Widget _legend(int tone, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: toneColor(tone), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mo, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ToneCell extends StatelessWidget {
  final int row;
  final int col;
  const _ToneCell({required this.row, required this.col});

  static const Map<String, List<String>> _samples = {
    '1-1': ['妈妈', 'māma', '엄마'],
    '1-2': ['今天', 'jīntiān', '오늘'],
    '1-3': ['身体', 'shēntǐ', '몸'],
    '1-4': ['工作', 'gōngzuò', '일'],
    '2-1': ['昨天', 'zuótiān', '어제'],
    '2-2': ['学习', 'xuéxí', '학습'],
    '2-3': ['学校', 'xuéxiào', '학교'],
    '2-4': ['国家', 'guójiā', '국가'],
    '3-1': ['老师', 'lǎoshī', '선생'],
    '3-2': ['你好', 'nǐ hǎo', '안녕'],
    '3-3': ['可以', 'kěyǐ', '가능'],
    '3-4': ['请坐', 'qǐng zuò', '앉아'],
    '4-1': ['再见', 'zàijiàn', '안녕히'],
    '4-2': ['现在', 'xiànzài', '지금'],
    '4-3': ['对不', 'duìbù', '미안'],
    '4-4': ['谢谢', 'xièxie', '감사'],
    '1-0': ['妈', 'ma', '엄마'],
    '2-0': ['朋友', 'péngyou', '친구'],
    '3-0': ['好的', 'hǎode', '좋아'],
    '4-0': ['爸爸', 'bàba', '아빠'],
  };

  @override
  Widget build(BuildContext context) {
    final key = '$row-$col';
    final sample = _samples[key];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            toneColor(row).withValues(alpha: 0.35),
            toneColor(col == 0 ? null : col).withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                col == 0 ? '$row·轻' : '$row·$col',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mo,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              if (sample != null) ...[
                Text(
                  sample[0],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mo,
                  ),
                ),
                Text(
                  sample[1],
                  style: const TextStyle(fontSize: 9, color: AppColors.moLight, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
