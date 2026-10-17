import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/models/essay.dart';
import 'package:jkreadnlearn/models/money.dart';
import 'package:jkreadnlearn/services/permission_service.dart';
import 'package:jkreadnlearn/services/speech_service.dart';
import 'package:jkreadnlearn/services/tts_service.dart';
import 'package:jkreadnlearn/services/voice_separator.dart';
import 'package:jkreadnlearn/state/progress_state.dart';
import 'package:jkreadnlearn/state/reading_session_controller.dart';
import 'package:jkreadnlearn/state/settings_state.dart';
import 'package:jkreadnlearn/state/wallet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _essay = Essay(
  id: 'test-en',
  title: 'Test',
  language: ReadingLanguage.english,
  gradeLevel: 1,
  text: 'The cat sat.',
);

/// Stands in for the microphone without a device.
class FakeSpeechService implements SpeechRecogniser {
  FakeSpeechService({this.failure, this.transcript = ''});

  /// When set, `listen` fails with this instead of opening the microphone.
  SpeechFailure? failure;

  /// What the recogniser will claim to have heard.
  String transcript;

  void Function(SpeechSessionEnd reason)? _onSessionEnd;
  int listenCalls = 0;
  bool cancelled = false;

  @override
  bool preferOnDevice = false;

  @override
  bool get isAvailable => failure != SpeechFailure.recogniserUnavailable;

  @override
  Future<bool> initialise() async => isAvailable;

  @override
  Future<String?> resolveLocale(ReadingLanguage language) async =>
      failure == SpeechFailure.localeUnavailable ? null : language.ttsLocale;

  @override
  Future<List<String>> installedLocales() async => const ['en-US'];

  @override
  Future<SpeechFailure?> listen({
    required ReadingLanguage language,
    required void Function(String transcript) onTranscript,
    void Function(SpeechSessionEnd reason)? onSessionEnd,
  }) async {
    listenCalls++;
    if (failure != null) return failure;
    _onSessionEnd = onSessionEnd;
    if (transcript.trim().isNotEmpty) onTranscript(transcript);
    return null;
  }

  @override
  Future<String> stop() async => transcript;

  @override
  Future<void> cancel() async {
    cancelled = true;
    transcript = '';
  }

  /// Simulates the recogniser closing the session because the child went quiet.
  void simulateSilenceTimeout() {
    _onSessionEnd?.call(SpeechSessionEnd.finishedSpeaking);
  }
}

class FakeTtsService implements Speaker {
  final List<String> spoken = [];
  bool stopCalled = false;

  @override
  Future<void> speakPassage(String text, ReadingLanguage language) async {
    spoken.add(text);
  }

  @override
  Future<void> speakWord(String word, ReadingLanguage language) async {
    spoken.add(word);
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}

class FakePermissionService implements MicrophonePermissions {
  FakePermissionService(this.status, {this.statusAfterRequest});

  MicrophoneAccess status;

  /// Applied when the app prompts. Lets a test model "denied, then the parent
  /// allowed it".
  MicrophoneAccess? statusAfterRequest;

  int requestCalls = 0;
  bool openedSettings = false;

  @override
  Future<MicrophoneAccess> microphoneStatus() async => status;

  @override
  Future<MicrophoneAccess> requestMicrophone() async {
    requestCalls++;
    if (statusAfterRequest != null) status = statusAfterRequest!;
    return status;
  }

