// Renders every state of InstallationParentField and its picker sheet to PNGs
// in build/gallery/installation_parent/ (git-ignored), for a quick visual check
// after changing either widget. Skipped by default (see dart_test.yaml); run it
// on demand with:
//
//   flutter test test/gallery/installation_parent_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; the
// field gallery and each sheet are also written on their own.
//
// Names that start with "my" are user data (Bike.name, Component.name). Anything
// else on screen (UNINSTALLED, BIKE NOT FOUND, hints, reasons) comes from the UI.
//
// Besides the pictures, the second test checks that no state traps the user:
// every enabled field can still be moved onto a bike.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/widgets/installation_parent_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gallery_harness.dart';

class _MockAppRepository extends Mock implements AppRepository {}

class _MockAppHintService extends Mock implements AppHintService {}

const _sheetWidth = 400.0;
const _fieldCellWidth = 360.0;

const _bike1 = 'bike-1';
const _bike2 = 'bike-2';
const _deletedBike = 'bike-deleted';
const _hardDeleted = 'part-hard-deleted';
const _softDeleted = 'part-soft-deleted';

final _now = DateTime.now();

Installation _onBike(String bikeId) =>
    BikeInstallation(bikeId: bikeId, dateTimeUTC: _now.toUtc(), dateTimeLocal: _now);

Installation _onPart(String componentId) =>
    ComponentInstallation(parentComponentId: componentId, dateTimeUTC: _now.toUtc(), dateTimeLocal: _now);

Installation _uninstalled() => Uninstallation(dateTimeUTC: _now.toUtc(), dateTimeLocal: _now);

Installation _archived() => Archival(dateTimeUTC: _now.toUtc(), dateTimeLocal: _now);

class _Scene {
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final ComponentHierarchyResolver hierarchy;

  const _Scene(this.bikes, this.components, this.hierarchy);

  /// The garage every state is drawn from. Soft-deleted rows never reach the
  /// repository's maps, so a soft-deleted bike is simply absent (like a
  /// hard-deleted one) and a soft-deleted component is only listed in the
  /// hierarchy's deleted ids.
  factory _Scene.build() {
    Component part(String id, String name, ComponentType type, List<Installation> installations) =>
        Component(id: id, name: name, componentType: type, installations: installations, adjustments: const []);
    Installation since(String? bikeId) => Installation.sinceBeginning(parent: bikeId);
    Installation sinceOn(String componentId) => Installation.componentSinceBeginning(parentComponentId: componentId);

    final components = {
      for (final c in [
        part('fork', 'myFork', ComponentType.fork, [since(_bike1)]),
        part('shock', 'myShock', ComponentType.shock, [since(_bike1)]),
        part('wheel-1', 'myWheel1', ComponentType.wheelFront, [since(_bike1)]),
        part('tire-1', 'myTire1', ComponentType.tire, [sinceOn('wheel-1')]),
        part('insert-1', 'myInsert1', ComponentType.other, [sinceOn('tire-1')]),
        part('wheel-2', 'myWheel2', ComponentType.wheelRear, [since(_bike2)]),
        part('wheel-3', 'myWheel3', ComponentType.wheelFront, [since(null)]),
        part('tire-2', 'myTire2', ComponentType.tire, [sinceOn('wheel-3')]),
        part('wheel-4', 'myWheel4', ComponentType.wheelRear, [since(_bike1), _archived()]),
        part('tire-3', 'myTire3', ComponentType.tire, [sinceOn('wheel-4')]),
        part('wheel-5', 'myWheel5', ComponentType.wheelFront, [since(_deletedBike)]),
        part('valve-1', 'myValve1', ComponentType.other, [sinceOn(_hardDeleted)]),
        part('insert-2', 'myInsert2', ComponentType.other, [sinceOn(_softDeleted)]),
        part('loop-1', 'myLoop1', ComponentType.other, [sinceOn('loop-2')]),
        part('loop-2', 'myLoop2', ComponentType.other, [sinceOn('loop-1')]),
      ])
        c.id: c,
    };
    return _Scene(
      {
        _bike1: Bike(id: _bike1, name: 'myBike1', person: 'p'),
        _bike2: Bike(id: _bike2, name: 'myBike2', person: 'p'),
      },
      components,
      ComponentHierarchyResolver(components, deletedComponentIds: const {_softDeleted}),
    );
  }
}

class _FieldCase {
  final String label;
  final Installation installation;
  final Installation? initial;
  final bool enabled;
  final bool changed;
  final bool invalid;
  final String? helperText;
  final String? errorText;

  const _FieldCase(
    this.label,
    this.installation, {
    this.initial,
    this.enabled = true,
    this.changed = false,
    this.invalid = false,
    this.helperText,
    this.errorText,
  });
}

