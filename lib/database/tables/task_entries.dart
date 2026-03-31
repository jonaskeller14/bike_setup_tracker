import 'package:drift/drift.dart';
import '../converters/utc_datetime_converter.dart';
import '../converters/local_floating_datetime_converter.dart';
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

  @override
  Set<Column> get primaryKey => {id};
}
