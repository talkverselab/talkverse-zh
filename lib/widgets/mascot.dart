import 'package:flutter/material.dart';

/// 마스코트 감정 11종.
enum MascotEmotion {
  excited('excited', '신나요'),
  neutral('neutral', '보통이야'),
  worried('worried', '걱정돼'),
  angry('angry', '화가나'),
  annoyed('annoyed', '짜증나'),
  sad('sad', '슬퍼'),
  disappointed('disappointed', '실망이야'),
  gaveup('gaveup', '포기했어'),
  exhausted('exhausted', '지쳤어'),
  displeased('displeased', '못마땅해'),
  breakdown('breakdown', '멘붕이야');

  final String slug;
  final String label;
  const MascotEmotion(this.slug, this.label);

  String get asset => 'assets/characters/emotions/$slug.png';
}

/// 중국 마스코트 — 12 감정 + 드래그 + 떠다님 + 탭하면 감정 순환.
class ChineseMascot extends StatefulWidget {
  final double size;
  final Offset initialPosition;
  final bool draggable;
  final MascotEmotion emotion;
  final VoidCallback? onTap;
  final bool cycleOnTap;

  const ChineseMascot({
    super.key,
    this.size = 96,
    this.initialPosition = const Offset(0, 0),
    this.draggable = true,
    this.emotion = MascotEmotion.excited,
    this.onTap,
    this.cycleOnTap = true,
  });

  @override
  State<ChineseMascot> createState() => _ChineseMascotState();
}

class _ChineseMascotState extends State<ChineseMascot>
    with TickerProviderStateMixin {
  late Offset _pos;
  late MascotEmotion _emotion;
  late AnimationController _floatCtrl;
  late AnimationController _tapCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _tapScale;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPosition;
    _emotion = widget.emotion;

    _floatCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _tapCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.18, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant ChineseMascot old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion) {
      setState(() => _emotion = widget.emotion);
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapCtrl.forward(from: 0);
    if (widget.cycleOnTap) {
      setState(() {
        final values = MascotEmotion.values;
        final i = values.indexOf(_emotion);
        _emotion = values[(i + 1) % values.length];
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onTap: _handleTap,
        onPanStart: widget.draggable
            ? (_) => setState(() => _dragging = true)
            : null,
        onPanUpdate: widget.draggable
            ? (d) => setState(() {
                  _pos = Offset(_pos.dx + d.delta.dx, _pos.dy + d.delta.dy);
                })
            : null,
        onPanEnd: widget.draggable
            ? (_) {
                setState(() => _dragging = false);
                _clampToScreen();
              }
            : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatAnim, _tapScale]),
          builder: (context, child) {
            final dy = _dragging ? 0.0 : _floatAnim.value;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: _tapScale.value,
                child: _MascotImage(
                  size: widget.size,
                  dragging: _dragging,
                  emotion: _emotion,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _clampToScreen() {
    final mq = MediaQuery.of(context).size;
    final safe = MediaQuery.of(context).padding;
    final w = widget.size;
    final minX = -w * 0.2;
    final maxX = mq.width - w * 0.8;
    final minY = safe.top - w * 0.1;
    final maxY = mq.height - safe.bottom - w * 0.8;
    setState(() {
      _pos = Offset(
        _pos.dx.clamp(minX, maxX),
        _pos.dy.clamp(minY, maxY),
      );
    });
  }
}

class _MascotImage extends StatelessWidget {
  final double size;
  final bool dragging;
  final MascotEmotion emotion;
  const _MascotImage({
    required this.size,
    required this.dragging,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDE2910).withValues(alpha: dragging ? 0.5 : 0.25),
              blurRadius: dragging ? 18 : 10,
              spreadRadius: dragging ? 3 : 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Image.asset(
            emotion.asset,
            key: ValueKey(emotion.slug),
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
