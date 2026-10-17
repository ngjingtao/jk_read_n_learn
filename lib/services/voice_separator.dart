/// Extension point for isolating the child's voice from other speakers.
///
/// Why this exists: a child practising at home is usually not alone. A parent
/// or teacher reads along, a sibling talks, a television plays. If that audio
/// reaches the recogniser, the transcript fills up with words the child never
/// said and the marks are wrong.
///
/// Filtering is a genuinely hard signal-processing problem, so v1 does the
/// honest thing: it defines the seam, does no filtering, and tells the parent
/// plainly that it is hearing raw microphone audio. Everything here is a real
/// abstraction that a DSP implementation can slot into without touching the
/// scoring code.
///
/// See `docs/VOICE_ISOLATION.md` for the planned implementations.
library;

/// Audio handed to a separator.
///
/// Deliberately minimal for now. When a real separator lands it will carry
/// either a file path (batch separation) or PCM frames (streaming separation),
/// plus channel count — this is the single place that has to change.
class CapturedAudio {
  const CapturedAudio({
    required this.source,
    required this.sampleRateHz,
    required this.channels,
    this.filePath,
  });

  /// How the audio arrived.
  final AudioCaptureSource source;

  final int sampleRateHz;
  final int channels;

  /// Set when [source] is [AudioCaptureSource.file].
  final String? filePath;
}

enum AudioCaptureSource {
  /// Live microphone stream feeding the recogniser directly. This is what v1
  /// uses, and it is the source a streaming separator would filter.
  liveRecogniserStream,

  /// A recorded file, for batch separation and offline re-scoring.
  file,
}

/// Audio after a separation attempt.
class IsolatedAudio {
  const IsolatedAudio({
    required this.strategy,
    required this.didIsolate,
    this.filePath,
    this.confidence,
  });

  /// Identifier of the separator that produced this result.
  final String strategy;

  /// `false` when the audio passed through untouched.
  final bool didIsolate;

  final String? filePath;

  /// How confident the separator is that only the target speaker remains,
  /// `0.0` – `1.0`. `null` when no separation was attempted.
  final double? confidence;
}

/// A strategy for keeping only the target speaker's voice.
abstract class VoiceSeparator {
  /// Stable identifier, safe to persist.
  String get id;

  /// Name shown to a parent or teacher.
  String get displayName;

  /// One-line explanation of what the strategy actually does to the audio.
  String get description;

  /// Whether this separator can run on the current device right now.
  bool get isAvailable;

  /// Reduces [input] to the target speaker's voice where possible.
  ///
  /// [expectedSpeakers] lists speakers known to be present, e.g.
  /// `['child', 'teacher']`. Implementations may ignore it.
  Future<IsolatedAudio> isolate(
    CapturedAudio input, {
    List<String> expectedSpeakers = const [],
  });
}

/// The v1 behaviour: no filtering at all.
///
/// Named explicitly rather than left as a null, so the app can be honest with
/// the parent about what it is and is not doing.
class PassthroughVoiceSeparator implements VoiceSeparator {
  const PassthroughVoiceSeparator();

  @override
  String get id => 'passthrough';

  @override
  String get displayName => 'Raw microphone';

  @override
  String get description =>
      'No filtering. Every voice in the room can be picked up by the '
      'recogniser.';

  @override
  bool get isAvailable => true;

  @override
  Future<IsolatedAudio> isolate(
    CapturedAudio input, {
    List<String> expectedSpeakers = const [],
  }) async {
    return IsolatedAudio(
      strategy: id,
      didIsolate: false,
      filePath: input.filePath,
    );
  }
}

/// Holds the separators available to the app and picks the active one.
///
/// A real implementation registers itself at startup:
///
/// ```dart
/// registry.register(const OnDeviceSourceSeparation());
/// ```
///
/// and immediately becomes the default, because [register] puts it at the front.
/// Nothing else in the app needs to change.
class VoiceSeparationRegistry {
  VoiceSeparationRegistry({List<VoiceSeparator>? separators})
      : _separators = [...?separators, const PassthroughVoiceSeparator()];

  final List<VoiceSeparator> _separators;

  /// Every known separator, highest priority first. The last entry is always
  /// the passthrough fallback.
  List<VoiceSeparator> get available => List.unmodifiable(_separators);

  /// The separator a reading session will use.
  VoiceSeparator get active => _separators.firstWhere(
        (separator) => separator.isAvailable,
        orElse: () => const PassthroughVoiceSeparator(),
      );

  /// Adds [separator] as the new preferred strategy.
  void register(VoiceSeparator separator) => _separators.insert(0, separator);

  /// Looks up a separator by [id], or `null`.
  VoiceSeparator? byId(String id) {
    for (final separator in _separators) {
      if (separator.id == id) return separator;
    }
    return null;
  }
}
