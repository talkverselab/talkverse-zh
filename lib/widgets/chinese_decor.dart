import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 印章 — 빨간 직사각형 인장. 한자 1-4자 표시.
class SealStamp extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final bool vertical;

  const SealStamp({
    super.key,
    required this.text,
    this.size = 56,
    this.color,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.zhuHong;
    final isOne = text.runes.length == 1;
    final fontSize = isOne ? size * 0.6 : size * 0.32;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: c, width: 2),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.contain,
          child: vertical
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: text.runes
                      .map((r) => Text(
                            String.fromCharCode(r),
                            style: TextStyle(
                              color: AppColors.xuanZhi,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ))
                      .toList(),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: AppColors.xuanZhi,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 卷轴 — 두루마리 스타일 컨테이너. 위·아래 금색 봉이 있음.
class ScrollPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;

  const ScrollPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = AppColors.xuanZhi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.jin.withValues(alpha: 0.6), width: 3),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// 灯笼 — 빨간 등롱 작은 장식 (Stack 안 Positioned 권장)
class Lantern extends StatelessWidget {
  final double size;
  const Lantern({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 끈
          Positioned(
            top: 0,
            child: Container(width: 1.5, height: size * 0.15, color: AppColors.jinDeep),
          ),
          // 갓
          Positioned(
            top: size * 0.13,
            child: Container(width: size * 0.7, height: size * 0.08, color: AppColors.jinDeep),
          ),
          // 몸체
          Positioned(
            top: size * 0.21,
            child: Container(
              width: size,
              height: size * 0.85,
              decoration: BoxDecoration(
                color: AppColors.zhuHong,
                borderRadius: BorderRadius.circular(size * 0.5),
                border: Border.all(color: AppColors.jinDeep, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.zhuHong.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // 받침
          Positioned(
            bottom: 0,
            child: Container(width: size * 0.7, height: size * 0.06, color: AppColors.jinDeep),
          ),
          // 술
          Positioned(
            bottom: -size * 0.04,
            child: Container(width: 1.5, height: size * 0.1, color: AppColors.jinDeep),
          ),
        ],
      ),
    );
  }
}

/// 雲紋 — 운문 패턴 그림 (장식용 배경)
class CloudPattern extends StatelessWidget {
  final Color color;
  final double opacity;

  const CloudPattern({
    super.key,
    this.color = AppColors.jin,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CloudPatternPainter(color: color.withValues(alpha: opacity)),
      child: const SizedBox.expand(),
    );
  }
}

class _CloudPatternPainter extends CustomPainter {
  final Color color;
  _CloudPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const step = 60.0;
    for (var x = -step; x < size.width + step; x += step) {
      for (var y = -step; y < size.height + step; y += step) {
        _drawRuyiCloud(canvas, paint, Offset(x, y), 22);
      }
    }
  }

  void _drawRuyiCloud(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    path.moveTo(center.dx - r, center.dy);
    path.arcToPoint(
      Offset(center.dx - r * 0.4, center.dy - r * 0.4),
      radius: Radius.circular(r * 0.5),
    );
    path.arcToPoint(
      Offset(center.dx + r * 0.4, center.dy - r * 0.4),
      radius: Radius.circular(r * 0.5),
    );
    path.arcToPoint(
      Offset(center.dx + r, center.dy),
      radius: Radius.circular(r * 0.5),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 回纹 — 만(卍) 띠 디바이더 (수평 패턴)
class GreekKeyDivider extends StatelessWidget {
  final double height;
  final Color color;
  const GreekKeyDivider({super.key, this.height = 16, this.color = AppColors.jin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _GreekKeyPainter(color: color),
      ),
    );
  }
}

class _GreekKeyPainter extends CustomPainter {
  final Color color;
  _GreekKeyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final unit = size.height / 4;
    for (var x = 0.0; x < size.width; x += unit * 5) {
      final path = Path()
        ..moveTo(x, size.height - unit)
        ..lineTo(x, unit)
        ..lineTo(x + unit * 4, unit)
        ..lineTo(x + unit * 4, unit * 3)
        ..lineTo(x + unit * 2, unit * 3)
        ..lineTo(x + unit * 2, unit * 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 毛笔 분리선 — 붓터치 느낌 그라데이션 라인
class BrushDivider extends StatelessWidget {
  final double height;
  final Color color;
  const BrushDivider({super.key, this.height = 3, this.color = AppColors.mo});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.6),
            color,
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0),
          ],
        ),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

/// 中国风 카드 — 빨간 헤더 + 금색 테두리 + 卍 코너
class ChineseCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? sealText;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  const ChineseCard({
    super.key,
    required this.child,
    this.title,
    this.sealText,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? AppColors.zhuHong;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.mo.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Container(
                color: a,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (sealText != null) ...[
                      SealStamp(text: sealText!, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: AppColors.xuanZhi,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right, color: AppColors.xuanZhi, size: 18),
                  ],
                ),
              ),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// 双囍 — 喜자 데코 텍스트 (장식)
class XiText extends StatelessWidget {
  final double size;
  const XiText({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Text(
      '囍',
      style: TextStyle(
        color: AppColors.zhuHong,
        fontSize: size,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

/// 별 — 5각 별 (중국 깃발 노란별)
class StarPainter extends CustomPainter {
  final Color color;
  StarPainter({this.color = AppColors.jin});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.shortestSide / 2;
    final inner = outer * 0.4;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class ChineseStar extends StatelessWidget {
  final double size;
  final Color color;
  const ChineseStar({super.key, this.size = 16, this.color = AppColors.jin});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: StarPainter(color: color),
    );
  }
}
