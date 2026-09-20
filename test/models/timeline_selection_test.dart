import 'package:bike_setup_tracker/models/timeline_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ids of the same value in different namespaces stay distinct', () {
    final selection = {setupSelectionId('a'), taskEntrySelectionId('a')};

    expect(selection.length, 2);
    expect(selection.idsOf(TimelineSelectionKind.setup), {'a'});
    expect(selection.idsOf(TimelineSelectionKind.taskEntry), {'a'});
    expect(selection.idsOf(TimelineSelectionKind.ratingEntry), isEmpty);
  });

  test('re-adding the same row does not grow the selection', () {
    final selection = {setupSelectionId('a'), setupSelectionId('a')};

    expect(selection.length, 1);
  });

  test('isSetupsOnly gates the setup-only bulk actions', () {
    expect(<TimelineSelectionId>{}.isSetupsOnly, isFalse);
    expect({setupSelectionId('a'), setupSelectionId('b')}.isSetupsOnly, isTrue);
    expect({setupSelectionId('a'), ratingEntrySelectionId('b')}.isSetupsOnly, isFalse);
    expect({taskEntrySelectionId('a')}.isSetupsOnly, isFalse);
  });
}
