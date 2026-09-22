import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../utils/installation_issue.dart';

class GarageComponentIconCard extends StatelessWidget {
  static const double minimumWidth = 47;
  static const double rowEndSpacing = 1;

  final Component component;
  final String? componentToShowDetails;
  final double? width;
  final InstallationIssue? issue;
  final bool merged;  // group header --> no border+backgorund

  const GarageComponentIconCard({
    super.key,
    required this.component,
    required this.componentToShowDetails,
    this.width,
    this.issue,
    this.merged = false,
  });

  static double widthFor(
    double availableWidth, {
    required double spacing,
  }) {
    final safeAvailableWidth = math.max(
      0.0,
      availableWidth - rowEndSpacing,
    );
    final columns = cardsPerRow(availableWidth, spacing: spacing);
    return (safeAvailableWidth - spacing * (columns - 1)) / columns;
  }

  static int cardsPerRow(
    double availableWidth, {
    required double spacing,
  }) {
    final safeAvailableWidth = math.max(
      0.0,
      availableWidth - rowEndSpacing,
    );
    final fittingCards = ((safeAvailableWidth + spacing) / (minimumWidth + spacing)).floor();
    return fittingCards < 1 ? 1 : fittingCards;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = componentToShowDetails == component.id;
    final appSettings = context.watch<AppSettings>();

    TaskStatusType? indicatorStatus;
    if (appSettings.enableTask && appSettings.enableGarageTaskIndicator) {
      indicatorStatus = context.watch<AppRepository>().componentTaskIndicatorStatus(component.id);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: ValueKey(component.id),
          width: width,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.tertiaryContainer
                : merged
                    ? Colors.transparent
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.tertiary
                  : issue != null
                      ? colorScheme.error
                      : merged
                          ? Colors.transparent
                          : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(
                    color: colorScheme.tertiary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )]
                : null,
          ),
          child: Icon(
            component.componentType.getIconData(),
            size: 24,
            color: isSelected
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurface,
          ),
        ),
        if (issue != null)
          Positioned(
            top: -3,
            left: -3,
            child: Semantics(
              label: issue!.label,
              child: Tooltip(
                message: issue!.label,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.tertiaryContainer : colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 14,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        if (indicatorStatus != null)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: indicatorStatus.getStatusColor(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.tertiaryContainer : colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
