import 'money.dart';

/// Something a child can buy with the JKD they have earned.
///
/// Deliberately emoji rather than image assets: it keeps the repository free of
/// binary art that would need licensing, and every device already renders these.
/// When a real designer is involved, swap [emoji] for an asset path — nothing
/// else has to change.
class Reward {
  const Reward({required this.id, required this.cost, required this.emoji});

  /// Stable identifier. Doubles as the localisation key for the display name,
  /// so a reward is never shown in a language it was not translated into
  /// without that being obvious.
  final String id;

  final Jkd cost;

  /// Shown in the shop and in the collection.
  final String emoji;
}

/// Everything that can be bought, cheapest first.
///
/// The price ladder is calibrated against the reward rate in `ScoringConfig`
/// (100 points = 1 JKD, so roughly 6 JKD for a clean 60-word passage):
///
/// * the first reward is about one good reading, so a child sees the loop close
/// * the most expensive is a long-term goal, roughly a term of regular reading
///
/// These are considered guesses, not measurements. Expect to retune them once
/// real children have used the app — see `docs/ROADMAP.md` Phase 6.
const List<Reward> kRewardCatalogue = [
  Reward(id: 'star', cost: Jkd(50), emoji: '⭐'),
  Reward(id: 'heart', cost: Jkd(100), emoji: '💖'),
  Reward(id: 'rocket', cost: Jkd(200), emoji: '🚀'),
  Reward(id: 'rainbow', cost: Jkd(300), emoji: '🌈'),
  Reward(id: 'panda', cost: Jkd(500), emoji: '🐼'),
  Reward(id: 'dragon', cost: Jkd(800), emoji: '🐉'),
  Reward(id: 'crown', cost: Jkd(1200), emoji: '👑'),
  Reward(id: 'trophy', cost: Jkd(2000), emoji: '🏆'),
];

/// Looks up a reward by [id], or `null` when the catalogue has moved on and a
/// saved id no longer exists.
///
/// This happens when a reward is retired: old save data still lists it. Callers
/// must tolerate `null` rather than assuming the catalogue is stable.
Reward? rewardById(String id) {
  for (final reward in kRewardCatalogue) {
    if (reward.id == id) return reward;
  }
  return null;
}
