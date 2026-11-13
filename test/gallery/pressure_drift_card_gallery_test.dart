// Renders the states of PressureDriftCard (readings, gaps, loading, collapsed and
// expanded) and its info sheet to PNGs in build/gallery/pressure_drift_card/
// (git-ignored), for a quick visual check after changing either widget. Skipped
// by default (see dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/pressure_drift_card_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; the
// cards and the sheet are also written on their own.
//
// Names that start with "my" are user data (Component.name, Adjustment.name).
// Anything else on screen (captions, hints, reasons) comes from the UI. The
// readings run through the real PressureDriftService, so every number is the
// physics, not a hand-picked value.
//
// Every row offers the "Set now" toggle, as on the setup page; `setNow` marks
// readings as already set.
//
// Besides the pictures, the second test checks that no state traps the user:
// every card can be expanded and collapsed, every expanded card either lists
// its readings or says why there are none, every chevron points the way to
// pump, every unmarked reading has its chevron, and the info sheet opens from
// every expanded card.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/pressure_drift_service.dart';
import 'package:bike_setup_tracker/services/setup_resolution_service.dart';
import 'package:bike_setup_tracker/widgets/hint_card_parts.dart';
import 'package:bike_setup_tracker/widgets/pressure_drift_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _cellWidth = 360.0;
const _sheetWidth = 400.0;
const _longName = 'myForkWithAVeryLongNameThatWillNeverFitOnOneLine';

/// The info sheet at phone and narrow width; the narrow ones also grow the
/// text, and the last is the longest language.
class _SheetShot {
  final String slug;
  final String title;
  final double width;
  final double textScale;
  final Locale locale;

  const _SheetShot(this.slug, this.title, {required this.width, this.textScale = 1, this.locale = const Locale('en')});
}

const _sheets = [
  _SheetShot('sheet', 'Info sheet', width: _sheetWidth),
  _SheetShot('sheet_narrow', 'Info sheet, narrow, text scale 1.5', width: 320, textScale: 1.5),
  _SheetShot(
    'sheet_de_narrow',
    'Info sheet, German, narrow, text scale 1.5',
    width: 320,
    textScale: 1.5,
    locale: Locale('de'),
  ),
];

/// When the page asks for the drift.
final _now = DateTime.utc(2026, 11, 12, 9);

/// One pressure as it was set in an earlier setup, by default on a mild day
/// at low elevation. A null temperature or altitude is a setup saved without it.
class _Reading {
  final String component;
  final String adjustment;
  final double value;
  final String unit;
  final double? temperatureC;
  final double? altitudeM;
  final int day;
  final ComponentType componentType;

  const _Reading(
    this.component,
    this.adjustment,
    this.value, {
    this.unit = 'psi',
    this.temperatureC = 20,
    this.altitudeM = 500,
    this.day = 10,
    this.componentType = ComponentType.fork,
  });
}

class _Case {
  final String label;
  final List<_Reading> readings;

  /// Conditions now; null while the page has none.
  final double? temperatureC;
  final double? altitudeM;
  final bool loading;

  /// Indexes of the readings marked as set now.
  final Set<int> setNow;

  /// Toggles the card once after it renders.
  final bool toggle;
  final int thresholdPercent;
  final String temperatureUnit;
  final String altitudeUnit;
  final String dateFormat;
  final Locale locale;
  final double width;
  final double textScale;

  const _Case(
    this.label, {
    this.readings = const [],
    this.temperatureC = 5,
    this.altitudeM = 1800,
    this.loading = false,
    this.setNow = const {},
    this.toggle = false,
    this.thresholdPercent = 3,
    this.temperatureUnit = '°C',
    this.altitudeUnit = 'm',
    this.dateFormat = 'dd.MM.yyyy',
    this.locale = const Locale('en'),
    this.width = _cellWidth,
    this.textScale = 1,
  });

  List<Component> get _components {
    final names = {for (final r in readings) r.component};
    return [
      for (final name in names)
        Component(
          name: name,
          componentType: readings.firstWhere((r) => r.component == name).componentType,
          installations: [Installation.sinceBeginning(parent: 'bike_1')],
          adjustments: [
            for (final (i, r) in readings.indexed)
              if (r.component == name)
                NumericalAdjustment(
                  id: 'adj_$i',
                  name: r.adjustment,
                  notes: null,
                  unit: AdjustmentUnit.fromLegacy(r.unit),
                ),
          ],
        ),
    ];
  }

