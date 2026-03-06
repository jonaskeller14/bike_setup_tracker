import 'package:drift/drift.dart';

enum TodoPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String label;
  const TodoPriority(this.label);
}

@DataClassName('TodoRule')
class TodoRules extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get priority => textEnum<TodoPriority>().withDefault(const Constant('medium'))();

  @override
  Set<Column> get primaryKey => {id};
}
