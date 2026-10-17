import '../../models/app_language.dart';
import 'phonetic.dart';
import 'text_utils.dart' as text;

/// Decides how similar two words are for the purposes of marking.
///
/// Swappable so the marking engine does not have to be rewritten when a real
/// pronunciation-assessment API arrives — see `docs/ROADMAP.md` Phase 3.
abstract interface class TokenComparator {
  /// Similarity of two already-normalised words, `0.0` – `1.0`.
  ///
  /// `1.0` means "the child read this word correctly".
  double similarity(String a, String b);
}

/// Compares the words as written.
///
/// Correct for Chinese, where a character is a meaning unit rather than a
/// spelling of a sound, and for Malay, which is already close to phonetic —
/// `buku` is read exactly as written, so a sound skeleton would add nothing.
class OrthographicComparator implements TokenComparator {
  const OrthographicComparator();

  @override
  double similarity(String a, String b) => text.similarity(a, b);
}

/// Compares how the words *sound*, via [phoneticKey].
///
/// The win is spelling variation: `nite` for `night`, `fone` for `phone`,
/// `colour` for `color`, `kat` for `cat`. All of those are the same reading, and
/// a child should not lose marks for any of them.
///
/// The risk is over-merging. Conservative rules keep it in check; see
/// `phonetic.dart` for why that trade was made in this direction.
class PhoneticComparator implements TokenComparator {
  const PhoneticComparator();

  @override
  double similarity(String a, String b) {
    final keyA = phoneticKey(a);
    final keyB = phoneticKey(b);

    // If either word reduces to nothing, fall back rather than declaring a
    // match on two empty strings.
    if (keyA.isEmpty || keyB.isEmpty) return text.similarity(a, b);

    return text.similarity(keyA, keyB);
  }
}

/// The comparator appropriate to [language].
///
/// Chosen per language rather than globally, because "as written" and "as it
/// sounds" are the right question in different languages.
TokenComparator comparatorFor(ReadingLanguage language) => switch (language) {
      ReadingLanguage.english => const PhoneticComparator(),
      ReadingLanguage.chinese => const OrthographicComparator(),
      ReadingLanguage.malay => const OrthographicComparator(),
    };
