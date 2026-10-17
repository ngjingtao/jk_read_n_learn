import '../../core/app_config.dart';
import '../../models/essay.dart';
import '../../models/money.dart';
import '../../models/scoring_models.dart';
import 'aligner.dart';
import 'text_utils.dart';
import 'token_comparator.dart';

/// Turns "what the child was asked to read" plus "what the machine heard" into
/// marks, per-word feedback, and a JKD reward.
///
/// The whole class is pure: same inputs, same output, no I/O, no platform
/// calls. That is deliberate — grading rules are the part of this app most
/// likely to be argued about by parents and teachers, so they are unit-tested
/// rather than trusted.
class ReadingScorer {
  const ReadingScorer({this.config = ScoringConfig.standard});

  final ScoringConfig config;

  /// Grades one read-aloud attempt at [essay].
  ///
  /// [transcript] is the recogniser output, [duration] is how long the child
  /// read for. Both feed the mark, so a slow, accurate reader and a fast, sloppy
  /// one end up with different results.
  ScoreResult score({
    required Essay essay,
    required String transcript,
    required Duration duration,
  }) {
    final mode = essay.language.tokenMode;

    // Compare by sound for English, by spelling for Chinese and Malay. See
    // `token_comparator.dart`.
    final aligner = ReadingAligner(comparator: comparatorFor(essay.language));

    final targetWordTokens =
        tokenize(essay.text, mode).where((t) => t.isWord).toList(growable: false);
    final spokenWordTokens =
        tokenize(transcript, mode).where((t) => t.isWord).toList(growable: false);

    final ops = aligner.align(
      tokensToWords(targetWordTokens),
      tokensToWords(spokenWordTokens),
    );

    final rows = List<AlignedWord?>.filled(targetWordTokens.length, null);
    final extras = <AlignedWord>[];

    for (final op in ops) {
      switch (op.type) {
        case AlignmentOpType.match:
          rows[op.targetIndex!] = AlignedWord(
            index: op.targetIndex!,
            display: targetWordTokens[op.targetIndex!].display,
            heard: spokenWordTokens[op.spokenIndex!].display,
            status: WordStatus.correct,
            similarity: 1,
          );
        case AlignmentOpType.substitute:
          // Close enough to be an attempt at the word; far enough to lose the
          // full mark. Below the floor, the child plainly said something else.
          final isAttempt = op.similarity >= config.mispronouncedSimilarityFloor;
          rows[op.targetIndex!] = AlignedWord(
            index: op.targetIndex!,
            display: targetWordTokens[op.targetIndex!].display,
            heard: spokenWordTokens[op.spokenIndex!].display,
            status: isAttempt ? WordStatus.mispronounced : WordStatus.missed,
            similarity: op.similarity,
          );
        case AlignmentOpType.delete:
          rows[op.targetIndex!] = AlignedWord(
            index: op.targetIndex!,
            display: targetWordTokens[op.targetIndex!].display,
            status: WordStatus.missed,
            similarity: 0,
          );
        case AlignmentOpType.insert:
          extras.add(
            AlignedWord(
              index: extras.length,
              display: spokenWordTokens[op.spokenIndex!].display,
              heard: spokenWordTokens[op.spokenIndex!].display,
              status: WordStatus.extra,
              similarity: 0,
            ),
          );
      }
    }

    final alignment = <AlignedWord>[
      for (var i = 0; i < rows.length; i++)
        rows[i] ??
            AlignedWord(
              index: i,
              display: targetWordTokens[i].display,
              status: WordStatus.missed,
              similarity: 0,
            ),
    ];

    final correct = alignment.where((w) => w.status == WordStatus.correct).length;
    final mispronounced =
        alignment.where((w) => w.status == WordStatus.mispronounced).length;
    final missed = alignment.where((w) => w.status == WordStatus.missed).length;
    final total = alignment.length;

    final lenient = total == 0
        ? 0.0
        : (correct + mispronounced * 0.5) / total;

    var points = correct * config.pointsPerCorrectWord +
        mispronounced * config.pointsPerMispronouncedWord;
    if (lenient >= config.completionBonusMinAccuracy) {
      points += config.completionBonus;
    }

    return ScoreResult(
      language: essay.language,
      totalWords: total,
      correctWords: correct,
      mispronouncedWords: mispronounced,
      missedWords: missed,
      extraWords: extras.length,
      points: points,
      jkd: Jkd.fromPoints(points, jkdPerPoint: config.jkdPerPoint),
      alignment: List.unmodifiable(alignment),
      extras: List.unmodifiable(extras),
      duration: duration,
      transcript: transcript,
    );
  }
}
