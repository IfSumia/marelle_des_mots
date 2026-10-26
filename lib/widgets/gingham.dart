import 'package:flutter/material.dart';

import '../theme.dart';

/// Pink gingham: translucent stripes in both directions, darker where they cross.
class GinghamBackground extends StatelessWidget {
  const GinghamBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _GinghamPainter(), size: Size.infinite),
    );
  }
}

class _GinghamPainter extends CustomPainter {
  static const tile = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Candy.bg);
    final stripe = Paint()..color = Candy.stripe.withAlpha(105);
    for (var y = 0.0; y < size.height; y += tile * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, tile), stripe);
    }
    for (var x = 0.0; x < size.width; x += tile * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, tile, size.height), stripe);
    }
  }

  @override
  bool shouldRepaint(_GinghamPainter oldDelegate) => false;
}
