import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:marelle_des_mots/data/lessons.dart';
import 'package:marelle_des_mots/logic/game_controller.dart';
import 'package:marelle_des_mots/services/sfx.dart';
import 'package:marelle_des_mots/services/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _library = LessonLibrary(
  toolWords: Lesson(id: 'default', title: 'Mots outils', words: ['le']),
  lessons: [
    Lesson(id: 'lecture3', number: 3, title: 'Lecture 3', words: ['a', 'b', 'c', 'd', 'e', 'f']),
  ],
);

Future<GameController> _newGame() async {
  SharedPreferences.setMockInitialValues({});
  final store = await Store.open();
  return GameController(
    library: _library,
    store: store,
    sfx: SilentSfx(),
    random: Random(7),
  )..init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('known() adds to the score, the streak and the trail', () async {
    final game = await _newGame();
    game.known();
    game.known();
    expect(game.score, 2);
    expect(game.streak, 2);
    expect(game.roundProgress, 2);
    expect(game.best, 2);
  });

  test('again() resets the streak, keeps the trail, and brings the word back', () async {
    final game = await _newGame();
    game.known();
    final seen = game.word;
    game.again();
    expect(game.streak, 0);
    expect(game.roundProgress, 1);
    expect(game.score, 1);
    expect(game.upcoming, contains(seen));
  });

  test('the round completes after ten known words, then continues', () async {
    final game = await _newGame();
    for (var i = 0; i < GameController.casesPerRound; i++) {
      game.known();
    }
    expect(game.roundComplete, isTrue);
    game.known(); // ignored while the celebration is showing
    expect(game.score, GameController.casesPerRound);
    game.continueRound();
    expect(game.roundComplete, isFalse);
    expect(game.roundProgress, 0);
  });

  test('events are sent to the mascot', () async {
    final game = await _newGame();
    final types = <GameEventType>[];
    final sub = game.events.listen((e) => types.add(e.type));
    game.known();
    game.again();
    await Future<void>.delayed(Duration.zero);
    expect(types, [GameEventType.known, GameEventType.again]);
    await sub.cancel();
  });

  test('the best streak is saved', () async {
    final game = await _newGame();
    game.known();
    game.known();
    game.known();
    expect(game.store.best, 3);
  });
}