final _fieldCases = [
  _FieldCase('Not installed', _uninstalled()),
  _FieldCase('Archived', _archived()),
  _FieldCase('Bike', _onBike(_bike1)),
  _FieldCase('Bike, hard-deleted (row gone)', _onBike(_deletedBike)),
  _FieldCase('Bike, soft-deleted (repository drops it, same as hard)', _onBike(_deletedBike)),
  _FieldCase('Component on a bike (1 level)', _onPart('fork')),
  _FieldCase('Subcomponent (2 levels)', _onPart('tire-1')),
  _FieldCase('Sub-subcomponent (3 levels)', _onPart('insert-1')),
  _FieldCase('Component on a deleted bike', _onPart('wheel-5')),
  _FieldCase('Archived component', _onPart('wheel-4')),
  _FieldCase('Component in an archived chain', _onPart('tire-3')),
  _FieldCase('Not installed component', _onPart('wheel-3')),
  _FieldCase('Component in a not installed chain', _onPart('tire-2')),
  _FieldCase('Component, hard-deleted', _onPart(_hardDeleted)),
  _FieldCase('Component, soft-deleted', _onPart(_softDeleted)),
  _FieldCase('Component whose parent is hard-deleted', _onPart('valve-1')),
  _FieldCase('Component whose parent is soft-deleted', _onPart('insert-2')),
  _FieldCase('Component in a loop', _onPart('loop-1')),
  _FieldCase('Disabled', _onBike(_bike1), enabled: false),
  _FieldCase('Disabled, subcomponent selected', _onPart('tire-1'), enabled: false),
  _FieldCase('Disabled, deleted component selected', _onPart(_hardDeleted), enabled: false),
  _FieldCase('Changed from saved value', _onBike(_bike2), initial: _onBike(_bike1), changed: true),
  _FieldCase('Invalid (timeline validation)', _onPart('loop-1'), invalid: true),
  _FieldCase('Helper text', _uninstalled(), helperText: 'WARNING: Select Bike to install Component.'),
  _FieldCase('Error text', _onBike(_deletedBike), errorText: 'Bike no longer exists'),
];

class _SheetCase {
  final String slug;
  final String title;
  final Installation installation;
  final Installation? initial;
  final String? componentId;
  final ComponentType componentType;
  final bool subcomponents;
  final bool allowArchive;
  final bool showAll;
  final String? query;
  final bool mountHint;
  final bool timelineHint;

  const _SheetCase({
    required this.slug,
    required this.title,
    required this.installation,
    this.initial,
    this.componentId = 'edited',
    this.componentType = ComponentType.tire,
    this.subcomponents = true,
    this.allowArchive = true,
    this.showAll = false,
    this.query,
    this.mountHint = false,
    this.timelineHint = false,
  });
}

final _sheetCases = [
  _SheetCase(
    slug: 'collapsed',
    title: 'Editing a tire · unusual parents hidden',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
  ),
  _SheetCase(
    slug: 'expanded',
    title: 'Editing a tire · Show all',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
    showAll: true,
  ),
  _SheetCase(
    slug: 'moved',
    title: 'Moved: new value highlighted, saved one marked',
    installation: _onPart('wheel-1'),
    initial: _onBike(_bike2),
    showAll: true,
  ),
  _SheetCase(
    slug: 'hard-deleted-bike-selected',
    title: 'Selected bike hard-deleted, saved component hard-deleted',
    installation: _onBike(_deletedBike),
    initial: _onPart(_hardDeleted),
  ),
  _SheetCase(
    slug: 'soft-deleted-component-selected',
    title: 'Selected component soft-deleted',
    installation: _onPart(_softDeleted),
    initial: _onPart(_softDeleted),
  ),
  _SheetCase(
    slug: 'carries-parts',
    title: 'Editing a component that carries parts',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
    componentId: 'wheel-1',
    componentType: ComponentType.wheelFront,
  ),
  _SheetCase(
    slug: 'deep-chain-edit',
    title: 'Editing a leaf on a deep chain (kept parent stays pickable)',
    installation: _onPart('tire-1'),
    initial: _onPart('tire-1'),
    componentId: 'insert-1',
    componentType: ComponentType.other,
  ),
  _SheetCase(
    slug: 'search-match',
    title: 'Search "wheel"',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
    showAll: true,
    query: 'wheel',
  ),
  _SheetCase(
    slug: 'search-empty',
    title: 'Search without matches',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
    query: 'zzz',
  ),
  _SheetCase(
    slug: 'subcomponents-off',
    title: 'Subcomponents off · bikes only, archive not offered',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
    subcomponents: false,
    allowArchive: false,
  ),
  _SheetCase(
    slug: 'subcomponents-hint',
    title: 'Subcomponents off · mount suggestion',
    installation: _onBike(_bike1),
    initial: _onBike(_bike1),
    subcomponents: false,
    mountHint: true,
  ),
  _SheetCase(
    slug: 'timeline-hint',
    title: 'Installation Timeline suggestion',
    installation: _onBike(_bike2),
    initial: _onBike(_bike1),
    subcomponents: false,
    timelineHint: true,
  ),
];

