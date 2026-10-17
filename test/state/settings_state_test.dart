import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/state/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to a Chinese interface', () async {
    final settings = SettingsState();
    await settings.load();

    expect(settings.language, UiLanguage.chinese);
    expect(settings.locale.languageCode, 'zh');
  });

  test('defaults to allowing network recognition for reliability', () async {
    final settings = SettingsState();
    await settings.load();

    expect(settings.preferOnDevice, isFalse);
  });

  test('remembers the chosen interface language', () async {
    final settings = SettingsState();
    await settings.load();
    await settings.setLanguage(UiLanguage.malay);

    // A fresh instance must see the saved choice, as it would after a restart.
    final reloaded = SettingsState();
    await reloaded.load();

    expect(reloaded.language, UiLanguage.malay);
    expect(reloaded.locale.languageCode, 'ms');
  });

  test('remembers the on-device recognition preference', () async {
    final settings = SettingsState();
    await settings.load();
    await settings.setPreferOnDevice(true);

    final reloaded = SettingsState();
    await reloaded.load();

    expect(reloaded.preferOnDevice, isTrue);
  });

  test('notifies listeners when the language changes', () async {
    final settings = SettingsState();
    await settings.load();

    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setLanguage(UiLanguage.english);
    await settings.setLanguage(UiLanguage.english); // no change, no notify

    expect(notifications, 1);
  });

  test('an unknown saved language falls back to Chinese', () async {
    SharedPreferences.setMockInitialValues({
      'settings.uiLanguage': 'klingon',
    });

    final settings = SettingsState();
    await settings.load();

    expect(settings.language, UiLanguage.chinese);
  });

  test('interface languages use real BCP-47 codes', () {
    // 'bm' would be Bambara, not Bahasa Malaysia. Getting this wrong makes
    // Flutter's own Material widgets render in the wrong language.
    expect(UiLanguage.malay.code, 'ms');
    expect(UiLanguage.malay.locale.languageCode, 'ms');
  });
}
