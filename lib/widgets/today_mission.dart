import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'chinese_decor.dart';

/// Today's Mission 카드 — 현재 진행 중인 레슨 표시 (산 일러스트 + progress).
class TodayMissionCard extends StatelessWidget {
  final String level;
  final String lessonTitle;
  final String lessonSubtitle;
  final int progress;
  final int total;
  final VoidCallback? onTap;

  const TodayMissionCard({
    super.key,
    required this.level,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.progress,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.jin, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.zhuHong.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 산 일러스트 (오른쪽 하단)
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(160, 100),
                painter: _MountainPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.jinBright,
                          border: Border.all(color: AppColors.jinDeep, width: 0.6),
                        ),
                        child: Text(
                          level,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mo,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SealStamp(text: '今', size: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lessonTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.xuanZhi,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lessonSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.xuanZhi.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$progress / $total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.jinBright,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.xuanZhi.withValues(alpha: 0.25),
                          border: Border.all(color: AppColors.jin, width: 0.6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: total > 0 ? progress / total : 0,
                        child: Container(
                          height: 8,
                          color: AppColors.jinBright,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.zhuHongDeep
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.3, size.height * 0.35)
      ..lineTo(size.width * 0.55, size.height * 0.6)
      ..lineTo(size.width * 0.75, size.height * 0.2)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, p);
    // 깃발
    final flag = Paint()..color = AppColors.jinBright;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.74, size.height * 0.2, 1.5, size.height * 0.18),
      flag,
    );
    final flagPath = Path()
      ..moveTo(size.width * 0.755, size.height * 0.2)
      ..lineTo(size.width * 0.84, size.height * 0.25)
      ..lineTo(size.width * 0.755, size.height * 0.3)
      ..close();
    canvas.drawPath(flagPath, flag);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 🔥 streak counter — 헤더용 작은 칩
class StreakChip extends StatelessWidget {
  final int days;
  const StreakChip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.zhuHongDeep,
        border: Border.all(color: AppColors.jinBright, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              color: AppColors.jinBright,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
