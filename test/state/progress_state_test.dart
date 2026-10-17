import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/models/essay.dart';
import 'package:jkreadnlearn/models/scoring_models.dart';
import 'package:jkreadnlearn/services/scoring/reading_scorer.dart';
import 'package:jkreadnlearn/state/progress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _essay = Essay(
  id: 'test-en',
  title: 'Test',
  language: ReadingLanguage.english,
  gradeLevel: 1,
  text: 'The cat sat on the mat.',
);

/// A real score, produced by the real scorer, so these tests exercise the same
/// numbers the app does.
ScoreResult _score(String transcript) => const ReadingScorer().score(
      essay: _essay,
      transcript: transcript,
      duration: const Duration(seconds: 10),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('per-passage progress', () {
    test('a first attempt is recorded but is not a record', () async {
      final progress = ProgressState();

      final isRecord = await progress.recordSession(
        essay: _essay,
        result: _score('The cat sat on the mat'),
      );

      // Improving on nothing is not an achievement. Claiming otherwise would
      // make the celebration meaningless the first time a child reads anything.
      expect(isRecord, isFalse);

      final record = progress.progressFor(_essay.id)!;
      expect(record.attempts, 1);
      expect(record.bestAccuracy, 1.0);
    });

    test('beating the previous best is a record', () async {
      final progress = ProgressState();

      await progress.recordSession(essay: _essay, result: _score('The cat'));
      final isRecord = await progress.recordSession(
        essay: _essay,
        result: _score('The cat sat on the mat'),
      );

      expect(isRecord, isTrue);
      expect(progress.progressFor(_essay.id)!.bestAccuracy, 1.0);
      expect(progress.progressFor(_essay.id)!.attempts, 2);
    });

    test('a worse attempt does not lower the best', () async {
      final progress = ProgressState();

      await progress.recordSession(
        essay: _essay,
        result: _score('The cat sat on the mat'),
      );
      final isRecord =
          await progress.recordSession(essay: _essay, result: _score('The cat'));

      expect(isRecord, isFalse);
      final record = progress.progressFor(_essay.id)!;
      expect(record.bestAccuracy, 1.0, reason: 'best must not regress');
      expect(record.attempts, 2);
    });

    test('progress survives a restart', () async {
      final progress = ProgressState();
      await progress.recordSession(
        essay: _essay,
        result: _score('The cat sat on the mat'),
      );

      final reloaded = ProgressState();
      await reloaded.load();

      expect(reloaded.progressFor(_essay.id)!.attempts, 1);
      expect(reloaded.progressFor(_essay.id)!.bestAccuracy, 1.0);
    });
  });

  group('reading streaks', () {
    late DateTime now;
    late ProgressState progress;

    setUp(() {
      now = DateTime(2026, 10, 17, 10);
      progress = ProgressState(null, () => now);
    });

    Future<void> readOn(DateTime day) async {
      now = DateTime(day.year, day.month, day.day, 10);
      await progress.recordSession(essay: _essay, result: _score('The cat sat'));
    }

    test('is zero before anything has been read', () {
      expect(progress.currentStreak, 0);
      expect(progress.longestStreak, 0);
    });

    test('starts at one after reading today', () async {
      await readOn(now);
      expect(progress.currentStreak, 1);
    });

    test('counts consecutive days', () async {
      await readOn(DateTime(2026, 10, 15));
      await readOn(DateTime(2026, 10, 16));
      await readOn(DateTime(2026, 10, 17));

      expect(progress.currentStreak, 3);
      expect(progress.longestStreak, 3);
    });

    test('stays alive if the child has not read yet today', () async {
      // Being asleep at midnight should not wipe out a run.
      await readOn(DateTime(2026, 10, 15));
      await readOn(DateTime(2026, 10, 16));
      now = DateTime(2026, 10, 17, 23, 59);

      expect(progress.currentStreak, 2);
    });

    test('breaks after a full day with nothing read', () async {
      await readOn(DateTime(2026, 10, 14));
      await readOn(DateTime(2026, 10, 15));
      now = DateTime(2026, 10, 17, 10);

      expect(progress.currentStreak, 0);
      expect(progress.longestStreak, 2);
    });

    test('remembers the longest run even after the current one breaks',
        () async {
      await readOn(DateTime(2026, 10, 1));
      await readOn(DateTime(2026, 10, 2));
      await readOn(DateTime(2026, 10, 3));
      await readOn(DateTime(2026, 10, 4));
      // Gap.
      await readOn(DateTime(2026, 10, 16));
      now = DateTime(2026, 10, 16, 10);

      expect(progress.currentStreak, 1);
      expect(progress.longestStreak, 4);
    });

    test('counts a month boundary as consecutive', () async {
      await readOn(DateTime(2026, 9, 30));
      await readOn(DateTime(2026, 10, 1));

      now = DateTime(2026, 10, 1, 10);
      expect(progress.currentStreak, 2);
    });

    test('multiple reads in one day count as a single streaking day', () async {
      await readOn(DateTime(2026, 10, 16));
      await progress.recordSession(essay: _essay, result: _score('The cat sat'));
      await progress.recordSession(essay: _essay, result: _score('The cat sat'));
      now = DateTime(2026, 10, 16, 20);

      expect(progress.currentStreak, 1);
      expect(progress.sessionsToday, 3);
    });
  });

  group('reward collection', () {
    test('owns nothing to begin with', () {
      expect(ProgressState().owns('star'), isFalse);
      expect(ProgressState().ownedRewards, isEmpty);
    });

    test('adding a reward is idempotent', () async {
      final progress = ProgressState();

      expect(await progress.addOwnedReward('star'), isTrue);
      expect(await progress.addOwnedReward('star'), isFalse);
      expect(progress.owns('star'), isTrue);
      expect(progress.ownedRewards, ['star']);
    });

    test('the collection survives a restart', () async {
      final progress = ProgressState();
      await progress.addOwnedReward('panda');

      final reloaded = ProgressState();
      await reloaded.load();

      expect(reloaded.owns('panda'), isTrue);
    });

    test('reset clears everything', () async {
      final progress = ProgressState();
      await progress.recordSession(essay: _essay, result: _score('The cat sat'));
      await progress.addOwnedReward('star');

      await progress.reset();

      expect(progress.ownedRewards, isEmpty);
      expect(progress.progressFor(_essay.id), isNull);
      expect(progress.currentStreak, 0);
      expect(progress.totalReadingDays, 0);
    });
  });
}
