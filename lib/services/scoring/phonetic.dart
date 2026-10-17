/// A heuristic spelling-to-sound skeleton for English words.
///
/// ## What this is, and what it is not
///
/// This is **not** a real grapheme-to-phoneme model. It is a small, conservative
/// set of rewrites that collapse the ways English spells the *same sound*, so
/// that two spellings of one sound compare as equal.
///
/// It exists because speech recognisers do not agree with essay authors on
/// spelling. A child reading the word `night` may come back from the recogniser
/// as `night`, `nite`, or `Night!`. Marking that child wrong for `nite` is
/// indefensible — they read the word perfectly.
///
/// A rule set this small was chosen deliberately. Aggressive rules (merging all
/// vowel digraphs, for instance) would make genuinely different words compare as
/// equal, which produces *false* full marks — a far worse failure than a
/// near-miss losing partial credit, because it tells a child they read something
/// correctly when they did not.
///
/// Real phoneme-level scoring (Azure Speech pronunciation assessment, or an
/// on-device forced aligner) is the proper fix. See `docs/ROADMAP.md` Phase 3.
library;

/// Rewrites applied longest-first. Every entry maps a spelling to a sound, not a
/// spelling to another spelling.
///
/// Only high-confidence, single-sound spellings are listed:
/// * `ph` / `f` — always the same sound.
/// * `ck` / `k`, `qu` / `kw` — always the same sound.
/// * `igh` — `night`, `light`, `right`.
/// * `tion` — `nation`, `station`.
/// * `ch`, `sh`, `th`, `ng` — present so the single-letter `c` rule below
///   cannot corrupt them (`chin` must not become `khin`).
const Map<String, String> _rewrites = {
  'tion': 'shun',
  'tch': 'ch',
  'igh': 'i',
  'ph': 'f',
  'ck': 'k',
  'ch': 'ch',
  'sh': 'sh',
  'th': 'th',
  'wh': 'w',
  'qu': 'kw',
  'ng': 'ng',
};

/// Longest key length in [_rewrites], so the scanner knows where to start.
const int _maxRewriteLength = 4;

/// Doubled *consonants* collapse: `letter` and `leter` are the same word.
///
/// Vowels are excluded on purpose. Collapsing them would merge `meet` with
/// `met` and `soon` with `son`, which are different words.
final RegExp _doubledConsonants = RegExp(r'([bcdfghjklmnpqrstvwxyz])\1+');

final RegExp _nonLetters = RegExp(r'[^a-z]');

const String _vowels = 'aeiou';

bool _isVowel(String ch) => _vowels.contains(ch);

/// Reduces [word] to a sound skeleton, or `''` when there is nothing to compare.
///
/// Both the essay word and the recognised word must pass through this before
/// being compared — consistency is what makes the comparison meaningful, not the
/// accuracy of any individual rule.
String phoneticKey(String word) {
  var w = word.toLowerCase().replaceAll(_nonLetters, '');
  if (w.isEmpty) return '';

  // Doubled consonants first, so the rewrites see the simpler form.
  w = w.replaceAllMapped(_doubledConsonants, (match) => match.group(1)!);

  // A final silent `e`: `phone` -> `phon`. Guarded by length so that `the`,
  // `he` and `be` are left alone — their `e` is the whole vowel.
  if (w.length >= 4 && w.endsWith('e') && !_isVowel(w[w.length - 2])) {
    w = w.substring(0, w.length - 1);
  }

  final out = StringBuffer();
  var i = 0;

  while (i < w.length) {
    var rewritten = false;

    for (var length = _maxRewriteLength; length >= 2; length--) {
      if (i + length > w.length) continue;
      final chunk = w.substring(i, i + length);
      final replacement = _rewrites[chunk];
      if (replacement != null) {
        out.write(replacement);
        i += length;
        rewritten = true;
        break;
      }
    }
    if (rewritten) continue;

    final ch = w[i];
    final isLast = i == w.length - 1;

    if (ch == 'c') {
      // Real rule: `c` is soft before e, i, y — `city`, `cent`, `cycle`.
      final next = isLast ? '' : w[i + 1];
      out.write('eiy'.contains(next) ? 's' : 'k');
    } else if (ch == 'x') {
      out.write('ks');
    } else if (ch == 'q') {
      out.write('k');
    } else if (ch == 'y' && isLast) {
      // Final `y` is a vowel sound: `happy` -> `happi`.
      out.write('i');
    } else {
      out.write(ch);
    }

    i++;
  }

  return out.toString();
}
