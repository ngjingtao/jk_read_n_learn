import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/essay.dart';
import '../models/scoring_models.dart';

/// Everything remembered about one passage across attempts.
class EssayProgress {
  const EssayProgress({
    required this.attempts,
    required this.bestAccuracy,
    required this.bestWordsPerMinute,
    required this.lastReadAt,
  });

  final int attempts;

  /// Best strict accuracy, `0.0` – `1.0`.
  final double bestAccuracy;

  final double bestWordsPerMinute;
  final DateTime lastReadAt;

  EssayProgress withResult(ScoreResult result, DateTime at) {
    return EssayProgress(
      attempts: attempts + 1,
      bestAccuracy:
          result.accuracy > bestAccuracy ? result.accuracy : bestAccuracy,
      bestWordsPerMinute: result.wordsPerMinute > bestWordsPerMinute
          ? result.wordsPerMinute
          : bestWordsPerMinute,
      lastReadAt: at,
    );
  }

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'bestAccuracy': bestAccuracy,
        'bestWordsPerMinute': bestWordsPerMinute,
        'lastReadAt': lastReadAt.toIso8601String(),
      };

  static EssayProgress fromJson(Map<String, dynamic> json) {
    return EssayProgress(
      attempts: json['attempts'] as int? ?? 0,
      bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0,
      bestWordsPerMinute: (json['bestWordsPerMinute'] as num?)?.toDouble() ?? 0,
      lastReadAt:
          DateTime.tryParse(json['lastReadAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

/// Long-term progress: reading streaks, per-passage records, and the reward
/// collection.
///
/// Separate from [WalletState] on purpose. The wallet is currency and has to be
/// exact; this is encouragement and can be lossy. Mixing them would mean a
/// corrupt streak could threaten a balance.
class ProgressState extends ChangeNotifier {
  /// [clock] is injectable so streak logic can be tested without waiting for
  /// real days to pass.
  ProgressState([this._preferences, DateTime Function()? clock])
      : _now = clock ?? DateTime.now;

  static const String _rewardsKey = 'progress.ownedRewards';
  static const String _essaysKey = 'progress.essays';
  static const String _daysKey = 'progress.sessionsByDay';

  SharedPreferences? _preferences;
  final DateTime Function() _now;

  final Set<String> _ownedRewards = {};
  final Map<String, EssayProgress> _essays = {};

  /// Reading sessions per calendar day, keyed `yyyy-MM-dd`.
  final Map<String, int> _sessionsByDay = {};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Reward ids the child owns, in catalogue order.
  List<String> get ownedRewards => [
        for (final id in _ownedRewards)
          if (_ownedRewards.contains(id)) id,
      ];

  bool owns(String rewardId) => _ownedRewards.contains(rewardId);

  EssayProgress? progressFor(String essayId) => _essays[essayId];

  int get sessionsToday => _sessionsByDay[_dayKey(_now())] ?? 0;

  /// Consecutive days with at least one reading session.
  ///
  /// A streak stays alive until a full day passes with nothing read: if the
  /// child has not read *yet* today but did read yesterday, the streak is still
  /// counting. Resetting it at midnight would punish a child for being asleep.
  int get currentStreak {
    if (_sessionsByDay.isEmpty) return 0;

    var day = _dayOnly(_now());
    if (!_sessionsByDay.containsKey(_dayKey(day))) {
      day = _shiftDay(day, -1);
      if (!_sessionsByDay.containsKey(_dayKey(day))) return 0;
    }

    var streak = 0;
    while (_sessionsByDay.containsKey(_dayKey(day))) {
      streak++;
      day = _shiftDay(day, -1);
    }
    return streak;
  }

  /// Longest run of consecutive reading days ever recorded.
  int get longestStreak {
    if (_sessionsByDay.isEmpty) return 0;

    final days = _sessionsByDay.keys
        .map(DateTime.parse)
        .map(_dayOnly)
        .toList()
      ..sort();

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  /// Days read in total.
  int get totalReadingDays => _sessionsByDay.length;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;

    _ownedRewards
      ..clear()
      ..addAll(prefs.getStringList(_rewardsKey) ?? const []);

    _essays.clear();
    final rawEssays = prefs.getString(_essaysKey);
    if (rawEssays != null && rawEssays.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEssays) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _essays[entry.key] =
                EssayProgress.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      } catch (error) {
        // Encouragement data must never block reading. Lose it and carry on.
        debugPrint('Essay progress could not be read, resetting: $error');
        _essays.clear();
      }
    }

    _sessionsByDay.clear();
    final rawDays = prefs.getString(_daysKey);
    if (rawDays != null && rawDays.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDays) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final count = entry.value;
          if (count is int) _sessionsByDay[entry.key] = count;
        }
      } catch (error) {
        debugPrint('Reading days could not be read, resetting: $error');
        _sessionsByDay.clear();
      }
    }

    _loaded = true;
    notifyListeners();
  }

  /// Records one finished attempt.
  ///
  /// Returns `true` when the attempt set a new best accuracy, so the result
  /// screen can celebrate it without recomputing anything.
  Future<bool> recordSession({
    required Essay essay,
    required ScoreResult result,
  }) async {
    final at = _now();
    final previous = _essays[essay.id];

    _essays[essay.id] = previous?.withResult(result, at) ??
        EssayProgress(
          attempts: 1,
          bestAccuracy: result.accuracy,
          bestWordsPerMinute: result.wordsPerMinute,
          lastReadAt: at,
        );

    final key = _dayKey(at);
    _sessionsByDay[key] = (_sessionsByDay[key] ?? 0) + 1;

    await _persist();

    // A first attempt is not a "new record" worth celebrating; it is just the
    // first. Only improvement counts.
    return previous != null && result.accuracy > previous.bestAccuracy;
  }

  /// Adds [rewardId] to the collection. Returns `false` if already owned.
  Future<bool> addOwnedReward(String rewardId) async {
    if (!_ownedRewards.add(rewardId)) return false;
    await _persist();
    return true;
  }

  /// Wipes progress. For a "start over" option alongside the wallet reset.
  Future<void> reset() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;
    _ownedRewards.clear();
    _essays.clear();
    _sessionsByDay.clear();
    await prefs.remove(_rewardsKey);
    await prefs.remove(_essaysKey);
    await prefs.remove(_daysKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;

    await prefs.setStringList(_rewardsKey, _ownedRewards.toList());
    await prefs.setString(
      _essaysKey,
      jsonEncode({
        for (final entry in _essays.entries) entry.key: entry.value.toJson(),
      }),
    );
    await prefs.setString(_daysKey, jsonEncode(_sessionsByDay));

    notifyListeners();
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Shifts by whole days without going through [Duration], which can land on
  /// the wrong calendar day when a timezone has daylight saving.
  static DateTime _shiftDay(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
