import 'dart:math' as math;

import 'token_comparator.dart';

/// The kind of step taken when walking the essay and the transcript together.
enum AlignmentOpType { match, substitute, delete, insert }

/// One step of the alignment.
class AlignmentOp {
  const AlignmentOp({
    required this.type,
    this.targetIndex,
    this.spokenIndex,
    this.similarity = 0,
  });

  final AlignmentOpType type;

  /// Index into the essay's normalised word list, when the step consumes one.
  final int? targetIndex;

  /// Index into the recogniser's normalised word list, when the step consumes
  /// one.
  final int? spokenIndex;

  /// Character-level similarity for [AlignmentOpType.match] and
  /// [AlignmentOpType.substitute] steps.
  final double similarity;
}

/// Aligns the words a child was *supposed* to read against the words a
/// recogniser *heard*, producing per-word feedback.
///
/// This is a Needleman–Wunsch sequence alignment: the classic biological
/// technique for lining up two sequences where items can match, differ, be
/// skipped, or be inserted. It maps onto reading assessment almost perfectly —
/// a skipped word is a deletion, an added word is an insertion, and a garbled
/// word is a substitution whose cost scales with how garbled it was.
///
/// Using a smooth similarity cost (rather than a hard correct/incorrect flag)
/// means "gardan" for "garden" is a cheaper mistake than "elephant" for
/// "garden", so the alignment still finds the sensible pairing.
class ReadingAligner {
  const ReadingAligner({this.comparator = const OrthographicComparator()});

  /// Decides how close two words are. Chosen by the caller from the language of
  /// the passage, so English is compared by sound and Chinese by character.
  final TokenComparator comparator;

  /// Cost of skipping one item, or of hearing one extra item.
  static const double _gapCost = 1.0;

  /// Aligns [target] (the essay) against [spoken] (the transcript).
  ///
  /// Both inputs must already be normalised via `normalizeWords`.
  List<AlignmentOp> align(List<String> target, List<String> spoken) {
    final n = target.length;
    final m = spoken.length;

    // cost[i][j] = best cost of aligning the first i target words with the
    // first j spoken words.
    final cost = List<List<double>>.generate(
      n + 1,
      (_) => List<double>.filled(m + 1, 0),
    );
    for (var i = 1; i <= n; i++) {
      cost[i][0] = i * _gapCost;
    }
    for (var j = 1; j <= m; j++) {
      cost[0][j] = j * _gapCost;
    }

    for (var i = 1; i <= n; i++) {
      final targetWord = target[i - 1];
      for (var j = 1; j <= m; j++) {
        final substitution =
            cost[i - 1][j - 1] + (_gapCost - comparator.similarity(targetWord, spoken[j - 1]));
        final deletion = cost[i - 1][j] + _gapCost;
        final insertion = cost[i][j - 1] + _gapCost;
        cost[i][j] = math.min(substitution, math.min(deletion, insertion));
      }
    }

    // Walk back from the bottom-right corner, recording which step got us here.
    final ops = <AlignmentOp>[];
    var i = n;
    var j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final sim = comparator.similarity(target[i - 1], spoken[j - 1]);
        if (_closeEnough(cost[i][j], cost[i - 1][j - 1] + (_gapCost - sim))) {
          ops.add(
            AlignmentOp(
              type: sim >= 1.0
                  ? AlignmentOpType.match
                  : AlignmentOpType.substitute,
              targetIndex: i - 1,
              spokenIndex: j - 1,
              similarity: sim,
            ),
          );
          i--;
          j--;
          continue;
        }
      }

      if (i > 0 && _closeEnough(cost[i][j], cost[i - 1][j] + _gapCost)) {
        ops.add(
          AlignmentOp(type: AlignmentOpType.delete, targetIndex: i - 1),
        );
        i--;
        continue;
      }

      ops.add(AlignmentOp(type: AlignmentOpType.insert, spokenIndex: j - 1));
      j--;
    }

    return List.unmodifiable(ops.reversed);
  }

  static bool _closeEnough(double a, double b) => (a - b).abs() < 1e-9;
}
