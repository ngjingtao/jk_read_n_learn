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

/// Text sizes offered in Settings.
///
/// Not a free slider: a handful of steps is easier to reason about, easier to
/// test, and impossible to leave in a state that breaks the layout.
enum TextSize {
  small(0.9),
  normal(1.0),
  large(1.2),
  extraLarge(1.4);

  const TextSize(this.factor);

  final double factor;

  static TextSize fromName(String? name) => TextSize.values.firstWhere(
        (size) => size.name == name,
        orElse: () => TextSize.normal,
      );
}

/// Line spacing for the passage itself.
///
/// The passage is the one thing a struggling reader stares at, so it gets its
/// own control rather than inheriting the general text scale.
enum LineSpacing {
  normal(1.9),
  wide(2.4),
  extraWide(3.0);

  const LineSpacing(this.height);

  /// Multiplier applied to the font size, as Flutter's `TextStyle.height`.
  final double height;

  static LineSpacing fromName(String? name) => LineSpacing.values.firstWhere(
        (spacing) => spacing.name == name,
        orElse: () => LineSpacing.normal,
      );
}

/// Parent-facing preferences: interface language, speech settings, and reading
/// comfort.
///
/// Persisted on the device alongside the wallet. Nothing here affects marking,
/// which is deliberate — a parent changing the interface language must not be
/// able to accidentally change how their child is scored.
class SettingsState extends ChangeNotifier {
  SettingsState([this._preferences]);

  static const String _languageKey = 'settings.uiLanguage';
  static const String _onDeviceKey = 'settings.preferOnDevice';
  static const String _textSizeKey = 'settings.textSize';
  static const String _lineSpacingKey = 'settings.lineSpacing';
  static const String _reduceMotionKey = 'settings.reduceMotion';

  SharedPreferences? _preferences;

  /// Defaults to Chinese: the first families using this app read Chinese, and an
  /// interface they cannot read is worse than one an English speaker has to
  /// change once.
  UiLanguage _language = UiLanguage.chinese;

  bool _preferOnDevice = false;
  TextSize _textSize = TextSize.normal;
  LineSpacing _lineSpacing = LineSpacing.normal;
  bool _reduceMotion = false;
  bool _loaded = false;

  UiLanguage get language => _language;
  Locale get locale => _language.locale;

  /// Passed straight to the recogniser. See `SpeechService.preferOnDevice` for
  /// why this defaults to off.
  bool get preferOnDevice => _preferOnDevice;

  TextSize get textSize => _textSize;
  LineSpacing get lineSpacing => _lineSpacing;

  /// Turns off the pulsing "listening" indicator and other decorative motion.
  ///
  /// The plain "Listening… 0:04" text beside it carries the same information, so
  /// nothing is lost — which is the point. Motion should never be the only way
  /// to know what the app is doing.
  bool get reduceMotion => _reduceMotion;

  bool get isLoaded => _loaded;

  /// Reads saved preferences. Safe to call more than once.
  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;

    _language = UiLanguage.fromCode(prefs.getString(_languageKey));
    _preferOnDevice = prefs.getBool(_onDeviceKey) ?? false;
    _textSize = TextSize.fromName(prefs.getString(_textSizeKey));
    _lineSpacing = LineSpacing.fromName(prefs.getString(_lineSpacingKey));
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;

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

  Future<void> setTextSize(TextSize size) async {
    if (size == _textSize) return;
    _textSize = size;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_textSizeKey, size.name);
  }

  Future<void> setLineSpacing(LineSpacing spacing) async {
    if (spacing == _lineSpacing) return;
    _lineSpacing = spacing;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_lineSpacingKey, spacing.name);
  }

  Future<void> setReduceMotion(bool value) async {
    if (value == _reduceMotion) return;
    _reduceMotion = value;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_reduceMotionKey, value);
  }
}
