import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'store.dart';

/// Looping background music (assets/audio/bg_music_game.m4a).
/// On by default, switch in the settings, paused when the app goes to the background.
class Music extends ChangeNotifier with WidgetsBindingObserver {
  Music(this._store);

  static const asset = 'audio/bg_music_game.m4a';
  static const volume = 0.25;

  final Store _store;
  AudioPlayer? _player;
  bool enabled = true;
  bool _started = false;

  Future<void> init() async {
    enabled = _store.musicOn;
    WidgetsBinding.instance.addObserver(this);
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume);
      _player = player;
      if (enabled) await _start();
    } catch (e) {
      debugPrint('Music unavailable: $e');
    }
  }

  Future<void> _start() async {
    try {
      await _player?.play(AssetSource(asset));
      _started = true;
    } catch (e) {
      debugPrint('Music file missing or unreadable: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    _store.saveMusicOn(value);
    notifyListeners();
    try {
      if (!value) {
        await _player?.pause();
      } else if (_started) {
        await _player?.resume();
      } else {
        await _start();
      }
    } catch (e) {
      debugPrint('Music error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player?.pause();
    } else if (state == AppLifecycleState.resumed && enabled && _started) {
      _player?.resume();
    }
  }
}
