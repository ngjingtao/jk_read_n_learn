import 'app_language.dart';
import 'money.dart';

/// A slice of essay text.
///
/// Punctuation and whitespace are kept as [isWord] `false` tokens so the
/// passage still renders exactly as written, while only real words become
/// tappable and gradeable.
class EssayToken {
  const EssayToken({
    required this.display,
    required this.normalized,
    required this.isWord,
  });

  /// Non-gradeable run of text: spaces, punctuation, newlines.
  const EssayToken.filler(this.display)
      : normalized = '',
        isWord = false;

  /// Text as it appears on screen, e.g. `garden,`.
  final String display;

  /// Comparison form used by the grader, e.g. `garden`. Empty for filler.
  final String normalized;

  /// Whether this token is a gradeable word/character.
  final bool isWord;
}

/// How well a single target word was read.
enum WordStatus {
  /// Heard exactly as written.
  correct,

  /// Heard as written, but the recogniser was not confident.
  ///
  /// This is the honest third state. Text-based marking cannot tell a word the
  /// child read clearly from one the recogniser guessed at — modern recognisers
  /// auto-correct, so a child saying "fink" can come back as "think" and be
  /// awarded full marks. Rather than pretending either way, a low-confidence
  /// match is reported as unclear and the parent is told.
  unclear,

  /// Heard as a recognisably close variant — partial credit.
  mispronounced,

  /// Not heard at all, or heard as a different word entirely.
  missed,

  /// Heard even though there is no matching word in the essay.
  extra,
}

/// One row of the alignment between the essay and what the child actually said.
class AlignedWord {
  const AlignedWord({
    required this.index,
    required this.display,
    required this.status,
    required this.similarity,
    this.heard,
    this.confidence,
  });

  /// Position of the target token within [ScoreResult.alignment].
  final int index;

  /// The essay token this row grades. Empty string for [WordStatus.extra] rows.
  final String display;

  /// What the recogniser transcribed, when anything was heard.
  final String? heard;

  final WordStatus status;

  /// Similarity between [display] and [heard], in the range 0.0 – 1.0.
  final double similarity;

  /// The recogniser's confidence in this word, `0.0` – `1.0`, or `null` when
  /// the platform did not rate it. See [WordStatus.unclear].
  final double? confidence;

  bool get isGradeable => status != WordStatus.extra;
}

/// The full outcome of one read-aloud attempt.
class ScoreResult {
  const ScoreResult({
    required this.language,
    required this.totalWords,
    required this.correctWords,
    required this.mispronouncedWords,
    required this.missedWords,
    required this.extraWords,
    required this.points,
    required this.jkd,
    required this.alignment,
    required this.duration,
    required this.transcript,
    this.unclearWords = 0,
    this.strictConfidence = false,
    this.extras = const [],
  });

  final ReadingLanguage language;

  /// Number of gradeable tokens in the essay.
  final int totalWords;

  final int correctWords;
  final int mispronouncedWords;
  final int missedWords;
  final int extraWords;

  /// Words the recogniser heard as written but was not confident about.
  ///
  /// A subset of the words *credited* as correct, unless [strictConfidence] is
  /// on. Reported separately so the result screen can tell a parent that the
  /// microphone, not the child, is the likely problem.
  final int unclearWords;

  /// Whether low-confidence words were denied full marks.
  ///
  /// Off by default, because a bad microphone must never cost a child marks.
  /// Turning it on trades that safety for catching auto-corrected
  /// mispronunciations — see the confidence setting in the app.
  final bool strictConfidence;

  /// Raw score before conversion to currency.
  final int points;

  /// Reward paid out for this attempt.
  final Jkd jkd;

  /// Per-token feedback, in reading order, for colour-coded highlighting.
  ///
  /// One row per gradeable word in the essay, so `alignment[i]` always grades
  /// the i-th word the child was asked to read. Words the child added that have
  /// no place in the essay are reported separately in [extras].
  final List<AlignedWord> alignment;

  /// Words the child said that do not appear in the essay at all.
  final List<AlignedWord> extras;

  /// How long the child spent reading.
  final Duration duration;

  /// Exactly what the recogniser heard.
  final String transcript;

  /// Words credited as correct for marking purposes.
  ///
  /// In the default (non-strict) mode an unclear word still counts: the child
  /// may well have read it perfectly, and a poor microphone must not cost them
  /// marks. In strict mode it does not, which is the whole point of opting in.
  int get creditedWords =>
      strictConfidence ? correctWords : correctWords + unclearWords;

  /// Strict accuracy: correctly read words over total words, 0.0 – 1.0.
  ///
  /// Deliberately harsh — a word the child mangled does not count — because
  /// this is the number shown as "accuracy" and it should mean what it says.
  /// Unclear words count unless strict confidence marking is on.
  double get accuracy => totalWords == 0 ? 0 : creditedWords / totalWords;

  /// Accuracy with partial credit for near-misses, 0.0 – 1.0.
  double get lenientAccuracy => totalWords == 0
      ? 0
      : (creditedWords + mispronouncedWords * 0.5) / totalWords;

  /// Correctly read words per minute.
  double get wordsPerMinute {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) return 0;
    return creditedWords / (seconds / 60);
  }

  /// A short, encouraging label for the result screen.
  ///
  /// Returns an enum, not a string: the model has no business knowing which
  /// language the interface is in.
  ScoreGrade get grade {
    final a = lenientAccuracy;
    if (a >= 0.95) return ScoreGrade.outstanding;
    if (a >= 0.85) return ScoreGrade.great;
    if (a >= 0.7) return ScoreGrade.good;
    if (a >= 0.5) return ScoreGrade.keepPractising;
    return ScoreGrade.tryAgain;
  }
}

/// How well the attempt went overall, for the headline on the result screen.
enum ScoreGrade {
  outstanding,
  great,
  good,
  keepPractising,
  tryAgain,
}
