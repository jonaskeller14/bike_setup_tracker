// Renders every state of the "Choose items" sheet (SelectDataItemsSheetContent)
// to PNGs in build/gallery/data_select/ (git-ignored), for a quick visual check
// after changing the sheet, its rows or the warning banner. Skipped by default
// (see dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/data_select_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; each
// sheet state is also written on its own.
//
// Names that start with "my" are user data (bike, setup, component names...).
// Anything else on screen (counts, BIKE NOT FOUND, the banner, the "... not
// selected" lines) comes from the UI.
//
// The sheet starts empty; each state is reached by ticking and unticking
// groups like a user would. Export, share and import use the same sheet with
// the same parameters, so there is no per-flow state.
//
// Besides the pictures, the second test checks that no state traps the user:
// Select missing clears every warning, and an empty selection can be filled.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/services/data_selection_dependencies.dart';
import 'package:bike_setup_tracker/widgets/sheets/data_select.dart';
import 'package:bike_setup_tracker/widgets/sheets/data_select_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _narrow = 320.0;
const _wide = 412.0;

final _day = DateTime(2026, 5, 1, 10);

/// One dataset with a reference of every kind: rider, bikes, components on a
/// bike and on a component, setups with values for component and rider
/// adjustments, a test session, a feedback, a task rule and its entry, and a
/// setup on a bike the dataset doesn't contain.
SelectedData _scene({bool longNames = false}) {
  String name(String short) => longNames ? '$short with a very long name that keeps going and going' : short;

  final rebound = BooleanAdjustment(id: 'rebound', name: 'myRebound', notes: null, unit: null);
  final lockout = BooleanAdjustment(id: 'lockout', name: 'myLockout', notes: null, unit: null);
  final pack = BooleanAdjustment(id: 'pack', name: 'myPack', notes: null, unit: null);
  Installation onBike(String id) => BikeInstallation(bikeId: id, dateTimeUTC: _day.toUtc(), dateTimeLocal: _day);
  Installation onPart(String id) =>
      ComponentInstallation(parentComponentId: id, dateTimeUTC: _day.toUtc(), dateTimeLocal: _day);
  Component part(String id, String label, ComponentType type, Installation at, [List<Adjustment>? adjustments]) =>
      Component(
        id: id,
        name: name(label),
        componentType: type,
        installations: [at],
        adjustments: adjustments,
      );
  Setup setup(String id, String label, String bike, {String? person, String? testSessionId}) => Setup(
    id: id,
    name: name(label),
    datetime: _day.toUtc(),
    datetimeLocal: _day,
    tags: const {},
    bike: bike,
    person: person,
    bikeAdjustmentValues: id == 's1' ? const {'rebound': BooleanValue(true), 'lockout': BooleanValue(false)} : const {},
    personAdjustmentValues: id == 's1' ? const {'pack': BooleanValue(true)} : const {},
    testSessionId: testSessionId,
  );

  return SelectedData(
    persons: {
      'p1': Person(id: 'p1', name: name('myRider1'), adjustments: [pack]),
    },
    bikes: {
      'b1': Bike(id: 'b1', name: name('myBike1'), person: 'p1'),
      'b2': Bike(id: 'b2', name: name('myBike2'), person: null),
    },
    components: {
      for (final c in [
        part('fork', 'myFork', ComponentType.fork, onBike('b1'), [rebound]),
        part('shock', 'myShock', ComponentType.shock, onBike('b1'), [lockout]),
        part('wheel', 'myWheel1', ComponentType.wheelFront, onBike('b2')),
        part('tire', 'myTire1', ComponentType.tire, onPart('wheel')),
      ])
        c.id: c,
    },
    setups: {
      for (final s in [
        setup('s1', 'mySetup1', 'b1', person: 'p1', testSessionId: 't1'),
        setup('s2', 'mySetup2', 'b2'),
        setup('s3', 'mySetup3', 'bike-not-in-file'),
      ])
        s.id: s,
    },
    taskRules: {
      'r1': TaskRule(
        id: 'r1',
        name: name('myTask1'),
        tags: const {},
        association: const ComponentTaskAssociation('fork'),
      ),
      'r2': TaskRule(id: 'r2', name: name('myTask2'), tags: const {}, association: const BikeTaskAssociation('b2')),
    },
    taskEntries: {
      'e1': TaskEntry(
        id: 'e1',
        name: name('myTask1'),
        dateTimeUTC: _day.toUtc(),
        dateTimeLocal: _day,
        taskRule: 'r1',
        association: const ComponentTaskAssociation('fork'),
      ),
    },
    feedbacks: {
      'f1': RideFeedback(id: 'f1', bike: 'b1', setupId: 's1', dateTimeUTC: _day.toUtc(), dateTimeLocal: _day),
    },
    testSessions: {
      't1': TestSession(
        id: 't1',
        name: name('myTestSession1'),
        bike: 'b1',
        adjustmentIds: const ['rebound'],
        startedAtUTC: _day.toUtc(),
        startedAtLocal: _day,
      ),
    },
  );
}

