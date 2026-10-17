import 'app_language.dart';

/// A passage the child can read aloud.
///
/// Essays are plain data so a teacher or curriculum author can add more
/// without touching app code — see `lib/data/sample_essays.dart`. A later
/// version can load these from a backend or bundled JSON.
class Essay {
  const Essay({
    required this.id,
    required this.title,
    required this.language,
    required this.text,
    required this.gradeLevel,
    this.author,
  });

  /// Stable identifier, used for progress and history records.
  final String id;

  final String title;
  final ReadingLanguage language;

  /// The full passage exactly as it should appear and be read.
  final String text;

  /// Rough grade/standard the passage suits, e.g. `2` for Standard 2.
  final int gradeLevel;

  final String? author;
}
