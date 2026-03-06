import 'package:drift/drift.dart';
import '../converters/string_list_converter.dart';

@DataClassName('StravaAthleteDb')
class StravaAthletes extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get firstname => text().nullable()();
  TextColumn get lastname => text().nullable()();
  TextColumn get profile => text().nullable()();
  TextColumn get gears => text().map(const StringListConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
