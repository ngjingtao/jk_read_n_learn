/// The in-app reward currency: **JKD**, short for *Jiong Ke Dollar*.
///
/// Stored as an integer number of hundredths so that repeated additions of
/// small rewards never accumulate floating-point drift. An award of `0.01 JKD`
/// is `1` hundredth; `12.34 JKD` is `1234`.
class Jkd implements Comparable<Jkd> {
  const Jkd(this.hundredths);

  /// Amount expressed in hundredths of a JKD.
  final int hundredths;

  static const Jkd zero = Jkd(0);

  /// Converts a raw point score into currency using the reward rate.
  ///
  /// [jkdPerPoint] is defined once in `ScoringConfig` so the exchange rate is
  /// auditable in a single place.
  factory Jkd.fromPoints(int points, {required double jkdPerPoint}) {
    return Jkd((points * jkdPerPoint * 100).round());
  }

  Jkd operator +(Jkd other) => Jkd(hundredths + other.hundredths);

  Jkd operator -(Jkd other) => Jkd(hundredths - other.hundredths);

  bool get isZero => hundredths == 0;

  double get asDouble => hundredths / 100;

  @override
  int compareTo(Jkd other) => hundredths.compareTo(other.hundredths);

  /// Value equality. Without this, `Jkd(55) == Jkd(55)` is `false`, because
  /// they are different instances — which silently breaks every comparison in
  /// the tests and any future spending logic.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Jkd && other.hundredths == hundredths);

  @override
  int get hashCode => hundredths.hashCode;

  /// Human-readable amount, e.g. `10.25 JKD`.
  String get label => '${asDouble.toStringAsFixed(2)} JKD';

  @override
  String toString() => label;
}
