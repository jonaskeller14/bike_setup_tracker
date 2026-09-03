import 'package:flutter/material.dart';

/// Shared layout for every onboarding slide: scrollable, centred content with
/// the slide's own primary action pinned below it.
///
/// Each slide owns its action so the label and its consequence stay together —
/// "Next" teaches, while later slides save a rider or open the Strava sheet.
/// The secondary action stays in the page's app bar: it must be available
/// without competing with the primary action for attention or for space.
class OnboardingSlideScaffold extends StatelessWidget {
  const OnboardingSlideScaffold({
    super.key,
    required this.onNext,
    required this.nextLabel,
    required this.child,
  });

  final VoidCallback onNext;
  final String nextLabel;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity)),
                  child: Center(child: child),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(nextLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
