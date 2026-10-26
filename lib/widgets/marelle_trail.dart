import 'package:flutter/material.dart';

import '../theme.dart';

/// The hopscotch squares: one lights up for every word read in the round.
class MarelleTrail extends StatelessWidget {
  const MarelleTrail({super.key, required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final fit = (constraints.maxWidth - gap * (total - 1)) / total;
        final size = fit.clamp(24.0, 36.0).toDouble();
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < total; i++) _Square(index: i, size: size, done: i < done),
          ],
        );
      },
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.index, required this.size, required this.done});

  final int index;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = Chalk.trail[index % Chalk.trail.length];
    return AnimatedRotation(
      turns: done ? -3 / 360 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: done ? 1.12 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? color : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: done ? const Color(0x00000000) : Chalk.whiteA(0.35),
              width: 2.5,
            ),
          ),
          child: Text(
            '${index + 1}',
            style: Chalk.display(14, color: done ? Chalk.ink : Chalk.whiteA(0.35)),
          ),
        ),
      ),
    );
  }
}
