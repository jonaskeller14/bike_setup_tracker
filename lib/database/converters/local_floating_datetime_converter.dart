import 'package:drift/drift.dart';

class LocalFloatingDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const LocalFloatingDateTimeConverter();

  @override
  DateTime fromSql(DateTime fromDb) {
    // Read the absolute physical time representing the UTC "face representation"
    final utcDate = fromDb.toUtc();
    // Strip the UTC flag to get the local "floating" face representation
    return DateTime(
      utcDate.year,
      utcDate.month,
      utcDate.day,
      utcDate.hour,
      utcDate.minute,
      utcDate.second,
      utcDate.millisecond,
      utcDate.microsecond,
    );
  }

  @override
  DateTime toSql(DateTime value) {
    // Force the floating local time into a UTC "face representation" to store as epoch intelligently
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }
}
