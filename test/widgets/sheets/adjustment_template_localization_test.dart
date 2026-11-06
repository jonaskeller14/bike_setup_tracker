import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/widgets/sheets/component_add_adjustment.dart';
import 'package:bike_setup_tracker/widgets/sheets/person_add_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettings();
  });

  tearDown(() => settings.dispose());

  Future<void> pumpApp(
    WidgetTester tester,
    Locale locale,
    void Function(BuildContext context) open, {
    Size size = const Size(800, 3000),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: localizedTestApp(
          locale: locale,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => open(context), child: const Text('open')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  void openComponentSheet(
    BuildContext context, {
    List<Adjustment> existing = const [],
    ValueChanged<Adjustment>? onPicked,
  }) => showComponentAddAdjustmentBottomSheet(
    context: context,
    componentType: ComponentType.fork,
    existingAdjustments: existing,
    addAdjustmentFromPreset: (adjustment) async => onPicked?.call(adjustment),
    addAdjustment: <T extends Adjustment>() async {},
  );

  group('component templates', () {
    testWidgets('are listed in German', (tester) async {
      await pumpApp(tester, const Locale('de'), openComponentSheet);

      expect(find.text('Zugstufe'), findsOneWidget);
      expect(find.text('Druckstufe'), findsOneWidget);
      expect(find.text('Luftdruck'), findsOneWidget);
      expect(find.text('Rebound'), findsNothing);
    });

    testWidgets('are listed in English', (tester) async {
      await pumpApp(tester, const Locale('en'), openComponentSheet);

      expect(find.text('Rebound'), findsOneWidget);
      expect(find.text('Zugstufe'), findsNothing);
    });

    testWidgets('hand the German text and the language-neutral key to the picker', (tester) async {
      Adjustment? picked;
      await pumpApp(tester, const Locale('de'), (context) => openComponentSheet(context, onPicked: (a) => picked = a));

      await tester.tap(find.text('Zugstufe'));
      await tester.pumpAndSettle();

      expect(picked, isA<StepAdjustment>());
      expect(picked!.name, 'Zugstufe');
      expect(picked!.notes, 'Klicks der Zugstufe');
      expect(picked!.presetKey, 'fork:rebound');
    });

    testWidgets('one added in English is already added in German', (tester) async {
      final english = NumericalAdjustment(name: 'Rebound', unit: null, notes: null, presetKey: 'fork:rebound');
      await pumpApp(tester, const Locale('de'), (context) => openComponentSheet(context, existing: [english]));

      expect(find.text('Zugstufe'), findsNothing);
      expect(find.text('Druckstufe'), findsOneWidget);
    });
  });

  group('on a small phone with large text', () {
    for (final type in ComponentType.values) {
      testWidgets('the German ${type.name} templates fit', (tester) async {
        await pumpApp(
          tester,
          const Locale('de'),
          (context) => showComponentAddAdjustmentBottomSheet(
            context: context,
            componentType: type,
            addAdjustmentFromPreset: (_) async {},
            addAdjustment: <T extends Adjustment>() async {},
          ),
          size: const Size(320, 640),
          textScale: 1.3,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the German rider attribute templates fit', (tester) async {
      await pumpApp(
        tester,
        const Locale('de'),
        (context) => showPersonAddAdjustmentBottomSheet(
          context: context,
          addAdjustmentFromPreset: (_) async {},
          addAdjustment: <T extends Adjustment>() async {},
        ),
        size: const Size(320, 640),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('rider attribute templates', () {
    testWidgets('are listed in German', (tester) async {
      await pumpApp(
        tester,
        const Locale('de'),
        (context) => showPersonAddAdjustmentBottomSheet(
          context: context,
          addAdjustmentFromPreset: (_) async {},
          addAdjustment: <T extends Adjustment>() async {},
        ),
      );

      expect(find.text('Fahrergewicht'), findsOneWidget);
      expect(find.text('Körpergröße'), findsOneWidget);
      expect(find.text('Fahrstil'), findsOneWidget);
      expect(find.text('Riding weight'), findsNothing);
    });

    testWidgets('one added in English is already added in German', (tester) async {
      final english = NumericalAdjustment(
        name: 'Riding weight',
        unit: null,
        notes: null,
        presetKey: 'person:riding_weight',
      );
      await pumpApp(
        tester,
        const Locale('de'),
        (context) => showPersonAddAdjustmentBottomSheet(
          context: context,
          existingAdjustments: [english],
          addAdjustmentFromPreset: (_) async {},
          addAdjustment: <T extends Adjustment>() async {},
        ),
      );

      expect(find.text('Fahrergewicht'), findsNothing);
      expect(find.text('Körpergröße'), findsOneWidget);
    });
  });
}
