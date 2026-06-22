import 'package:flutter/material.dart';

import '../../icons/bike_icons.dart';
import '../../models/bike.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide2 extends StatelessWidget {
  const OnboardingSlide2({super.key});

  Widget _smallComponentIconCard(IconData icon) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 40),
      ),
    ); 
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const DelayedFade(
                  delay: 0,
                  keyId: "onboarding_icon_bike_main",
                  child: Icon(Bike.iconData, size: 120),
                ),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      DelayedFade(delay: 400, keyId: "onboarding_icon_fork", child: _smallComponentIconCard(BikeIcons.fork)),
                      DelayedFade(delay: 700, keyId: "onboarding_icon_shock", child: _smallComponentIconCard(BikeIcons.shock)),
                      DelayedFade(delay: 1000, keyId: "onboarding_icon_wheelFront", child: _smallComponentIconCard(BikeIcons.wheelFront)),
                      DelayedFade(delay: 1300, keyId: "onboarding_icon_wheelRear", child: _smallComponentIconCard(BikeIcons.wheelRear)),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                stepWidget(context: context, step: 1),
                const SizedBox(height: 12),
                Text('Build Your Digital Garage', 
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
                      TextSpan(text: "Add your "),
                      TextSpan(text: "bikes", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: " and their "),
                      TextSpan(text: "components", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: " that you want to track. Create a perfect digital twin of your real-world garage."),
                    ]
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