const _galleryKey = ValueKey('field-gallery');

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('installation_parent'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      tester.view.physicalSize = const Size(2 * _fieldCellWidth + 80, 4000);
      await tester.pumpWidget(_fieldGalleryApp(theme, _Scene.build()));
      await tester.pumpAndSettle();
      await session.add('fields', 'Field states', tester.renderObject(find.byKey(_galleryKey)));

      for (final (index, sheetCase) in _sheetCases.indexed) {
        tester.view.physicalSize = const Size(_sheetWidth, 3600);
        await tester.pumpWidget(_sheetApp(theme, _Scene.build(), sheetCase, ValueKey(index)));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(InstallationParentField));
        await tester.pumpAndSettle();
        if (sheetCase.showAll) {
          await tester.tap(find.text('Show all'));
          await tester.pumpAndSettle();
        }
        if (sheetCase.query != null) {
          await tester.enterText(find.byType(TextField), sheetCase.query!);
          await tester.pumpAndSettle();
        }
        await session.add(
          'sheet_${sheetCase.slug}',
          'Sheet · ${sheetCase.title}',
          tester.renderObject(find.byKey(ValueKey(index))),
          crop: tester.getRect(find.byType(BottomSheet)),
        );
      }

      await session.finish();
    });
  }

  testWidgets('every enabled field state can be fixed by picking a bike', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_sheetWidth, 3600);

    for (final (index, c) in _fieldCases.indexed.where((e) => e.$2.enabled)) {
      Installation? picked;
      await tester.pumpWidget(
        _providers(
          scene: _Scene.build(),
          subcomponents: true,
          child: _app(
            galleryThemes.first.$2,
            Padding(
              padding: const EdgeInsets.all(16),
              child: InstallationParentField(
                installation: c.installation,
                initial: c.initial,
                componentId: 'edited',
                componentType: ComponentType.tire,
                onChanged: (value) => picked = value,
              ),
            ),
            key: ValueKey(index),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InstallationParentField));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is ListTile && (w.title as Text?)?.data == 'myBike2'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(picked, isA<BikeInstallation>(), reason: '"${c.label}" cannot be moved onto a bike');
      expect(picked!.parent, _bike2, reason: c.label);
    }
  });
}

Widget _providers({
  required _Scene scene,
  required bool subcomponents,
  required Widget child,
  Component? mountParent,
  bool offerTimeline = false,
}) {
  final repository = _MockAppRepository();
  when(() => repository.bikes).thenReturn(scene.bikes);
  when(() => repository.components).thenReturn(scene.components);
  when(() => repository.componentHierarchy).thenReturn(scene.hierarchy);
  when(() => repository.affectedDescendantIds(any()))
      .thenAnswer((invocation) => scene.hierarchy.descendantsOf(invocation.positionalArguments.first as String));

  final hints = _MockAppHintService();
  when(() => hints.subcomponentsMountParent(
        any(),
        componentId: any(named: 'componentId'),
        currentBikeId: any(named: 'currentBikeId'),
      )).thenReturn(mountParent);
  when(() => hints.shouldOfferInstallationTimelineOnMove(any())).thenReturn(offerTimeline);

  final settings = AppSettings()..enableInstallOnComponent = subcomponents;

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppRepository>.value(value: repository),
      ChangeNotifierProvider<AppSettings>.value(value: settings),
      ChangeNotifierProvider<AppHintService>.value(value: hints),
    ],
    child: child,
  );
}

Widget _app(ThemeData theme, Widget home, {Key? key}) => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(body: home),
      ),
    );

Widget _fieldGalleryApp(ThemeData theme, _Scene scene) {
  final errorColor = theme.colorScheme.error;
  return _providers(
    scene: scene,
    subcomponents: true,
    child: _app(
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
                  for (final c in _fieldCases)
                    SizedBox(
                      width: _fieldCellWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(c.label, style: theme.textTheme.labelSmall),
                          ),
                          InstallationParentField(
                            installation: c.installation,
                            initial: c.initial,
                            componentId: 'edited',
                            componentType: ComponentType.tire,
                            currentBikeId: InstallationParentField.bikeIdOf(c.installation, scene.hierarchy),
                            enabled: c.enabled,
                            changed: c.changed,
                            tint: c.invalid ? errorColor : null,
                            invalidBorder: c.invalid
                                ? OutlineInputBorder(borderSide: BorderSide(color: errorColor, width: 2))
                                : null,
                            labelText: 'Installed on',
                            helperText: c.helperText,
                            errorText: c.errorText,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _sheetApp(ThemeData theme, _Scene scene, _SheetCase c, Key key) {
  return _providers(
    scene: scene,
    subcomponents: c.subcomponents,
    mountParent: c.mountHint ? scene.components['fork'] : null,
    offerTimeline: c.timelineHint,
    child: _app(
      theme,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: InstallationParentField(
            installation: c.installation,
            initial: c.initial,
            componentId: c.componentId,
            componentType: c.componentType,
            currentBikeId: InstallationParentField.bikeIdOf(c.installation, scene.hierarchy) ?? _bike1,
            allowArchive: c.allowArchive,
            labelText: 'Installed on',
            timelineOfferInstallations: c.timelineHint ? [c.initial!] : null,
            onChanged: (_) {},
          ),
        ),
      ),
      key: key,
    ),
  );
}
