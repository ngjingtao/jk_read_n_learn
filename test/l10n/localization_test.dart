import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jkreadnlearn/l10n/generated/app_localizations.dart';
import 'package:jkreadnlearn/models/app_language.dart';
import 'package:jkreadnlearn/ui/l10n_extensions.dart';

/// Loads the generated strings for [locale], exactly as MaterialApp does.
Future<AppLocalizations> load(Locale locale) =>
    AppLocalizations.delegate.load(locale);

void main() {
  test('every declared locale can be loaded', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await load(locale);
      expect(l10n.appTitle, isNotEmpty, reason: 'empty title for $locale');
    }
  });

  group('translations are real, not English placeholders', () {
    // Keys where a copy-paste of the English string would mean an untranslated
    // screen. Language *names* are excluded on purpose: "English" is correctly
    // "English" in every language.
    const mustDiffer = <String>[
      'homeGreeting',
      'actionListen',
      'actionReadAloud',
      'settingsTitle',
      'walletTitle',
      'resultTitle',
      'gradeOutstanding',
    ];

    Future<Map<String, String>> stringsFor(Locale locale) async {
      final l10n = await load(locale);
      return {
        'homeGreeting': l10n.homeGreeting,
        'actionListen': l10n.actionListen,
        'actionReadAloud': l10n.actionReadAloud,
        'settingsTitle': l10n.settingsTitle,
        'walletTitle': l10n.walletTitle,
        'resultTitle': l10n.resultTitle,
        'gradeOutstanding': l10n.gradeOutstanding,
      };
    }

    test('Chinese differs from English', () async {
      final english = await stringsFor(const Locale('en'));
      final chinese = await stringsFor(const Locale('zh'));

      for (final key in mustDiffer) {
        expect(
          chinese[key],
          isNot(english[key]),
          reason: '$key was left in English in the Chinese translation',
        );
      }
    });

    test('Malay differs from English', () async {
      final english = await stringsFor(const Locale('en'));
      final malay = await stringsFor(const Locale('ms'));

      for (final key in mustDiffer) {
        expect(
          malay[key],
          isNot(english[key]),
          reason: '$key was left in English in the Malay translation',
        );
      }
    });
  });

  group('essay meta line', () {
    test('pluralises correctly in English', () async {
      final l10n = await load(const Locale('en'));

      expect(l10n.unitFor(TokenMode.word, 1), '1 word');
      expect(l10n.unitFor(TokenMode.word, 42), '42 words');
      expect(l10n.unitFor(TokenMode.character, 1), '1 character');
      expect(l10n.unitFor(TokenMode.character, 42), '42 characters');
    });

    test('uses the right unit for Chinese characters', () async {
      final l10n = await load(const Locale('zh'));

      expect(l10n.unitFor(TokenMode.character, 42), '42 个字');
      // Chinese has no plural form, so the word unit reads the same.
      expect(l10n.unitFor(TokenMode.word, 42), '42 个字');
    });

    test('uses separate units for words and characters in Malay', () async {
      final l10n = await load(const Locale('ms'));

      expect(l10n.unitFor(TokenMode.word, 42), '42 perkataan');
      expect(l10n.unitFor(TokenMode.character, 42), '42 aksara');
    });

    test('grade labels resolve in every locale', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await load(locale);
        for (final language in ReadingLanguage.values) {
          expect(l10n.readingLanguageName(language), isNotEmpty);
        }
      }
    });
  });
}
