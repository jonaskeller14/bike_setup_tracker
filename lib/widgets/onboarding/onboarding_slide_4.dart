import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/weather.dart';
import '../set_adjustment/set_step_adjustment.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide4 extends StatefulWidget {
  const OnboardingSlide4({super.key});

  @override
  State<OnboardingSlide4> createState() => _OnboardingSlide4State();
}

class _OnboardingSlide4State extends State<OnboardingSlide4> {
  double? _setStepAdjustmentWidgetValue;

  Widget _setStepAdjustmentWidgetAnimation() {
    const double startVal = 2.0;
    const double peakVal = 12.0;
    final double endVal = _setStepAdjustmentWidgetValue ?? 8.0;

    final Animatable<double> sequence = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(startVal),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: startVal, end: peakVal).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: peakVal, end: endVal).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 5000),
      builder: (context, value, child) {
        // 1. Calculate the value from the animation sequence
        final double animValue = sequence.transform(value);
        // 2. Determine which value to display: 
        // If the animation is finished (value == 1.0) and the user has touched it, use _currentValue.
        // Otherwise, follow the animation.
        final double displayValue = (value < 1.0) 
            ? animValue 
            : (_setStepAdjustmentWidgetValue ?? endVal);

        return SetStepAdjustmentWidget(
          key: const ValueKey("Onboarding Rebound Animation"),
          adjustment: StepAdjustment(
            name: "Rebound",
            notes: null,
            unit: null,
            category: AdjustmentCategory.component,
            min: 0,
            max: 12,
            step: 1,
            visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
          ),
          initialValue: startVal,
          value: displayValue, 
          onChanged: (double? newValue) => setState(() => _setStepAdjustmentWidgetValue = newValue),
          onChangedEnd: (_) {},
          highlighting: false,
        );
      },
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card( //TODO Import this layout or the components like Rows to prevent duplicate code
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Setup.iconData),
                        title: const Text("My new Setup", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Text(
                                  DateFormat(appSettings.dateFormat).format(DateTime.now()),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Text(
                                  DateFormat(appSettings.timeFormat).format(DateTime.now()),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 2,
                              children: [
                                Icon(Condition.dry.getIconData(), size: 13, color: Condition.dry.getColor()),
                                Text("Dry", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      _setStepAdjustmentWidgetAnimation(),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                stepWidget(context: context, step: 3),
                const SizedBox(height: 12),
                Text(
                  'Your Setup Diary',
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
                      TextSpan(text: "A "),
                      TextSpan(text: "Setup", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: " is a current snapshot of all components of one bike. It captures the specific values of your adjustments and automatically adds context (e.g. location, weather, trail conditions)."),
                    ]
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
