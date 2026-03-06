import 'package:drift/drift.dart';
import '../../models/todo_rule.dart';

@DataClassName('TodoRuleDb')
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
