import 'package:drift/drift.dart';
import '../converters/local_floating_datetime_converter.dart';
import '../converters/utc_datetime_converter.dart';
import 'bikes.dart';
import 'components.dart';
import 'task_rules.dart';

@DataClassName('TaskEntryDb')
class TaskEntries extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dateTimeUTC => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get dateTimeLocal => dateTime().map(const LocalFloatingDateTimeConverter())();
  TextColumn get taskRule => text().references(TaskRules, #id, onDelete: KeyAction.cascade)();
  TextColumn get componentId => text().nullable().references(Components, #id)();
  TextColumn get bikeId => text().nullable().references(Bikes, #id)();
  TextColumn get snapshot => text().nullable()(); // JSON serialized ComponentStats

  @override
  Set<Column> get primaryKey => {id};
}
