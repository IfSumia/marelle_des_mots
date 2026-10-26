import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/lessons.dart';
import '../services/sfx.dart';
import '../services/store.dart';
import 'deck_settings.dart';
import 'word_pool.dart';

enum GameEventType { known, again, roundComplete }

/// Something the child just did. The mascot listens to these.
class GameEvent {
  const GameEvent(this.type, {this.streak = 0});

  final GameEventType type;

  /// Words known in a row, including this one (0 after "again").
  final int streak;
}

/// The rules of the game: which word is next, score, streak, trail.
class GameController extends ChangeNotifier {
  GameController({
    required this.library,
    required this.store,
    required this.sfx,
    Random? random,
  }) : _random = random ?? Random();

  /// Words to read before the hopscotch trail is complete.
  static const casesPerRound = 10;

  /// Swiping "show me again" ends the streak. Set to false to be gentler:
  /// the streak is then only paused, never lost.
  static const againResetsStreak = true;

  final LessonLibrary library;
  final Store store;
  final Sfx sfx;
  final Random _random;

  final StreamController<GameEvent> _events = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _events.stream;

  DeckSettings settings = const DeckSettings();
  List<String> _pool = const [];
  final List<String> _deck = [];

  String word = '';
  int score = 0;
  int streak = 0;
  int best = 0;
  int roundProgress = 0;
  bool roundComplete = false;

  int get poolSize => _pool.length;

  @visibleForTesting
  List<String> get upcoming => List.unmodifiable(_deck);

  /// Loads the saved settings and deals the first word.
  void init() {
    settings = store.settings;
    best = store.best;
    _rebuild();
  }

  // ---- what the child does ----

  /// Tap, or swipe right: "I know this word".
  void known() {
    if (roundComplete) return;
    score++;
    streak++;
    roundProgress++;
    if (streak > best) {
      best = streak;
      store.saveBest(best);
    }
    if (roundProgress >= casesPerRound) {
      roundComplete = true;
      sfx.play('fanfare');
      _events.add(GameEvent(GameEventType.roundComplete, streak: streak));
    } else {
      // one marimba note per trail square: reading climbs a scale
      sfx.play('note${(roundProgress - 1).clamp(0, casesPerRound - 1)}');
      _events.add(GameEvent(GameEventType.known, streak: streak));
      _deal();
    }
    notifyListeners();
  }

  /// Swipe left: "show me this one again". The word comes back in a few cards.
  void again() {
    if (roundComplete) return;
    if (againResetsStreak) streak = 0;
    final position = min(_deck.length, 3 + _random.nextInt(4));
    _deck.insert(position, word);
    sfx.play('again');
    _events.add(const GameEvent(GameEventType.again));
    _deal();
    notifyListeners();
  }

  // ---- menu actions ----

  void continueRound() {
    roundProgress = 0;
    roundComplete = false;
    _deal(); // keeps the words queued by "encore"; reshuffles only when the deck runs out
    notifyListeners();
  }

  void shuffle() {
    _reshuffle();
    _deal();
    notifyListeners();
  }

  void resetScore() {
    score = 0;
    streak = 0;
    roundProgress = 0;
    roundComplete = false;
    _reshuffle();
    _deal();
    notifyListeners();
  }

  void applySettings(DeckSettings newSettings) {
    settings = newSettings;
    store.saveSettings(newSettings);
    roundProgress = 0;
    roundComplete = false;
    _rebuild();
    notifyListeners();
  }

  // ---- deck ----

  void _rebuild() {
    _pool = buildPool(library, settings);
    _reshuffle();
    _deal();
  }

  void _reshuffle() {
    _deck
      ..clear()
      ..addAll(_pool)
      ..shuffle(_random);
    // do not open the new deck with the word she just saw
    if (_deck.length > 1 && _deck.first == word) {
      final last = _deck.length - 1;
      final swap = _deck[0];
      _deck[0] = _deck[last];
      _deck[last] = swap;
    }
  }

  void _deal() {
    if (_deck.isEmpty) _reshuffle();
    if (_deck.isEmpty) {
      word = '';
      return;
    }
    word = _deck.removeAt(0);
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
