import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/app_language.dart';
import '../../models/scoring_models.dart';
import '../../services/scoring/text_utils.dart';

/// Renders a passage with every word individually tappable.
///
/// Punctuation and spacing are painted as plain text and are not tappable, so
/// the passage looks exactly like a printed page rather than a word grid. When
/// [statuses] is supplied the passage is also colour-coded for feedback.
class EssayText extends StatefulWidget {
  const EssayText({
    super.key,
    required this.text,
    required this.language,
    this.onWordTap,
    this.statuses,
    this.fontSize,
    this.lineHeight = 1.9,
    this.highlight = true,
  });

  final String text;
  final ReadingLanguage language;

  /// Called with the on-screen form of a tapped word, punctuation included.
  final ValueChanged<String>? onWordTap;

  /// Feedback per gradeable word, indexed by word ordinal within [text].
  final List<WordStatus>? statuses;

  final double? fontSize;

  /// Multiplier applied to the font size, as Flutter's `TextStyle.height`.
  ///
  /// Passed in rather than read from `SettingsState` so the widget stays usable
  /// without a provider above it — which is what lets it be widget-tested on its
  /// own, and is why the reading-comfort settings can be tested at all.
  final double lineHeight;

  /// Whether to paint status backgrounds. Turn off for a neutral re-read.
  final bool highlight;

  @override
  State<EssayText> createState() => _EssayTextState();
}

class _EssayTextState extends State<EssayText> {
  /// Tap recognisers must be owned and disposed by a stateful widget. Creating
  /// them inline in `build` leaks them on every rebuild.
  final List<TapGestureRecognizer> _recognisers = [];

  @override
  void dispose() {
    _disposeRecognisers();
    super.dispose();
  }

  void _disposeRecognisers() {
    for (final recogniser in _recognisers) {
      recogniser.dispose();
    }
    _recognisers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognisers();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Chinese characters need a larger size than Latin text to be as legible.
    final baseFontSize = widget.fontSize ??
        (widget.language.tokenMode == TokenMode.character ? 28.0 : 24.0);

    final tokens = tokenize(widget.text, widget.language.tokenMode);

    final spans = <InlineSpan>[];
    var wordOrdinal = 0;

    for (final token in tokens) {
      if (!token.isWord) {
        spans.add(TextSpan(text: token.display));
        continue;
      }

      final status = (widget.statuses != null &&
              wordOrdinal < widget.statuses!.length)
          ? widget.statuses![wordOrdinal]
          : null;
      wordOrdinal++;

      TapGestureRecognizer? recogniser;
      if (widget.onWordTap != null) {
        recogniser = TapGestureRecognizer()
          ..onTap = () => widget.onWordTap!(token.display);
        _recognisers.add(recogniser);
      }

      spans.add(
        TextSpan(
          text: token.display,
          recognizer: recogniser,
          style: _wordStyle(
            base: TextStyle(fontSize: baseFontSize, height: widget.lineHeight),
            status: widget.highlight ? status : null,
            scheme: scheme,
            tappable: widget.onWordTap != null,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: baseFontSize,
        height: widget.lineHeight,
        color: scheme.onSurface,
      ),
    );
  }

  TextStyle _wordStyle({
    required TextStyle base,
    required WordStatus? status,
    required ColorScheme scheme,
    required bool tappable,
  }) {
    switch (status) {
      case WordStatus.correct:
        return base.copyWith(
          backgroundColor: const Color(0xFFC8E6C9),
          color: const Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
        );
      case WordStatus.mispronounced:
        return base.copyWith(
          backgroundColor: const Color(0xFFFFE0B2),
          color: const Color(0xFF8A4B00),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFE65100),
        );
      case WordStatus.missed:
        return base.copyWith(
          backgroundColor: const Color(0xFFFFCDD2),
          color: const Color(0xFFB71C1C),
          decoration: TextDecoration.lineThrough,
          decorationColor: const Color(0xFFB71C1C),
        );
      case WordStatus.extra:
      case null:
        if (!tappable) return base;
        // A dotted hint that words can be tapped, without looking like a link.
        return base.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: scheme.outline,
        );
    }
  }
}
