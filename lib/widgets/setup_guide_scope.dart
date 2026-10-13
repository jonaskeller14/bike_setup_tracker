import 'package:flutter/widgets.dart';

import '../models/component/component.dart';
import '../models/component/setup_guide.dart';
import 'setup_guide_card.dart';

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

/// "Recommended: 76 psi · on guide", "Recommended: 76 psi · +6 psi", or the
/// reason there is no value: "Recommended: – · Outside the published range".
String recommendedValueLine(GuideRecommendation recommendation, Component component) {
  final value = recommendation.value;
  if (value == null) return "Recommended: – · ${guideDetailText(recommendation, component)}";
  final status = switch (recommendation.deviation) {
    null => null,
    GuideDeviation(onGuide: true) => "on guide",
    GuideDeviation(delta: null) => "off guide",
    GuideDeviation(:final delta?) => "${guideSignedDelta(delta)}${recommendation.adjustment.unitSuffix()}",
  };
  return ["Recommended: ${guideValueText(recommendation.adjustment, value)}", ?status].join(" · ");
}
