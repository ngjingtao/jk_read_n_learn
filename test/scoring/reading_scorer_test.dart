import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/core/app_config.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/models/essay.dart';
import 'package:jkreadnlearn/models/money.dart';
import 'package:jkreadnlearn/models/scoring_models.dart';
import 'package:jkreadnlearn/services/scoring/reading_scorer.dart';

/// Short passages keep the expected numbers readable inside the tests.
const _englishEssay = Essay(
  id: 'test-en',
  title: 'Test',
  language: ReadingLanguage.english,
  gradeLevel: 1,
  text: 'The cat sat.',
);

const _chineseEssay = Essay(
  id: 'test-zh',
  title: '测试',
  language: ReadingLanguage.chinese,
  gradeLevel: 1,
  text: '我爱学校',
);

void main() {
  const scorer = ReadingScorer();

  ScoreResult score(String text, String transcript, {int seconds = 10}) {
    return scorer.score(
      essay: text == 'zh' ? _chineseEssay : _englishEssay,
      transcript: transcript,
      duration: Duration(seconds: seconds),
    );
  }

  group('perfect reading', () {
    final result = score('en', 'The cat sat');

    test('marks every word correct', () {
      expect(result.totalWords, 3);
      expect(result.correctWords, 3);
      expect(result.missedWords, 0);
      expect(result.accuracy, 1.0);
    });

    test('pays points plus the completion bonus', () {
      // 3 correct * 10 points + 25 completion bonus
      expect(result.points, 55);
    });

    test('converts points to JKD at the configured rate', () {
      expect(result.jkd, const Jkd(55));
      expect(result.jkd.label, '0.55 JKD');
    });

    test('reports a top grade', () {
      expect(result.grade, ScoreGrade.outstanding);
    });
  });

  group('word level feedback', () {
    test('flags only the skipped word as missed', () {
      final result = score('en', 'The sat');

      expect(result.alignment.map((w) => w.status), [
        WordStatus.correct,
        WordStatus.missed,
        WordStatus.correct,
      ]);
      expect(result.alignment[1].display, 'cat');
      expect(result.missedWords, 1);
    });

    test('gives partial credit for a near miss', () {
      const essay = Essay(
        id: 'test-garden',
        title: 'Garden',
        language: ReadingLanguage.english,
        gradeLevel: 1,
        text: 'garden',
      );
      final result = scorer.score(
        essay: essay,
        transcript: 'gardan',
        duration: const Duration(seconds: 2),
      );

      expect(result.alignment.single.status, WordStatus.mispronounced);
      expect(result.alignment.single.heard, 'gardan');
      // Partial credit only: no completion bonus below the accuracy floor.
      expect(result.points, 3);
      expect(result.accuracy, 0.0);
      expect(result.lenientAccuracy, 0.5);
    });

    test('treats a wholly different word as missed, not mispronounced', () {
      final result = score('en', 'The elephant sat');

      expect(result.alignment[1].status, WordStatus.missed);
      expect(result.alignment[1].heard, 'elephant');
    });

    test('collects words the child added into extras', () {
      final result = score('en', 'The very small cat sat');

      expect(result.extraWords, 2);
      expect(result.extras.map((w) => w.heard), ['very', 'small']);
      expect(result.correctWords, 3, reason: 'extras must not inflate marks');
      expect(result.alignment.every((w) => w.status == WordStatus.correct),
          isTrue);
    });

    test('returns one alignment row per essay word, in order', () {
      final result = score('en', 'The cat sat');

      expect(result.alignment.map((w) => w.index), [0, 1, 2]);
      expect(result.alignment.map((w) => w.display), ['The', 'cat', 'sat']);
    });
  });

  group('nothing heard', () {
    test('scores zero and pays nothing', () {
      final result = score('en', '');

      expect(result.accuracy, 0.0);
      expect(result.points, 0);
      expect(result.jkd, Jkd.zero);
      expect(result.grade, ScoreGrade.tryAgain);
    });
  });

  group('Chinese is graded per character', () {
    final result = score('zh', '我爱学校');

    test('counts each Han character as a word', () {
      expect(result.totalWords, 4);
      expect(result.correctWords, 4);
      expect(result.accuracy, 1.0);
    });

    test('still highlights a single wrong character', () {
      final partial = score('zh', '我爱学');

      expect(partial.alignment.map((w) => w.status), [
        WordStatus.correct,
        WordStatus.correct,
        WordStatus.correct,
        WordStatus.missed,
      ]);
      expect(partial.accuracy, 0.75);
    });
  });

  group('fluency', () {
    test('derives words per minute from correct words and duration', () {
      final result = score('en', 'The cat sat', seconds: 6);

      // 3 correct words in 6 seconds == 30 words per minute.
      expect(result.wordsPerMinute, closeTo(30, 0.01));
    });

    test('does not divide by zero on an instantaneous result', () {
      final result = score('en', 'The cat sat', seconds: 0);

      expect(result.wordsPerMinute, 0);
    });
  });

  group('reward rate', () {
    test('respects a custom exchange rate', () {
      const generous = ReadingScorer(
        config: ScoringConfig(jkdPerPoint: 0.1),
      );
      final result = generous.score(
        essay: _englishEssay,
        transcript: 'The cat sat',
        duration: const Duration(seconds: 10),
      );

      // 55 points at 0.1 JKD per point = 5.50 JKD.
      expect(result.jkd, const Jkd(550));
    });
  });
}