  List<Setup> get _setups => [
    for (final (i, r) in readings.indexed)
      Setup(
        id: 'setup_$i',
        datetime: DateTime.utc(2026, 10, r.day, 9),
        datetimeLocal: DateTime(2026, 10, r.day, 9),
        bike: 'bike_1',
        person: null,
        tags: const {},
        bikeAdjustmentValues: {'adj_$i': NumericalValue(r.value)},
        personAdjustmentValues: const {},
        position: r.altitudeM == null ? null : ContextPosition(latitude: 47, longitude: 11, altitude: r.altitudeM),
        weather: r.temperatureC == null
            ? null
            : ContextWeather(currentDateTime: DateTime.utc(2026, 10, r.day, 9), currentTemperature: r.temperatureC),
      ),
  ];

  ContextWeather? get _weather =>
      temperatureC == null ? null : ContextWeather(currentDateTime: _now, currentTemperature: temperatureC);

  ContextPosition? get _position =>
      altitudeM == null ? null : ContextPosition(latitude: 47, longitude: 11, altitude: altitudeM);

  /// The same call as the setup page.
  PressureCheck get check => PressureDriftService.check(
    components: _components,
    provenance: SetupResolutionService.resolveHistoricalProvenanceAt(datetime: _now, setups: _setups),
    currentWeather: _weather,
    currentPosition: _position,
    at: _now,
    significanceThreshold: thresholdPercent / 100,
  );

  AppSettings settings() => AppSettings()
    ..pressureCheckThresholdPercent = thresholdPercent
    ..temperatureUnit = temperatureUnit
    ..altitudeUnit = altitudeUnit
    ..dateFormat = dateFormat;

  Widget card() {
    return ChangeNotifierProvider<AppSettings>.value(
      value: settings(),
      child: Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: PressureDriftCard(
            check: check,
            loading: loading,
            setNowIds: {for (final i in setNow) 'adj_$i'},
            setNowAvailableIds: {for (final (i, _) in readings.indexed) 'adj_$i'},
            onSetNowChanged: (_, _) {},
          ),
        ),
      ),
    );
  }
}

const _fine = _Reading('myFork', 'myAirSpring', 80);

