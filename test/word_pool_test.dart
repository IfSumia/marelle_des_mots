import 'package:flutter_test/flutter_test.dart';
import 'package:marelle_des_mots/data/lessons.dart';
import 'package:marelle_des_mots/logic/deck_settings.dart';
import 'package:marelle_des_mots/logic/word_pool.dart';

const _library = LessonLibrary(
  toolWords: Lesson(id: 'default', title: 'Mots outils', words: ['le', 'la', 'et']),
  lessons: [
    Lesson(id: 'lecture3', number: 3, title: 'Lecture 3', words: ['la', 'li', 'li', 'Il']),
    Lesson(id: 'lecture4', number: 4, title: 'Lecture 4', words: ['ra', 'li', 'il']),
    Lesson(id: 'lecture5', number: 5, title: 'Lecture 5', words: ['ru']),
  ],
);

void main() {
  test('cumulative: every lesson up to N, repeats inside a lesson kept', () {
    final pool = buildPool(_library, const DeckSettings(cumulative: true, upTo: 3));
    expect(pool, ['la', 'li', 'li', 'Il']);
  });

  test('cumulative: a word already in an earlier lesson is not added again', () {
    final pool = buildPool(_library, const DeckSettings(cumulative: true, upTo: 4));
    // "li" is dropped from lecture 4; "il" differs from "Il" so it stays
    expect(pool, ['la', 'li', 'li', 'Il', 'ra', 'il']);
  });

  test('not cumulative: only the ticked lessons, in lesson order', () {
    final pool = buildPool(
      _library,
      const DeckSettings(cumulative: false, picked: {5, 3}),
    );
    expect(pool, ['la', 'li', 'li', 'Il', 'ru']);
  });

  test('tool words are added without duplicating words already present', () {
    final pool = buildPool(_library, const DeckSettings(upTo: 3, toolWords: true));
    expect(pool, ['la', 'li', 'li', 'Il', 'le', 'et']);
  });

  test('custom words are split on spaces, commas, semicolons and new lines', () {
    expect(tokenize('a, b  c;d\ne'), ['a', 'b', 'c', 'd', 'e']);
    final pool = buildPool(
      _library,
      const DeckSettings(cumulative: false, customWords: true, customText: 'chat chien'),
    );
    expect(pool, ['chat', 'chien']);
  });

  test('an empty selection falls back to the tool words', () {
    final pool = buildPool(_library, const DeckSettings(cumulative: false));
    expect(pool, ['le', 'la', 'et']);
  });

  test('settings survive a JSON round trip', () {
    const original = DeckSettings(
      cumulative: false,
      upTo: 7,
      picked: {3, 9},
      toolWords: true,
      customWords: true,
      customText: 'papa maman',
    );
    final copy = DeckSettings.fromJson(original.toJson());
    expect(copy.cumulative, false);
    expect(copy.upTo, 7);
    expect(copy.picked, {3, 9});
    expect(copy.toolWords, true);
    expect(copy.customWords, true);
    expect(copy.customText, 'papa maman');
  });
}
