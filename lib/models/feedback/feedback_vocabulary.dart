enum FeedbackEnd {
  front('Front'),
  rear('Rear');

  final String label;
  const FeedbackEnd(this.label);
}

/// What the rider can feel without knowing the cause (issue #85, Phase 0).
enum FeedbackAttribute {
  grip(qualityLabel: 'Grip', problemLabel: 'Low grip', hint: 'Wheel slides or lets go'),
  comfort(qualityLabel: 'Comfort', problemLabel: 'Harsh', hint: 'Hits come through to hands or feet'),
  support(
    qualityLabel: 'Support',
    problemLabel: 'Sinks / dives',
    hint: 'Sits low, dives under braking, wallows in berms',
  ),
  calm(qualityLabel: 'Calm', problemLabel: 'Unsettled', hint: "Bouncy, kicks, doesn't settle after hits"),
  bottoming(qualityLabel: 'Bottoming', problemLabel: 'Bottoms out', hint: 'Hits the end of travel hard or often');

  /// Used for session goals and aspect comparisons.
  final String qualityLabel;

  /// Used for the everyday problem chip and open issues.
  final String problemLabel;
  final String hint;

  const FeedbackAttribute({required this.qualityLabel, required this.problemLabel, required this.hint});
}

abstract final class FeedbackVocabulary {
  static const Map<int, String> overallOutcomeLabels = {
    -2: 'Worse',
    -1: 'Slightly worse',
    0: 'Same',
    1: 'Slightly better',
    2: 'Better',
  };

  /// +1 means the aspect improved (a problem got smaller).
  static const Map<int, String> aspectOutcomeLabels = {
    -1: 'Worse',
    0: 'Same',
    1: 'Better',
  };

  static const String nothingStoodOut = 'Nothing stood out';
  static const String dialledIn = 'Dialled in';
  static const String notesHelper = 'Not used for ranking or proposals.';
}
