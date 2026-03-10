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
                delayedFade(
                  delay: 0,
                  child: const Icon(Bike.iconData, size: 120),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 12,
                  children: [
                    delayedFade(delay: 400, child: _smallComponentIconCard(BikeIcons.fork)),
                    delayedFade(delay: 700, child: _smallComponentIconCard(BikeIcons.shock)),
                    delayedFade(delay: 1000, child: _smallComponentIconCard(BikeIcons.wheelFront)), 
                    delayedFade(delay: 1300, child: _smallComponentIconCard(BikeIcons.wheelRear)),
                  ],
                ),
                const SizedBox(height: 60),
                Column(
                  children: [
                    stepWidget(context: context, step: 1),
                    const SizedBox(height: 12),
                    Text('Build Your Digital Garage', 
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