// 20 °C at 500 m → 5 °C at 1800 m reads about -3.5 %; → -10 °C at 500 m about
// -12 %; → 30 °C at 500 m about +4 %.
final _cases = [
  const _Case('Within threshold (collapsed by default)', readings: [_fine], temperatureC: 18, altitudeM: 600),
  const _Case('Within threshold, expanded', readings: [_fine], temperatureC: 18, altitudeM: 600, toggle: true),
  const _Case('Reads low: pump up (-3.5 %)', readings: [_fine]),
  const _Case('Reads high: let air out (+4 %)', readings: [_fine], temperatureC: 30, altitudeM: 500),
  const _Case(
    'Far off: double chevrons',
    readings: [
      _Reading('myFork', 'myAirSpring', 80),
      _Reading('myShock', 'myShockPressure', 180, temperatureC: -10, altitudeM: 2500, day: 3),
    ],
    temperatureC: -10,
    altitudeM: 500,
  ),
  const _Case(
    'Mixed: fine, low, high, far off',
    readings: [
      _Reading('myFork', 'myAirSpring', 80, temperatureC: 5, altitudeM: 1800, day: 2),
      _Reading('myShock', 'myShockPressure', 180),
      _Reading('myFrontTire', 'myTirePressure', 22, temperatureC: -5, altitudeM: 1800, day: 5),
      _Reading('myRearTire', 'myTirePressure', 24, temperatureC: 30, altitudeM: 0, day: 7),
    ],
  ),
  const _Case('Threshold 10 %: -3.5 % is fine', readings: [_fine], thresholdPercent: 10, toggle: true),
  const _Case(
    'bar and kPa',
    readings: [
      _Reading('myRearTire', 'myTirePressure', 1.6, unit: 'bar'),
      _Reading('myFork', 'myAirSpring', 550, unit: 'kPa'),
    ],
  ),
  const _Case(
    '°F, ft and a US date',
    readings: [_fine],
    temperatureUnit: '°F',
    altitudeUnit: 'ft',
    dateFormat: 'MM/dd/yyyy',
  ),
  const _Case(
    'Implausible: reading below zero (3 psi set at 3000 m)',
    readings: [_Reading('myFork', 'myAirSpring', 3, altitudeM: 3000)],
    temperatureC: -10,
    altitudeM: 0,
  ),
  const _Case('No pressure recorded yet', toggle: true),
  const _Case(
    'Recorded without temperature or altitude',
    readings: [_Reading('myFork', 'myAirSpring', 80, temperatureC: null)],
    toggle: true,
  ),
  const _Case('No current conditions (collapsed)', readings: [_fine], temperatureC: null),
  const _Case('No current conditions, expanded', readings: [_fine], altitudeM: null, toggle: true),
  const _Case('Fetching conditions (collapsed)', readings: [_fine], temperatureC: null, loading: true),
  const _Case('Fetching conditions, expanded', readings: [_fine], temperatureC: null, loading: true, toggle: true),
  const _Case('Refreshing while readings are shown', readings: [_fine], loading: true),
  const _Case(
    'German',
    readings: [
      _Reading('myFork', 'myAirSpring', 80),
      _Reading('myShock', 'myShockPressure', 180, temperatureC: 30, altitudeM: 0),
    ],
    locale: Locale('de'),
  ),
  const _Case(
    'Narrow screen, long names, text scale 1.5',
    readings: [
      _Reading(_longName, 'myAirSpringWithALongName', 80),
      _Reading('myShock', 'myShockPressure', 180, temperatureC: -10, altitudeM: 2500),
    ],
    width: 320,
    textScale: 1.5,
  ),
  const _Case('Drifted row marked as set now', readings: [_fine], setNow: {0}, toggle: true),
  const _Case(
    'Row within threshold marked',
    readings: [_fine],
    temperatureC: 18,
    altitudeM: 600,
    setNow: {0},
    toggle: true,
  ),
  const _Case(
    'All marked: no pump, stays open',
    readings: [
      _Reading('myFork', 'myAirSpring', 80),
      _Reading('myShock', 'myShockPressure', 180, temperatureC: 30, altitudeM: 0),
    ],
    setNow: {0, 1},
    toggle: true,
  ),
  const _Case(
    'References without conditions only',
    readings: [
      _Reading('myFork', 'myAirSpring', 80, temperatureC: null),
      _Reading('myShock', 'myShockPressure', 180, altitudeM: null),
    ],
    toggle: true,
  ),
  const _Case(
    'Mixed: drifted, marked, no conditions',
    readings: [
      _Reading('myFork', 'myAirSpring', 80),
      _Reading('myShock', 'myShockPressure', 180, temperatureC: null),
      _Reading('myRearTire', 'myTirePressure', 24, temperatureC: null),
    ],
    setNow: {0, 2},
  ),
  const _Case(
    'Tyre drifted by time only',
    readings: [_Reading('myRearTire', 'myTirePressure', 24, day: 31, componentType: ComponentType.tire)],
    temperatureC: 20,
    altitudeM: 500,
  ),
  const _Case(
    'German, narrow, text scale 1.5',
    readings: [
      _Reading(_longName, 'myAirSpringWithALongName', 80),
      _Reading('myShock', 'myShockPressure', 180, temperatureC: null),
    ],
    setNow: {1},
    locale: Locale('de'),
    width: 320,
    textScale: 1.5,
  ),
];

const _galleryKey = ValueKey('card-gallery');

