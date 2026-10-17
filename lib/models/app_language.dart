/// How a language's text is split into gradeable units.
enum TokenMode {
  /// Whitespace-delimited words. Used for English and Bahasa Malaysia.
  word,

  /// One gradeable unit per Han character. Used for Chinese.
  character,
}

/// The languages JK Read n Learn can grade, as requested: en / zh / bm.
///
/// Speech engines on real devices do not always ship every locale, so each
/// language advertises an ordered list of locale candidates. [SpeechService]
/// picks the first one the device actually supports.
enum ReadingLanguage {
  english(
    code: 'en',
    label: 'English',
    nativeLabel: 'English',
    ttsLocale: 'en-US',
    sttLocaleCandidates: ['en-US', 'en-GB', 'en-MY', 'en'],
    tokenMode: TokenMode.word,
  ),
  chinese(
    code: 'zh',
    label: 'Chinese',
    nativeLabel: '中文',
    ttsLocale: 'zh-CN',
    sttLocaleCandidates: ['zh-CN', 'zh-Hans-CN', 'zh-HK', 'zh-TW', 'zh'],
    tokenMode: TokenMode.character,
  ),
  malay(
    code: 'ms',
    label: 'Bahasa Malaysia',
    nativeLabel: 'Bahasa Melayu',
    ttsLocale: 'ms-MY',
    sttLocaleCandidates: ['ms-MY', 'ms', 'id-ID', 'en-MY'],
    tokenMode: TokenMode.word,
  );

  const ReadingLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.ttsLocale,
    required this.sttLocaleCandidates,
    required this.tokenMode,
  });

  /// Short stable identifier used in persisted data: `en`, `zh`, `ms`.
  ///
  /// These are BCP-47 language subtags, not display names, so they can be
  /// handed straight to speech engines and Flutter's localisation delegates.
  /// Malay is `ms` — `bm` would be Bambara.
  final String code;

  /// English display name, for menus aimed at parents and teachers.
  final String label;

  /// Name in the language itself, shown on the language switcher.
  final String nativeLabel;

  /// Preferred locale handed to the text-to-speech engine.
  final String ttsLocale;

  /// Locales to try for speech recognition, most preferred first.
  final List<String> sttLocaleCandidates;

  /// Whether reading is graded per word or per character.
  final TokenMode tokenMode;

  /// Resolves a persisted [code] back to a language, defaulting to English.
  static ReadingLanguage fromCode(String? code) {
    return ReadingLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => ReadingLanguage.english,
    );
  }
}
