import 'dart:convert';

import '../data/lessons.dart';

/// Which words go into the deck. Saved on the phone between sessions.
class DeckSettings {
  const DeckSettings({
    this.cumulative = true,
    this.upTo = 3,
    this.picked = const {},
    this.toolWords = false,
    this.customWords = false,
    this.customText = '',
  });

  /// true: "everything up to lesson [upTo]". false: only the [picked] lessons.
  final bool cumulative;
  final int upTo;
  final Set<int> picked;
  final bool toolWords;
  final bool customWords;
  final String customText;

  DeckSettings copyWith({
    bool? cumulative,
    int? upTo,
    Set<int>? picked,
    bool? toolWords,
    bool? customWords,
    String? customText,
  }) =>
      DeckSettings(
        cumulative: cumulative ?? this.cumulative,
        upTo: upTo ?? this.upTo,
        picked: picked ?? this.picked,
        toolWords: toolWords ?? this.toolWords,
        customWords: customWords ?? this.customWords,
        customText: customText ?? this.customText,
      );

  /// The lessons these settings select, in lesson order.
  List<Lesson> selectedLessons(LessonLibrary library) => library.lessons
      .where((l) => cumulative ? (l.number ?? 0) <= upTo : picked.contains(l.number))
      .toList();

  String toJson() => jsonEncode({
        'cumulative': cumulative,
        'upTo': upTo,
        'picked': picked.toList()..sort(),
        'toolWords': toolWords,
        'customWords': customWords,
        'customText': customText,
      });

  factory DeckSettings.fromJson(String source) {
    try {
      final m = jsonDecode(source) as Map<String, dynamic>;
      return DeckSettings(
        cumulative: m['cumulative'] as bool? ?? true,
        upTo: m['upTo'] as int? ?? 3,
        picked: ((m['picked'] as List?) ?? const []).cast<int>().toSet(),
        toolWords: m['toolWords'] as bool? ?? false,
        customWords: m['customWords'] as bool? ?? false,
        customText: m['customText'] as String? ?? '',
      );
    } catch (_) {
      return const DeckSettings();
    }
  }
}
