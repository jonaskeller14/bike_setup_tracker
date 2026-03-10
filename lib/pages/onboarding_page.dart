import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../widgets/onboarding/onboarding_slide_1.dart';
import '../widgets/onboarding/onboarding_slide_2.dart';
import '../widgets/onboarding/onboarding_slide_3.dart';
import '../widgets/onboarding/onboarding_slide_4.dart';

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
    _pages = [
      () => OnboardingSlide1(), 
      () => OnboardingSlide2(), 
      () => OnboardingSlide3(), 
      () => OnboardingSlide4(), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                onPressed: () {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              )
            : const SizedBox.shrink(),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pages.length, (index) => _builProgressIndicatorDot(index)),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<AppSettings>().showOnboarding = false,
            child: const Text("Skip"),
          ),
        ],
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () {
          if (_currentPage == _pages.length - 1) {
            context.read<AppSettings>().showOnboarding = false;
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
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: _pages.length,
          itemBuilder: (context, index) => _pages[index](),
        ),
      ),
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
