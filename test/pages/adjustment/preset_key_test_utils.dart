import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/rating/rating_metric.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const testPresetKey = 'test:preset';

/// Pushes [page], runs [interact] on it, taps save, runs [afterSave] (e.g. to
/// answer a dialog) and returns what the page popped.
Future<Object?> pushAndSave(
  WidgetTester tester,
  Widget page, {
  Future<void> Function()? interact,
  Future<void> Function()? afterSave,
}) async {
  Object? result;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppSettings>(
      create: (_) => AppSettings(),
      child: MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: const Text('Open Page'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Page'));
  await tester.pumpAndSettle();
  await interact?.call();
  await tester.tap(find.byIcon(Icons.check));
  await tester.pumpAndSettle();
  await afterSave?.call();
  return result;
}

/// The adjustment an adjustment or metric page saved, whatever it was wrapped in.
Adjustment savedAdjustment(Object? result) => switch (result) {
  EditResult<Adjustment>(:final value) => value,
  EditResult<RatingMetric>(:final value) => value.adjustment,
  RatingMetric(:final adjustment) => adjustment,
  Adjustment() => result,
  _ => throw TestFailure('Page saved nothing: $result'),
};

Future<void> enterName(WidgetTester tester, String name) =>
    tester.enterText(find.byType(TextFormField).first, name);

/// Template and edit saves keep [testPresetKey]; add saves have no key.
///
/// [template] and [edit] build the page around an adjustment carrying
/// [testPresetKey]. [fillAdd] completes the required fields after the name.
void presetKeyTests({
  required Widget Function() template,
  required Widget Function() edit,
  Widget Function()? add,
  Future<void> Function(WidgetTester tester)? fillAdd,
}) {
  group('presetKey', () {
    testWidgets('template save keeps the key', (tester) async {
      final saved = savedAdjustment(await pushAndSave(tester, template()));
      expect(saved.presetKey, testPresetKey);
    });

    testWidgets('edit with a new name keeps the key', (tester) async {
      final saved = savedAdjustment(await pushAndSave(
        tester,
        edit(),
        interact: () => enterName(tester, 'Renamed'),
      ));
      expect(saved.name, 'Renamed');
      expect(saved.presetKey, testPresetKey);
    });

    if (add != null) {
      testWidgets('add save has no key', (tester) async {
        final saved = savedAdjustment(await pushAndSave(
          tester,
          add(),
          interact: () async {
            await enterName(tester, 'Fresh');
            await fillAdd?.call(tester);
          },
        ));
        expect(saved.name, 'Fresh');
        expect(saved.presetKey, isNull);
      });
    }
  });
}
