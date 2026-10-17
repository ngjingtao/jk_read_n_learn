import 'package:flutter/foundation.dart';

import '../models/app_language.dart';
import '../models/essay.dart';
import '../models/scoring_models.dart';
import '../services/permission_service.dart';
import '../services/scoring/confidence_tracker.dart';
import '../services/scoring/reading_scorer.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/voice_separator.dart';
import 'progress_state.dart';
import 'settings_state.dart';
import 'wallet_state.dart';

/// Where a reading attempt currently is.
enum ReadingPhase {
  /// Nothing happening; waiting for the child to listen or start reading.
  ready,

  /// Asking for the microphone.
  checkingPermission,

  /// The microphone is open and the transcript is streaming in.
  listening,

  /// Audio finished, marks are being computed.
  scoring,

  /// Marks are in and the reward has been paid.
  finished,
}

/// Something that stopped the child from being marked.
///
/// An enum, not a string: the interface is localised and this class is not.
enum ReadingError {
  /// The microphone heard nothing at all.
  nothingHeard,

  /// The platform exposes no dictation.
  recogniserUnavailable,

  /// No installed locale matches the language being read.
  localeUnavailable,

  /// Microphone access was refused, but can be asked for again.
  microphoneDenied,

  /// Microphone access is switched off at the OS level. Only the device
  /// settings can fix this, so the UI must offer to open them.
  microphonePermanentlyDenied,

  /// The audio engine threw.
  engineFailed,
}

/// Drives one read-aloud attempt: play the passage, record the child, mark it,
/// pay the reward.
///
/// The UI holds none of this logic. That keeps the screens thin and, more
/// importantly, makes the tricky sequencing testable — above all the rule that
/// speech *must* stop before the microphone opens, or the recogniser hears the
/// app's own voice.
class ReadingSessionController extends ChangeNotifier {
  ReadingSessionController({
    required this.essay,
    required this.tts,
    required this.speech,
    required this.permissions,
    required this.wallet,
    required this.progress,
    required this.settings,
    required this.voiceSeparation,
    this.scorer = const ReadingScorer(),
  });

  final Essay essay;
  final Speaker tts;
  final SpeechRecogniser speech;
  final MicrophonePermissions permissions;
  final WalletState wallet;
  final ProgressState progress;
  final SettingsState settings;
  final VoiceSeparationRegistry voiceSeparation;
  final ReadingScorer scorer;

  final Stopwatch _stopwatch = Stopwatch();

  /// Approximate per-word confidence, rebuilt for each attempt.
  ///
  /// Recreated per session so confidence from a previous reading can never leak
  /// into the next one's marks.
  ConfidenceTracker? _confidence;

  ReadingPhase _phase = ReadingPhase.ready;
  String _liveTranscript = '';
  ScoreResult? _result;
  ReadingError? _error;
  bool _isSpeaking = false;
  bool _disposed = false;
  bool _isNewRecord = false;

  ReadingPhase get phase => _phase;

  /// Cumulative transcript so far, for live display while reading.
  String get liveTranscript => _liveTranscript;

  ScoreResult? get result => _result;

  ReadingError? get error => _error;

  bool get isSpeaking => _isSpeaking;

  /// Language this session is marked in.
  ReadingLanguage get language => essay.language;

  /// Identifier of the voice-isolation strategy in force.
  ///
  /// Surfaced in the UI so a parent can tell whether a sibling or a television
  /// is capable of polluting their child's marks. The UI maps this id to a
  /// localised name; today it always resolves to the passthrough strategy.
  String get voiceStrategyId => voiceSeparation.active.id;

  /// Reads the whole passage aloud.
  Future<void> speakPassage() async {
    await _safeSpeech(() => tts.speakPassage(essay.text, essay.language));
  }

  /// Reads a single tapped word, slowly.
  Future<void> speakWord(String word) async {
    await _safeSpeech(() => tts.speakWord(word, essay.language));
  }

  /// Asks for the microphone, then begins streaming a transcript.
  Future<void> startListening() async {
    if (_phase == ReadingPhase.listening ||
        _phase == ReadingPhase.checkingPermission) {
      return;
    }

    _error = null;
    _liveTranscript = '';
    _result = null;
    _isSpeaking = false;
    _confidence = ConfidenceTracker(mode: essay.language.tokenMode);

    // Ordering matters and is not optional: the microphone and the speaker share
    // an audio session, so leaving text-to-speech running makes the app
    // transcribe its own voice.
    await tts.stop();

    _phase = ReadingPhase.checkingPermission;
    _notify();

    final access = await _ensureMicrophoneAccess();
    if (access != null) {
      _phase = ReadingPhase.ready;
      _error = access;
      _notify();
      return;
    }

    // Apply the parent's privacy preference at the moment of use, so changing
    // it in settings takes effect on the very next attempt.
    speech.preferOnDevice = settings.preferOnDevice;

    final failure = await speech.listen(
      language: essay.language,
      onTranscript: (transcript, confidence) {
        _liveTranscript = transcript;
        _confidence?.add(transcript, confidence);
        _notify();
      },
      // The recogniser closes the session itself once the child stops talking.
      // Without this the app would sit on "listening" forever, which is exactly
      // how a child ends up staring at a frozen screen.
      onSessionEnd: _onRecogniserEnded,
    );

    if (failure != null) {
      _phase = ReadingPhase.ready;
      _error = switch (failure) {
        SpeechFailure.recogniserUnavailable => ReadingError.recogniserUnavailable,
        SpeechFailure.localeUnavailable => ReadingError.localeUnavailable,
        SpeechFailure.engineError => ReadingError.engineFailed,
      };
      _notify();
      return;
    }

    _stopwatch
      ..reset()
      ..start();
    _phase = ReadingPhase.listening;
    _notify();
  }

