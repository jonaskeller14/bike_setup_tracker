import 'package:drift/drift.dart';
import '../../models/strava/strava_activity.dart'; 

@DataClassName('StravaActivityDb')
class StravaActivities extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();
  IntColumn get athlete => integer()();
  TextColumn get sportType => textEnum<SportType>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get startDateLocal => dateTime()();
  TextColumn get gearId => text().nullable()();
  RealColumn get startLat => real().nullable()();
  RealColumn get startLon => real().nullable()();
  RealColumn get distance => real().nullable()();
  RealColumn get totalElevationGain => real().nullable()();
  IntColumn get movingTime => integer()();
  IntColumn get elapsedTime => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
