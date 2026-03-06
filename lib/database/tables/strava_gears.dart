import 'package:drift/drift.dart';

@DataClassName('StravaGearDb')
class StravaGears extends Table {
  TextColumn get id => text()();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}
