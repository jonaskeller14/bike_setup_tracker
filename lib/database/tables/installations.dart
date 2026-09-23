import 'package:drift/drift.dart';

import '../../models/component/installation.dart';
import '../converters/local_floating_datetime_converter.dart';
import '../converters/utc_datetime_converter.dart';
import 'components.dart';

@DataClassName('InstallationDb')
// Supports the latest event lookup for a component at a historical timestamp.
@TableIndex(
  name: 'installations_component_date_idx',
  columns: {#componentId, #dateTimeUTC},
)
// Supports recursive parent-to-child traversal at an activity timestamp.
@TableIndex(
  name: 'installations_parent_lookup_idx',
  columns: {#parentType, #parent, #dateTimeUTC},
)
class Installations extends Table {
  TextColumn get id => text()();

  // The component that is installed
  TextColumn get componentId =>
      text().references(Components, #id, onDelete: KeyAction.cascade)();

  // The entity it is installed on (bike/component id or null)
  TextColumn get parent => text().nullable()();

  // Discriminates the event kind: installed on a bike, uninstalled (parts-bin),
  // or archived (retired). Defaults to 'bike'; the v9 migration backfills
  // existing rows ('none' where parent is null).
  TextColumn get parentType => text()
      .map(const EnumNameConverter(InstallationParentType.values))
      .withDefault(const Constant('bike'))();

  DateTimeColumn get dateTimeUTC => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get dateTimeLocal => dateTime().map(const LocalFloatingDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
