/// Every tunable number that affects grading, in one place.
///
/// Keeping scoring constants out of the algorithms means a teacher can be
/// shown *why* a child got the marks they did, and a future settings screen can
/// expose these without touching the grading logic.
class ScoringConfig {
  const ScoringConfig({
    this.pointsPerCorrectWord = 10,
    this.pointsPerMispronouncedWord = 3,
    this.pointsPerUnclearWord = 6,
    this.completionBonus = 25,
    this.completionBonusMinAccuracy = 0.6,
    this.mispronouncedSimilarityFloor = 0.6,
    this.unclearConfidenceFloor = 0.8,
    this.jkdPerPoint = 0.01,
  });

  /// Points for a word read exactly as written.
  final int pointsPerCorrectWord;

  /// Partial points for a word that was close but not exact.
  final int pointsPerMispronouncedWord;

  /// Points for a word that was heard as written but with low recogniser
  /// confidence, in strict mode only.
  ///
  /// Sits between a full mark and a near-miss on purpose: we are not claiming
  /// the child got it wrong, only that we could not confirm it.
  final int pointsPerUnclearWord;

  /// Recogniser confidence below which a matched word is treated as unclear,
  /// 0.0 – 1.0.
  ///
  /// **Uncalibrated.** It is the same 0.8 that `speech_to_text` itself suggests
  /// as its confidence threshold, which is a reasonable starting point and
  /// nothing more. Real device testing is required before this number is
  /// trusted — see `docs/ROADMAP.md` Phase 3. It is deliberately a single
  /// constant so calibration means changing one value.
  final double unclearConfidenceFloor;

  /// Flat bonus paid once the attempt clears [completionBonusMinAccuracy].
  /// This exists so that a struggling child still earns something for trying,
  /// which matters a great deal for a six-year-old's motivation.
  final int completionBonus;

  /// Lenient accuracy needed to unlock [completionBonus], 0.0 – 1.0.
  final double completionBonusMinAccuracy;

  /// A heard word at or above this character-level similarity counts as an
  /// attempt at the target word (partial credit). Below it, the child is
  /// treated as having said something else entirely, i.e. missed the word.
  final double mispronouncedSimilarityFloor;

  /// Exchange rate into the reward currency. `0.01` means 100 points = 1 JKD.
  final double jkdPerPoint;

  /// Default configuration used by the app.
  static const ScoringConfig standard = ScoringConfig();
}
