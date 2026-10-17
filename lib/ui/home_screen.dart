import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_essays.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/app_language.dart';
import '../models/essay.dart';
import '../services/scoring/text_utils.dart';
import '../state/wallet_state.dart';
import 'l10n_extensions.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';

/// Picks a language and a passage. The child's JKD balance sits in the app bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ReadingLanguage _language = ReadingLanguage.english;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wallet = context.watch<WalletState>();
    final essays = essaysFor(_language);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          _BalanceChip(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Greeting(),
          _LanguagePicker(
            selected: _language,
            onChanged: (language) => setState(() => _language = language),
          ),
          if (!wallet.isLoaded)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                for (final essay in essays)
                  _EssayCard(
                    essay: essay,
                    onTap: () => _openEssay(essay),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEssay(Essay essay) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReaderScreen(essay: essay)),
    );
    // The wallet may have grown while reading; WalletState notifies listeners
    // already, so there is nothing to refresh here.
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeGreeting,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.selected, required this.onChanged});

  final ReadingLanguage selected;
  final ValueChanged<ReadingLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final language in ReadingLanguage.values)
            ChoiceChip(
              label: Text(l10n.readingLanguageName(language)),
              selected: language == selected,
              onSelected: (_) => onChanged(language),
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight:
                    language == selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _EssayCard extends StatelessWidget {
  const _EssayCard({required this.essay, required this.onTap});

  final Essay essay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final wordCount = tokenize(essay.text, essay.language.tokenMode)
        .where((t) => t.isWord)
        .length;
    final meta = '${l10n.standardLabel(essay.gradeLevel)}'
        ' · ${l10n.unitFor(essay.language.tokenMode, wordCount)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${essay.gradeLevel}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        essay.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<WalletState>().balance;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              balance.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
