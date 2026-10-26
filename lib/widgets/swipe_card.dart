import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme.dart';

enum _Exit { flyRight, flyLeft, hop }

/// The word card.
///
/// - tap: "I know it" (the card hops away, like the HTML version)
/// - swipe right: "I know it"
/// - swipe left: "show me again"
///
/// [word] is the word to show next. The card keeps showing the old word while
/// it leaves, then switches to [word] and settles back in.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.word,
    required this.height,
    required this.enabled,
    required this.onKnown,
    required this.onAgain,
  });

  final String word;
  final double height;

  /// false while the round-complete celebration is on its way in.
  final bool enabled;
  final VoidCallback onKnown;
  final VoidCallback onAgain;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  static const _swipeDistance = 90.0;
  static const _swipeVelocity = 800.0;

  late String _shown = widget.word;
  double _dx = 0;
  bool _leaving = false;
  _Exit _exit = _Exit.hop;
  double _exitFrom = 0;
  double _exitTo = 0;
  double _backFrom = 0;
  int _dustSeed = 0;

  late final AnimationController _exitCtl;
  late final AnimationController _backCtl;
  late final AnimationController _enterCtl;
  late final AnimationController _wiggleCtl;
  late final AnimationController _dustCtl;

  @override
  void initState() {
    super.initState();
    _exitCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..addListener(_onExitTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _afterExit();
      });
    _backCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
      ..addListener(() {
        setState(() => _dx = lerpDouble(_backFrom, 0, Curves.easeOutBack.transform(_backCtl.value))!);
      });
    _enterCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);
    _wiggleCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _dustCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _wiggleCtl.stop();
    } else if (!_wiggleCtl.isAnimating) {
      _wiggleCtl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // new word dealt while the card is resting (shuffle, new settings...)
    if (!_leaving && widget.word != _shown) {
      _shown = widget.word;
      _enterCtl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _exitCtl.dispose();
    _backCtl.dispose();
    _enterCtl.dispose();
    _wiggleCtl.dispose();
    _dustCtl.dispose();
    super.dispose();
  }

  // ---- decisions ----

  void _decide({required bool known, required _Exit style}) {
    if (_leaving || !widget.enabled) return;
    _leaving = true;
    _backCtl.stop();
    _exit = style;
    _exitFrom = _dx;
    final width = MediaQuery.sizeOf(context).width;
    _exitTo = (style == _Exit.flyLeft ? -1 : 1) * width * 1.1;
    if (known) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        _dustSeed = Random().nextInt(1 << 30);
        _dustCtl.forward(from: 0);
      }
      widget.onKnown();
    } else {
      widget.onAgain();
    }
    _exitCtl.forward(from: 0);
  }

  void _onExitTick() {
    if (!_leaving) return;
    setState(() {
      if (_exit != _Exit.hop) {
        _dx = lerpDouble(_exitFrom, _exitTo, Curves.easeIn.transform(_exitCtl.value))!;
      }
    });
  }

  void _afterExit() {
    setState(() {
      _leaving = false;
      _dx = 0;
      _shown = widget.word;
    });
    _exitCtl.value = 0;
    _enterCtl.forward(from: 0);
  }

  void _springBack() {
    if (_leaving || _dx == 0) return;
    _backFrom = _dx;
    _backCtl.forward(from: 0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_leaving) return;
    final v = details.primaryVelocity ?? 0;
    if (_dx > _swipeDistance || v > _swipeVelocity) {
      _decide(known: true, style: _Exit.flyRight);
    } else if (_dx < -_swipeDistance || v < -_swipeVelocity) {
      _decide(known: false, style: _Exit.flyLeft);
    } else {
      _springBack();
    }
  }

  // ---- drawing ----

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _decide(known: true, style: _Exit.hop),
          onHorizontalDragStart: (_) => _backCtl.stop(),
          onHorizontalDragUpdate: (d) {
            if (_leaving || !widget.enabled) return;
            setState(() => _dx += d.delta.dx);
          },
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _springBack,
          child: AnimatedBuilder(
            animation: Listenable.merge([_enterCtl, _wiggleCtl]),
            builder: (context, _) => _buildCard(width),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _dustCtl,
              builder: (context, _) => CustomPaint(
                painter: _DustPainter(_dustCtl.value, _dustSeed),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(double screenWidth) {
    var dy = 0.0;
    var scale = 1.0;
    var opacity = 1.0;
    var angle = (_dx / screenWidth) * 0.35;

    if (_leaving && _exit == _Exit.hop) {
      // same shape as the V1 "hopAway": up, then down and shrinking
      final e = _exitCtl.value;
      const peak = 0.35;
      if (e < peak) {
        final k = e / peak;
        dy = lerpDouble(0, -46, k)!;
        scale = lerpDouble(1, 1.08, k)!;
        angle = lerpDouble(0, -0.1, k)!;
      } else {
        final k = (e - peak) / (1 - peak);
        dy = lerpDouble(-46, 40, k)!;
        scale = lerpDouble(1.08, 0.4, k)!;
        angle = lerpDouble(-0.1, 0.17, k)!;
        opacity = 1 - k;
      }
    }

    final t = _enterCtl.value;
    if (t < 1) {
      scale *= 0.7 + 0.3 * Curves.easeOutBack.transform(t);
      opacity *= (t * 3).clamp(0.0, 1.0).toDouble();
    }

    final tint = (_dx.abs() / 120).clamp(0.0, 1.0).toDouble();
    final knownSide = _dx > 0;
    final accent = knownSide ? Candy.grass : Candy.yellow;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(_dx, dy),
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scale: scale,
            child: Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Candy.card,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Color.lerp(Candy.text, accent, tint)!, width: 3.5),
                boxShadow: [
                  BoxShadow(color: Color.lerp(Candy.text, accent, tint)!, offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Transform.rotate(
                      angle: _wiggleCtl.value * 0.021,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _shown,
                          maxLines: 1,
                          style: Candy.body(
                            100,
                            weight: FontWeight.w900,
                            style: FontStyle.italic,
                          ).copyWith(
                            shadows: const [Shadow(color: Color(0x40F2677F), offset: Offset(0, 4))],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (tint > 0.05)
                    Positioned(
                      bottom: 16,
                      child: Opacity(
                        opacity: tint,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            knownSide ? 'Je le sais ! ✓' : 'Encore ! ↺',
                            style: Candy.display(20, color: Candy.ink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The burst of coloured chalk dust when a word is known (14 specks).
class _DustPainter extends CustomPainter {
  _DustPainter(this.t, this.seed);

  final double t;
  final int seed;

  static const _colors = [Candy.yellow, Candy.coral, Candy.sky, Candy.grass, Candy.lilac];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rnd = Random(seed);
    final center = size.center(Offset.zero);
    const count = 14;
    for (var i = 0; i < count; i++) {
      final angle = (2 * pi * i) / count + rnd.nextDouble() * 0.4;
      final dist = 60 + rnd.nextDouble() * 50;
      final eased = Curves.easeOut.transform(t);
      final pos = center + Offset(cos(angle), sin(angle)) * dist * eased;
      final radius = 3.5 * (1 - t);
      canvas.drawCircle(pos, radius, Paint()..color = _colors[i % _colors.length]);
    }
  }

  @override
  bool shouldRepaint(_DustPainter old) => old.t != t || old.seed != seed;
}
