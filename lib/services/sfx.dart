import 'package:audioplayers/audioplayers.dart';

/// Short sound effects (assets/audio/<name>.wav).
abstract class Sfx {
  Future<void> init();
  void play(String name);
  void dispose();
}

/// Used in tests, and as the fallback if audio cannot start.
class SilentSfx implements Sfx {
  @override
  Future<void> init() async {}
  @override
  void play(String name) {}
  @override
  void dispose() {}
}

/// One low-latency player per sound, so a tap and its "pop" feel instant.
class AudioSfx implements Sfx {
  static final names = [
    for (var i = 0; i < 10; i++) 'note$i',
    'again',
    'fanfare',
    'boing',
    'cheer',
  ];

  final Map<String, AudioPlayer> _players = {};

  @override
  Future<void> init() async {
    await AudioCache.instance.loadAll([for (final n in names) 'audio/$n.wav']);
    for (final n in names) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      _players[n] = player;
    }
  }

  @override
  void play(String name) {
    final player = _players[name];
    if (player == null) return;
    // Fire and forget: a sound that fails must never break the game.
    player.play(AssetSource('audio/$name.wav')).catchError((Object _) {});
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}
