import 'package:flutter/widgets.dart';

import '../models/component/component.dart';
import '../models/component/setup_guide.dart';
import 'setup_guide_card.dart';
import 'setup_guide_status.dart';

/// The setup guide's recommendations for the adjusters below it, so their
/// tooltips can show the recommended value. Only the setup page provides one.
class SetupGuideScope extends InheritedWidget {
  final List<SetupGuideSection> sections;

  const SetupGuideScope({super.key, required this.sections, required super.child});

  /// The recommendation for [adjustmentId] and the component it belongs to,
  /// or null without a scope or a guide rule for that adjuster.
  static (GuideRecommendation, Component)? recommendationFor(BuildContext context, String adjustmentId) {
    final scope = context.dependOnInheritedWidgetOfExactType<SetupGuideScope>();
    if (scope == null) return null;
    for (final section in scope.sections) {
      for (final recommendation in section.recommendations) {
        if (recommendation.adjustment.id == adjustmentId) return (recommendation, section.guided.component);
      }
    }
    return null;
  }

  @override
  bool updateShouldNotify(SetupGuideScope oldWidget) =>
      !identical(sections, oldWidget.sections) && (sections.isNotEmpty || oldWidget.sections.isNotEmpty);
}

/// "Recommended: 76 psi", or with the reason it can't be applied:
/// "Recommended: – · Outside the published range", "Recommended: 18 · Above
/// this adjuster's maximum". [GuideStatus] says how the current value relates.
String recommendedValueLine(GuideRecommendation recommendation, Component component) {
  final adjustment = recommendation.adjustment;
  final value = recommendation.value;
  if (value != null) return "Recommended: ${guideValueText(adjustment, value)}";
  final unapplied = recommendation.unappliedValue;
  final shown = unapplied == null ? "–" : guideValueText(adjustment, unapplied);
  return "Recommended: $shown · ${guideDetailText(recommendation, component)}";
}
