import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/reward.dart';
import '../state/progress_state.dart';
import '../state/wallet_state.dart';
import 'l10n_extensions.dart';

/// Where a child spends the JKD they earned.
///
/// The whole point of a reward currency is that it can be spent. A balance that
/// only ever grows stops being a reward after about a week, so the shop is not
/// decoration — it is what makes the reading loop mean something.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final wallet = context.watch<WalletState>();
    final progress = context.watch<ProgressState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shopTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  wallet.balance.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.shopSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          _CollectionStrip(progress: progress),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final reward in kRewardCatalogue)
                _RewardCard(
                  reward: reward,
                  owned: progress.owns(reward.id),
                  affordable: wallet.balance.hundredths >= reward.cost.hundredths,
                  onBuy: () => _buy(context, reward),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, Reward reward) async {
    final l10n = AppLocalizations.of(context);
    final wallet = context.read<WalletState>();
    final progress = context.read<ProgressState>();
    final messenger = ScaffoldMessenger.of(context);

    // Mark as owned first: if the ledger write fails we would rather show a
    // reward the child did not pay for than take payment for nothing. Money
    // leaving without the thing arriving is the failure a child would notice.
    final added = await progress.addOwnedReward(reward.id);
    if (!added) return;

    final paid = await wallet.spend(
      reward.cost,
      label: reward.id,
      rewardId: reward.id,
    );

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.shopBought(l10n.rewardName(reward))),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (!paid) {
      // Should be unreachable: the button is disabled unless affordable. Log it
      // rather than silently leaving the balance short.
      debugPrint('Reward ${reward.id} granted without payment.');
    }
  }
}

/// The child's collection, shown as a row of emoji.
class _CollectionStrip extends StatelessWidget {
  const _CollectionStrip({required this.progress});

  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final owned = kRewardCatalogue.where((r) => progress.owns(r.id)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shopCollection,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (owned.isEmpty)
              Text(
                l10n.shopCollectionEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final reward in owned)
                    Tooltip(
                      message: l10n.rewardName(reward),
                      child: Text(
                        reward.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.owned,
    required this.affordable,
    required this.onBuy,
  });

  final Reward reward;
  final bool owned;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 156,
      child: Card(
        color: owned
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: owned || affordable ? 1 : 0.4,
                child: Text(reward.emoji, style: const TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.rewardName(reward),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reward.cost.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              if (owned)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.shopOwned,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: affordable ? onBuy : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: Text(
                      affordable ? l10n.shopBuy : l10n.shopNotEnough,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
