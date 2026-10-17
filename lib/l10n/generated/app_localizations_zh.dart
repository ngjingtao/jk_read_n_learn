// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'JK 阅读学习';

  @override
  String get homeGreeting => '今天想读什么？';

  @override
  String get homeSubtitle => '点任何一个字就能听发音。然后大声读出来，就能赚 JKD。';

  @override
  String unitWords(int count) {
    return '$count 个字';
  }

  @override
  String unitCharacters(int count) {
    return '$count 个字';
  }

  @override
  String standardLabel(int grade) {
    return '$grade 年级';
  }

  @override
  String get actionListen => '听一听';

  @override
  String get actionReadAloud => '大声朗读';

  @override
  String get actionCancel => '取消';

  @override
  String get actionAllDone => '我读完了';

  @override
  String get actionReadAgain => '再读一次';

  @override
  String get actionBackToList => '回到阅读列表';

  @override
  String get actionOpenSettings => '打开设置';

  @override
  String get actionKeepIt => '保留';

  @override
  String get actionClear => '清除';

  @override
  String get actionStartListening => '开始聆听';

  @override
  String get actionStop => '停止';

  @override
  String listeningStatus(String time) {
    return '正在聆听…… $time';
  }

  @override
  String get iCanHear => '我听到：';

  @override
  String get markingInProgress => '正在评分……';

  @override
  String get howListeningWorks => '关于聆听';

  @override
  String get micSheetTitle => '麦克风会听到什么';

  @override
  String get micSheetBody =>
      '目前应用会把麦克风收到的一切都用来评分，所以旁边一起读的家长，或者房间里的电视，都可能被录进转写结果里。语音过滤功能已在计划中。';

  @override
  String strategyLabel(String name) {
    return '当前策略：$name';
  }

  @override
  String speechRecognitionStatus(String status) {
    return '语音识别：$status';
  }

  @override
  String get statusAvailable => '可用';

  @override
  String get statusUnavailable => '此设备不可用';

  @override
  String get voiceStrategyPassthroughName => '原始麦克风';

  @override
  String get voiceStrategyPassthroughDescription => '不做任何过滤。房间里所有人的声音都可能被识别。';

  @override
  String get errorNothingHeard => '我没有听到声音。试着读大声一点。';

  @override
  String get errorRecogniserUnavailable => '此设备无法使用语音识别。';

  @override
  String errorLocaleUnavailable(String language) {
    return '此设备没有 $language 的语音识别。请在系统设置里安装该语言包。';
  }

  @override
  String get errorEngineFailed => '此设备上的语音引擎无法启动。';

  @override
  String get errorPermissionDenied =>
      'JK 阅读学习需要用麦克风来给你的朗读评分。请在弹窗中允许使用麦克风，然后重试。';

  @override
  String get errorPermissionPermanentlyDenied =>
      '麦克风权限已被关闭。请到设备设置里允许 JK 阅读学习使用麦克风，然后回来重试。';

  @override
  String get resultTitle => '你的成绩';

  @override
  String get resultAccurate => '正确';

  @override
  String resultSummary(int correct, int total, int seconds) {
    return '一共 $total 个字，读对了 $correct 个，用了 $seconds 秒';
  }

  @override
  String resultWordsPerMinute(int wpm) {
    return '每分钟 $wpm 个字';
  }

  @override
  String resultEarned(String amount) {
    return '你赚到了 $amount';
  }

  @override
  String resultPoints(int points) {
    return '$points 分';
  }

  @override
  String get labelCorrect => '读对了';

  @override
  String get labelUnclear => '听得不清楚';

  @override
  String get labelNearlyRight => '差一点';

  @override
  String get labelMissed => '漏读或读错';

  @override
  String get labelExtra => '多读的字';

  @override
  String get unclearHint => '麦克风对这几个字不太确定。坐近一点，或者用耳机，通常会有改善。这些字仍然算读对。';

  @override
  String get resultHowYouReadIt => '你读得怎么样';

  @override
  String get resultColourLegend => '绿色是读对了，黄色是接近，红色是漏读或读错。点一下字可以再听一次。';

  @override
  String get extrasTitle => '我听到了一些文章里没有的字';

  @override
  String get extrasNote => '如果旁边有人在读，他们的声音也可能被收到。语音过滤功能即将推出。';

  @override
  String get gradeOutstanding => '太棒了';

  @override
  String get gradeGreat => '读得很好';

  @override
  String get gradeGood => '做得不错';

  @override
  String get gradeKeepPractising => '继续练习';

  @override
  String get gradeTryAgain => '再试一次';

  @override
  String get walletTitle => '我的 JKD';

  @override
  String get walletCurrencyName => '囧币（Jiong Ke Dollar）';

  @override
  String get walletTagline => '大声朗读就能赚到。';

  @override
  String get walletHistory => '记录';

  @override
  String get walletEmpty => '还没有奖励。读一篇文章，赚到你的第一笔 JKD！';

  @override
  String get walletResetTitle => '确定要重新开始吗？';

  @override
  String get walletResetBody => '这会清除此设备上的 JKD 余额和所有阅读记录。';

  @override
  String get walletResetTooltip => '重新开始';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppLanguage => '界面语言';

  @override
  String get settingsSoundAndSpeech => '声音与语音';

  @override
  String get settingsOnDeviceOnly => '只使用设备端语音识别';

  @override
  String get settingsOnDeviceOnlySubtitle =>
      '隐私更好：声音不会离开这台平板。但很多设备没有对应语言的离线模型，这时聆听会直接失败，而不会改用网络识别。';

  @override
  String get settingsHearingTest => '聆听测试';

  @override
  String get settingsHearingTestSubtitle => '检查麦克风和识别器是否能听到你';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsComfort => '阅读舒适度';

  @override
  String get settingsTextSize => '字体大小';

  @override
  String get settingsTextSizeSmall => '小';

  @override
  String get settingsTextSizeNormal => '标准';

  @override
  String get settingsTextSizeLarge => '大';

  @override
  String get settingsTextSizeExtraLarge => '特大';

  @override
  String get settingsLineSpacing => '行距';

  @override
  String get settingsLineSpacingNormal => '标准';

  @override
  String get settingsLineSpacingWide => '宽';

  @override
  String get settingsLineSpacingExtraWide => '超宽';

  @override
  String get settingsReduceMotion => '减少动态效果';

  @override
  String get settingsReduceMotionSubtitle => '停止聆听时的闪烁圆点。旁边的计时器仍会显示当前状态。';

  @override
  String get settingsStrictConfidence => '对听不清的字严格评分';

  @override
  String get settingsStrictConfidenceSubtitle =>
      '默认关闭。关闭时，麦克风听不清的字仍然拿满分 —— 不会因为读得小声而被扣分。打开后这些字会少拿一些分，好处是能抓出被识别器悄悄纠正掉的发音错误。';

  @override
  String streakDays(int days) {
    return '已连续 $days 天';
  }

  @override
  String get streakNone => '今天读一次，开始连续记录';

  @override
  String streakBest(int days) {
    return '最长：$days 天';
  }

  @override
  String get streakTooltip => '连续阅读的天数';

  @override
  String get shopTitle => '奖励商店';

  @override
  String get shopSubtitle => '用你赚到的 JKD 换贴纸，收集起来。';

  @override
  String get shopOwned => '已拥有';

  @override
  String get shopBuy => '购买';

  @override
  String get shopNotEnough => 'JKD 还不够';

  @override
  String get shopCollection => '我的收藏';

  @override
  String get shopCollectionEmpty => '还没有收藏。先读一篇文章，再回来看看。';

  @override
  String shopBought(String name) {
    return '你买到了$name';
  }

  @override
  String get rewardStar => '星星';

  @override
  String get rewardHeart => '爱心';

  @override
  String get rewardRocket => '火箭';

  @override
  String get rewardRainbow => '彩虹';

  @override
  String get rewardPanda => '熊猫';

  @override
  String get rewardDragon => '龙';

  @override
  String get rewardCrown => '王冠';

  @override
  String get rewardTrophy => '奖杯';

  @override
  String get progressTitle => '你的进度';

  @override
  String progressAttempts(int count) {
    return '已读 $count 次';
  }

  @override
  String progressBestAccuracy(int percent) {
    return '最好：$percent%';
  }

  @override
  String progressBestSpeed(int wpm) {
    return '最快：每分钟 $wpm 个字';
  }

  @override
  String get progressNewRecord => '这篇读出了新纪录！';

  @override
  String get progressNever => '还没读过';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get diagnosticsTitle => '聆听测试';

  @override
  String get diagnosticsIntro => '请大声读出下面的句子，然后看看下面有没有出现这些字。';

  @override
  String get diagnosticsHeard => '我听到：';

  @override
  String get diagnosticsNothingYet => '还没有听到。点「开始聆听」，然后大声朗读。';

  @override
  String get diagnosticsMicPermission => '麦克风权限';

  @override
  String get diagnosticsRecogniser => '语音识别';

  @override
  String get diagnosticsRecogniserLanguage => '识别语言';

  @override
  String get diagnosticsOnDeviceMode => '识别方式';

  @override
  String get diagnosticsOnDeviceModeValue => '仅设备端';

  @override
  String get diagnosticsNetworkModeValue => '设备端与网络';

  @override
  String get diagnosticsGranted => '已允许';

  @override
  String get diagnosticsDenied => '已拒绝';

  @override
  String get diagnosticsAvailable => '可用';

  @override
  String get diagnosticsUnavailable => '不可用';

  @override
  String get diagnosticsUnknown => '未知';

  @override
  String get diagnosticsNoneInstalled => '没有安装匹配的语言包';

  @override
  String get diagnosticsPrivacyNote => '你在这里说的话不会被保存，也不会被评分。';

  @override
  String get aboutBody =>
      'JK 阅读学习帮助孩子用英语、中文和马来语大声朗读。点任何一个字就能听发音，大声读完整篇，就能赚到 JKD。';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }
}
