// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JK Read n Learn';

  @override
  String get homeGreeting => 'What shall we read today?';

  @override
  String get homeSubtitle =>
      'Tap any word to hear it. Then read it out loud to earn JKD.';

  @override
  String unitWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'words',
      one: 'word',
    );
    return '$count $_temp0';
  }

  @override
  String unitCharacters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'characters',
      one: 'character',
    );
    return '$count $_temp0';
  }

  @override
  String standardLabel(int grade) {
    return 'Standard $grade';
  }

  @override
  String get actionListen => 'Listen';

  @override
  String get actionReadAloud => 'Read aloud';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionAllDone => 'All done';

  @override
  String get actionReadAgain => 'Read it again';

  @override
  String get actionBackToList => 'Back to my reading list';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get actionKeepIt => 'Keep it';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionStartListening => 'Start listening';

  @override
  String get actionStop => 'Stop';

  @override
  String listeningStatus(String time) {
    return 'Listening… $time';
  }

  @override
  String get iCanHear => 'I can hear:';

  @override
  String get markingInProgress => 'Marking your reading…';

  @override
  String get howListeningWorks => 'How listening works';

  @override
  String get micSheetTitle => 'What the microphone hears';

  @override
  String get micSheetBody =>
      'Right now the app marks whatever the microphone picks up, so a parent reading along or a television in the room can end up in the transcript. Voice filtering is planned.';

  @override
  String strategyLabel(String name) {
    return 'Strategy: $name';
  }

  @override
  String speechRecognitionStatus(String status) {
    return 'Speech recognition: $status';
  }

  @override
  String get statusAvailable => 'available';

  @override
  String get statusUnavailable => 'not available on this device';

  @override
  String get voiceStrategyPassthroughName => 'Raw microphone';

  @override
  String get voiceStrategyPassthroughDescription =>
      'No filtering. Every voice in the room can be picked up by the recogniser.';

  @override
  String get errorNothingHeard =>
      'I could not hear anything. Try reading a little louder.';

  @override
  String get errorRecogniserUnavailable =>
      'Speech recognition is not available on this device.';

  @override
  String errorLocaleUnavailable(String language) {
    return 'This device has no speech recogniser for $language. Install the language pack in system settings.';
  }

  @override
  String get errorEngineFailed =>
      'The voice engine could not start on this device.';

  @override
  String get errorPermissionDenied =>
      'JK Read n Learn needs the microphone to mark your reading. Allow it when asked, then try again.';

  @override
  String get errorPermissionPermanentlyDenied =>
      'Microphone access is switched off. Open your device settings, allow the microphone for JK Read n Learn, then come back.';

  @override
  String get resultTitle => 'Your marks';

  @override
  String get resultAccurate => 'accurate';

  @override
  String resultSummary(int correct, int total, int seconds) {
    return '$correct of $total words read correctly in ${seconds}s';
  }

  @override
  String resultWordsPerMinute(int wpm) {
    return '$wpm words per minute';
  }

  @override
  String resultEarned(String amount) {
    return 'You earned $amount';
  }

  @override
  String resultPoints(int points) {
    return '$points points';
  }

  @override
  String get labelCorrect => 'Read correctly';

  @override
  String get labelNearlyRight => 'Nearly right';

  @override
  String get labelMissed => 'Missed or wrong';

  @override
  String get labelExtra => 'Extra words added';

  @override
  String get resultHowYouReadIt => 'How you read it';

  @override
  String get resultColourLegend =>
      'Green is right, amber is close, red was skipped or said wrongly. Tap a word to hear it again.';

  @override
  String get extrasTitle => 'Words I heard that are not in the passage';

  @override
  String get extrasNote =>
      'If someone else was reading nearby, their voice may be picked up too. Voice filtering is coming.';

  @override
  String get gradeOutstanding => 'Outstanding';

  @override
  String get gradeGreat => 'Great reading';

  @override
  String get gradeGood => 'Good effort';

  @override
  String get gradeKeepPractising => 'Keep practising';

  @override
  String get gradeTryAgain => 'Try again';

  @override
  String get walletTitle => 'My JKD';

  @override
  String get walletCurrencyName => 'Jiong Ke Dollars';

  @override
  String get walletTagline => 'Earned by reading out loud.';

  @override
  String get walletHistory => 'History';

  @override
  String get walletEmpty =>
      'No rewards yet. Read a passage to earn your first JKD!';

  @override
  String get walletResetTitle => 'Start over?';

  @override
  String get walletResetBody =>
      'This clears the JKD balance and all reading history on this device.';

  @override
  String get walletResetTooltip => 'Start over';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsSoundAndSpeech => 'Sound and speech';

  @override
  String get settingsOnDeviceOnly => 'Use on-device recognition only';

  @override
  String get settingsOnDeviceOnlySubtitle =>
      'Better privacy: the voice never leaves the tablet. But on many devices the offline model for a language is missing, and listening will fail rather than fall back.';

  @override
  String get settingsHearingTest => 'Hearing test';

  @override
  String get settingsHearingTestSubtitle =>
      'Check that the microphone and the recogniser can hear you';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsComfort => 'Reading comfort';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextSizeSmall => 'Small';

  @override
  String get settingsTextSizeNormal => 'Normal';

  @override
  String get settingsTextSizeLarge => 'Large';

  @override
  String get settingsTextSizeExtraLarge => 'Extra large';

  @override
  String get settingsLineSpacing => 'Line spacing';

  @override
  String get settingsLineSpacingNormal => 'Normal';

  @override
  String get settingsLineSpacingWide => 'Wide';

  @override
  String get settingsLineSpacingExtraWide => 'Extra wide';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionSubtitle =>
      'Stops the pulsing listening indicator. The timer beside it still shows what is happening.';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get streakNone => 'Read today to start a streak';

  @override
  String streakBest(int days) {
    return 'Best: $days days';
  }

  @override
  String get streakTooltip => 'Days in a row you have read';

  @override
  String get shopTitle => 'Reward shop';

  @override
  String get shopSubtitle => 'Spend your JKD on stickers for your collection.';

  @override
  String get shopOwned => 'Owned';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopNotEnough => 'Not enough JKD yet';

  @override
  String get shopCollection => 'My collection';

  @override
  String get shopCollectionEmpty =>
      'Nothing collected yet. Read a passage, then come back.';

  @override
  String shopBought(String name) {
    return 'You bought $name';
  }

  @override
  String get rewardStar => 'Star';

  @override
  String get rewardHeart => 'Heart';

  @override
  String get rewardRocket => 'Rocket';

  @override
  String get rewardRainbow => 'Rainbow';

  @override
  String get rewardPanda => 'Panda';

  @override
  String get rewardDragon => 'Dragon';

  @override
  String get rewardCrown => 'Crown';

  @override
  String get rewardTrophy => 'Trophy';

  @override
  String get progressTitle => 'Your progress';

  @override
  String progressAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count times',
      one: 'Read once',
    );
    return '$_temp0';
  }

  @override
  String progressBestAccuracy(int percent) {
    return 'Best: $percent%';
  }

  @override
  String progressBestSpeed(int wpm) {
    return 'Best speed: $wpm words per minute';
  }

  @override
  String get progressNewRecord => 'A new best for this passage!';

  @override
  String get progressNever => 'Not read yet';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get diagnosticsTitle => 'Hearing test';

  @override
  String get diagnosticsIntro =>
      'Read the sentences below out loud, then check that the words appear below.';

  @override
  String get diagnosticsHeard => 'I heard:';

  @override
  String get diagnosticsNothingYet =>
      'Nothing yet. Tap Start listening and read out loud.';

  @override
  String get diagnosticsMicPermission => 'Microphone permission';

  @override
  String get diagnosticsRecogniser => 'Speech recognition';

  @override
  String get diagnosticsRecogniserLanguage => 'Recogniser language';

  @override
  String get diagnosticsOnDeviceMode => 'Recognition mode';

  @override
  String get diagnosticsOnDeviceModeValue => 'On device only';

  @override
  String get diagnosticsNetworkModeValue => 'On device and network';

  @override
  String get diagnosticsGranted => 'Granted';

  @override
  String get diagnosticsDenied => 'Denied';

  @override
  String get diagnosticsAvailable => 'Available';

  @override
  String get diagnosticsUnavailable => 'Not available';

  @override
  String get diagnosticsUnknown => 'Unknown';

  @override
  String get diagnosticsNoneInstalled => 'No matching language pack installed';

  @override
  String get diagnosticsPrivacyNote =>
      'Nothing you say here is saved or scored.';

  @override
  String get aboutBody =>
      'JK Read n Learn teaches children to read aloud in English, Chinese and Bahasa Malaysia. Tap any word to hear it, read the passage out loud, and earn JKD.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }
}
