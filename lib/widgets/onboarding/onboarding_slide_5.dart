import 'dart:async';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_icon_card.dart';
import 'package:flutter/material.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
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
  final List<Bike> _mockBikes = [
    Bike(name: "Santa Cruz V10", person: null),
    Bike(name: "Specialized Tarmac SL8", person: null),
  ];

  final List<Component> _mockComponents = [
    Component(name: "Suspension Fork", installations: [Installation.sinceBeginning(parent: null)], componentType: ComponentType.fork),
    Component(name: "Rear Shock", installations: [Installation.sinceBeginning(parent: null)], componentType: ComponentType.shock),
    Component(name: "Brake", installations: [Installation.sinceBeginning(parent: null)], componentType: ComponentType.brakeCalliper),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_runAnimationSequence());
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

  Widget _handCursor() {
    return IgnorePointer(
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.touch_app,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hintTextWidget() {
    return AnimatedSwitcher(
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
                _hintTextWidget(),
                const SizedBox(height: 24),

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
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
                                    children: _mockComponents.map((c) {
                                      return GestureDetector(
                                        onTap: () => _onComponentTap(c.id),
                                        onDoubleTap: () => _onComponentDoubleTap(c.id),
                                        child: GarageComponentIconCard(
                                          component: c, 
                                          componentToShowDetails: null
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
                                              (c) => c.id == _expandedId,
                                            ).componentType.getIconData(),
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onTertiaryContainer,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _mockComponents.firstWhere(
                                              (c) => c.id == _expandedId,
                                            ).name,
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

                        
                        ..._mockBikes.map((b) {
                          return Card(
                            child: ListTile(
                              title: Text(b.name),
                            ),
                          );
                        }),
                        const Divider(),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.shelves),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  "Archive - Deinstalled components",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: null,
                                trailing: null,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    

                    Positioned.fill(
                      child: _handCursor(),
                    ),
                  ],
                ),
              
                const SizedBox(height: 60),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