/// The groups in the order the sheet shows them (with every feature on).
const _groupOrder = [
  DataKind.bike,
  DataKind.component,
  DataKind.setup,
  DataKind.person,
  DataKind.taskRule,
  DataKind.taskEntry,
  DataKind.feedback,
  DataKind.testSession,
];

Finder _group(DataKind kind) => find.byType(ExpansionTile).at(_groupOrder.indexOf(kind));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _groupCheckbox(DataKind kind) => find.descendant(of: _group(kind), matching: find.byType(Checkbox)).first;

/// Taps a group's header checkbox until the whole group is [ticked]. A partly
/// ticked group unticks on the first tap.
Future<void> _setGroup(WidgetTester tester, DataKind kind, {required bool ticked}) async {
  while (tester.widget<Checkbox>(_groupCheckbox(kind)).value != ticked) {
    await _tap(tester, _groupCheckbox(kind));
  }
}

Future<void> _expand(WidgetTester tester, Iterable<DataKind> kinds) async {
  for (final kind in kinds) {
    await _tap(tester, find.descendant(of: _group(kind), matching: find.byType(Text)).first);
  }
}

typedef _Steps = Future<void> Function(WidgetTester tester);

Future<void> _nothing(WidgetTester tester) async {}

/// Every setup ticked (which ticks what they need), then the bikes unticked.
Future<void> _setupsWithoutBikes(WidgetTester tester) async {
  await _setGroup(tester, DataKind.setup, ticked: true);
  await _setGroup(tester, DataKind.bike, ticked: false);
}

/// Everything ticked, then every group that other rows reference unticked, so
/// each kind of row shows its "Not selected" line.
Future<void> _everyKindMissing(WidgetTester tester) async {
  for (final kind in _groupOrder) {
    await _setGroup(tester, kind, ticked: true);
  }
  for (final kind in [DataKind.bike, DataKind.person, DataKind.component, DataKind.taskRule, DataKind.testSession]) {
    await _setGroup(tester, kind, ticked: false);
  }
}

class _Case {
  final String slug;
  final String title;
  final double width;
  final Locale locale;
  final bool longNames;
  final bool enablePerson;
  final bool hasIssues;
  final _Steps select;
  final List<DataKind> expand;
  final bool tapShow;

  const _Case({
    required this.slug,
    required this.title,
    required this.select,
    this.width = _wide,
    this.locale = const Locale('en'),
    this.longNames = false,
    this.enablePerson = true,
    this.hasIssues = false,
    this.expand = const [],
    this.tapShow = false,
  });
}

