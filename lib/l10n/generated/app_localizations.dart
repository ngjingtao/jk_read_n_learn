import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
    Locale('zh'),
  ];

  /// The product name. Kept identical in every language.
  ///
  /// In en, this message translates to:
  /// **'JK Read n Learn'**
  String get appTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'What shall we read today?'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap any word to hear it. Then read it out loud to earn JKD.'**
  String get homeSubtitle;

  /// Count plus unit, e.g. '42 words'. Self-contained so callers can concatenate it directly.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{word} other{words}}'**
  String unitWords(int count);

  /// No description provided for @unitCharacters.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{character} other{characters}}'**
  String unitCharacters(int count);

  /// No description provided for @standardLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard {grade}'**
  String standardLabel(int grade);

  /// No description provided for @actionListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get actionListen;

  /// No description provided for @actionReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get actionReadAloud;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get actionAllDone;

  /// No description provided for @actionReadAgain.
  ///
  /// In en, this message translates to:
  /// **'Read it again'**
  String get actionReadAgain;

  /// No description provided for @actionBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to my reading list'**
  String get actionBackToList;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// No description provided for @actionKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get actionKeepIt;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionStartListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get actionStartListening;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @listeningStatus.
  ///
  /// In en, this message translates to:
  /// **'Listening… {time}'**
  String listeningStatus(String time);

  /// No description provided for @iCanHear.
  ///
  /// In en, this message translates to:
  /// **'I can hear:'**
  String get iCanHear;

  /// No description provided for @markingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Marking your reading…'**
  String get markingInProgress;

  /// No description provided for @howListeningWorks.
  ///
  /// In en, this message translates to:
  /// **'How listening works'**
  String get howListeningWorks;

  /// No description provided for @micSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'What the microphone hears'**
  String get micSheetTitle;

  /// No description provided for @micSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Right now the app marks whatever the microphone picks up, so a parent reading along or a television in the room can end up in the transcript. Voice filtering is planned.'**
  String get micSheetBody;

  /// No description provided for @strategyLabel.
  ///
  /// In en, this message translates to:
  /// **'Strategy: {name}'**
  String strategyLabel(String name);

  /// No description provided for @speechRecognitionStatus.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition: {status}'**
  String speechRecognitionStatus(String status);

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get statusAvailable;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'not available on this device'**
  String get statusUnavailable;

  /// No description provided for @voiceStrategyPassthroughName.
  ///
  /// In en, this message translates to:
  /// **'Raw microphone'**
  String get voiceStrategyPassthroughName;

  /// No description provided for @voiceStrategyPassthroughDescription.
  ///
  /// In en, this message translates to:
  /// **'No filtering. Every voice in the room can be picked up by the recogniser.'**
  String get voiceStrategyPassthroughDescription;

  /// No description provided for @errorNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'I could not hear anything. Try reading a little louder.'**
  String get errorNothingHeard;

  /// No description provided for @errorRecogniserUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device.'**
  String get errorRecogniserUnavailable;

  /// No description provided for @errorLocaleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no speech recogniser for {language}. Install the language pack in system settings.'**
  String errorLocaleUnavailable(String language);

  /// No description provided for @errorEngineFailed.
  ///
  /// In en, this message translates to:
  /// **'The voice engine could not start on this device.'**
  String get errorEngineFailed;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'JK Read n Learn needs the microphone to mark your reading. Allow it when asked, then try again.'**
  String get errorPermissionDenied;

  /// No description provided for @errorPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is switched off. Open your device settings, allow the microphone for JK Read n Learn, then come back.'**
  String get errorPermissionPermanentlyDenied;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your marks'**
  String get resultTitle;

  /// No description provided for @resultAccurate.
  ///
  /// In en, this message translates to:
  /// **'accurate'**
  String get resultAccurate;

  /// No description provided for @resultSummary.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} words read correctly in {seconds}s'**
  String resultSummary(int correct, int total, int seconds);

  /// No description provided for @resultWordsPerMinute.
  ///
  /// In en, this message translates to:
  /// **'{wpm} words per minute'**
  String resultWordsPerMinute(int wpm);

  /// No description provided for @resultEarned.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount}'**
  String resultEarned(String amount);

  /// No description provided for @resultPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String resultPoints(int points);

  /// No description provided for @labelCorrect.
  ///
  /// In en, this message translates to:
  /// **'Read correctly'**
  String get labelCorrect;

  /// No description provided for @labelNearlyRight.
  ///
  /// In en, this message translates to:
  /// **'Nearly right'**
  String get labelNearlyRight;

  /// No description provided for @labelMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed or wrong'**
  String get labelMissed;

  /// No description provided for @labelExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra words added'**
  String get labelExtra;

  /// No description provided for @resultHowYouReadIt.
  ///
  /// In en, this message translates to:
  /// **'How you read it'**
  String get resultHowYouReadIt;

  /// No description provided for @resultColourLegend.
  ///
  /// In en, this message translates to:
  /// **'Green is right, amber is close, red was skipped or said wrongly. Tap a word to hear it again.'**
  String get resultColourLegend;

  /// No description provided for @extrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Words I heard that are not in the passage'**
  String get extrasTitle;

  /// No description provided for @extrasNote.
  ///
  /// In en, this message translates to:
  /// **'If someone else was reading nearby, their voice may be picked up too. Voice filtering is coming.'**
  String get extrasNote;

  /// No description provided for @gradeOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get gradeOutstanding;

  /// No description provided for @gradeGreat.
  ///
  /// In en, this message translates to:
  /// **'Great reading'**
  String get gradeGreat;

  /// No description provided for @gradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good effort'**
  String get gradeGood;

  /// No description provided for @gradeKeepPractising.
  ///
  /// In en, this message translates to:
  /// **'Keep practising'**
  String get gradeKeepPractising;

  /// No description provided for @gradeTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gradeTryAgain;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My JKD'**
  String get walletTitle;

  /// No description provided for @walletCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Jiong Ke Dollars'**
  String get walletCurrencyName;

  /// No description provided for @walletTagline.
  ///
  /// In en, this message translates to:
  /// **'Earned by reading out loud.'**
  String get walletTagline;

  /// No description provided for @walletHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get walletHistory;

  /// No description provided for @walletEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet. Read a passage to earn your first JKD!'**
  String get walletEmpty;

  /// No description provided for @walletResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Start over?'**
  String get walletResetTitle;

  /// No description provided for @walletResetBody.
  ///
  /// In en, this message translates to:
  /// **'This clears the JKD balance and all reading history on this device.'**
  String get walletResetBody;

  /// No description provided for @walletResetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get walletResetTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsSoundAndSpeech.
  ///
  /// In en, this message translates to:
  /// **'Sound and speech'**
  String get settingsSoundAndSpeech;

  /// No description provided for @settingsOnDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Use on-device recognition only'**
  String get settingsOnDeviceOnly;

  /// No description provided for @settingsOnDeviceOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Better privacy: the voice never leaves the tablet. But on many devices the offline model for a language is missing, and listening will fail rather than fall back.'**
  String get settingsOnDeviceOnlySubtitle;

  /// No description provided for @settingsHearingTest.
  ///
  /// In en, this message translates to:
  /// **'Hearing test'**
  String get settingsHearingTest;

  /// No description provided for @settingsHearingTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check that the microphone and the recogniser can hear you'**
  String get settingsHearingTestSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get languageMalay;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hearing test'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsIntro.
  ///
  /// In en, this message translates to:
  /// **'Read the sentences below out loud, then check that the words appear below.'**
  String get diagnosticsIntro;

  /// No description provided for @diagnosticsHeard.
  ///
  /// In en, this message translates to:
  /// **'I heard:'**
  String get diagnosticsHeard;

  /// No description provided for @diagnosticsNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Tap Start listening and read out loud.'**
  String get diagnosticsNothingYet;

  /// No description provided for @diagnosticsMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission'**
  String get diagnosticsMicPermission;

  /// No description provided for @diagnosticsRecogniser.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition'**
  String get diagnosticsRecogniser;

  /// No description provided for @diagnosticsRecogniserLanguage.
  ///
  /// In en, this message translates to:
  /// **'Recogniser language'**
  String get diagnosticsRecogniserLanguage;

  /// No description provided for @diagnosticsOnDeviceMode.
  ///
  /// In en, this message translates to:
  /// **'Recognition mode'**
  String get diagnosticsOnDeviceMode;

  /// No description provided for @diagnosticsOnDeviceModeValue.
  ///
  /// In en, this message translates to:
  /// **'On device only'**
  String get diagnosticsOnDeviceModeValue;

  /// No description provided for @diagnosticsNetworkModeValue.
  ///
  /// In en, this message translates to:
  /// **'On device and network'**
  String get diagnosticsNetworkModeValue;

  /// No description provided for @diagnosticsGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get diagnosticsGranted;

  /// No description provided for @diagnosticsDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get diagnosticsDenied;

  /// No description provided for @diagnosticsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get diagnosticsAvailable;

  /// No description provided for @diagnosticsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get diagnosticsUnavailable;

  /// No description provided for @diagnosticsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get diagnosticsUnknown;

  /// No description provided for @diagnosticsNoneInstalled.
  ///
  /// In en, this message translates to:
  /// **'No matching language pack installed'**
  String get diagnosticsNoneInstalled;

  /// No description provided for @diagnosticsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing you say here is saved or scored.'**
  String get diagnosticsPrivacyNote;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'JK Read n Learn teaches children to read aloud in English, Chinese and Bahasa Malaysia. Tap any word to hear it, read the passage out loud, and earn JKD.'**
  String get aboutBody;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
