import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/app_language.dart';

/// Why a listening attempt could not start, or why it ended.
///
/// Typed rather than a message string: the service must not decide what a
/// parent reads, because the UI is localised and the service is not.
enum SpeechFailure {
  /// The platform exposes no dictation at all.
  recogniserUnavailable,

  /// Dictation exists, but no installed locale satisfies the language.
  localeUnavailable,

  /// The recogniser started but failed mid-session.
  engineError,
}

/// Why a listening session stopped.
enum SpeechSessionEnd {
  /// The child stopped talking for long enough that the recogniser closed the
  /// session itself. The transcript is still valid and should be marked.
  finishedSpeaking,

  /// The app asked it to stop.
  requested,

  /// The recogniser failed.
  error,
}

/// Turns speech into text.
///
/// An interface, not the concrete engine, so that
/// [ReadingSessionController] can be tested without a microphone.
abstract interface class SpeechRecogniser {
  /// Whether the platform exposes dictation at all.
  bool get isAvailable;

  /// Whether to demand on-device (offline) recognition.
  ///
  /// Off by default on purpose. When this is `true`, a device that ships no
  /// offline model for the requested language does not fall back to the network
  /// — the listen attempt simply *fails*, which looks to a child like the app is
  /// broken. Since `ms-MY` offline models are rare, reliability wins by
  /// default. Turning it on is a genuine privacy improvement, so it belongs in
  /// a parent-facing setting rather than being hard-coded either way.
  bool get preferOnDevice;
  set preferOnDevice(bool value);

  /// Prepares the platform recogniser. Safe to call repeatedly.
  Future<bool> initialise();

  /// First locale installed on the device that satisfies [language], or `null`.
  Future<String?> resolveLocale(ReadingLanguage language);

  /// Every locale the device's recogniser offers, for the hearing test.
  Future<List<String>> installedLocales();

  /// Starts listening.
  ///
  /// [onTranscript] fires repeatedly with the cumulative transcript so the UI
  /// can show words appearing live, together with the recogniser's confidence
  /// in that result. Confidence is `null` when the platform does not rate its
  /// output — which is common, and must not be treated as "unsure".
  ///
  /// [onSessionEnd] fires if the recogniser closes the session on its own —
  /// without it, a child who goes quiet leaves the app stuck showing
  /// "listening" forever with nobody at the microphone.
  ///
  /// Returns `null` on success, or the reason it failed.
  Future<SpeechFailure?> listen({
    required ReadingLanguage language,
    required void Function(String transcript, double? confidence) onTranscript,
    void Function(SpeechSessionEnd reason)? onSessionEnd,
  });

  /// Stops listening and returns everything heard.
  Future<String> stop();

  /// Stops listening and throws the transcript away.
  Future<void> cancel();
}

/// Wraps on-device speech recognition.
///
/// Recogniser availability varies wildly across phones and tablets, and the
/// locale a child needs (especially `ms-MY`) is often not installed. This class
/// hides that behind a small surface: is it usable, what did it hear, and why
/// did it stop.
class SpeechService implements SpeechRecogniser {
  SpeechService({SpeechToText? recogniser})
      : _stt = recogniser ?? SpeechToText();

  final SpeechToText _stt;

  bool _initialised = false;
  bool _available = false;
  SpeechFailure? _lastFailure;

  /// Running transcript for the current attempt. `speech_to_text` reports
  /// cumulative results, so we overwrite rather than append.
  String _transcript = '';

  bool _listening = false;

  /// True between the platform reporting `listening` and it reporting `done`.
  bool _sessionActive = false;

  /// True when *we* asked for the stop, so the resulting `done` status is not
  /// misreported to the caller as the child finishing.
  bool _stopRequested = false;

  void Function(SpeechSessionEnd reason)? _onSessionEnd;

  @override
  bool get isAvailable => _available;

  bool get isListening => _listening;

  String get transcript => _transcript;

  SpeechFailure? get lastFailure => _lastFailure;

  @override
  bool preferOnDevice = false;

  /// Maximum length of a single reading attempt.
  Duration listenFor = const Duration(minutes: 5);

  /// How long a silence ends the attempt automatically.
  Duration pauseFor = const Duration(seconds: 6);

