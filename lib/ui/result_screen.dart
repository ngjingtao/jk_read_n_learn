import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/essay.dart';
import '../models/scoring_models.dart';
import '../services/tts_service.dart';
import '../state/progress_state.dart';
import '../state/settings_state.dart';
import 'l10n_extensions.dart';
import 'widgets/essay_text.dart';

/// Marks for one attempt, with the passage colour-coded word by word.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.essay,
    required this.result,
    this.isNewRecord = false,
  });

  final Essay essay;
  final ScoreResult result;

  /// Whether the attempt beat the child's previous best on this passage.
  final bool isNewRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tts = context.read<Speaker>();
    final settings = context.watch<SettingsState>();
    final progress = context.watch<ProgressState>().progressFor(essay.id);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SummaryCard(result: result, isNewRecord: isNewRecord),
          const SizedBox(height: 16),
          _RewardCard(result: result),
          if (progress != null) ...[
            const SizedBox(height: 16),
            _ProgressCard(progress: progress, streak: context.watch<ProgressState>().currentStreak),
          ],
          const SizedBox(height: 16),
          _BreakdownCard(result: result),
          const SizedBox(height: 20),
          Text(
            l10n.resultHowYouReadIt,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.resultColourLegend,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: EssayText(
                text: essay.text,
                language: essay.language,
                lineHeight: settings.lineSpacing.height,
                statuses: [for (final word in result.alignment) word.status],
                onWordTap: (word) => tts.speakWord(word, essay.language),
              ),
            ),
          ),
          if (result.extras.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ExtrasCard(result: result),
          ],
          if (result.unclearWords > 0) ...[
            const SizedBox(height: 16),
            _UnclearCard(result: result),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.actionReadAgain),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.actionBackToList),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.isNewRecord});

  final ScoreResult result;
  final bool isNewRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final percent = (result.accuracy * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          value: result.accuracy,
                          strokeWidth: 9,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n.resultAccurate,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gradeLabel(result.grade),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.resultSummary(
                          result.correctWords,
                          result.totalWords,
                          result.duration.inSeconds,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.resultWordsPerMinute(result.wordsPerMinute.round()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isNewRecord) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.progressNewRecord,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7A5B00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Long-term progress for this passage, plus the current streak.
///
/// Shown next to the reward on purpose: a child who scored badly still sees that
/// they are on a run of days, which is the thing that keeps them coming back.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.streak});

  final EssayProgress progress;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            _ProgressRow(
              icon: Icons.repeat,
              label: l10n.progressAttempts(progress.attempts),
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              icon: Icons.emoji_events_outlined,
              label: l10n.progressBestAccuracy(
                (progress.bestAccuracy * 100).round(),
              ),
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              icon: Icons.speed,
              label: l10n.progressBestSpeed(progress.bestWordsPerMinute.round()),
            ),
            if (streak > 0) ...[
              const Divider(height: 24),
              _ProgressRow(
                icon: Icons.local_fire_department_outlined,
                label: l10n.streakDays(streak),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.result});

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(
              Icons.savings,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resultEarned(result.jkd.label),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.resultPoints(result.points),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.result});

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            _Row(
              color: const Color(0xFF2E7D32),
              label: l10n.labelCorrect,
              value: result.correctWords,
            ),
            if (result.unclearWords > 0) ...[
              const Divider(height: 20),
              _Row(
                color: const Color(0xFF0277BD),
                label: l10n.labelUnclear,
                value: result.unclearWords,
              ),
            ],
            const Divider(height: 20),
            _Row(
              color: const Color(0xFFE65100),
              label: l10n.labelNearlyRight,
              value: result.mispronouncedWords,
            ),
            const Divider(height: 20),
            _Row(
              color: const Color(0xFFC62828),
              label: l10n.labelMissed,
              value: result.missedWords,
            ),
            if (result.extraWords > 0) ...[
              const Divider(height: 20),
              _Row(
                color: const Color(0xFF546E7A),
                label: l10n.labelExtra,
                value: result.extraWords,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Explains words the recogniser heard but was unsure about.
///
/// This card exists to point the parent at the *microphone*, not the child. The
/// most likely cause is that the tablet was too far away — and telling a parent
/// that is far more useful than quietly docking marks.
class _UnclearCard extends StatelessWidget {
  const _UnclearCard({required this.result});

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final unclear =
        result.alignment.where((w) => w.status == WordStatus.unclear).toList();

    return Card(
      color: const Color(0xFFE1F5FE),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hearing, size: 20, color: Color(0xFF01579B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.labelUnclear,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF01579B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final word in unclear)
                  Chip(
                    label: Text(word.display),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unclearHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF01579B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows words the recogniser heard that are not in the passage at all.
///
/// Worth surfacing: when this list is long and the child clearly read well, the
/// likeliest explanation is a second voice in the room, not a mistake.
class _ExtrasCard extends StatelessWidget {
  const _ExtrasCard({required this.result});

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.extrasTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final extra in result.extras)
                  Chip(
                    label: Text(extra.heard ?? extra.display),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.extrasNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
