import '../data/lessons.dart';
import 'deck_settings.dart';

/// Splits pasted text into words (same rule as the HTML V1).
List<String> tokenize(String text) => text
    .split(RegExp(r'[\s,;\n]+'))
    .map((w) => w.trim())
    .where((w) => w.isNotEmpty)
    .toList();

/// Builds the pool of words the deck is dealt from.
///
/// Repeats *inside* a lesson are kept on purpose (they are part of the
/// reading exercise, as in V1). Across lessons, a word that an earlier
/// selected lesson already contains is not added again, so a cumulative
/// deck does not drown in "le", "il" and "a". Comparison is exact:
/// "Il" and "il" are different words.
List<String> buildPool(LessonLibrary library, DeckSettings settings) {
  final pool = <String>[];
  final seenInEarlierLessons = <String>{};

  for (final lesson in settings.selectedLessons(library)) {
    final fresh = <String>[];
    for (final w in lesson.words) {
      if (!seenInEarlierLessons.contains(w)) fresh.add(w);
    }
    pool.addAll(fresh);
    seenInEarlierLessons.addAll(lesson.words);
  }

  if (settings.toolWords) {
    for (final w in library.toolWords.words) {
      if (!seenInEarlierLessons.contains(w)) pool.add(w);
    }
  }

  if (settings.customWords) {
    pool.addAll(tokenize(settings.customText));
  }

  // Never leave the child with an empty deck.
  if (pool.isEmpty) return List.of(library.toolWords.words);
  return pool;
}
