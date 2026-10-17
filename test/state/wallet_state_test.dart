import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/models/money.dart';
import 'package:jkreadnlearn/state/wallet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<WalletState> walletWith(Jkd starting) async {
    final wallet = WalletState();
    await wallet.load();
    if (!starting.isZero) {
      await wallet.credit(
        JkdTransaction(
          label: 'Test',
          amount: starting,
          at: DateTime(2026, 10, 17),
        ),
      );
    }
    return wallet;
  }

  group('spending', () {
    test('deducts from the balance', () async {
      final wallet = await walletWith(const Jkd(500));

      final paid = await wallet.spend(const Jkd(200), label: 'star');

      expect(paid, isTrue);
      expect(wallet.balance, const Jkd(300));
    });

    test('records the purchase as a negative ledger entry', () async {
      final wallet = await walletWith(const Jkd(500));

      await wallet.spend(const Jkd(200), label: 'star', rewardId: 'star');

      final entry = wallet.history.first;
      expect(entry.amount, const Jkd(-200));
      expect(entry.rewardId, 'star');
      expect(wallet.history, hasLength(2));
    });

    test('refuses to overspend', () async {
      final wallet = await walletWith(const Jkd(100));

      final paid = await wallet.spend(const Jkd(200), label: 'trophy');

      expect(paid, isFalse);
      expect(wallet.balance, const Jkd(100), reason: 'balance must be untouched');
      expect(wallet.history, hasLength(1), reason: 'no ledger entry on refusal');
    });

    test('allows spending the exact balance', () async {
      final wallet = await walletWith(const Jkd(200));

      expect(await wallet.spend(const Jkd(200), label: 'rocket'), isTrue);
      expect(wallet.balance, Jkd.zero);
    });

    test('refuses a zero or negative spend', () async {
      final wallet = await walletWith(const Jkd(500));

      expect(await wallet.spend(Jkd.zero, label: 'nothing'), isFalse);
      expect(await wallet.spend(const Jkd(-100), label: 'odd'), isFalse);
      expect(wallet.balance, const Jkd(500));
    });

    test('an empty wallet cannot buy anything', () async {
      final wallet = await walletWith(Jkd.zero);

      expect(await wallet.spend(const Jkd(50), label: 'star'), isFalse);
      expect(wallet.balance, Jkd.zero);
    });

    test('a balance and a collection survive a restart', () async {
      final wallet = await walletWith(const Jkd(500));
      await wallet.spend(const Jkd(200), label: 'star', rewardId: 'star');

      final reloaded = WalletState();
      await reloaded.load();

      expect(reloaded.balance, const Jkd(300));
      expect(reloaded.history.first.rewardId, 'star');
    });
  });
}
