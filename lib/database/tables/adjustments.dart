import 'package:drift/drift.dart';

import '../../models/adjustment/adjustment.dart';
import 'components.dart';
import 'persons.dart';

@DataClassName('AdjustmentDb')
class Adjustments extends Table {
  TextColumn get id => text()();

  TextColumn get componentId =>
      text().nullable().references(Components, #id, onDelete: KeyAction.cascade)();

  TextColumn get personId =>
      text().nullable().references(Persons, #id, onDelete: KeyAction.cascade)();

  // For sorting adjustments within its parent (Component or Person).
  // Rating metrics live in their own RatingMetrics table.
  IntColumn get orderIndex => integer()();

  @override
  List<String> get customConstraints => [
        'CHECK ('
            ' (component_id IS NOT NULL) + '
            ' (person_id IS NOT NULL) == 1 '
            ')'
      ];

  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get unit => text().nullable()();

  // Stores "numerical", "boolean", "categorical" etc to instantiate the correct subclass
  TextColumn get type => textEnum<AdjustmentType>()();

  // Stores the subclass-specific properties (min, max, options, etc) as a serialized JSON string
  TextColumn get jsonPayload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
