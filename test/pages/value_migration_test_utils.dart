import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppRepository extends Mock implements AppRepository {}

extension PendingMigrations<T> on AdjustmentEditResult<T> {
  /// What the parent form would write for this edit.
  List<ValueMigration> get migrations => pendingValueMigrations({'': ?pending});
}

/// A repository whose `recordedValues` returns [recorded] for any adjustment.
MockAppRepository repositoryWithRecorded([List<RecordedValue> recorded = const []]) {
  final repository = MockAppRepository();
  when(() => repository.recordedValues(any())).thenAnswer((_) async => recorded);
  return repository;
}

int _recordCounter = 0;

RecordedValue recordedValue(
  AdjustmentValue value, {
  String? label,
  bool deleted = false,
  DateTime? day,
}) {
  final id = 'record-${_recordCounter++}';
  return RecordedValue(
    recordId: id,
    label: label ?? 'Record $id',
    dateTimeLocal: day ?? DateTime(2024, 3, 1),
    value: value,
    isDeleted: deleted,
  );
}

/// Sets the hours of the duration field labelled [label] from [from] to [to]
/// through its picker sheet, then closes the sheet.
Future<void> setDurationHours(WidgetTester tester, String label, {required int from, required int to}) async {
  await tester.tap(find.widgetWithText(TextFormField, label));
  await tester.pumpAndSettle();
  // Tapping the selected hour switches the picker to typed input.
  await tester.tap(find.text(from.toString().padLeft(2, '0')).first);
  await tester.pumpAndSettle();
  final sheetFields = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
  await tester.enterText(sheetFields.first, to.toString().padLeft(2, '0'));
  await tester.pumpAndSettle();
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}
