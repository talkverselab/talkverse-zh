import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('학습 진행', style: TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 2),
            Text('Progress', style: TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month, color: AppColors.mo), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OverallCard(),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatBox(label: '완료한 수업', value: '14', seal: '完')),
              SizedBox(width: 8),
              Expanded(child: _StatBox(label: '학습 시간', value: '8h 30m', seal: '时')),
              SizedBox(width: 8),
              Expanded(child: _StatBox(label: '연속 학습', value: '7일', seal: '日')),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const SealStamp(text: '周', size: 22),
              const SizedBox(width: 8),
              Text(
                '이번 주 학습',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mo,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WeeklyRow(),
          const SizedBox(height: 18),
          const BrushDivider(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SealStamp(text: '册', size: 22),
              const SizedBox(width: 8),
              Text(
                '학습 영역별',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mo,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _CategoryBar(label: '회화', percent: 0.45, color: AppColors.zhuHong),
          const _CategoryBar(label: '한자 209', percent: 0.18, color: Color(0xFFC62828)),
          const _CategoryBar(label: '단어', percent: 0.06, color: AppColors.feiCui),
          const _CategoryBar(label: '발음', percent: 0.30, color: Color(0xFF1565C0)),
          const _CategoryBar(label: 'HSK', percent: 0.12, color: AppColors.jinDeep),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const percent = 0.35;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
        ),
        border: Border.all(color: AppColors.jin, width: 1.5),
      ),
      child: Stack(
        children: [
          const Positioned(top: -4, right: -4, child: SealStamp(text: '加油', size: 50)),
          Padding(
            padding: const EdgeInsets.only(right: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전체 진행률',
                  style: TextStyle(
                    color: AppColors.jinBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(percent * 100).round()}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.xuanZhi,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '%',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.xuanZhi.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.xuanZhi.withValues(alpha: 0.25),
                        border: Border.all(color: AppColors.jin.withValues(alpha: 0.4)),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(height: 8, color: AppColors.jinBright),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String seal;
  const _StatBox({required this.label, required this.value, required this.seal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SealStamp(text: seal, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.zhuHong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.moLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WeeklyRow extends StatelessWidget {
  static const _days = ['월', '화', '수', '목', '금', '토', '일'];
  static const _done = [true, true, true, true, true, false, false];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.xuanZhiDeep,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final done = _done[i];
          return Expanded(
            child: Column(
              children: [
                Text(
                  _days[i],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.moLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: done ? AppColors.zhuHong : AppColors.xuanZhi,
                    border: Border.all(
                      color: done ? AppColors.zhuHongDeep : AppColors.jin.withValues(alpha: 0.5),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    done ? Icons.check : Icons.circle_outlined,
                    size: done ? 18 : 12,
                    color: done ? AppColors.xuanZhi : AppColors.moLight.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  const _CategoryBar({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mo,
                  ),
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.xuanZhiDeep,
                  border: Border.all(color: AppColors.jin.withValues(alpha: 0.3)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(height: 7, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
