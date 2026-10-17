// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'JK Baca dan Belajar';

  @override
  String get homeGreeting => 'Apa yang kita baca hari ini?';

  @override
  String get homeSubtitle =>
      'Ketik mana-mana perkataan untuk mendengarnya. Kemudian baca dengan kuat untuk mendapat JKD.';

  @override
  String unitWords(int count) {
    return '$count perkataan';
  }

  @override
  String unitCharacters(int count) {
    return '$count aksara';
  }

  @override
  String standardLabel(int grade) {
    return 'Darjah $grade';
  }

  @override
  String get actionListen => 'Dengar';

  @override
  String get actionReadAloud => 'Baca dengan kuat';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionAllDone => 'Saya sudah habis';

  @override
  String get actionReadAgain => 'Baca sekali lagi';

  @override
  String get actionBackToList => 'Kembali ke senarai bacaan';

  @override
  String get actionOpenSettings => 'Buka tetapan';

  @override
  String get actionKeepIt => 'Simpan';

  @override
  String get actionClear => 'Hapuskan';

  @override
  String get actionStartListening => 'Mula mendengar';

  @override
  String get actionStop => 'Berhenti';

  @override
  String listeningStatus(String time) {
    return 'Sedang mendengar… $time';
  }

  @override
  String get iCanHear => 'Saya dengar:';

  @override
  String get markingInProgress => 'Sedang menanda bacaan anda…';

  @override
  String get howListeningWorks => 'Cara pendengaran berfungsi';

  @override
  String get micSheetTitle => 'Apa yang mikrofon dengar';

  @override
  String get micSheetBody =>
      'Buat masa ini aplikasi menanda apa sahaja yang mikrofon dengar, jadi ibu bapa yang membaca bersama atau televisyen di dalam bilik boleh masuk ke dalam transkrip. Penapisan suara sedang dirancang.';

  @override
  String strategyLabel(String name) {
    return 'Strategi: $name';
  }

  @override
  String speechRecognitionStatus(String status) {
    return 'Pengecaman suara: $status';
  }

  @override
  String get statusAvailable => 'tersedia';

  @override
  String get statusUnavailable => 'tidak tersedia pada peranti ini';

  @override
  String get voiceStrategyPassthroughName => 'Mikrofon mentah';

  @override
  String get voiceStrategyPassthroughDescription =>
      'Tiada penapisan. Semua suara di dalam bilik boleh dikesan oleh pengecam.';

  @override
  String get errorNothingHeard =>
      'Saya tidak mendengar apa-apa. Cuba baca dengan lebih kuat.';

  @override
  String get errorRecogniserUnavailable =>
      'Pengecaman suara tidak tersedia pada peranti ini.';

  @override
  String errorLocaleUnavailable(String language) {
    return 'Peranti ini tiada pengecam suara untuk $language. Sila pasang pek bahasa dalam tetapan sistem.';
  }

  @override
  String get errorEngineFailed =>
      'Enjin suara tidak dapat dimulakan pada peranti ini.';

  @override
  String get errorPermissionDenied =>
      'JK Baca dan Belajar memerlukan mikrofon untuk menanda bacaan anda. Benarkan apabila diminta, kemudian cuba lagi.';

  @override
  String get errorPermissionPermanentlyDenied =>
      'Akses mikrofon telah dimatikan. Buka tetapan peranti, benarkan mikrofon untuk JK Baca dan Belajar, kemudian kembali semula.';

  @override
  String get resultTitle => 'Markah anda';

  @override
  String get resultAccurate => 'tepat';

  @override
  String resultSummary(int correct, int total, int seconds) {
    return '$correct daripada $total perkataan dibaca dengan betul dalam ${seconds}s';
  }

  @override
  String resultWordsPerMinute(int wpm) {
    return '$wpm perkataan seminit';
  }

  @override
  String resultEarned(String amount) {
    return 'Anda memperoleh $amount';
  }

  @override
  String resultPoints(int points) {
    return '$points mata';
  }

  @override
  String get labelCorrect => 'Dibaca dengan betul';

  @override
  String get labelUnclear => 'Tidak jelas kedengaran';

  @override
  String get labelNearlyRight => 'Hampir betul';

  @override
  String get labelMissed => 'Tertinggal atau salah';

  @override
  String get labelExtra => 'Perkataan tambahan';

  @override
  String get unclearHint =>
      'Mikrofon tidak pasti tentang perkataan ini. Duduk lebih dekat, atau guna fon kepala, biasanya membantu. Perkataan ini masih dikira betul.';

  @override
  String get resultHowYouReadIt => 'Cara anda membaca';

  @override
  String get resultColourLegend =>
      'Hijau betul, kuning hampir betul, merah tertinggal atau salah. Ketik perkataan untuk mendengarnya lagi.';

  @override
  String get extrasTitle =>
      'Perkataan yang saya dengar tetapi tiada dalam petikan';

  @override
  String get extrasNote =>
      'Jika orang lain membaca berdekatan, suara mereka juga mungkin ditangkap. Penapisan suara akan datang.';

  @override
  String get gradeOutstanding => 'Cemerlang';

  @override
  String get gradeGreat => 'Bacaan yang bagus';

  @override
  String get gradeGood => 'Usaha yang baik';

  @override
  String get gradeKeepPractising => 'Teruskan berlatih';

  @override
  String get gradeTryAgain => 'Cuba lagi';

  @override
  String get walletTitle => 'JKD saya';

  @override
  String get walletCurrencyName => 'Duit Jiong Ke';

  @override
  String get walletTagline => 'Diperoleh dengan membaca dengan kuat.';

  @override
  String get walletHistory => 'Rekod';

  @override
  String get walletEmpty =>
      'Belum ada ganjaran. Baca satu petikan untuk mendapat JKD pertama anda!';

  @override
  String get walletResetTitle => 'Mula semula?';

  @override
  String get walletResetBody =>
      'Ini akan menghapuskan baki JKD dan semua rekod bacaan pada peranti ini.';

  @override
  String get walletResetTooltip => 'Mula semula';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsAppLanguage => 'Bahasa antara muka';

  @override
  String get settingsSoundAndSpeech => 'Bunyi dan suara';

  @override
  String get settingsOnDeviceOnly => 'Guna pengecaman dalam peranti sahaja';

  @override
  String get settingsOnDeviceOnlySubtitle =>
      'Privasi lebih baik: suara tidak keluar dari tablet ini. Tetapi banyak peranti tiada model luar talian untuk sesetengah bahasa, dan pendengaran akan gagal daripada beralih ke rangkaian.';

  @override
  String get settingsHearingTest => 'Ujian pendengaran';

  @override
  String get settingsHearingTestSubtitle =>
      'Pastikan mikrofon dan pengecam dapat mendengar anda';

  @override
  String get settingsAbout => 'Perihal';

  @override
  String get settingsComfort => 'Keselesaan membaca';

  @override
  String get settingsTextSize => 'Saiz teks';

  @override
  String get settingsTextSizeSmall => 'Kecil';

  @override
  String get settingsTextSizeNormal => 'Biasa';

  @override
  String get settingsTextSizeLarge => 'Besar';

  @override
  String get settingsTextSizeExtraLarge => 'Sangat besar';

  @override
  String get settingsLineSpacing => 'Jarak baris';

  @override
  String get settingsLineSpacingNormal => 'Biasa';

  @override
  String get settingsLineSpacingWide => 'Lebar';

  @override
  String get settingsLineSpacingExtraWide => 'Sangat lebar';

  @override
  String get settingsReduceMotion => 'Kurangkan gerakan';

  @override
  String get settingsReduceMotionSubtitle =>
      'Hentikan titik berdenyut semasa mendengar. Pemasa di sebelahnya masih menunjukkan apa yang berlaku.';

  @override
  String get settingsStrictConfidence =>
      'Penandaan ketat untuk perkataan tidak jelas';

  @override
  String get settingsStrictConfidenceSubtitle =>
      'Dimatikan secara lalai. Apabila dimatikan, perkataan yang tidak pasti masih mendapat markah penuh, jadi pembaca yang perlahan tidak dihukum. Apabila dihidupkan, perkataan itu kehilangan sebahagian markah, yang dapat menangkap salah sebut yang dibetulkan secara senyap oleh pengecam.';

  @override
  String streakDays(int days) {
    return '$days hari berturut-turut';
  }

  @override
  String get streakNone => 'Baca hari ini untuk mula berturut-turut';

  @override
  String streakBest(int days) {
    return 'Terbaik: $days hari';
  }

  @override
  String get streakTooltip => 'Hari berturut-turut anda membaca';

  @override
  String get shopTitle => 'Kedai ganjaran';

  @override
  String get shopSubtitle => 'Belanjakan JKD anda untuk pelekat koleksi.';

  @override
  String get shopOwned => 'Dimiliki';

  @override
  String get shopBuy => 'Beli';

  @override
  String get shopNotEnough => 'JKD belum cukup';

  @override
  String get shopCollection => 'Koleksi saya';

  @override
  String get shopCollectionEmpty =>
      'Belum ada koleksi. Baca satu petikan, kemudian kembali.';

  @override
  String shopBought(String name) {
    return 'Anda membeli $name';
  }

  @override
  String get rewardStar => 'Bintang';

  @override
  String get rewardHeart => 'Hati';

  @override
  String get rewardRocket => 'Roket';

  @override
  String get rewardRainbow => 'Pelangi';

  @override
  String get rewardPanda => 'Panda';

  @override
  String get rewardDragon => 'Naga';

  @override
  String get rewardCrown => 'Mahkota';

  @override
  String get rewardTrophy => 'Piala';

  @override
  String get progressTitle => 'Kemajuan anda';

  @override
  String progressAttempts(int count) {
    return 'Dibaca $count kali';
  }

  @override
  String progressBestAccuracy(int percent) {
    return 'Terbaik: $percent%';
  }

  @override
  String progressBestSpeed(int wpm) {
    return 'Laju terbaik: $wpm perkataan seminit';
  }

  @override
  String get progressNewRecord => 'Rekod baharu untuk petikan ini!';

  @override
  String get progressNever => 'Belum dibaca';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get diagnosticsTitle => 'Ujian pendengaran';

  @override
  String get diagnosticsIntro =>
      'Baca ayat di bawah dengan kuat, kemudian pastikan perkataannya muncul di bawah.';

  @override
  String get diagnosticsHeard => 'Saya dengar:';

  @override
  String get diagnosticsNothingYet =>
      'Belum ada apa-apa. Ketik Mula mendengar dan baca dengan kuat.';

  @override
  String get diagnosticsMicPermission => 'Kebenaran mikrofon';

  @override
  String get diagnosticsRecogniser => 'Pengecaman suara';

  @override
  String get diagnosticsRecogniserLanguage => 'Bahasa pengecam';

  @override
  String get diagnosticsOnDeviceMode => 'Cara pengecaman';

  @override
  String get diagnosticsOnDeviceModeValue => 'Dalam peranti sahaja';

  @override
  String get diagnosticsNetworkModeValue => 'Dalam peranti dan rangkaian';

  @override
  String get diagnosticsGranted => 'Dibenarkan';

  @override
  String get diagnosticsDenied => 'Ditolak';

  @override
  String get diagnosticsAvailable => 'Tersedia';

  @override
  String get diagnosticsUnavailable => 'Tidak tersedia';

  @override
  String get diagnosticsUnknown => 'Tidak diketahui';

  @override
  String get diagnosticsNoneInstalled =>
      'Tiada pek bahasa yang sepadan dipasang';

  @override
  String get diagnosticsPrivacyNote =>
      'Apa yang anda sebut di sini tidak disimpan dan tidak dinilai.';

  @override
  String get aboutBody =>
      'JK Baca dan Belajar membantu kanak-kanak membaca dengan kuat dalam bahasa Inggeris, Cina dan Melayu. Ketik mana-mana perkataan untuk mendengarnya, baca petikan dengan kuat, dan perolehi JKD.';

  @override
  String aboutVersion(String version) {
    return 'Versi $version';
  }
}
