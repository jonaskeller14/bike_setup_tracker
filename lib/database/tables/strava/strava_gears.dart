import 'package:drift/drift.dart';
import '../../converters/utc_datetime_converter.dart';

@DataClassName('StravaGearDb')
class StravaGears extends Table {
  TextColumn get id => text()();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}