final _cases = [
  const _Case(slug: 'empty', title: 'Nothing selected · Continue disabled', select: _nothing),
  _Case(
    slug: 'consistent',
    title: 'Consistent: setups ticked, what they need was ticked too',
    select: (tester) => _setGroup(tester, DataKind.setup, ticked: true),
    expand: const [DataKind.bike, DataKind.setup],
  ),
  const _Case(
    slug: 'inconsistent',
    title: 'Inconsistent: setups ticked, bikes unticked',
    select: _setupsWithoutBikes,
    hasIssues: true,
    expand: [DataKind.bike, DataKind.component, DataKind.setup, DataKind.testSession],
  ),
  const _Case(
    slug: 'inconsistent-collapsed',
    title: 'Inconsistent, all groups collapsed (group ⚠ only)',
    select: _setupsWithoutBikes,
    hasIssues: true,
  ),
  const _Case(
    slug: 'after-show',
    title: 'Inconsistent, after tapping Show',
    select: _setupsWithoutBikes,
    hasIssues: true,
    tapShow: true,
  ),
  const _Case(
    slug: 'every-kind',
    title: 'Every kind of row with a missing reference',
    select: _everyKindMissing,
    hasIssues: true,
    expand: _groupOrder,
  ),
  _Case(
    slug: 'rider-flag-off',
    title: 'Rider feature off, rider unticked (bike row has only the warning line)',
    select: (tester) async {
      await _setGroup(tester, DataKind.bike, ticked: true);
      await _setGroup(tester, DataKind.person, ticked: false);
    },
    enablePerson: false,
    hasIssues: true,
    expand: const [DataKind.bike],
  ),
  _Case(
    slug: 'outside-dataset',
    title: 'Setup on a bike the file lacks: red, but no warning (nothing to tick)',
    select: (tester) async {
      await _expand(tester, const [DataKind.setup]);
      await _tap(tester, find.text('mySetup3'));
    },
  ),
  const _Case(
    slug: 'narrow-every-kind',
    title: '320 px · every kind',
    width: _narrow,
    select: _everyKindMissing,
    hasIssues: true,
    expand: _groupOrder,
  ),
  const _Case(
    slug: 'narrow-long-names',
    title: '320 px · long names, inconsistent',
    width: _narrow,
    longNames: true,
    select: _setupsWithoutBikes,
    hasIssues: true,
    expand: [DataKind.bike, DataKind.setup],
  ),
  const _Case(
    slug: 'narrow-german',
    title: '320 px · German, every kind',
    width: _narrow,
    locale: Locale('de'),
    select: _everyKindMissing,
    hasIssues: true,
    expand: _groupOrder,
  ),
  const _Case(
    slug: 'narrow-german-collapsed',
    title: '320 px · German, collapsed',
    width: _narrow,
    locale: Locale('de'),
    select: _setupsWithoutBikes,
    hasIssues: true,
  ),
];

Future<void> _pumpSheet(WidgetTester tester, ThemeData theme, _Case c, Key key) async {
  final settings = AppSettings()
    ..showOnboarding = false
    ..enablePerson = c.enablePerson
    ..enableTask = true
    ..enableRating = true;
  addTearDown(settings.dispose);
  tester.view.physicalSize = Size(c.width, 3000);
  final data = _scene(longNames: c.longNames);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: RepaintBoundary(
        key: key,
        child: localizedTestApp(
          theme: theme,
          locale: c.locale,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => SelectDataItemsSheetContent(allData: data, onConfirm: (_) {}, onBack: () {}),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await c.select(tester);
  await _expand(tester, c.expand);
  if (c.tapShow) await _tap(tester, find.descendant(of: _banner, matching: find.byType(TextButton)).first);
  // Taps scrolled the list; show it from the top.
  tester.state<ScrollableState>(find.byType(Scrollable).last).position.jumpTo(0);
  await tester.pumpAndSettle();
}

final _banner = find.byType(DataSelectWarningBanner);

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('data_select'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      for (final (index, c) in _cases.indexed) {
        final key = ValueKey(index);
        await _pumpSheet(tester, theme, c, key);
        expect(_banner, c.hasIssues ? findsOneWidget : findsNothing, reason: c.title);
        await session.add(
          c.slug,
          c.title,
          tester.renderObject(find.byKey(key)),
          crop: tester.getRect(find.byType(BottomSheet)),
        );
      }

      await session.finish();
    });
  }

  testWidgets('every state can reach a consistent, confirmable selection', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    for (final (index, c) in _cases.indexed) {
      await _pumpSheet(tester, galleryThemes.first.$2, c, ValueKey(index));
      if (c.hasIssues) {
        await _tap(tester, find.descendant(of: _banner, matching: find.byType(TextButton)).last);
      } else if (tester.widget<FilledButton>(find.byType(FilledButton)).onPressed == null) {
        await _setGroup(tester, DataKind.bike, ticked: true);
      }

      expect(_banner, findsNothing, reason: '"${c.title}": Select missing leaves a warning');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
        reason: '"${c.title}": Continue stays disabled',
      );
    }
  });
}
