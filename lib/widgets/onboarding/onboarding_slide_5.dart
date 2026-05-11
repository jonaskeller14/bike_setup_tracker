import 'package:flutter/material.dart';
import '../../icons/bike_icons.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide5 extends StatefulWidget {
  const OnboardingSlide5({super.key});

  @override
  State<OnboardingSlide5> createState() => _OnboardingSlide5State();
}

class _OnboardingSlide5State extends State<OnboardingSlide5> {
  // Cursor animation states
  Alignment _cursorAlignment = const Alignment(1.5, 1.5);
  double _cursorScale = 1.0;
  double _cursorOpacity = 0.0;

  // Interactive mock states
  bool _isInteractive = false;
  String? _expandedId;
  String _hintText = "Watch the gestures below...";

  // Mock data
  final List<Map<String, dynamic>> _mockComponents = [
    {"id": "c1", "name": "Suspension Fork", "icon": BikeIcons.fork},
    {"id": "c2", "name": "Rear Shock", "icon": BikeIcons.shock},
    {"id": "c3", "name": "Brakes", "icon": BikeIcons.brakeCalliper},
  ];

  @override
  Future<void> initState() async {
    super.initState();
    await _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Wait for slide to load
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Move to Component 1 (Fork)
    setState(() {
      _cursorOpacity = 1.0;
      _cursorAlignment = const Alignment(
        -0.8,
        0.2,
      ); // Align over first component
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // TAP (Tap on component logo -> Show component card)
    setState(() {
      _hintText = "Tap component to show card";
      _cursorScale = 0.8;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _cursorScale = 1.0;
      _expandedId = "c1"; // Expand card
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Move out of the way
    setState(() {
      _cursorAlignment = const Alignment(1.5, 1.5);
      _cursorOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _expandedId = null; // Collapse card
    });

    // Reset and move to bike header
    setState(() {
      _cursorOpacity = 1.0;
      _cursorAlignment = const Alignment(0.0, -0.8); // Over bike title
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // DOUBLE TAP (Double tap bike -> Filter)
    setState(() => _hintText = "Double tap bike to filter");
    setState(() => _cursorScale = 0.8);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _cursorScale = 1.0);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _cursorScale = 0.8);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _cursorScale = 1.0);
    // Visual feedback for filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Filtering for 'My Enduro Bike'"),
        duration: Duration(seconds: 1),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Move to Component 2 and drag to reorder
    setState(() {
      _hintText = "Drag components to move them";
      _cursorAlignment = const Alignment(-0.4, 0.2); // Over shock
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Press down
    setState(() => _cursorScale = 0.8);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Drag
    setState(() {
      _cursorAlignment = const Alignment(0.4, 0.2); // Drag right
      // swap data
      final temp = _mockComponents[1];
      _mockComponents[1] = _mockComponents[2];
      _mockComponents[2] = temp;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Release
    setState(() => _cursorScale = 1.0);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Finish animation
    setState(() {
      _cursorOpacity = 0.0;
      _cursorAlignment = const Alignment(1.5, 1.5);
      _hintText = "Now it's your turn! Try it out.";
      _isInteractive = true;
    });
  }

  void _onComponentTap(String id) {
    if (!_isInteractive) return;
    setState(() {
      _expandedId = _expandedId == id ? null : id;
      _hintText = "Tapped component";
    });
  }

  void _onComponentDoubleTap(String id) {
    if (!_isInteractive) return;
    setState(() => _hintText = "Double tapped to open details");
  }

  void _onBikeDoubleTap() {
    if (!_isInteractive) return;
    setState(() => _hintText = "Double tapped bike to filter");
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
                stepWidget(context: context, step: 5),
                const SizedBox(height: 12),
                Text(
                  'Master your Garage',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _hintText,
                    key: ValueKey(_hintText),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isInteractive
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Interactive Mock Garage
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onDoubleTap: _onBikeDoubleTap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.pedal_bike),
                              title: Text(
                                "My Enduro Bike",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              trailing: const Icon(Icons.drag_handle),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _mockComponents.map((comp) {
                                  return GestureDetector(
                                    onTap: () => _onComponentTap(comp["id"]),
                                    onDoubleTap: () =>
                                        _onComponentDoubleTap(comp["id"]),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        comp["icon"],
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Expanded card mock
                            if (_expandedId != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _mockComponents.firstWhere(
                                          (c) => c["id"] == _expandedId,
                                        )["icon"],
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiaryContainer,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _mockComponents.firstWhere(
                                          (c) => c["id"] == _expandedId,
                                        )["name"],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // The animated hand cursor
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          alignment: _cursorAlignment,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _cursorOpacity,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 150),
                              scale: _cursorScale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Add a subtle shadow/glow to cursor to make it visible over elements
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.touch_app,
                                    size: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
