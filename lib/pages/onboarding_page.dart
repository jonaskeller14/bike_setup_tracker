import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/weather.dart';
import '../icons/bike_icons.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late List<Function> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [_slide1, _slide2, _slide3, _slide4];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _pages[index](),
          ),

          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) => _builProgressIndicatorDot(index)),
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => context.read<AppSettings>().setShowOnboarding(false),
              child: const Text("Skip"),
            ),
          ),

          if (_currentPage > 0)
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                onPressed: () {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              ),
            ),

          Positioned(
            bottom: 50,
            left: null,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentPage == _pages.length - 1) {
                  context.read<AppSettings>().setShowOnboarding(false);
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              label: Text(_currentPage == _pages.length - 1 ? "Finish" : "Next"),
              icon: Icon(_currentPage == _pages.length - 1 
                  ? Icons.check 
                  : Icons.arrow_forward),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slide1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
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
                TextSpan(text: "Stop guessing your settings. Start tracking!\n"),
                TextSpan(text: "Find your perfect setup with "),
                TextSpan(text: "Bike Setup Tracker.", style: TextStyle(fontStyle: FontStyle.italic))
              ]
            )
          ),
        ],
      ),
    );
  }

  Widget _slide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _delayedFade(
            delay: 0,
            child: const Icon(Bike.iconData, size: 120),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              _delayedFade(delay: 400, child: _smallComponentIconCard(BikeIcons.fork)),
              _delayedFade(delay: 700, child: _smallComponentIconCard(BikeIcons.shock)),
              _delayedFade(delay: 1000, child: _smallComponentIconCard(BikeIcons.wheelFront)), 
              _delayedFade(delay: 1300, child: _smallComponentIconCard(BikeIcons.wheelRear)),
            ],
          ),
          const SizedBox(height: 60),
          Column(
            children: [
              _stepWidget(1),
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
    );
  }

  Widget _smallComponentIconCard(IconData icon) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 40),
      ),
    ); 
  }

  Widget _delayedFade({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, size, child) {
        return Transform.scale(
          scale: size,
          child: child,
        );
      },
      key: ValueKey([child, delay]),
      child: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: delay)),
        builder: (context, snapshot) {
          return snapshot.connectionState == ConnectionState.done 
              ? child 
              : const Opacity(opacity: 0);
        },
      ),
    );
  }

  Widget _slide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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
                      Icon(BikeIcons.fork, size: 40),
                      const SizedBox(width: 12),
                      Text("Suspension Fork", style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  _delayedFade(
                    delay: 400, 
                    child:  _adjustmentPreview(
                      icon: NumericalAdjustment.iconData, 
                      name: "Pressure", 
                      type: "Numerical Adjustment", 
                      detail: "in PSI"
                    ),
                  ),
                
                  const SizedBox(height: 8),

                  _delayedFade(
                    delay: 700, 
                    child: _adjustmentPreview(
                      icon: StepAdjustment.iconData, 
                      name: "Rebound", 
                      type: "Step Adjustment", 
                      detail: "0 to 12 Clicks"
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  _delayedFade(
                    delay: 1000, 
                    child: _adjustmentPreview(
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
              _stepWidget(2),
              const SizedBox(height: 12),
              Text(
                'Virtual Dials for Physical Knobs',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _stepWidget(int step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "STEP $step",
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _adjustmentPreview({
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

  Widget _slide4() {
    final appSettings = context.watch<AppSettings>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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
                        children: [
                          Condition.dry.getConditionsIcon(size: 13),
                          const SizedBox(width: 2),
                          Text(
                            "Dry",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
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
          _stepWidget(3),
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
    );
  }

  Widget _setStepAdjustmentWidgetAnimation() {
    const double startVal = 2.0;
    const double peakVal = 12.0;
    const double endVal = 8.0;

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
        final double animValue = sequence.transform(value);
        
        return SetStepAdjustmentWidget(
          key: const ValueKey("Onboarding Rebound Animation"),
          adjustment: StepAdjustment(
            name: "Rebound",
            notes: null,
            unit: null,
            min: 0,
            max: 12,
            step: 1,
            visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
          ),
          initialValue: startVal,
          value: animValue,
          onChanged: (newValue) {},
          onChangedEnd: (newValue) {},
          highlighting: false,
        );
      },
    );
  }

  Widget _builProgressIndicatorDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
