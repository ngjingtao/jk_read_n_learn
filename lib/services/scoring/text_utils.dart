import 'dart:math' as math;

import '../../models/app_language.dart';
import '../../models/scoring_models.dart';

/// Word-ish run: letters/numbers, optionally joined by apostrophes or hyphens.
/// Keeps `don't` and `well-known` as single reading units.
final RegExp _wordRun = RegExp(
  r"[\p{L}\p{N}]+(?:['\u2019\-][\p{L}\p{N}]+)*",
  unicode: true,
);

/// A single Han character. Each one is its own gradeable unit for Chinese.
final RegExp _hanCharacter = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');

/// Characters removed when building the comparison form of a token.
///
/// Deliberately aggressive: anything that is not a letter, digit or Han
/// character is dropped. The tokenizer already excludes punctuation, but
/// `normalizeToken` is public and is also fed raw recogniser output, so it must
/// survive being handed `"Garden,"` or `"garden."` directly.
final RegExp _nonAlphanumeric = RegExp(r'[^\p{L}\p{N}]', unicode: true);

/// Splits [text] into renderable tokens according to [mode].
///
/// The returned list always reconstructs the original string when the
/// [EssayToken.display] values are concatenated, because gaps between words are
/// emitted as filler tokens. That lets the reader screen paint real text with
/// per-word tap targets instead of a synthetic word grid.
List<EssayToken> tokenize(String text, TokenMode mode) {
  if (text.isEmpty) return const [];

  final matcher = mode == TokenMode.character
      ? RegExp('${_hanCharacter.pattern}|${_wordRun.pattern}', unicode: true)
      : _wordRun;

  final tokens = <EssayToken>[];
  var cursor = 0;

  for (final match in matcher.allMatches(text)) {
    if (match.start > cursor) {
      tokens.add(EssayToken.filler(text.substring(cursor, match.start)));
    }
    final raw = match.group(0)!;
    tokens.add(
      EssayToken(
        display: raw,
        normalized: normalizeToken(raw),
        isWord: true,
      ),
    );
    cursor = match.end;
  }

  if (cursor < text.length) {
    tokens.add(EssayToken.filler(text.substring(cursor)));
  }

  return List.unmodifiable(tokens);
}

/// Builds the comparison form of a token: lower-cased, with punctuation that
/// should not affect grading removed.
///
/// Both the essay text and the recogniser output pass through this, so the two
/// sides are normalised identically.
String normalizeToken(String raw) {
  return raw.toLowerCase().replaceAll(_nonAlphanumeric, '');
}

/// Convenience: only the gradeable words/characters of [text], normalised.
List<String> normalizeWords(String text, TokenMode mode) {
  return tokensToWords(tokenize(text, mode));
}

/// Extracts the normalised comparison forms from tokenizer output.
List<String> tokensToWords(List<EssayToken> tokens) {
  return [
    for (final token in tokens)
      if (token.isWord) token.normalized,
  ];
}

/// Character-level similarity of two normalised tokens, `0.0` – `1.0`.
///
/// This is what lets a near-miss earn partial credit. It is a pure text
/// comparison: it cannot hear that "fink" and "think" are a common childhood
/// substitution. Swapping this out for a phoneme-based score is the single
/// highest-value future upgrade — see `docs/ROADMAP.md`.
double similarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;

  final distance = levenshtein(a, b);
  return 1 - distance / math.max(a.length, b.length);
}

/// Standard Levenshtein edit distance.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (j) => j);

  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      current[j] = math.min(substitution, math.min(deletion, insertion));
    }
    previous = current;
  }

  return previous[b.length];
}
