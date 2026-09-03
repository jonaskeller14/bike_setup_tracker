import 'package:flutter/material.dart';

import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide1 extends StatelessWidget {
  const OnboardingSlide1({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return OnboardingSlideScaffold(
      onNext: onNext,
      nextLabel: "Next",
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
            'Ready to Dial It In?',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text.rich(
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
            const TextSpan(
              children: [
                TextSpan(text: "Stop guessing your settings. Start tracking!\n"),
                TextSpan(text: "Find your perfect setup with "),
                TextSpan(text: "Bike Setup Tracker.", style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
