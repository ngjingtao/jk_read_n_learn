import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/app.dart';
import 'package:jkreadnlearn/state/settings_state.dart';
import 'package:jkreadnlearn/ui/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app, real providers and real localisation delegates.
///
/// The unit tests prove the strings exist; only this proves they reach a
/// screen, which is where localisation actually breaks.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('boots with a Chinese interface by default', (tester) async {
    await tester.pumpWidget(const JkReadNLearnApp());
    await tester.pumpAndSettle();

    expect(find.text('JK 阅读学习'), findsOneWidget);
    expect(find.text('今天想读什么？'), findsOneWidget);
  });

  testWidgets('switching the interface language re-renders the app',
      (tester) async {
    await tester.pumpWidget(const JkReadNLearnApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeScreen));
    await Provider.of<SettingsState>(context, listen: false)
        .setLanguage(UiLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('JK Read n Learn'), findsOneWidget);
    expect(find.text('What shall we read today?'), findsOneWidget);
    expect(find.text('今天想读什么？'), findsNothing);
  });

  testWidgets('opening a passage shows the localised reading controls',
      (tester) async {
    await tester.pumpWidget(const JkReadNLearnApp());
    await tester.pumpAndSettle();

    // Passage titles stay in the language of the passage, regardless of the
    // interface language — the child reads English here, not Chinese.
    await tester.tap(find.text('My Morning Garden'));
    await tester.pumpAndSettle();

    expect(find.text('大声朗读'), findsOneWidget);
    expect(find.text('听一听'), findsOneWidget);
  });

  testWidgets('the reading list is not empty in any interface language',
      (tester) async {
    await tester.pumpWidget(const JkReadNLearnApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeScreen));
    final settings = Provider.of<SettingsState>(context, listen: false);

    for (final language in UiLanguage.values) {
      await settings.setLanguage(language);
      await tester.pumpAndSettle();
      expect(
        find.text('My Morning Garden'),
        findsOneWidget,
        reason: 'passage list vanished for ${language.code}',
      );
    }
  });
}
