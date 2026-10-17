import '../../models/app_language.dart';
import 'text_utils.dart';

/// Builds an approximate per-word confidence from a stream of partial
/// recognition results.
///
/// ## Why this exists
///
/// The single worst failure of text-based marking is that modern recognisers
/// *auto-correct*. A child says "fink", the recogniser returns "think", and the
/// app awards full marks for a word they mispronounced. The transcript cannot
/// show this. The recogniser's own confidence can: it reports high confidence
/// for words it heard clearly and low confidence when it had to guess.
///
/// ## Why it is approximate, and honest about it
///
/// `speech_to_text` reports confidence **per utterance**, not per word. So this
/// class does the only reasonable thing available: it watches the transcript
/// grow and, each time a new word appears, records the confidence reported in
/// that update. A word's score is therefore "how sure was the recogniser when
/// this word showed up".
///
/// That is a proxy, not a measurement. It must be calibrated against a real
/// device before anyone trusts the threshold — see `docs/ROADMAP.md` Phase 3.
///
/// ## It fails safe
///
/// When the platform reports no confidence (a value of -1 in `speech_to_text`),
/// every entry stays `null` and the scorer produces no "unclear" words at all.
/// A device without confidence ratings therefore behaves exactly as it did
/// before this existed.
class ConfidenceTracker {
  ConfidenceTracker({required this.mode});

  /// How the language's text is split, so the tracker and the scorer agree on
  /// word boundaries. If they disagreed, the confidences would line up with the
  /// wrong words.
  final TokenMode mode;

  final List<double?> _byWord = [];
  List<String> _lastWords = const [];

  /// Confidence per spoken word, in reading order. `null` where unknown.
  List<double?> get confidences => List.unmodifiable(_byWord);

  /// How many spoken words have been seen.
  int get length => _byWord.length;

  /// Whether the platform has supplied any usable confidence value.
  ///
  /// `false` means the caller should behave as if this class did not exist.
  bool get hasAnyConfidence => _byWord.any(_isUsable);

  /// Feeds one partial result, in the order they arrived.
  ///
  /// [confidence] may be `null` when the platform does not rate its output.
  void add(String transcript, double? confidence) {
    final words = normalizeWords(transcript, mode);

    // Partial results revise the tail of the transcript, so anything from the
    // first point of divergence onwards has to be re-scored.
    var common = 0;
    while (common < words.length &&
        common < _lastWords.length &&
        words[common] == _lastWords[common]) {
      common++;
    }

    if (_byWord.length > common) {
      _byWord.removeRange(common, _byWord.length);
    }
    for (var i = common; i < words.length; i++) {
      _byWord.add(_sanitise(confidence));
    }

    _lastWords = words;
  }

  /// Confidence for spoken word [index], or `null` when unknown.
  double? confidenceAt(int index) {
    if (index < 0 || index >= _byWord.length) return null;
    final value = _byWord[index];
    return _isUsable(value) ? value : null;
  }

  /// `speech_to_text` uses -1 for "not available". Anything outside 0–1 is
  /// treated as absent rather than being clamped, because a nonsensical value
  /// means the platform is not rating this result, not that it is unsure.
  static double? _sanitise(double? value) {
    if (value == null) return null;
    if (value < 0 || value > 1) return null;
    return value;
  }

  static bool _isUsable(double? value) => value != null && value >= 0 && value <= 1;
}
