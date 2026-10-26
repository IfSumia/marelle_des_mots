import 'package:flutter/material.dart';

import '../mascot/mascot_controller.dart';
import 'sprite_player.dart';

/// The mascot, drawn in a square of [size] points.
///
/// Must be a direct child of a [Stack] (it returns a [Positioned]), drawn
/// BEFORE the card so the card hides him. [cardTop] is the y of the card's top
/// edge inside that Stack; the Stack must have at least [size] of room above it.
///
/// - hidden: his box sits entirely behind the card (nothing is drawn)
/// - peeking: 55% of him sticks out above the card edge
/// - up: he stands on the card edge, full body
///
/// Taller frames (jumps) paint above the box on purpose, so keep
/// Stack.clipBehavior at Clip.none. The box itself moves with real layout
/// (not a paint transform) so that taps on him are still hit-tested.
class MascotView extends StatelessWidget {
  const MascotView({
    super.key,
    required this.controller,
    required this.size,
    required this.cardTop,
  });

  final MascotController controller;
  final double size;
  final double cardTop;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final idle = controller.sprites.clip('idle');
        final clip = controller.sprites.clip(controller.clipName) ?? idle;
        if (idle == null || clip == null) return const SizedBox.shrink();

        final rise = switch (controller.presence) {
          Presence.hidden => 0.0,
          Presence.peeking => 0.55,
          Presence.up => 1.0,
        };
        final pixelScale = size / idle.frameHeight;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: rise),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          builder: (context, r, _) {
            if (r < 0.02) return const SizedBox.shrink();
            return Positioned(
              top: cardTop - r.clamp(0.0, 1.0).toDouble() * size,
              left: 0,
              right: 0,
              height: size,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.poke,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: SpritePlayer(
                      clip: clip,
                      serial: controller.serial,
                      pixelScale: pixelScale,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
