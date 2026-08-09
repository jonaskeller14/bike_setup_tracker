import 'package:flutter/material.dart';

import '../../icons/bike_icons.dart';
import '../../models/adjustment/adjustment.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide3 extends StatelessWidget {
  const OnboardingSlide3({super.key});

  Widget _adjustmentPreview({
    required BuildContext context,
    required IconData icon, 
    required String name, 
    required String type, 
    required String detail
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(type, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
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
                Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(BikeIcons.fork, size: 40),
                            const SizedBox(width: 12),
                            Text("Suspension Fork", style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        const Divider(height: 24),
                        
                        DelayedFade(
                          delay: 400, 
                          keyId: "onboarding_adj_pressure",
                          child:  _adjustmentPreview(
                            context: context,
                            icon: NumericalAdjustment.iconData, 
                            name: "Pressure", 
                            type: "Numerical Adjustment", 
                            detail: "in PSI"
                          ),
                        ),
                      
                        const SizedBox(height: 8),
          
                        DelayedFade(
                          delay: 700, 
                          keyId: "onboarding_adj_rebound",
                          child: _adjustmentPreview(
                            context: context,
                            icon: StepAdjustment.iconData, 
                            name: "Rebound", 
                            type: "Step Adjustment", 
                            detail: "0 to 12 Clicks"
                          ),
                        ),
                        
                        const SizedBox(height: 8),
          
                        DelayedFade(
                          delay: 1000, 
                          keyId: "onboarding_adj_lockout",
                          child: _adjustmentPreview(
                            context: context,
                            icon: BooleanAdjustment.iconData, 
                            name: "Lockout", 
                            type: "On/Off Adjustment", 
                            detail: "Open or Firm"
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
          
                Column(
                  children: [
                    stepWidget(context: context, step: 2),
                    const SizedBox(height: 12),
                    Text(
                      'Virtual Dials for Physical Knobs',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                      const TextSpan(
                        children: [
                          TextSpan(text: "Every component is built from a few simple "),
                          TextSpan(text: "Adjustments", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ". This modular design lets you track anything. "),
                          TextSpan(text: "Adjustments", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: " define the rules—like limits and units—not the actual values."),
                        ],
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
