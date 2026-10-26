import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../logic/game_controller.dart';
import '../services/sfx.dart';
import 'sprite_library.dart';

/// Where the mascot is relative to the card it hides behind.
enum Presence {
  /// Completely behind the card.
  hidden,

  /// Head and shoulders above the card edge.
  peeking,

  /// Standing on top of the card edge, full body.
  up,
}

/// The mascot's behaviour: when it peeks, how it reacts, what happens on a poke.
///
/// Reactions are picked by clip-name prefix (know_, again_, poke_), so adding
/// `know_3_dance_8.png` to assets/sprites/ adds a new reaction automatically.
class MascotController extends ChangeNotifier {
  MascotController({required this.sprites, required this.sfx, Random? random})
      : _random = random ?? Random() {
    _scheduleAmbient();
    _scheduleBlink();
  }

  final SpriteLibrary sprites;
  final Sfx sfx;
  final Random _random;

  Presence presence = Presence.hidden;
  String clipName = 'idle';

  /// Bumps every time a clip (re)starts, so the player restarts it.
  int serial = 0;

  bool _busy = false;
  bool _disposed = false;
  Timer? _revertTimer;
  Timer? _hideTimer;
  Timer? _ambientTimer;
  Timer? _blinkTimer;
  Timer? _delayTimer;
  final List<String> _recent = [];
  final List<DateTime> _pokes = [];

  // ---- reacting to the game ----

  void onGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.known:
        if (event.streak > 0 && event.streak % 5 == 0 && sprites.has('streak_cheer')) {
          _react('streak_cheer');
        } else {
          _react(_pick('know_'));
        }
      case GameEventType.again:
        _react(_pick('again_'));
      case GameEventType.roundComplete:
        _react(sprites.has('streak_cheer') ? 'streak_cheer' : _pick('know_'));
    }
  }

  /// The child tapped the mascot.
  void poke() {
    if (presence == Presence.hidden) return;
    sfx.play('boing');

    final now = DateTime.now();
    _pokes
      ..add(now)
      ..removeWhere((t) => now.difference(t) > const Duration(seconds: 3));

    String? name;
    if (_pokes.length >= 5 && sprites.has('poke_3_dizzy')) {
      name = 'poke_3_dizzy';
      _pokes.clear();
    } else {
      name = _pick('poke_');
    }
    _react(name);
  }

  // ---- internals ----

  void _react(String? name) {
    if (_disposed || name == null) return;
    _hideTimer?.cancel();
    _delayTimer?.cancel();
    final wasHidden = presence == Presence.hidden;
    presence = Presence.up;
    _busy = true;
    notifyListeners();
    if (wasHidden) {
      // let him climb up before the clip starts
      _delayTimer = Timer(const Duration(milliseconds: 240), () => _playOnce(name));
    } else {
      _playOnce(name);
    }
  }

  void _playOnce(String name) {
    final clip = sprites.clip(name);
    if (_disposed || clip == null) {
      _finish();
      return;
    }
    _revertTimer?.cancel();
    clipName = name;
    serial++;
    notifyListeners();
    _revertTimer = Timer(clip.duration + const Duration(milliseconds: 150), _finish);
  }

  void _finish() {
    if (_disposed) return;
    _busy = false;
    clipName = 'idle';
    serial++;
    if (presence == Presence.up) {
      presence = Presence.peeking;
      _scheduleHide();
    }
    notifyListeners();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    final wait = Duration(milliseconds: 1500 + _random.nextInt(2500));
    _hideTimer = Timer(wait, () {
      if (_disposed) return;
      if (_busy) {
        _scheduleHide();
        return;
      }
      presence = Presence.hidden;
      notifyListeners();
    });
  }

  /// Every few seconds, if nothing is happening, he pops up to say hello.
  void _scheduleAmbient() {
    _ambientTimer?.cancel();
    _ambientTimer = Timer(Duration(seconds: 6 + _random.nextInt(7)), () {
      if (_disposed) return;
      if (!_busy && presence == Presence.hidden) {
        presence = Presence.peeking;
        notifyListeners();
        _scheduleHide();
      }
      _scheduleAmbient();
    });
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: 3000 + _random.nextInt(3000)), () {
      if (_disposed) return;
      if (!_busy && presence != Presence.hidden && sprites.has('idle_blink')) {
        _busy = true;
        _playOnce('idle_blink');
      }
      _scheduleBlink();
    });
  }

  /// Picks a random clip starting with [prefix], never one of the last two used.
  String? _pick(String prefix) {
    final names = sprites.namesWithPrefix(prefix);
    if (names.isEmpty) return null;
    final avoid = _recent.reversed.take(min(2, names.length - 1)).toSet();
    final options = names.where((n) => !avoid.contains(n)).toList();
    final choice = options[_random.nextInt(options.length)];
    _recent.add(choice);
    if (_recent.length > 4) _recent.removeAt(0);
    return choice;
  }

  @override
  void dispose() {
    _disposed = true;
    _revertTimer?.cancel();
    _hideTimer?.cancel();
    _ambientTimer?.cancel();
    _blinkTimer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }
}
