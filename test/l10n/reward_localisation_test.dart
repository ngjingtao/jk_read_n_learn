import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/l10n/generated/app_localizations.dart';
import 'package:jkreadnlearn/models/money.dart';
import 'package:jkreadnlearn/models/reward.dart';
import 'package:jkreadnlearn/ui/l10n_extensions.dart';

void main() {
  group('reward catalogue', () {
    test('ids are unique and non-empty', () {
      final ids = kRewardCatalogue.map((r) => r.id).toSet();
      expect(ids, hasLength(kRewardCatalogue.length));
      expect(kRewardCatalogue.every((r) => r.id.isNotEmpty), isTrue);
    });

    test('is ordered cheapest first, with no free or negative rewards', () {
      // Ordering is what lets the shop read as a ladder of increasing effort.
      for (var i = 1; i < kRewardCatalogue.length; i++) {
        expect(
          kRewardCatalogue[i].cost.hundredths,
          greaterThan(kRewardCatalogue[i - 1].cost.hundredths),
          reason: '${kRewardCatalogue[i].id} is not more expensive than '
              '${kRewardCatalogue[i - 1].id}',
        );
      }
      expect(kRewardCatalogue.first.cost.hundredths, greaterThan(0));
    });

    test('every reward is reachable within a few good readings', () {
      // A clean 60-word passage is about 6.25 JKD. If the cheapest reward cost
      // more than that, a child would read for a whole session and be able to
      // buy nothing, which is exactly the failure that makes a reward system
      // stop working.
      expect(
        kRewardCatalogue.first.cost.hundredths,
        lessThanOrEqualTo(625),
      );
    });

    test('lookup finds known ids and tolerates retired ones', () {
      expect(rewardById('star')?.cost, const Jkd(50));
      // Save data outlives the catalogue: a retired reward must return null
      // rather than throwing.
      expect(rewardById('unicorn'), isNull);
    });
  });

  group('every reward has a real translation', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test('in ${locale.languageCode}', () async {
        final l10n = await AppLocalizations.delegate.load(locale);

        for (final reward in kRewardCatalogue) {
          final name = l10n.rewardName(reward);
          expect(
            name,
            isNotEmpty,
            reason: '${reward.id} has no name in ${locale.languageCode}',
          );
          expect(
            name,
            isNot(reward.id),
            reason: '${reward.id} fell through to its raw id in '
                '${locale.languageCode} — add reward${reward.id[0].toUpperCase()}'
                '${reward.id.substring(1)} to app_${locale.languageCode}.arb',
          );
        }
      });
    }

    test('a retired reward id degrades to the id rather than throwing', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.rewardNameById('unicorn'), 'unicorn');
    });
  });
}
