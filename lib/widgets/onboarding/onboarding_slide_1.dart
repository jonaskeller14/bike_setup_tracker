import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../l10n/markup_text.dart';
import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide1 extends StatelessWidget {
  const OnboardingSlide1({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlideScaffold(
      onNext: onNext,
      nextLabel: context.l10n.onboardingNext,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DelayedFade(
            delay: Duration.zero,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Image.asset('assets/icons/logo_1024.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            context.l10n.onboardingSlide1Title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text.rich(
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
            markupTextSpan(context.l10n.onboardingSlide1Body),
          ),
        ],
      ),
    );
  }
}
