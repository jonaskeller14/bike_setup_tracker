import '../models/feedback/feedback_key.dart';
import '../models/feedback/test_session_method.dart';
import 'app_localizations.dart';
import 'enum_labels.dart';

/// "Front · Calm".
String testSessionGoalLabel(FeedbackAspect aspect, String Function(String slug) customLabel, AppLocalizations l10n) =>
    switch (aspect) {
      EndAspect(:final end, :final attribute) => l10n.testSessionGoalLabel(end.label(l10n), attribute.qualityLabel(l10n)),
      CustomAspect(:final slug) => customLabel(slug),
      _ => aspect.raw,
    };

String testSessionMethodLabel(TestSessionMethod? method, AppLocalizations l10n) => switch (method) {
  PatternSearch() => l10n.testSessionMethodFineTune,
  OrthogonalArray() => l10n.testSessionMethodExplore,
  Tournament() => l10n.testSessionMethodCompare,
  null => l10n.testSessionMethodFree,
};

String testSessionMethodDescription(TestSessionMethod? method, AppLocalizations l10n) => switch (method) {
  PatternSearch() => l10n.testSessionMethodFineTuneInfo,
  OrthogonalArray() => l10n.testSessionMethodExploreInfo,
  Tournament() => l10n.testSessionMethodCompareInfo,
  null => l10n.testSessionMethodFreeInfo,
};

/// A rough run count for [knobCount] knobs, or the number of candidates for a
/// Compare session.
String? testSessionExpectedRuns(TestSessionMethod? method, int knobCount, AppLocalizations l10n) => switch (method) {
  _ when knobCount <= 0 => null,
  PatternSearch() => l10n.testSessionExpectedRuns(knobCount * 4),
  OrthogonalArray() => l10n.testSessionExpectedRuns(knobCount + 2),
  Tournament(:final candidateSetupIds) => l10n.testSessionExpectedRuns(candidateSetupIds.length + 1),
  null => null,
};
