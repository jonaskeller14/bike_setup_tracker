import 'package:drift/drift.dart';
import '../converters/local_floating_datetime_converter.dart';
import '../converters/utc_datetime_converter.dart';
import 'components.dart';

@DataClassName('InstallationDb')
class Installations extends Table {
  TextColumn get id => text()();

  // The component that is installed
  TextColumn get componentId =>
      text().references(Components, #id, onDelete: KeyAction.cascade)();

  // The entity it is installed on (usually a bike id, but parent is generic in existing model)
  TextColumn get parent => text().nullable()();

  DateTimeColumn get dateTimeUTC => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get dateTimeLocal => dateTime().map(const LocalFloatingDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
