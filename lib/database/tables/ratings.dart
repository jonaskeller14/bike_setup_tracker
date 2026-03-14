import 'package:drift/drift.dart';
import '../../models/rating.dart';

@DataClassName('RatingDb')
class Ratings extends Table {
  TextColumn get id => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get filter => text().nullable()();
  TextColumn get filterType => textEnum<FilterType>()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
