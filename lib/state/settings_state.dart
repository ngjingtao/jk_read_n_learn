import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the *interface* is shown in.
///
/// Distinct from [ReadingLanguage], which is the language of the *passage* the
/// child reads. A Malay-speaking parent may well want a Chinese interface while
/// their child practises English, so these are two independent choices.
enum UiLanguage {
  english('en'),
  chinese('zh'),
  malay('ms');

  const UiLanguage(this.code);

  /// BCP-47 language subtag. Must match the `@@locale` in the matching .arb
  /// file, and must be a locale Flutter's Material delegates actually support.
  final String code;

  Locale get locale => Locale(code);

  /// Resolves a persisted [code], defaulting to Chinese.
  static UiLanguage fromCode(String? code) {
    return UiLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => UiLanguage.chinese,
    );
  }
}

/// Parent-facing preferences: interface language and speech settings.
///
/// Persisted on the device alongside the wallet. Nothing here affects marking,
/// which is deliberate — a parent changing the interface language must not be
/// able to accidentally change how their child is scored.
class SettingsState extends ChangeNotifier {
  SettingsState([this._preferences]);

  static const String _languageKey = 'settings.uiLanguage';
  static const String _onDeviceKey = 'settings.preferOnDevice';

  SharedPreferences? _preferences;

  /// Defaults to Chinese: the first families using this app read Chinese, and an
  /// interface they cannot read is worse than one an English speaker has to
  /// change once.
  UiLanguage _language = UiLanguage.chinese;

  bool _preferOnDevice = false;
  bool _loaded = false;

  UiLanguage get language => _language;
  Locale get locale => _language.locale;

  /// Passed straight to the recogniser. See `SpeechService.preferOnDevice` for
  /// why this defaults to off.
  bool get preferOnDevice => _preferOnDevice;

  bool get isLoaded => _loaded;

  /// Reads saved preferences. Safe to call more than once.
  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;

    _language = UiLanguage.fromCode(prefs.getString(_languageKey));
    _preferOnDevice = prefs.getBool(_onDeviceKey) ?? false;

    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(UiLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_languageKey, language.code);
  }

  Future<void> setPreferOnDevice(bool value) async {
    if (value == _preferOnDevice) return;
    _preferOnDevice = value;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_onDeviceKey, value);
  }
}
