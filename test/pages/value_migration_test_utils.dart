import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAppRepository extends Mock implements AppRepository {}

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
  RecordedValueSource source = RecordedValueSource.setup,
}) {
  final id = 'record-${_recordCounter++}';
  return RecordedValue(
    recordId: id,
    source: source,
    label: label ?? 'Record $id',
    dateTimeLocal: day ?? DateTime(2024, 3, 1),
    value: value,
    isDeleted: deleted,
  );
}
