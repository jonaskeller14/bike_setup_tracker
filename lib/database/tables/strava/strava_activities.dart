import 'package:drift/drift.dart';
import '../../../models/strava/strava_activity.dart';
import '../../converters/local_floating_datetime_converter.dart';
import '../../converters/utc_datetime_converter.dart'; 

@DataClassName('StravaActivityDb')
class StravaActivities extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get lastModified => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get name => text()();
  IntColumn get athlete => integer()();
  TextColumn get sportType => textEnum<SportType>()();
  DateTimeColumn get startDate => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get startDateLocal => dateTime().map(const LocalFloatingDateTimeConverter())();
  TextColumn get gearId => text().nullable()();
  RealColumn get startLat => real().nullable()();
  RealColumn get startLon => real().nullable()();
  RealColumn get distance => real().nullable()();
  RealColumn get totalElevationGain => real().nullable()();
  IntColumn get movingTime => integer()();
  IntColumn get elapsedTime => integer()();
  IntColumn get workoutType => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