/// Lets the spinner of a loading card run without waiting for it to settle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late Directory output;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    output = await prepareGallery('pressure_drift_card');
  });

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      tester.view.physicalSize = const Size(2 * _cellWidth + 80, 5000);
      await tester.pumpWidget(_galleryApp(theme));
      await _settle(tester);
      for (final (i, c) in _cases.indexed) {
        if (!c.toggle) continue;
        await tester.tap(find.descendant(of: find.byKey(ValueKey('cell$i')), matching: find.byType(HintCardHeader)));
        await _settle(tester);
      }
      await session.add('cards', 'Card states', tester.renderObject(find.byKey(_galleryKey)));

      for (final sheet in _sheets) {
        tester.view.physicalSize = Size(sheet.width, 3200);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_sheetApp(theme, sheet));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(HintLearnMoreText).first);
        await tester.pumpAndSettle();
        await session.add(
          sheet.slug,
          sheet.title,
          tester.renderObject(find.byKey(const ValueKey('sheet'))),
          crop: tester.getRect(find.byType(BottomSheet)),
        );
        expect(tester.takeException(), isNull, reason: '"${sheet.title}" overflows or throws');
      }

      await session.finish();
    });
  }

  testWidgets('every card opens, explains itself and points the way to pump', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_sheetWidth, 2000);

    for (final (index, c) in _cases.indexed) {
      final unmarked = c.check.driftEntries.where((e) => !c.setNow.any((i) => e.adjustmentId == 'adj_$i')).toList();
      await tester.pumpWidget(
        _app(
          galleryThemes.first.$2,
          SingleChildScrollView(child: c.card()),
          key: ValueKey(index),
          settings: c.settings(),
        ),
      );
      await _settle(tester);

      final header = find.byType(HintCardHeader);
      expect(header, findsOneWidget, reason: '"${c.label}": the card is hidden');
      final learnMore = find.byType(HintLearnMoreText);
      if (learnMore.evaluate().isEmpty) {
        await tester.tap(header);
        await _settle(tester);
      }
      expect(learnMore, findsOneWidget, reason: '"${c.label}": the card does not expand to explain itself');

      final icons = tester.widgetList<PressureDriftIcon>(find.byType(PressureDriftIcon)).toList();
      expect(icons.length, unmarked.length, reason: '"${c.label}": not every unmarked reading is listed');
      for (final icon in icons) {
        final shown = tester.widget<Icon>(find.descendant(of: find.byWidget(icon), matching: find.byType(Icon))).icon;
        final expected = switch ((icon.relativeDelta.abs() >= icon.threshold, icon.relativeDelta < 0)) {
          (false, _) => const [Icons.check_circle_outline],
          (true, true) => const [Icons.keyboard_arrow_up, Icons.keyboard_double_arrow_up],
          (true, false) => const [Icons.keyboard_arrow_down, Icons.keyboard_double_arrow_down],
        };
        expect(
          expected,
          contains(shown),
          reason: '"${c.label}": the icon for ${icon.relativeDelta} points the wrong way',
        );
      }

      await tester.tap(find.byType(HintLearnMoreText).first);
      await _settle(tester);
      expect(find.byType(BottomSheet), findsOneWidget, reason: '"${c.label}": Learn more does not open the info sheet');
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await _settle(tester);

      await tester.tap(header);
      await _settle(tester);
      expect(learnMore, findsNothing, reason: '"${c.label}": the card does not collapse again');
    }
  });
}

/// [settings] sit above the app, as in main.dart, so the info sheet's route
/// finds them; each card also gets its own case's settings.
Widget _app(
  ThemeData theme,
  Widget home, {
  Key? key,
  AppSettings? settings,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => RepaintBoundary(
  key: key,
  child: ChangeNotifierProvider<AppSettings>.value(
    value: settings ?? AppSettings(),
    child: localizedTestApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: home),
    ),
  ),
);

Widget _galleryApp(ThemeData theme) {
  return _app(
    theme,
    Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _galleryKey,
        child: ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final (i, c) in _cases.indexed)
                  SizedBox(
                    key: ValueKey('cell$i'),
                    width: c.width,
                    child: MediaQuery(
                      data: MediaQueryData(textScaler: TextScaler.linear(c.textScale)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(c.label, style: theme.textTheme.labelSmall),
                          ),
                          c.card(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _sheetApp(ThemeData theme, _SheetShot sheet) => _app(
  theme,
  Padding(
    padding: const EdgeInsets.all(16),
    child: Align(alignment: Alignment.topCenter, child: _cases[5].card()),
  ),
  key: const ValueKey('sheet'),
  settings: _cases[5].settings(),
  locale: sheet.locale,
  textScale: sheet.textScale,
);
