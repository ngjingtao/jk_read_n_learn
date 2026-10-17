import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/app_language.dart';
import '../models/reward.dart';
import '../models/scoring_models.dart';
import '../services/voice_separator.dart';
import '../state/reading_session_controller.dart';
import '../state/settings_state.dart';

/// Formats a date for the wallet ledger in the active interface language.
///
/// Falls back to the default locale if `intl` has no date symbols for the
/// requested one, so a missing locale degrades to a readable date rather than
/// throwing inside a list builder.
String formatShortDate(DateTime date, String localeName) {
  try {
    return DateFormat.yMMMd(localeName).format(date);
  } catch (_) {
    return DateFormat.yMMMd().format(date);
  }
}

/// Bridges the domain layer to the interface language.
///
/// This is the only place that knows how a [ScoreGrade], a [ReadingError] or a
/// voice strategy turns into words on screen. Keeping the mapping here means the
/// models stay language-free, which is what lets the grading engine be tested
/// without any localisation at all.
extension AppLocalizationsX on AppLocalizations {
  /// Display name for a passage language, in the interface language.
  String readingLanguageName(ReadingLanguage language) => switch (language) {
        ReadingLanguage.english => languageEnglish,
        ReadingLanguage.chinese => languageChinese,
        ReadingLanguage.malay => languageMalay,
      };

  /// Display name for an interface language, in the interface language.
  ///
  /// Each name is written in its own script, so a parent who has landed in the
  /// wrong language can still find their way out.
  String uiLanguageName(UiLanguage language) => switch (language) {
        UiLanguage.english => languageEnglish,
        UiLanguage.chinese => languageChinese,
        UiLanguage.malay => languageMalay,
      };

  /// Gradeable unit for a passage, pluralised for [count].
  String unitFor(TokenMode mode, int count) => mode == TokenMode.character
      ? unitCharacters(count)
      : unitWords(count);

  String gradeLabel(ScoreGrade grade) => switch (grade) {
        ScoreGrade.outstanding => gradeOutstanding,
        ScoreGrade.great => gradeGreat,
        ScoreGrade.good => gradeGood,
        ScoreGrade.keepPractising => gradeKeepPractising,
        ScoreGrade.tryAgain => gradeTryAgain,
      };

  String readingError(ReadingError error, ReadingLanguage language) =>
      switch (error) {
        ReadingError.nothingHeard => errorNothingHeard,
        ReadingError.recogniserUnavailable => errorRecogniserUnavailable,
        ReadingError.localeUnavailable =>
          errorLocaleUnavailable(readingLanguageName(language)),
        ReadingError.microphoneDenied => errorPermissionDenied,
        ReadingError.microphonePermanentlyDenied =>
          errorPermissionPermanentlyDenied,
        ReadingError.engineFailed => errorEngineFailed,
      };

  /// Whether [error] is something only the device settings can resolve.
  ///
  /// Drives whether the error banner offers a button to open them.
  bool errorNeedsSystemSettings(ReadingError error) =>
      error == ReadingError.microphonePermanentlyDenied;

  /// Localised name for a voice-isolation strategy.
  ///
  /// Falls back to whatever the separator calls itself, so a strategy that
  /// arrives later still shows something sensible before it is translated.
  String voiceStrategyName(VoiceSeparator separator) =>
      switch (separator.id) {
        'passthrough' => voiceStrategyPassthroughName,
        _ => separator.displayName,
      };

  String voiceStrategyDescription(VoiceSeparator separator) =>
      switch (separator.id) {
        'passthrough' => voiceStrategyPassthroughDescription,
        _ => separator.description,
      };

  /// Display name for a reward.
  ///
  /// Falls back to the raw id, which is ugly but visible — an untranslated
  /// reward should be obvious in review rather than silently showing English.
  String rewardName(Reward reward) => switch (reward.id) {
        'star' => rewardStar,
        'heart' => rewardHeart,
        'rocket' => rewardRocket,
        'rainbow' => rewardRainbow,
        'panda' => rewardPanda,
        'dragon' => rewardDragon,
        'crown' => rewardCrown,
        'trophy' => rewardTrophy,
        _ => reward.id,
      };

  /// Display name for a reward id from the ledger, where the catalogue may no
  /// longer contain it.
  String rewardNameById(String id) {
    final reward = rewardById(id);
    return reward == null ? id : rewardName(reward);
  }

  String textSizeName(TextSize size) => switch (size) {
        TextSize.small => settingsTextSizeSmall,
        TextSize.normal => settingsTextSizeNormal,
        TextSize.large => settingsTextSizeLarge,
        TextSize.extraLarge => settingsTextSizeExtraLarge,
      };

  String lineSpacingName(LineSpacing spacing) => switch (spacing) {
        LineSpacing.normal => settingsLineSpacingNormal,
        LineSpacing.wide => settingsLineSpacingWide,
        LineSpacing.extraWide => settingsLineSpacingExtraWide,
      };
}
