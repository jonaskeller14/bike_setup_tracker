import 'package:drift/drift.dart';
import '../../models/component.dart';

@DataClassName('ComponentDb')
class Components extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();

  TextColumn get componentType =>
      text().map(const EnumNameConverter(ComponentType.values))();

  TextColumn get notes => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
