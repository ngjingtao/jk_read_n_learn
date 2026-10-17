import 'package:flutter_tts/flutter_tts.dart';

import '../models/app_language.dart';

/// The voice the app speaks with.
///
/// An interface rather than a concrete class so that anything depending on
/// speech — above all [ReadingSessionController] — can be tested without
/// constructing a platform audio engine.
abstract interface class Speaker {
  /// Reads a whole passage aloud at a comfortable pace for a beginner.
  Future<void> speakPassage(String text, ReadingLanguage language);

  /// Pronounces a single word, slowly.
  Future<void> speakWord(String word, ReadingLanguage language);

  /// Stops any speech in progress.
  ///
  /// Must be called before starting speech recognition: the microphone and the
  /// speaker share an audio session, and on iOS leaving speech running makes
  /// the recogniser hear the app itself.
  Future<void> stop();
}

/// Wraps the platform text-to-speech engine.
///
/// Two jobs: read a passage to the child, and pronounce a single word when it is
/// tapped. Both need a slow, clear voice — the default engine rate is tuned for
/// adult ears and is far too fast for a beginner.
class TtsService implements Speaker {
  TtsService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;

  bool _ready = false;

  /// Rate used for reading a passage aloud. The engine's scale is 0.0 – 1.0.
  static const double passageRate = 0.45;

  /// Slower still, for a single tapped word the child is stuck on.
  static const double wordRate = 0.35;

  /// Prepares the engine. Safe to call repeatedly.
  Future<void> _ensureReady() async {
    if (_ready) return;
    // Makes speak() complete only once audio actually finishes, so callers can
    // await a whole passage instead of guessing at a delay.
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Best available locale for [language] on this device.
  ///
  /// Falls back through the language's candidates and finally to the declared
  /// locale, so a device without `ms-MY` installed still gets *something*
  /// rather than silence.
  Future<String> resolveLocale(ReadingLanguage language) async {
    await _ensureReady();
    for (final candidate in language.sttLocaleCandidates) {
      if (await _tts.isLanguageAvailable(candidate) == true) return candidate;
    }
    return language.ttsLocale;
  }

  @override
  Future<void> speakPassage(String text, ReadingLanguage language) {
    return _speak(text, language, passageRate);
  }

  @override
  Future<void> speakWord(String word, ReadingLanguage language) {
    return _speak(word, language, wordRate);
  }

  /// Reads [text] aloud in [language].
  Future<void> _speak(
    String text,
    ReadingLanguage language,
    double rate,
  ) async {
    if (text.trim().isEmpty) return;
    await _ensureReady();
    // Never talk over an in-flight utterance; overlapping speech is confusing
    // to a child and can leave the engine in a bad state on Android.
    await _tts.stop();
    await _tts.setLanguage(await resolveLocale(language));
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
