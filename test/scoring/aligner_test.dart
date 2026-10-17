import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/services/scoring/aligner.dart';

void main() {
  const aligner = ReadingAligner();

  group('ReadingAligner', () {
    test('matches a perfect reading word for word', () {
      final ops = aligner.align(['the', 'cat', 'sat'], ['the', 'cat', 'sat']);

      expect(ops, hasLength(3));
      expect(ops.every((op) => op.type == AlignmentOpType.match), isTrue);
    });

    test('treats a skipped word as a deletion and keeps the rest aligned', () {
      final ops = aligner.align(['the', 'cat', 'sat'], ['the', 'sat']);

      expect(ops.map((op) => op.type), [
        AlignmentOpType.match,
        AlignmentOpType.delete,
        AlignmentOpType.match,
      ]);
      expect(ops[1].targetIndex, 1, reason: 'the skipped word is "cat"');
    });

    test('treats an added word as an insertion', () {
      final ops = aligner.align(['the', 'cat'], ['the', 'big', 'cat']);

      expect(ops.map((op) => op.type), [
        AlignmentOpType.match,
        AlignmentOpType.insert,
        AlignmentOpType.match,
      ]);
      expect(ops[1].spokenIndex, 1, reason: 'the added word is "big"');
    });

    test('treats a garbled word as a substitution carrying its similarity', () {
      final ops = aligner.align(['garden'], ['gardan']);

      expect(ops, hasLength(1));
      expect(ops.single.type, AlignmentOpType.substitute);
      expect(ops.single.similarity, closeTo(0.833, 0.01));
    });

    test('handles a completely wrong reading without losing alignment', () {
      final ops = aligner.align(
        ['the', 'cat', 'sat'],
        ['a', 'dog', 'stood'],
      );

      expect(ops, hasLength(3));
      expect(ops.every((op) => op.type == AlignmentOpType.substitute), isTrue);
      // Every target word must be consumed exactly once, in order.
      expect(ops.map((op) => op.targetIndex), [0, 1, 2]);
    });

    test('handles an empty transcript by deleting everything', () {
      final ops = aligner.align(['the', 'cat'], const []);

      expect(ops.map((op) => op.type),
          [AlignmentOpType.delete, AlignmentOpType.delete]);
    });

    test('handles an empty essay by inserting everything', () {
      final ops = aligner.align(const [], ['hello', 'there']);

      expect(ops.map((op) => op.type),
          [AlignmentOpType.insert, AlignmentOpType.insert]);
    });

    test('resolves repeated words to a stable, optimal alignment', () {
      final ops = aligner.align(['go', 'go', 'go'], ['go', 'go']);

      // Three ways to score this are equally optimal. The traceback walks
      // backwards and prefers the diagonal, so it pairs the spoken words with
      // the *last* two target words and reports a single miss. Which of three
      // identical words counts as missed is genuinely arbitrary; what matters
      // is that exactly one is missed and the total is right.
      expect(ops.map((op) => op.type), [
        AlignmentOpType.delete,
        AlignmentOpType.match,
        AlignmentOpType.match,
      ]);
    });
  });
}