  /// Stops listening, marks the attempt, and pays out JKD.
  Future<void> finishAndScore() async {
    if (_phase != ReadingPhase.listening) return;

    _stopwatch.stop();
    final transcript = await speech.stop();
    final duration = _stopwatch.elapsed;

    if (transcript.trim().isEmpty) {
      _phase = ReadingPhase.ready;
      _error = ReadingError.nothingHeard;
      _notify();
      return;
    }

    _phase = ReadingPhase.scoring;
    _notify();

    final result = scorer.score(
      essay: essay,
      transcript: transcript,
      duration: duration,
      // Only pass confidences when the platform actually rated anything, so a
      // device without confidence support produces exactly the old behaviour.
      spokenWordConfidences:
          (_confidence?.hasAnyConfidence ?? false) ? _confidence!.confidences : null,
      strictConfidence: settings.strictConfidenceMarking,
    );

    await wallet.credit(
      JkdTransaction(
        label: essay.title,
        amount: result.jkd,
        at: DateTime.now(),
        essayId: essay.id,
        accuracy: result.accuracy,
        points: result.points,
      ),
    );

    // Progress is recorded after the reward, so a failure to save progress can
    // never cost the child the JKD they already earned.
    _isNewRecord = await progress.recordSession(essay: essay, result: result);

    _result = result;
    _phase = ReadingPhase.finished;
    _notify();
  }

  /// Whether this attempt beat the child's previous best on this passage.
  ///
  /// `false` for a first attempt: improving on nothing is not a record, and
  /// claiming otherwise would make the celebration meaningless.
  bool get isNewRecord => _isNewRecord;

  /// Abandons the attempt without marking or paying out.
  Future<void> cancelListening() async {
    if (_phase != ReadingPhase.listening) return;
    _stopwatch.stop();
    await speech.cancel();
    _liveTranscript = '';
    _phase = ReadingPhase.ready;
    _notify();
  }

  /// Returns to a clean slate so the child can read the same passage again.
  void retry() {
    _liveTranscript = '';
    _result = null;
    _error = null;
    _isNewRecord = false;
    _phase = ReadingPhase.ready;
    _notify();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  /// Locale the recogniser will actually use, for display to a parent.
  Future<String?> resolvedLocale() => speech.resolveLocale(essay.language);

  // ------------------------------------------------------------- internals

  /// Returns `null` when the microphone is usable, or the error to show.
  Future<ReadingError?> _ensureMicrophoneAccess() async {
    var status = await permissions.microphoneStatus();
    if (status == MicrophoneAccess.granted) return null;

    if (status == MicrophoneAccess.denied) {
      status = await permissions.requestMicrophone();
      if (status == MicrophoneAccess.granted) return null;
    }

    return switch (status) {
      MicrophoneAccess.permanentlyDenied ||
      MicrophoneAccess.restricted =>
        ReadingError.microphonePermanentlyDenied,
      _ => ReadingError.microphoneDenied,
    };
  }

  void _onRecogniserEnded(SpeechSessionEnd reason) {
    if (_disposed) return;
    if (reason == SpeechSessionEnd.finishedSpeaking) {
      // The child stopped reading. Mark what we have rather than making them
      // press a button they may not understand.
      finishAndScore();
      return;
    }
    if (reason == SpeechSessionEnd.error && _phase == ReadingPhase.listening) {
      _phase = ReadingPhase.ready;
      _error = ReadingError.engineFailed;
      _notify();
    }
  }

  /// Runs [action], converting platform-channel exceptions into a typed error
  /// instead of an unhandled crash. Audio plugins throw for reasons that are
  /// mundane and recoverable — a missing voice, a busy audio session.
  Future<void> _safeSpeech(Future<void> Function() action) async {
    try {
      _isSpeaking = true;
      _notify();
      await action();
    } catch (error) {
      _error = ReadingError.engineFailed;
      debugPrint('TTS failure: $error');
    } finally {
      _isSpeaking = false;
      _notify();
    }
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopwatch.stop();
    // Fire-and-forget: dispose() cannot await, but leaving the microphone hot
    // would be worse than an unawaited future.
    tts.stop();
    speech.cancel();
    super.dispose();
  }
}
