import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/services/scoring/text_utils.dart';

void main() {
  group('tokenize (word mode)', () {
    test('reconstructs the original text exactly', () {
      const text = 'The cat sat on the mat. "Good!" she said.';
      final tokens = tokenize(text, TokenMode.word);

      expect(tokens.map((t) => t.display).join(), text);
    });

    test('marks only real words as gradeable', () {
      final tokens = tokenize('Hi, world!', TokenMode.word);
      final words = tokens.where((t) => t.isWord).map((t) => t.display);

      expect(words, ['Hi', 'world']);
    });

    test('keeps contractions and hyphenated words whole', () {
      final words = tokenize(
        "I don't like well-known songs.",
        TokenMode.word,
      ).where((t) => t.isWord).map((t) => t.normalized).toList();

      expect(words, ['i', 'dont', 'like', 'wellknown', 'songs']);
    });

    test('handles empty input', () {
      expect(tokenize('', TokenMode.word), isEmpty);
    });
  });

  group('tokenize (character mode)', () {
    test('grades one Han character at a time', () {
      final words = tokenize('我爱学校', TokenMode.character)
          .where((t) => t.isWord)
          .map((t) => t.display)
          .toList();

      expect(words, ['我', '爱', '学', '校']);
    });

    test('reconstructs Chinese text including punctuation', () {
      const text = '老师说：“很好！”';
      final tokens = tokenize(text, TokenMode.character);

      expect(tokens.map((t) => t.display).join(), text);
    });

    test('treats a Latin run inside Chinese as one unit', () {
      final words = tokenize('我喜欢 ABC 歌', TokenMode.character)
          .where((t) => t.isWord)
          .map((t) => t.display)
          .toList();

      expect(words, ['我', '喜', '欢', 'ABC', '歌']);
    });
  });

  group('normalizeToken', () {
    test('lower-cases and strips punctuation', () {
      expect(normalizeToken('Garden,'), 'garden');
      expect(normalizeToken('“很好！”'), '很好');
    });
  });

  group('similarity', () {
    test('is 1.0 for identical strings', () {
      expect(similarity('reading', 'reading'), 1.0);
    });

    test('scores a one-letter slip highly', () {
      expect(similarity('garden', 'gardan'), closeTo(0.833, 0.01));
    });

    test('scores unrelated words low', () {
      // Not zero: normalised edit distance still gives partial credit for
      // shared letters. What matters is that it sits well below the
      // "mispronounced" floor, so unrelated words land as misses.
      expect(similarity('cat', 'elephant'), lessThan(0.4));
    });

    test('is 0.0 when either side is empty', () {
      expect(similarity('', 'cat'), 0.0);
      expect(similarity('cat', ''), 0.0);
    });
  });

  group('levenshtein', () {
    test('counts single edits', () {
      expect(levenshtein('cat', 'cat'), 0);
      expect(levenshtein('cat', 'cats'), 1);
      expect(levenshtein('cat', 'cut'), 1);
      expect(levenshtein('cat', 'bat'), 1);
    });

    test('handles empty strings', () {
      expect(levenshtein('', 'abc'), 3);
      expect(levenshtein('abc', ''), 3);
    });
  });
}
