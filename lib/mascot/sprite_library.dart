import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// One animation: a horizontal strip of equally wide frames.
class SpriteClip {
  const SpriteClip({
    required this.name,
    required this.image,
    required this.frames,
    required this.fps,
    required this.loop,
  });

  final String name;
  final ui.Image image;
  final int frames;
  final double fps;
  final bool loop;

  double get frameWidth => image.width / frames;
  double get frameHeight => image.height.toDouble();

  Duration get duration => Duration(milliseconds: (frames * 1000 / fps).round());
}

/// Loads every strip in assets/sprites/.
///
/// The file name says everything: `know_1_jump_10.png` is the clip
/// "know_1_jump" with 10 frames. Drop a new strip in the folder and it is
/// picked up, no code to change. Files whose name does not end in
/// `_<number>.png` (for example `idle_6_anchors.png`) are ignored.
class SpriteLibrary {
  const SpriteLibrary(this._clips);

  final Map<String, SpriteClip> _clips;

  static const empty = SpriteLibrary({});

  /// Clips that play over and over until something else happens.
  static bool isLooping(String name) =>
      name == 'idle' ||
      name == 'peek_hold' ||
      name == 'drag_dangle' ||
      name == 'sleep' ||
      (name.startsWith('tickle_') && name != 'tickle_end');

  /// Frames per second. Subtle clips are slower so they do not look jittery.
  static double fpsFor(String name) => name == 'idle' || name == 'sleep' ? 4 : 10;

  static Future<SpriteLibrary> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final nameAndCount = RegExp(r'^(.+)_(\d+)$');
    final clips = <String, SpriteClip>{};

    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith('assets/sprites/') || !asset.endsWith('.png')) continue;
      final file = asset.split('/').last;
      final match = nameAndCount.firstMatch(file.substring(0, file.length - 4));
      if (match == null) continue;
      final name = match.group(1)!;
      final frames = int.parse(match.group(2)!);
      if (frames < 1) continue;

      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      clips[name] = SpriteClip(
        name: name,
        image: frame.image,
        frames: frames,
        fps: fpsFor(name),
        loop: isLooping(name),
      );
    }
    return SpriteLibrary(clips);
  }

  SpriteClip? clip(String name) => _clips[name];
  bool has(String name) => _clips.containsKey(name);

  /// Names of all clips starting with [prefix], e.g. "know_".
  List<String> namesWithPrefix(String prefix) =>
      _clips.keys.where((n) => n.startsWith(prefix)).toList()..sort();
}
