import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';

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
              children: List.generate(_pages.length, (index) => _buildDot(index)),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bike, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 40),
          Text('Welcome', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Track your bike setups easily. To get started we explain the core concept of the app in the next slides...', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _slide2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bike, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 40),
          Text('Build Your Digital Garage', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Add your bikes and their parts that you want to track.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _slide3() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bike, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 40),
          Text('Adjustments: Virtual Dials for Physical Knobs', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Everything can be broken down into a few types of Adjustments. --> You can track everything, due to full modularity.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _slide4() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bike, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 40),
          Text('Your Setup Diary', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('A Setup is a current snapshot of all components of one bike. It captures the specific values of your adjustments and automatically adds context (e.g. location, weather, trail conditions).', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
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
