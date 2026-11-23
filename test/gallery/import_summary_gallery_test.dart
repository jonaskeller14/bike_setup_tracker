// Renders every state of the import summary step (ImportSummarySheetContent)
// to PNGs in build/gallery/import_summary/ (git-ignored), for a quick visual
// check after changing the sheet or its rows. Skipped by default (see
// dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/import_summary_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; each
// sheet state is also written on its own.
//
// Names that start with "my" are user data (bike, setup, component names...).
// Anything else on screen (badges, placeholders, counts, "Unnamed setup")
// comes from the UI.
//
// Each state is a real preview: a file and the data on this device go through
// FileImport.preview, as in the app. Every group is expanded.
//
// Besides the pictures, the second test checks that no state traps the user:
// every state either imports or goes back.
@Tags(['gallery'])
library;

import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/import_preview.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/widgets/sheets/import_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _narrow = 320.0;
const _wide = 412.0;

final _newer = DateTime.utc(2026, 5, 2, 9);
final _older = DateTime.utc(2026, 4, 20, 18);
final _day = DateTime(2026, 5, 1, 10);

String _long(String name, bool longNames) =>
    longNames ? '$name with a very long name that keeps going and going' : name;

Bike _bike(String id, String name, {DateTime? edited, bool? isDeleted}) =>
    Bike(id: id, name: name, person: null, lastModified: edited ?? _older, isDeleted: isDeleted);

Component _component(String id, String name, ComponentType type, {DateTime? edited}) =>
    Component(id: id, name: name, componentType: type, installations: const [], lastModified: edited ?? _older);

Setup _setup(String id, String? name, {DateTime? edited}) => Setup(
  id: id,
  name: name,
  lastModified: edited ?? _older,
  datetime: _day.toUtc(),
  datetimeLocal: _day,
  tags: const {},
  bike: 'b1',
  person: null,
  bikeAdjustmentValues: const {},
  personAdjustmentValues: const {},
);

/// Every outcome on every kind: new, restored from the trash, updated,
/// identical, older (skipped by Merge, overwritten otherwise), deleted in the
/// file, and a local item the file lacks (trashed by Replace only).
(SelectedData, SelectedData) _mixed({bool longNames = false}) {
  String name(String short) => _long(short, longNames);
  final identicalBike = _bike('b2', name('myBike2'));
  final identicalSetup = _setup('s1', name('mySetup1'));

  final local = SelectedData(
    persons: {'p1': Person(id: 'p1', name: name('myRider1'), lastModified: _older)},
    bikes: {
      'b1': _bike('b1', name('myBike1'), edited: _older),
      'b2': identicalBike,
      'b3': _bike('b3', name('myBike3')),
      'b4': _bike('b4', name('myBike4'), isDeleted: true),
    },
    components: {
      'fork': _component('fork', name('myFork1'), ComponentType.fork),
      'shock': _component('shock', name('myShock1Edited'), ComponentType.shock, edited: _newer),
    },
    setups: {'s1': identicalSetup},
    testSessions: {
      't1': TestSession(
        id: 't1',
        name: name('myTestSession1'),
        bike: 'b1',
        adjustmentIds: const [],
        startedAtUTC: _day.toUtc(),
        startedAtLocal: _day,
        lastModified: _older,
      ),
    },
  );
  final remote = SelectedData(
    persons: {'p1': Person(id: 'p1', name: name('myRider1'), lastModified: _newer, isDeleted: true)},
    bikes: {
      'b1': _bike('b1', name('myBike1Renamed'), edited: _newer),
      'b2': identicalBike,
      'b4': _bike('b4', name('myBike4'), edited: _newer),
      'b5': _bike('b5', name('myBike5'), edited: _newer),
    },
    components: {
      'fork': _component('fork', name('myFork1Renamed'), ComponentType.fork, edited: _newer),
      'shock': _component('shock', name('myShock1'), ComponentType.shock, edited: _older),
    },
    setups: {
      's1': identicalSetup,
      's2': _setup('s2', name('mySetup2'), edited: _newer),
      's3': _setup('s3', null, edited: _newer),
    },
    taskRules: {
      'r1': TaskRule(id: 'r1', name: name('myTask1'), tags: const {}, association: const BikeTaskAssociation('b1')),
    },
    taskEntries: {
      'e1': TaskEntry(
        id: 'e1',
        name: name('myTask1'),
        dateTimeUTC: _day.toUtc(),
        dateTimeLocal: _day,
        taskRule: 'r1',
        association: const BikeTaskAssociation('b1'),
      ),
    },
    feedbacks: {
      'f1': RideFeedback(id: 'f1', bike: 'b1', setupId: 's1', dateTimeUTC: _day.toUtc(), dateTimeLocal: _day),
    },
    testSessions: {
      't1': TestSession(
        id: 't1',
        name: name('myTestSession1Renamed'),
        bike: 'b1',
        adjustmentIds: const [],
        startedAtUTC: _day.toUtc(),
        startedAtLocal: _day,
        lastModified: _newer,
      ),
    },
  );
  return (remote, local);
}

(SelectedData, SelectedData) _mixedLong() => _mixed(longNames: true);

/// The maintainer's case: a file with one setup, imported with Replace over a
/// device full of data.
(SelectedData, SelectedData) _oneSetupOverFullDevice() {
  final setup = _setup('s1', 'mySetup1');
  final local = SelectedData(
    bikes: {for (var i = 1; i <= 6; i++) 'b$i': _bike('b$i', 'myBike$i')},
    components: {for (var i = 1; i <= 4; i++) 'c$i': _component('c$i', 'myFork$i', ComponentType.fork)},
    setups: {'s1': setup, for (var i = 2; i <= 8; i++) 's$i': _setup('s$i', 'mySetup$i')},
  );
  return (SelectedData(setups: {'s1': setup}), local);
}

