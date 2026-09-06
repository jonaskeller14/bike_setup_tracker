import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/component.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup.dart';
import '../display_adjustment/display_numerical_adjustment.dart';
import '../items/setup_tile_header.dart';
import '../items/tile_meta_row.dart';
import '../lists/adjustment_compact_display_list.dart';
import '../set_adjustment/set_boolean_adjustment.dart';
import '../set_adjustment/set_step_adjustment.dart';
import 'onboarding_motion.dart';
import 'onboarding_shared_element.dart';

/// The example fork slide 4 records setups for.
///
/// Onboarding runs without an `AppRepository`, so the component, its adjustment
/// definitions and the already-saved snapshots are built here. The definitions
/// carry fixed ids so the same adjustment addresses its value in every
/// snapshot, exactly as a real component does.
abstract final class OnboardingSetupExample {
  static final NumericalAdjustment pressure = NumericalAdjustment(
    id: 'onboarding-pressure',
    name: "Pressure",
    notes: null,
    unit: AdjustmentUnit.fromLegacy('psi'),
    min: 0,
    max: 300,
  );

  static final StepAdjustment rebound = StepAdjustment(
    id: 'onboarding-rebound',
    name: "Rebound",
    notes: null,
    unit: null,
    min: 0,
    max: 12,
    step: 1,
    visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
  );

  static final BooleanAdjustment lockout = BooleanAdjustment(
    id: 'onboarding-lockout',
    name: "Lockout",
    notes: null,
    unit: null,
  );

  static final Component fork = Component(
    id: 'onboarding-fork',
    name: "Suspension Fork",
    componentType: ComponentType.fork,
    installations: const [],
    adjustments: [pressure, rebound, lockout],
  );

  /// The values the new setup starts from — the ones the last ride was saved
  /// with — and where the scripted edits take them.
  static const double startPressure = 78;
  static const double startRebound = 6;
  static const bool startLockout = false;
  static const double editedPressure = 81;
  static const double editedRebound = 10;

  static Map<String, dynamic> _values(double pressureValue, double reboundValue, bool lockoutValue) => {
    pressure.id: pressureValue,
    rebound.id: reboundValue,
    lockout.id: lockoutValue,
  };

  static Setup _setup({
    required String name,
    required DateTime at,
    required Map<String, dynamic> values,
    required Map<String, dynamic> previousValues,
  }) {
    return Setup(
      name: name,
      datetime: at,
      datetimeLocal: at,
      tags: const <String>{},
      bike: 'onboarding-bike',
      person: null,
      bikeAdjustmentValues: values,
      personAdjustmentValues: const {},
    )..previousBikeAdjustmentValues = previousValues;
  }

  /// The setup the slide records, stamped with [now].
  static OnboardingSnapshot newSetup(DateTime now) => OnboardingSnapshot(
    setup: _setup(
      name: "My new Setup",
      at: now,
      values: _values(editedPressure, editedRebound, startLockout),
      previousValues: _values(startPressure, startRebound, startLockout),
    ),
    place: "Whistler, CA",
    condition: Condition.dry,
  );

  /// The snapshots already in the diary, newest first.
  static List<OnboardingSnapshot> olderSnapshots(DateTime now) {
    final lastRide = _values(startPressure, startRebound, startLockout);
    final firstRide = _values(72, 4, true);

    return [
      OnboardingSnapshot(
        setup: _setup(
          name: "Enduro Day",
          at: now.subtract(const Duration(days: 6)),
          values: lastRide,
          previousValues: firstRide,
        ),
        place: "Finale Ligure, IT",
        condition: Condition.wet,
      ),
      OnboardingSnapshot(
        setup: _setup(
          name: "Bikepark Day",
          at: now.subtract(const Duration(days: 20)),
          values: firstRide,
          previousValues: const {},
        ),
        place: "Leogang, AT",
        condition: Condition.dry,
      ),
    ];
  }
}

/// A saved setup plus the context it was ridden in.
class OnboardingSnapshot {
  const OnboardingSnapshot({required this.setup, required this.place, required this.condition});

  final Setup setup;
  final String place;
  final Condition condition;
}

/// The setup being recorded on slide 4.
///
/// Chrome and header are the production ones a `SetupListTile` renders, and the
/// rows are the real set/display adjustment widgets, so the mock card is built
/// from the same pieces a real setup is.
class OnboardingSetupCard extends StatelessWidget {
  const OnboardingSetupCard({
    super.key,
    required this.snapshot,
    required this.headerReveal,
    required this.pressure,
    required this.rebound,
    required this.lockout,
    required this.onReboundChanged,
    required this.onLockoutChanged,
    this.rowsKey,
    this.rowsHidden,
  });

  final OnboardingSnapshot snapshot;

  /// How far the stamped header has opened, 0..1. Driven by the slide's
  /// scripted sequence.
  final double headerReveal;

  final double pressure;
  final double rebound;
  final bool lockout;
  final ValueChanged<double?> onReboundChanged;
  final ValueChanged<bool?> onLockoutChanged;

