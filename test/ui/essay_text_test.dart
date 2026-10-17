import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/models/scoring_models.dart';
import 'package:jkreadnlearn/ui/widgets/essay_text.dart';

/// Pulls the flat list of spans out of the rendered `Text.rich`.
List<TextSpan> _spansOf(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text));
  final root = text.textSpan! as TextSpan;
  return root.children!.cast<TextSpan>();
}

Future<void> _pump(
  WidgetTester tester, {
  required String text,
  ReadingLanguage language = ReadingLanguage.english,
  List<WordStatus>? statuses,
  ValueChanged<String>? onWordTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EssayText(
          text: text,
          language: language,
          statuses: statuses,
          onWordTap: onWordTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the passage exactly, punctuation included',
      (tester) async {
    const text = 'The cat sat.';
    await _pump(tester, text: text);

    final rendered = _spansOf(tester).map((s) => s.text).join();

    expect(rendered, text);
  });

  testWidgets('makes words tappable but leaves punctuation inert',
      (tester) async {
    await _pump(tester, text: 'The cat.', onWordTap: (_) {});

    final spans = _spansOf(tester);
    final wordSpans = spans.where((s) => s.text != ' ' && s.text != '.');
    final punctuationSpans = spans.where((s) => s.text == '.');

    expect(wordSpans.every((s) => s.recognizer != null), isTrue);
    expect(punctuationSpans.single.recognizer, isNull);
  });

  testWidgets('reports the tapped word using its on-screen form',
      (tester) async {
    final tapped = <String>[];
    await _pump(tester, text: 'The cat sat.', onWordTap: tapped.add);

    final catSpan = _spansOf(tester).firstWhere((s) => s.text == 'cat');
    (catSpan.recognizer! as TapGestureRecognizer).onTap!();

    expect(tapped, ['cat']);
  });

  testWidgets('colours each word according to its status', (tester) async {
    await _pump(
      tester,
      text: 'The cat sat.',
      statuses: const [
        WordStatus.correct,
        WordStatus.missed,
        WordStatus.mispronounced,
      ],
    );

    final spans = _spansOf(tester);
    final correct = spans.firstWhere((s) => s.text == 'The');
    final missed = spans.firstWhere((s) => s.text == 'cat');
    final close = spans.firstWhere((s) => s.text == 'sat');

    expect(correct.style!.backgroundColor, const Color(0xFFC8E6C9));
    expect(missed.style!.backgroundColor, const Color(0xFFFFCDD2));
    expect(close.style!.backgroundColor, const Color(0xFFFFE0B2));
  });

  testWidgets('grades Chinese one character at a time', (tester) async {
    final tapped = <String>[];
    await _pump(
      tester,
      text: '我爱学校',
      language: ReadingLanguage.chinese,
      onWordTap: tapped.add,
    );

    final spans = _spansOf(tester);
    expect(spans.map((s) => s.text).toList(), ['我', '爱', '学', '校']);

    (spans[2].recognizer! as TapGestureRecognizer).onTap!();
    expect(tapped, ['学']);
  });

  testWidgets('does not attach tap handlers when no callback is given',
      (tester) async {
    await _pump(tester, text: 'The cat sat.');

    expect(_spansOf(tester).every((s) => s.recognizer == null), isTrue);
  });
}
