import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../icons/bike_icons.dart';
import '../../models/bike.dart';
import 'onboarding_component_card.dart';
import 'onboarding_shared_element.dart';
import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide2 extends StatelessWidget {
  const OnboardingSlide2({
    super.key,
    required this.onNext,
    this.forkKey,
    this.forkHidden,
  });

  final VoidCallback onNext;

  /// Source endpoint of the fork card's flight into slide 3.
  final GlobalKey? forkKey;
  final ValueListenable<bool>? forkHidden;

  Widget _smallComponentIconCard(IconData icon, {GlobalKey? endpointKey, ValueListenable<bool>? hidden}) {
    // The padding matches the component card on slide 3 so the icon does not
    // shift when the flight hands the card over.
    return SharedElementEndpoint(
      endpointKey: endpointKey,
      hidden: hidden,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(OnboardingComponentCard.padding),
          child: Icon(icon, size: OnboardingComponentCard.iconSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingSlideScaffold(
      onNext: onNext,
      nextLabel: "Next",
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                DelayedFade(
                  delay: 400,
                  keyId: "onboarding_icon_fork",
                  child: _smallComponentIconCard(BikeIcons.fork, endpointKey: forkKey, hidden: forkHidden),
                ),
                DelayedFade(delay: 700, keyId: "onboarding_icon_shock", child: _smallComponentIconCard(BikeIcons.shock)),
                DelayedFade(
                  delay: 1000,
                  keyId: "onboarding_icon_wheelFront",
                  child: _smallComponentIconCard(BikeIcons.wheelFront),
                ),
                DelayedFade(
                  delay: 1300,
                  keyId: "onboarding_icon_wheelRear",
                  child: _smallComponentIconCard(BikeIcons.wheelRear),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          stepWidget(context: context, step: 1),
          const SizedBox(height: 12),
          Text(
            'Build Your Digital Garage',
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
                TextSpan(
                  text: " that you want to track. Create a perfect digital twin of your real-world garage.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
