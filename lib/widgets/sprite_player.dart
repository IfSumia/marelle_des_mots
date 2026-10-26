import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../mascot/sprite_library.dart';

/// How sprite pixels are smoothed when scaled up. `none` keeps hard pixel-art
/// edges (can shimmer at fractional scales); `low` is smooth and cheap.
const FilterQuality kSpriteFilter = FilterQuality.low;

/// Plays one [SpriteClip]. Changing [serial] restarts the clip from frame 0.
///
/// Only a timer at the clip's frame rate (4 to 10 per second) repaints, and it
/// is paused while the app is in the background: very cheap.
class SpritePlayer extends StatefulWidget {
  const SpritePlayer({
    super.key,
    required this.clip,
    required this.serial,
    required this.pixelScale,
  });

  final SpriteClip clip;
  final int serial;

  /// Screen points per pixel of the source art.
  final double pixelScale;

  @override
  State<SpritePlayer> createState() => _SpritePlayerState();
}

class _SpritePlayerState extends State<SpritePlayer> with WidgetsBindingObserver {
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  @override
  void didUpdateWidget(SpritePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serial != widget.serial || oldWidget.clip != widget.clip) {
      _restart();
    }
  }

  void _restart() {
    _timer?.cancel();
    _frame.value = 0;
    if (widget.clip.frames <= 1) return;
    final interval = Duration(milliseconds: (1000 / widget.clip.fps).round());
    _timer = Timer.periodic(interval, _tick);
  }

  void _tick(Timer timer) {
    final next = _frame.value + 1;
    if (next < widget.clip.frames) {
      _frame.value = next;
    } else if (widget.clip.loop) {
      _frame.value = 0;
    } else {
      timer.cancel(); // hold the last frame until the controller moves on
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restart();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SpritePainter(widget.clip, _frame, widget.pixelScale),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.clip, this.frame, this.pixelScale) : super(repaint: frame);

  final SpriteClip clip;
  final ValueListenable<int> frame;
  final double pixelScale;

  final Paint _paint = Paint()..filterQuality = kSpriteFilter;

  @override
  void paint(Canvas canvas, Size size) {
    final index = frame.value.clamp(0, clip.frames - 1).toInt();
    final src = Rect.fromLTWH(index * clip.frameWidth, 0, clip.frameWidth, clip.frameHeight);
    final w = clip.frameWidth * pixelScale;
    final h = clip.frameHeight * pixelScale;
    // feet on the bottom edge, centred; taller frames (jumps) extend upward
    final dst = Rect.fromLTWH((size.width - w) / 2, size.height - h, w, h);
    canvas.drawImageRect(clip.image, src, dst, _paint);
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.clip != clip || old.pixelScale != pixelScale;
}