  @override
  Future<bool> openSettings() async {
    openedSettings = true;
    return true;
  }
}

void main() {
  setUp(() {
    // The wallet persists through SharedPreferences; an in-memory store keeps
    // tests off the platform channel.
    SharedPreferences.setMockInitialValues({});
  });

  ReadingSessionController build({
    FakeSpeechService? speech,
    FakePermissionService? permissions,
    FakeTtsService? tts,
    WalletState? wallet,
    ProgressState? progress,
  }) {
    return ReadingSessionController(
      essay: _essay,
      tts: tts ?? FakeTtsService(),
      speech: speech ?? FakeSpeechService(transcript: 'The cat sat'),
      permissions:
          permissions ?? FakePermissionService(MicrophoneAccess.granted),
      wallet: wallet ?? WalletState(),
      progress: progress ?? ProgressState(),
      settings: SettingsState(),
      voiceSeparation: VoiceSeparationRegistry(),
    );
  }

  group('a successful attempt', () {
    test('marks the reading and moves to the finished phase', () async {
      final controller = build();

      await controller.startListening();
      expect(controller.phase, ReadingPhase.listening);

      await controller.finishAndScore();

      expect(controller.phase, ReadingPhase.finished);
      expect(controller.result, isNotNull);
      expect(controller.result!.correctWords, 3);
    });

    test('pays the reward into the wallet', () async {
      final wallet = WalletState();
      final controller = build(wallet: wallet);

      await controller.startListening();
      await controller.finishAndScore();

      expect(wallet.balance, const Jkd(55));
      expect(wallet.history, hasLength(1));
      expect(wallet.history.first.essayId, 'test-en');
    });

    test('stops speech before opening the microphone', () async {
      // Speaker and microphone share an audio session: if text-to-speech is
      // still running, the recogniser transcribes the app itself.
      final tts = FakeTtsService();
      final controller = build(tts: tts);

      await controller.startListening();

      expect(tts.stopCalled, isTrue);
    });
  });

  group('when the child stops talking', () {
    test('the recogniser ends the session and the attempt is marked anyway',
        () async {
      final wallet = WalletState();
      final speech = FakeSpeechService(transcript: 'The cat sat');
      final controller = build(speech: speech, wallet: wallet);

      await controller.startListening();
      expect(controller.phase, ReadingPhase.listening);

      // What happens in a real session: the child goes quiet, the platform
      // closes the session, and nobody taps anything.
      speech.simulateSilenceTimeout();
      await pumpEventQueue();

      expect(controller.phase, ReadingPhase.finished);
      expect(wallet.balance, const Jkd(55));
    });

    test('a second finish call cannot pay twice', () async {
      final wallet = WalletState();
      final speech = FakeSpeechService(transcript: 'The cat sat');
      final controller = build(speech: speech, wallet: wallet);

      await controller.startListening();
      await controller.finishAndScore();
      speech.simulateSilenceTimeout();
      await controller.finishAndScore();
      await pumpEventQueue();

      expect(wallet.balance, const Jkd(55));
      expect(wallet.history, hasLength(1));
    });
  });

  group('microphone permission', () {
    test('denied access reports an error and does not listen', () async {
      final permissions = FakePermissionService(MicrophoneAccess.denied);
      final speech = FakeSpeechService(transcript: 'The cat sat');
      final controller = build(speech: speech, permissions: permissions);

      await controller.startListening();

      expect(controller.error, ReadingError.microphoneDenied);
      expect(controller.phase, ReadingPhase.ready);
      expect(permissions.requestCalls, 1);
      expect(speech.listenCalls, 0);
    });

    test('granted after prompting proceeds normally', () async {
      final permissions = FakePermissionService(
        MicrophoneAccess.denied,
        statusAfterRequest: MicrophoneAccess.granted,
      );
      final controller = build(permissions: permissions);

      await controller.startListening();

      expect(controller.error, isNull);
      expect(controller.phase, ReadingPhase.listening);
    });

    test('switched off in system settings does not re-prompt', () async {
      final permissions =
          FakePermissionService(MicrophoneAccess.permanentlyDenied);
      final controller = build(permissions: permissions);

      await controller.startListening();

      expect(controller.error, ReadingError.microphonePermanentlyDenied);
      // Prompting again would silently do nothing, so the app must not pretend
      // it tried.
      expect(permissions.requestCalls, 0);
    });

    test('device policy restrictions are treated as unfixable in-app', () async {
      final permissions =
          FakePermissionService(MicrophoneAccess.restricted);
      final controller = build(permissions: permissions);

      await controller.startListening();

      expect(controller.error, ReadingError.microphonePermanentlyDenied);
    });
  });

  group('recogniser problems', () {
    test('no recogniser on the device is reported clearly', () async {
      final controller = build(
        speech: FakeSpeechService(failure: SpeechFailure.recogniserUnavailable),
      );

      await controller.startListening();

      expect(controller.error, ReadingError.recogniserUnavailable);
      expect(controller.phase, ReadingPhase.ready);
    });

    test('a missing language pack is reported separately from no recogniser',
        () async {
      final controller = build(
        speech: FakeSpeechService(failure: SpeechFailure.localeUnavailable),
      );

      await controller.startListening();

      expect(controller.error, ReadingError.localeUnavailable);
    });

    test('nothing heard pays nothing', () async {
      final wallet = WalletState();
      final controller = build(
        speech: FakeSpeechService(transcript: '   '),
        wallet: wallet,
      );

      await controller.startListening();
      await controller.finishAndScore();

      expect(controller.error, ReadingError.nothingHeard);
      expect(controller.phase, ReadingPhase.ready);
      expect(wallet.balance, Jkd.zero);
      expect(wallet.history, isEmpty);
    });
  });

  group('recovery', () {
    test('retry returns to a clean slate', () async {
      final controller = build();

      await controller.startListening();
      await controller.finishAndScore();
      expect(controller.phase, ReadingPhase.finished);

      controller.retry();

      expect(controller.phase, ReadingPhase.ready);
      expect(controller.result, isNull);
      expect(controller.liveTranscript, isEmpty);
    });

    test('cancelling abandons the attempt without paying', () async {
      final wallet = WalletState();
      final speech = FakeSpeechService(transcript: 'The cat sat');
      final controller = build(speech: speech, wallet: wallet);

      await controller.startListening();
      await controller.cancelListening();

      expect(controller.phase, ReadingPhase.ready);
      expect(speech.cancelled, isTrue);
      expect(wallet.balance, Jkd.zero);
    });

    test('a second start while listening is ignored', () async {
      final speech = FakeSpeechService(transcript: 'The cat sat');
      final controller = build(speech: speech);

      await controller.startListening();
      await controller.startListening();

      expect(speech.listenCalls, 1);
    });
  });
}