  /// Whether the platform exposes dictation at all.
  ///
  /// Separate from locale support: dictation can exist while a specific language
  /// is missing, which the UI surfaces as a helpful message rather than silence.
  @override
  Future<bool> initialise() async {
    if (_initialised) return _available;
    _initialised = true;
    try {
      _available = await _stt.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: false,
      );
    } catch (_) {
      _available = false;
    }
    if (!_available) _lastFailure = SpeechFailure.recogniserUnavailable;
    return _available;
  }

  /// First locale installed on the device that satisfies [language], or `null`.
  ///
  /// Falls back to a prefix match so `zh-Hans-CN` can satisfy a request for
  /// `zh-CN`.
  @override
  Future<String?> resolveLocale(ReadingLanguage language) async {
    if (!await initialise()) return null;

    final installedIds = (await _stt.locales()).map((l) => l.localeId).toList();

    for (final candidate in language.sttLocaleCandidates) {
      for (final id in installedIds) {
        if (id.toLowerCase() == candidate.toLowerCase()) return id;
      }
    }

    final primary = language.sttLocaleCandidates.first.split('-').first;
    for (final id in installedIds) {
      if (id.toLowerCase().startsWith(primary)) return id;
    }

    return null;
  }

  /// Every locale the device's recogniser offers.
  ///
  /// Used by the hearing test, so a parent can see what the device actually has
  /// rather than only whether the wanted language was found.
  @override
  Future<List<String>> installedLocales() async {
    if (!await initialise()) return const [];
    return (await _stt.locales()).map((l) => l.localeId).toList(growable: false);
  }

  /// Starts listening for [language].
  ///
  /// [onTranscript] fires repeatedly with the cumulative transcript so the UI
  /// can show words appearing live. [onSessionEnd] fires if the recogniser
  /// closes the session on its own — without it, a child who goes quiet leaves
  /// the app stuck showing "listening" forever with nobody at the microphone.
  ///
  /// Returns `null` on success, or the reason it failed.
  @override
  Future<SpeechFailure?> listen({
    required ReadingLanguage language,
    required void Function(String transcript, double? confidence) onTranscript,
    void Function(SpeechSessionEnd reason)? onSessionEnd,
  }) async {
    if (!await initialise()) return SpeechFailure.recogniserUnavailable;

    final localeId = await resolveLocale(language);
    if (localeId == null) {
      _lastFailure = SpeechFailure.localeUnavailable;
      return SpeechFailure.localeUnavailable;
    }

    _transcript = '';
    _lastFailure = null;
    _stopRequested = false;
    _onSessionEnd = onSessionEnd;

    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          _transcript = result.recognizedWords;
          // `speech_to_text` reports -1 when it has no rating for this result,
          // and 0 when there are no alternates at all. Neither means "unsure",
          // so both are reported as absent.
          final rated = result.hasConfidenceRating &&
              result.confidence >= 0 &&
              result.confidence <= 1;
          onTranscript(_transcript, rated ? result.confidence : null);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          onDevice: preferOnDevice,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          listenFor: listenFor,
          pauseFor: pauseFor,
        ),
      );
    } catch (_) {
      _lastFailure = SpeechFailure.engineError;
      return SpeechFailure.engineError;
    }

    _listening = true;
    _sessionActive = true;
    return null;
  }

  /// Stops listening and returns everything heard.
  @override
  Future<String> stop() async {
    if (!_listening && !_sessionActive) return _transcript;
    _stopRequested = true;
    try {
      // A platform that will not answer must not be able to freeze the app.
      // The transcript already collected is perfectly usable, so a stop that
      // times out costs nothing and a stop that hangs costs everything.
      await _stt.stop().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore: the transcript we already hold is still valid.
    }
    _listening = false;
    _sessionActive = false;
    return _transcript;
  }

  /// Stops listening and throws the transcript away.
  @override
  Future<void> cancel() async {
    _stopRequested = true;
    try {
      await _stt.cancel().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore: the session is being abandoned regardless.
    }
    _listening = false;
    _sessionActive = false;
    _transcript = '';
  }

  void _onStatus(String status) {
    switch (status) {
      case 'listening':
        _listening = true;
        _sessionActive = true;
      case 'done':
        _listening = false;
        if (_sessionActive) {
          _sessionActive = false;
          if (!_stopRequested) {
            _onSessionEnd?.call(SpeechSessionEnd.finishedSpeaking);
          }
        }
      case 'notListening':
        _listening = false;
    }
  }

  void _onError(SpeechRecognitionError error) {
    _lastFailure = SpeechFailure.engineError;
    final wasActive = _sessionActive;
    _listening = false;
    _sessionActive = false;
    if (wasActive) _onSessionEnd?.call(SpeechSessionEnd.error);
  }
}
