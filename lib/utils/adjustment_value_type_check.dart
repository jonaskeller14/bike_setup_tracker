import 'package:flutter/foundation.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/person.dart';
import '../models/rating/rating.dart';
import '../models/rating/rating_entry.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';

void checkSetupValueTypes(
  Iterable<Setup> setups, {
  required Iterable<Component> components,
  required Iterable<Person> persons,
}) {
  final adjustments = adjustmentsById(components: components, persons: persons);
  for (final setup in setups) {
    _checkValueTypes(setup.bikeAdjustmentValues, adjustments);
    _checkValueTypes(setup.personAdjustmentValues, adjustments);
  }
}

void checkRatingEntryValueTypes(Iterable<RatingEntry> entries, {required Iterable<Rating> ratings}) {
  final adjustments = metricAdjustmentsById(ratings);
  for (final entry in entries) {
    _checkValueTypes(entry.metricValues, adjustments);
  }
}

/// Asserts in debug (logs otherwise) when a value does not match the type of
/// its adjustment in [adjustments]. Values of unknown ids and unresolved values
/// are skipped: their definition may be gone.
void _checkValueTypes(Map<String, AdjustmentValue> values, Map<String, Adjustment> adjustments) {
  for (final MapEntry(key: id, :value) in values.entries) {
    final adjustment = adjustments[id];
    if (adjustment == null || value is UnresolvedValue || value.matches(adjustment.type)) continue;
    final message = 'Adjustment value $value does not match ${adjustment.type.name} adjustment $id';
    assert(false, message);
    debugPrint(message);
  }
}
