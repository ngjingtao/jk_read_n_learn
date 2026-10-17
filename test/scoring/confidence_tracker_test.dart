import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/services/scoring/confidence_tracker.dart';
import 'package:jkreadnlearn/services/scoring/text_utils.dart';

void main() {
  ConfidenceTracker english() =>
      ConfidenceTracker(mode: ReadingLanguage.english.tokenMode);

  group('when the platform does not rate its output', () {
    test('reports no usable confidence at all', () {
      final tracker = english();

      tracker.add('the cat sat', null);

      expect(tracker.hasAnyConfidence, isFalse);
      expect(tracker.confidenceAt(0), isNull);
      expect(tracker.confidenceAt(1), isNull);
    });

    test('treats -1 as absent rather than as very unsure', () {
      // `speech_to_text` uses -1 for "not available". Reading that as a real
      // score would mark every word of a perfectly good reading as unclear.
      final tracker = english();

      tracker.add('the cat sat', -1);

      expect(tracker.hasAnyConfidence, isFalse);
      expect(tracker.confidenceAt(0), isNull);
    });

    test('treats out-of-range values as absent, not as clamped', () {
      final tracker = english();

      tracker.add('the cat sat', 7);

      expect(tracker.hasAnyConfidence, isFalse);
    });
  });

  group('assigning confidence to words', () {
    test('gives each newly appeared word the confidence of that update', () {
      final tracker = english();

      tracker.add('the', 0.95);
      tracker.add('the cat', 0.4);
      tracker.add('the cat sat', 0.9);

      expect(tracker.length, 3);
      expect(tracker.confidenceAt(0), 0.95);
      expect(tracker.confidenceAt(1), 0.4);
      expect(tracker.confidenceAt(2), 0.9);
    });

    test('re-scores from the point of divergence when a word is revised', () {
      final tracker = english();

      tracker.add('the cat sat', 0.9);
      // The recogniser changes its mind about the middle word.
      tracker.add('the cot sat', 0.3);

      expect(tracker.length, 3);
      expect(tracker.confidenceAt(0), 0.9, reason: 'unchanged prefix keeps its score');
      expect(tracker.confidenceAt(1), 0.3);
      expect(tracker.confidenceAt(2), 0.3);
    });

    test('drops words when the transcript gets shorter', () {
      final tracker = english();

      tracker.add('the cat sat', 0.9);
      tracker.add('the cat', 0.9);

      expect(tracker.length, 2);
    });

    test('stays aligned with the scorer\'s own tokenisation', () {
      // If the tracker and the scorer disagreed on word boundaries, every
      // confidence would be attached to the wrong word. Both go through
      // normalizeWords, and this pins that.
      const transcript = "I don't like well-known songs.";
      final tracker = english();

      tracker.add(transcript, 0.5);

      expect(
        tracker.length,
        normalizeWords(transcript, ReadingLanguage.english.tokenMode).length,
      );
    });

    test('grades Chinese one character at a time', () {
      final tracker =
          ConfidenceTracker(mode: ReadingLanguage.chinese.tokenMode);

      tracker.add('我爱学校', 0.4);

      expect(tracker.length, 4);
    });

    test('returns null for an index that was never seen', () {
      final tracker = english();
      tracker.add('the', 0.9);

      expect(tracker.confidenceAt(5), isNull);
      expect(tracker.confidenceAt(-1), isNull);
    });
  });
}
