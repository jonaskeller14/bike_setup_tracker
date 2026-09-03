import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding_motion.dart';
import 'onboarding_setup_card.dart';
import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

/// The whole scripted sequence: stamp the setup, dial the pressure in, click the
/// rebound over, drop it into the diary and then tuck the diary into a stack.
/// It never gates the primary action, and the first touch fast-forwards it so
/// the slide is settled and the user is in control.
const Duration kOnboardingSetupScript = Duration(milliseconds: 5000);
const Duration kOnboardingSetupHandover = Duration(milliseconds: 350);

class OnboardingSlide4 extends StatefulWidget {
  const OnboardingSlide4({
    super.key,
    required this.onFinish,
    required this.active,
    this.rowsKey,
    this.rowsHidden,
  });

  final VoidCallback onFinish;

  /// True once this is the settled page. The scripted sequence starts then, and
  /// only ever once — coming back to the slide does not replay it.
  final bool active;

  /// Target endpoint of the adjustment rows' flight from slide 3.
  final GlobalKey? rowsKey;
  final ValueListenable<bool>? rowsHidden;

  @override
  State<OnboardingSlide4> createState() => _OnboardingSlide4State();
}

class _OnboardingSlide4State extends State<OnboardingSlide4> with SingleTickerProviderStateMixin {
  // Fractions of the script. The setup names itself first, then it is filled
  // in one value at a time — the pressure ramps in before the rebound starts
  // clicking — then the drop into the diary, a second to read it, and the tuck
  // into the stack.
  static const double _stampStart = 0.04;
  static const double _stampEnd = 0.14;
  static const double _pressureStart = 0.17;
  static const double _pressureEnd = 0.36;
  static const double _reboundStart = 0.38;
  static const double _reboundEnd = 0.54;
  static const double _dropStart = 0.56;
  static const double _dropEnd = 0.72;
  static const double _stackStart = 0.92;

  static const double _dotSize = 15;
  static const double _lineWidth = 3;

  /// The pressure is dialled in a tenth at a time, the way a shock pump reads.
  static const double _pressureStep = 0.1;

  /// Gap below an entry, and what it closes to once the diary is stacked.
  static const double _entryGap = 12;
  static const double _stackedGap = 5;

  late final AnimationController _script = AnimationController(vsync: this, duration: kOnboardingSetupScript);

  late final DateTime _now = DateTime.now();
  late final OnboardingSnapshot _recorded = OnboardingSetupExample.newSetup(_now);
  late final List<OnboardingSnapshot> _older = OnboardingSetupExample.olderSnapshots(_now);

  bool _started = false;

  /// Set on the first touch: the values are the user's from then on and the
  /// script stops driving them.
  bool _userInControl = false;
  double _pressure = OnboardingSetupExample.startPressure;
  double _rebound = OnboardingSetupExample.startRebound;
  bool _lockout = OnboardingSetupExample.startLockout;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(covariant OnboardingSlide4 oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStart();
  }

  @override
  void dispose() {
    _script.dispose();
    super.dispose();
  }

  void _maybeStart() {
    if (_started || !widget.active) return;
    _started = true;

    if (reduceMotion(context)) {
      _script.value = 1;
    } else {
      unawaited(_script.forward());
    }
  }

  /// Where the script has taken the pressure, rounded to the pump's resolution.
  double get _scriptedPressure {
    final raw = lerpDouble(
      OnboardingSetupExample.startPressure,
      OnboardingSetupExample.editedPressure,
      Curves.easeInOut.transform(stageProgress(_script.value, _pressureStart, _pressureEnd)),
    )!;
    return (raw / _pressureStep).roundToDouble() * _pressureStep;
  }

  /// Where the script has taken the rebound, in whole clicks.
  double get _scriptedRebound => lerpDouble(
    OnboardingSetupExample.startRebound,
    OnboardingSetupExample.editedRebound,
    Curves.easeInOut.transform(stageProgress(_script.value, _reboundStart, _reboundEnd)),
  )!.roundToDouble();

  double get _displayedPressure => _userInControl ? _pressure : _scriptedPressure;
  double get _displayedRebound => _userInControl ? _rebound : _scriptedRebound;

