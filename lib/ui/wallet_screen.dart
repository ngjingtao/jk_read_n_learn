import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/progress_state.dart';
import '../state/wallet_state.dart';
import 'l10n_extensions.dart';

/// The child's JKD savings book.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final wallet = context.watch<WalletState>();
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletTitle),
        actions: [
          IconButton(
            tooltip: l10n.walletResetTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmReset(context, wallet),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.walletCurrencyName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    wallet.balance.label,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.walletTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.walletHistory,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (wallet.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  l10n.walletEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final entry in wallet.history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  // Purchases store an id, not a translated string, so the
                  // ledger renders in whatever language is active *now*.
                  entry.rewardId != null
                      ? l10n.rewardNameById(entry.rewardId!)
                      : entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatShortDate(entry.at, localeName)),
                trailing: Text(
                  // Signed: purchases show as a negative amount, so the ledger
                  // reads correctly without a second code path.
                  '${entry.amount.hundredths >= 0 ? '+' : ''}${entry.amount.label}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: entry.amount.hundredths >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WalletState wallet) async {
    final l10n = AppLocalizations.of(context);
    final progress = context.read<ProgressState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.walletResetTitle),
        content: Text(l10n.walletResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionKeepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionClear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Reset both together. Clearing the balance but leaving the collection
      // would let a child keep rewards they never paid for.
      await wallet.reset();
      await progress.reset();
    }
  }
}
