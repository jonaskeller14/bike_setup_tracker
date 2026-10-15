import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../../repositories/app_repository.dart';
import '../../theme.dart';
import '../../utils/bike_actions.dart';
import '../../utils/component_actions.dart';
import '../../utils/setup_actions.dart';
import 'app_hint_deck.dart';

class GettingStartedGuideHint extends StatelessWidget {
  const GettingStartedGuideHint({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final steps = [
      _GuidedStep(label: 'Add your bike', isCompleted: appRepository.bikes.isNotEmpty),
      _GuidedStep(label: 'Add a component', isCompleted: appRepository.components.isNotEmpty),
      _GuidedStep(label: 'Record a setup', isCompleted: appRepository.setups.isNotEmpty),
    ];

    if (steps.every((step) => step.isCompleted)) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final animate = !MediaQuery.of(context).disableAnimations;
    final hint = HintColors.of(context);
    // The step indicator reads primary/surface roles; point them at the hint palette.
    final colorScheme = Theme.of(context).colorScheme.copyWith(
      primary: hint.accent,
      onPrimary: hint.onAccent,
      surfaceContainerHighest: hint.container,
      onSurfaceVariant: hint.onContainer,
    );
    final currentIndex = steps.indexWhere((s) => !s.isCompleted);

    return AppHintDeck(
      icon: Icons.flag_outlined,
      label: 'Steps to get started',
      onDismiss: onDismiss,
      dismissLabel: 'Hide guide',
      pages: [
        AppHintPage(
          action: AppHintAction(
            label: steps[currentIndex].label,
            icon: Icons.add,
            completesHint: false,
            onPressed: () async {
              switch (currentIndex) {
                case 0: await BikeActions.addBike(context);
                case 1: await ComponentActions.addComponent(context);
                case 2: await SetupActions.addSetup(context);
              }
            },
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FixedTimeline.tileBuilder(
              theme: TimelineThemeData(
                nodePosition: 0,
                indicatorPosition: 0, // Aligns indicator to the top of the content
                indicatorTheme: const IndicatorThemeData(size: 26.0),
                connectorTheme: ConnectorThemeData(
                  thickness: 2.0,
                  color: colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              builder: TimelineTileBuilder.connected(
                connectionDirection: ConnectionDirection.after,
                itemCount: steps.length,
                contentsBuilder: (context, index) {
                  final step = steps[index];
                  final isCurrent = index == currentIndex;

                  return Padding(
                    padding: EdgeInsets.only(left: 14.0, top: 2.0, bottom: index == steps.length - 1 ? 8.0 : 20.0),
                    child: Text(
                      step.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: step.isCompleted
                            ? hint.onContainer.withValues(alpha: 0.45)
                            : isCurrent
                                ? hint.onContainer
                                : hint.onContainer.withValues(alpha: 0.65),
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: hint.onContainer.withValues(alpha: 0.35),
                      ),
                    ),
                  );
                },
                indicatorBuilder: (context, index) {
                  final step = steps[index];
                  return _StepTransitionIndicator(
                    index: index,
                    isCompleted: step.isCompleted,
                    isCurrent: index == currentIndex,
                    colors: colorScheme,
                    textTheme: textTheme,
                    duration: Duration(milliseconds: animate ? 600 : 1),
                  );
                },
                connectorBuilder: (context, index, type) {
                  return SolidLineConnector(
                    color: steps[index].isCompleted
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.25),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A purely stateless-acting implicitly animated widget.
/// It observes the `isCompleted` boolean and mathematically tracks
/// progress from 0.0 to 1.0 when it flips. No timer variables needed.
class _StepTransitionIndicator extends ImplicitlyAnimatedWidget {
  final int index;
  final bool isCompleted;
  final bool isCurrent;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _StepTransitionIndicator({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
    required this.colors,
    required this.textTheme,
    required super.duration,
  }) : super(curve: Curves.easeInOut);

  @override
  ImplicitlyAnimatedWidgetState<_StepTransitionIndicator> createState() => _StepTransitionIndicatorState();
}

class _StepTransitionIndicatorState extends AnimatedWidgetBaseState<_StepTransitionIndicator> {
  Tween<double>? _progress;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _progress = visitor(
      _progress,
      widget.isCompleted ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    // Evaluates from 0.0 to 1.0 during transition.
    final value = _progress?.evaluate(animation) ?? (widget.isCompleted ? 1.0 : 0.0);

    if (value >= 1.0) {
      // Done - Show Checkmark
      return DotIndicator(
        size: 26,
        color: widget.colors.primary,
        child: Icon(Icons.check, size: 16, color: widget.colors.onPrimary),
      );
    }

    if (value > 0.0) {
      // Transitioning - The progress circle visually "fills up" as value climbs to 1.0
      return SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.colors.primary.withValues(alpha: 0.3),
                  width: 2.0,
                ),
              ),
            ),
            CircularProgressIndicator(
              value: value,
              strokeWidth: 2.0,
              color: widget.colors.primary,
            ),
          ],
        ),
      );
    }

    // Pending - Show Index Number
    return OutlinedDotIndicator(
      size: 26,
      borderWidth: widget.isCurrent ? 0 : 1.5,
      color: widget.isCurrent ? widget.colors.primary : widget.colors.primary.withValues(alpha: 0.4),
      backgroundColor: widget.isCurrent ? widget.colors.primary : widget.colors.surfaceContainerHighest,
      child: Center(
        child: Text(
          '${widget.index + 1}',
          style: widget.textTheme.labelSmall?.copyWith(
            color: widget.isCurrent ? widget.colors.onPrimary : widget.colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _GuidedStep {
  final String label;
  final bool isCompleted;
  const _GuidedStep({required this.label, required this.isCompleted});
}
