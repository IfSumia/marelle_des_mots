import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One list of words: a numbered reading lesson ("Lecture 3") or the
/// "mots outils" list (which has no number).
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.words,
    this.number,
  });

  final String id;
  final String title;
  final List<String> words;

  /// Lesson number, e.g. 3 for "Lecture 3". Null for the tool-words list.
  final int? number;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        number: json['number'] as int?,
        words: (json['words'] as List).cast<String>(),
      );
}

/// All the word lists shipped with the app (assets/data/lessons.json).
///
/// To add a lesson, add one entry to that JSON file. Nothing else to touch.
class LessonLibrary {
  const LessonLibrary({required this.toolWords, required this.lessons});

  final Lesson toolWords;

  /// Numbered lessons, sorted by number.
  final List<Lesson> lessons;

  static Future<LessonLibrary> load() async {
    final raw = await rootBundle.loadString('assets/data/lessons.json');
    return LessonLibrary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory LessonLibrary.fromJson(Map<String, dynamic> json) {
    final lessons = (json['lessons'] as List)
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
    return LessonLibrary(
      toolWords: Lesson.fromJson(json['toolWords'] as Map<String, dynamic>),
      lessons: lessons,
    );
  }

  int get firstNumber => lessons.isEmpty ? 0 : lessons.first.number ?? 0;
  int get lastNumber => lessons.isEmpty ? 0 : lessons.last.number ?? 0;
}
