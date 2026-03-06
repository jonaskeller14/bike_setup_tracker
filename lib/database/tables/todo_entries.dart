import 'package:drift/drift.dart';
import 'todo_rules.dart';

@DataClassName('TodoEntryDb')
class TodoEntries extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dateTimeUTC => dateTime()();
  DateTimeColumn get dateTimeLocal => dateTime()();
  TextColumn get todoRule => text().references(TodoRules, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}