/// A file whose only item is deleted in the file and absent here: nothing changes.
(SelectedData, SelectedData) _nothingChanges() => (
  SelectedData(bikes: {'b9': _bike('b9', 'myBike9', isDeleted: true)}),
  SelectedData(bikes: {'b1': _bike('b1', 'myBike1')}),
);

enum _Load { data, pending, error }

class _Case {
  final String slug;
  final String title;
  final ImportMethod method;
  final (SelectedData, SelectedData) Function() data;
  final _Load load;
  final ImportSourceOptions source;
  final double width;
  final Locale locale;

  const _Case({
    required this.slug,
    required this.title,
    required this.method,
    required this.data,
    this.load = _Load.data,
    this.source = ImportSourceOptions.file,
    this.width = _wide,
    this.locale = const Locale('en'),
  });
}

const _cases = [
  _Case(slug: 'merge', title: 'Merge · every outcome', method: ImportMethod.merge, data: _mixed),
  _Case(
    slug: 'overwrite',
    title: 'Overwrite · older file version overwrites too',
    method: ImportMethod.overwrite,
    data: _mixed,
  ),
  _Case(
    slug: 'replace',
    title: 'Replace · every outcome, local-only items trashed',
    method: ImportMethod.replace,
    data: _mixed,
  ),
  _Case(
    slug: 'replace-many-trashed',
    title: 'Replace from a backup · one setup over a full device',
    method: ImportMethod.replace,
    data: _oneSetupOverFullDevice,
    source: ImportSourceOptions.backup,
  ),
  _Case(slug: 'empty', title: 'Nothing changes on this device', method: ImportMethod.merge, data: _nothingChanges),
  _Case(
    slug: 'loading',
    title: 'Loading the device data',
    method: ImportMethod.merge,
    data: _mixed,
    load: _Load.pending,
  ),
  _Case(
    slug: 'error',
    title: 'The device data could not be read',
    method: ImportMethod.merge,
    data: _mixed,
    load: _Load.error,
  ),
  _Case(
    slug: 'narrow-merge',
    title: '320 px · Merge, every outcome',
    method: ImportMethod.merge,
    data: _mixed,
    width: _narrow,
  ),
  _Case(
    slug: 'narrow-long-names',
    title: '320 px · long names in both columns',
    method: ImportMethod.overwrite,
    data: _mixedLong,
    width: _narrow,
  ),
  _Case(
    slug: 'narrow-german',
    title: '320 px · German, Replace',
    method: ImportMethod.replace,
    data: _mixed,
    width: _narrow,
    locale: Locale('de'),
  ),
  _Case(
    slug: 'narrow-german-error',
    title: '320 px · German, error',
    method: ImportMethod.replace,
    data: _mixed,
    load: _Load.error,
    width: _narrow,
    locale: Locale('de'),
  ),
];

class _Callbacks {
  var confirmed = false;
  var back = false;
}

Future<_Callbacks> _pumpSheet(WidgetTester tester, ThemeData theme, _Case c, Key key) async {
  final settings = AppSettings()..showOnboarding = false;
  addTearDown(settings.dispose);
  tester.view.physicalSize = Size(c.width, 3000);
  final (remote, local) = c.data();
  final callbacks = _Callbacks();
  Future<SelectedData> load() => switch (c.load) {
    _Load.data => Future.value(local),
    _Load.pending => Completer<SelectedData>().future,
    _Load.error => Future.error(const FileSystemException('database is locked')),
  };

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
                  builder: (_) => ImportSummarySheetContent(
                    remoteData: remote,
                    source: c.source,
                    method: c.method,
                    loadLocalData: load,
                    onConfirm: () => callbacks.confirmed = true,
                    onBack: () => callbacks.back = true,
                  ),
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
  if (c.load == _Load.pending) {
    // The spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return callbacks;
  }
  await tester.pumpAndSettle();
  for (var i = 0; i < find.byType(ExpansionTile).evaluate().length; i++) {
    final title = find.descendant(of: find.byType(ExpansionTile).at(i), matching: find.byType(Text)).first;
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
  }
  if (find.byType(Scrollable).evaluate().isNotEmpty) {
    tester.state<ScrollableState>(find.byType(Scrollable).last).position.jumpTo(0);
    await tester.pumpAndSettle();
  }
  return callbacks;
}

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('import_summary'));

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

  testWidgets('every state can import or go back', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    // Loading has no button of its own: it ends by itself, and the import flow's PopScope handles system back.
    for (final (index, c) in _cases.where((c) => c.load != _Load.pending).indexed) {
      final callbacks = await _pumpSheet(tester, galleryThemes.first.$2, c, ValueKey(index));
      final import = find.byType(FilledButton);
      if (c.load == _Load.data) {
        expect(import, findsOneWidget, reason: '"${c.title}": no Import button');
        await tester.tap(import);
        expect(callbacks.confirmed, isTrue, reason: '"${c.title}": Import does nothing');
      } else {
        expect(import, findsNothing, reason: '"${c.title}": Import shown without a preview');
      }
      await tester.tap(find.byType(BackButtonIcon));
      expect(callbacks.back, isTrue, reason: '"${c.title}": back does nothing');
    }
  });
}
