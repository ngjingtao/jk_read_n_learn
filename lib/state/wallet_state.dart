import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/money.dart';

/// A single line in the child's reward ledger.
class JkdTransaction {
  const JkdTransaction({
    required this.label,
    required this.amount,
    required this.at,
    this.essayId,
    this.accuracy,
    this.points,
  });

  /// What earned the reward, e.g. `My Morning Garden`.
  final String label;

  /// Always positive today. Kept signed so spending can be added later without
  /// a migration — a shop for stickers and avatars is an obvious next step.
  final Jkd amount;

  final DateTime at;

  final String? essayId;

  /// Reading accuracy for the attempt, `0.0` – `1.0`, when applicable.
  final double? accuracy;

  final int? points;

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount.hundredths,
        'at': at.toIso8601String(),
        if (essayId != null) 'essayId': essayId,
        if (accuracy != null) 'accuracy': accuracy,
        if (points != null) 'points': points,
      };

  static JkdTransaction fromJson(Map<String, dynamic> json) {
    return JkdTransaction(
      label: json['label'] as String? ?? 'Reward',
      amount: Jkd(json['amount'] as int? ?? 0),
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      essayId: json['essayId'] as String?,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      points: json['points'] as int?,
    );
  }
}

/// The child's JKD ("Jiong Ke Dollar") balance, persisted on the device.
///
/// Deliberately local-only for now. A real wallet shared between a child's
/// tablet and a parent's phone needs a server, which is out of scope until the
/// reading loop itself is proven.
class WalletState extends ChangeNotifier {
  /// [preferences] is injectable so tests can run without a real device store.
  WalletState([this._preferences]);

  static const String _balanceKey = 'jkd.balanceHundredths';
  static const String _historyKey = 'jkd.history';
  static const int _historyLimit = 200;

  SharedPreferences? _preferences;

  Jkd _balance = Jkd.zero;
  List<JkdTransaction> _history = const [];
  bool _loaded = false;

  Jkd get balance => _balance;

  /// Most recent reward first.
  List<JkdTransaction> get history => List.unmodifiable(_history);

  bool get isLoaded => _loaded;

  /// Reads the saved wallet from disk. Safe to call more than once.
  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;

    _balance = Jkd(prefs.getInt(_balanceKey) ?? 0);

    final raw = prefs.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _history = decoded
            .whereType<Map<String, dynamic>>()
            .map(JkdTransaction.fromJson)
            .toList(growable: false);
      } catch (error) {
        // A corrupt ledger should never stop a child from reading. Reset it.
        debugPrint('JKD history could not be read, resetting: $error');
        _history = const [];
      }
    }

    _loaded = true;
    notifyListeners();
  }

  /// Adds [amount] to the balance and records it in the ledger.
  Future<void> credit(JkdTransaction transaction) async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;

    _balance = _balance + transaction.amount;
    _history = [transaction, ..._history].take(_historyLimit).toList(growable: false);

    await prefs.setInt(_balanceKey, _balance.hundredths);
    await prefs.setString(
      _historyKey,
      jsonEncode([for (final entry in _history) entry.toJson()]),
    );

    notifyListeners();
  }

  /// Wipes the wallet. For a "start over" option and for debugging.
  Future<void> reset() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefs = _preferences!;
    _balance = Jkd.zero;
    _history = const [];
    await prefs.remove(_balanceKey);
    await prefs.remove(_historyKey);
    notifyListeners();
  }
}