  /// Target endpoint of the adjustment rows' flight from slide 3.
  final GlobalKey? rowsKey;
  final ValueListenable<bool>? rowsHidden;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          onboardingReveal(
            progress: headerReveal,
            child: onboardingSetupCardHeader(context: context, snapshot: snapshot),
          ),
          SharedElementEndpoint(
            endpointKey: rowsKey,
            hidden: rowsHidden,
            child: OnboardingSetupRows(
              pressure: pressure,
              rebound: rebound,
              lockout: lockout,
              onReboundChanged: onReboundChanged,
              onLockoutChanged: onLockoutChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three adjustment rows of the setup being recorded.
///
/// Also rendered by the flight that carries the rows over from slide 3, so the
/// transition ends on exactly the rows the slide keeps.
class OnboardingSetupRows extends StatelessWidget {
  const OnboardingSetupRows({
    super.key,
    this.pressure = OnboardingSetupExample.startPressure,
    this.rebound = OnboardingSetupExample.startRebound,
    this.lockout = OnboardingSetupExample.startLockout,
    this.onReboundChanged,
    this.onLockoutChanged,
  });

  final double pressure;
  final double rebound;
  final bool lockout;
  final ValueChanged<double?>? onReboundChanged;
  final ValueChanged<bool?>? onLockoutChanged;

  static void _ignore(Object? _) {}

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shown the way a saved value is rather than as another control
        // competing for a tap: the script dials it in, the user does not.
        DisplayNumericalAdjustmentWidget(
          key: const ValueKey('onboarding_pressure_row'),
          adjustment: OnboardingSetupExample.pressure,
          initialValue: OnboardingSetupExample.startPressure,
          value: pressure,
          showFill: true,
        ),
        SetStepAdjustmentWidget(
          key: const ValueKey('onboarding_rebound_row'),
          adjustment: OnboardingSetupExample.rebound,
          initialValue: OnboardingSetupExample.startRebound,
          value: rebound,
          onChanged: onReboundChanged ?? _ignore,
          onChangedEnd: _ignore,
        ),
        SetBooleanAdjustmentWidget(
          key: const ValueKey('onboarding_lockout_row'),
          adjustment: OnboardingSetupExample.lockout,
          initialValue: OnboardingSetupExample.startLockout,
          value: lockout,
          onChanged: onLockoutChanged ?? _ignore,
        ),
      ],
    );
  }
}

/// A setup already in the diary: the same chrome and header over the compact
/// value list a saved setup is listed with.
class OnboardingSetupSnapshotCard extends StatelessWidget {
  const OnboardingSetupSnapshotCard({super.key, required this.snapshot, this.collapse = 0});

  final OnboardingSnapshot snapshot;

  /// How far the card is tucked into the stack, 0..1. Only the values and the
  /// context row collapse: the title and its date hold their place, so a
  /// stacked card still says which ride it was and the timeline dot beside it
  /// never has to move.
  final double collapse;

  /// Older entries stay legible but recede behind the setup being recorded, and
  /// recede further once they are stacked.
  static const double _dim = 0.7;
  static const double _stackedDim = 0.55;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: lerpDouble(_dim, _stackedDim, collapse)!,
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            onboardingSetupCardHeader(
              context: context,
              snapshot: snapshot,
              metadataReveal: 1 - collapse,
            ),
            onboardingReveal(
              alignment: Alignment.topCenter,
              progress: 1 - collapse,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdjustmentCompactDisplayList(
                  components: [OnboardingSetupExample.fork],
                  adjustmentValues: snapshot.setup.bikeAdjustmentValues,
                  previousAdjustmentValues: snapshot.setup.previousBikeAdjustmentValues,
                  showRowIcons: true,
                  highlightInitialValues: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inset of the header inside the card, and the size of a `Setup` tile icon.
/// Together they place a card's title, which [onboardingSetupTitleAnchor] needs.
const EdgeInsets _headerPadding = EdgeInsets.fromLTRB(16, 12, 16, 4);
const double _setupIconSize = 24;

/// The production setup tile header, fed by a mock setup.
///
/// [metadataReveal] collapses the place and conditions row, leaving a card
/// tucked into the stack with just its title and date.
Widget onboardingSetupCardHeader({
  required BuildContext context,
  required OnboardingSnapshot snapshot,
  double metadataReveal = 1,
}) {
  final appSettings = context.watch<AppSettings>();
  final condition = snapshot.condition;
  final dateText = DateFormat(appSettings.dateFormat).format(snapshot.setup.datetimeLocal);
  final timeText = DateFormat(appSettings.timeFormat).format(snapshot.setup.datetimeLocal);

  return Padding(
    padding: _headerPadding,
    child: SetupTileHeader(
      setup: snapshot.setup,
      dateTimeText: "$dateText • $timeText",
      showSetupIcon: true,
      // One composite child rather than one entry per row: the block collapses
      // as a whole, and an empty list is what keeps the header's own metadata
      // padding from lingering behind it.
      metadata: [
        if (metadataReveal > 0)
          onboardingReveal(
            alignment: Alignment.topCenter,
            progress: metadataReveal,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TileMetaRow(icon: Icons.location_pin, text: snapshot.place, muted: true),
                TileMetaRow(
                  icon: condition.iconData,
                  text: condition.value,
                  iconColor: condition.color,
                  muted: true,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Vertical centre of a card's title, measured from the card's top edge.
///
/// The timeline dot lines up with the title rather than with the card's corner.
/// A stacked card keeps its title in place, so the dot needs no separate
/// treatment once the diary compresses.
double onboardingSetupTitleAnchor(BuildContext context) {
  final style = Theme.of(context).textTheme.titleMedium;
  final line = MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 16) * (style?.height ?? 1.5);
  return _headerPadding.top + math.max(_setupIconSize, line) / 2;
}