  /// Hands the slide to the user: the script stops performing and runs out to
  /// its settled state, so nothing keeps moving while they interact.
  void _takeControl() {
    if (_userInControl) return;
    setState(() {
      _pressure = _scriptedPressure;
      _rebound = _scriptedRebound;
      _userInControl = true;
    });
    if (_script.value < 1) {
      unawaited(_script.animateTo(1, duration: kOnboardingSetupHandover, curve: Curves.easeOut));
    }
  }

  void _setRebound(double? value) {
    _takeControl();
    final next = value ?? OnboardingSetupExample.startRebound;
    if (next == _rebound) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _rebound = next);
  }

  void _setLockout(bool? value) {
    _takeControl();
    unawaited(HapticFeedback.selectionClick());
    setState(() => _lockout = value ?? OnboardingSetupExample.startLockout);
  }

  Widget _timeline(BuildContext context, double drop, double stack) {
    final gap = lerpDouble(_entryGap, _stackedGap, stack)!;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _entry(
            context,
            drop: drop,
            gap: gap,
            isFirst: true,
            isLast: false,
            child: OnboardingSetupCard(
              snapshot: _recorded,
              headerReveal: stageProgress(_script.value, _stampStart, _stampEnd),
              pressure: _displayedPressure,
              rebound: _displayedRebound,
              lockout: _lockout,
              onReboundChanged: _setRebound,
              onLockoutChanged: _setLockout,
              rowsKey: widget.rowsKey,
              rowsHidden: widget.rowsHidden,
            ),
          ),
          for (var index = 0; index < _older.length; index++)
            onboardingReveal(
              alignment: Alignment.topCenter,
              progress: stageProgress(drop, index * 0.3, 0.7 + index * 0.3),
              child: _entry(
                context,
                drop: drop,
                gap: gap,
                isFirst: false,
                isLast: index == _older.length - 1,
                child: OnboardingSetupSnapshotCard(snapshot: _older[index], collapse: stack),
              ),
            ),
        ],
      ),
    );
  }

  /// One entry of the diary: its card, with the rail drawn beside it.
  ///
  /// The rail is positioned rather than laid out next to the card, so the entry
  /// never asks its contents for an intrinsic height — the compact value list
  /// measures itself with a `LayoutBuilder` and cannot answer that.
  Widget _entry(
    BuildContext context, {
    required double drop,
    required double gap,
    required bool isFirst,
    required bool isLast,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // The dot marks the entry's title, not the corner of its card.
    final anchor = onboardingSetupTitleAnchor(context);
    final lineColor = scheme.secondary.withValues(alpha: 0.6 * drop);

    Widget connector({double? top, double? height, double? bottom}) => Positioned(
      top: top,
      height: height,
      bottom: bottom,
      left: (_dotSize - _lineWidth) / 2,
      width: _lineWidth,
      child: ColoredBox(color: lineColor),
    );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: EdgeInsets.only(left: _dotSize + 12, bottom: gap),
          child: child,
        ),
        // The rail draws itself in with the drop: before it, the card is simply
        // a setup being recorded, not yet an entry in a diary.
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: _dotSize,
          child: Stack(
            children: [
              if (!isFirst) connector(top: 0, height: anchor - _dotSize / 2),
              if (!isLast) connector(top: anchor + _dotSize / 2, bottom: 0),
              Positioned(
                top: anchor - _dotSize / 2,
                left: 0,
                child: Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                    border: Border.all(color: scheme.secondary.withValues(alpha: drop), width: 2.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingSlideScaffold(
      onNext: widget.onFinish,
      nextLabel: "Finish",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Observing the pointer rather than absorbing it: the rows below stay
          // interactive, they just stop being driven by the script. Translucent
          // so a touch anywhere over the diary counts, not only one that lands
          // on a card.
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _takeControl(),
            child: AnimatedBuilder(
              animation: _script,
              builder: (context, _) => _timeline(
                context,
                stageProgress(_script.value, _dropStart, _dropEnd),
                stageProgress(_script.value, _stackStart, 1),
              ),
            ),
          ),
          const SizedBox(height: 60),
          stepWidget(context: context, step: 3),
          const SizedBox(height: 12),
          Text(
            'Your Setup Diary',
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
                TextSpan(text: "A "),
                TextSpan(
                  text: "Setup",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      " is a current snapshot of all components of one bike. It captures the specific values of your adjustments and automatically adds context (e.g. location, weather, trail conditions).",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
