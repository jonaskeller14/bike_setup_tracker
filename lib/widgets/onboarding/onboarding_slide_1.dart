import 'package:flutter/material.dart';

import 'onboarding_slide_scaffold.dart';

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
          TweenAnimationBuilder<double>(
            key: const ValueKey("onboarding_logo_anim"),
            tween: Tween(begin: 0, end: 10),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            onEnd: () {},
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
