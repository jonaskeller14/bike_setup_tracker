/// Moves the dates of exported sample JSON forward so the data looks recent.
///
/// Status that depends on "now" (due tasks, the calendar's current month)
/// would otherwise drift further from the sample's creation date on every run.
/// Dates are shifted by whole calendar days on their wall-clock fields, so the
/// time of day of every entry — and the UTC/local pair of an entry — stays as
/// recorded, independent of the host's time zone and DST.
library;

final RegExp _isoDateTime = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?(Z?)$',
);

/// Dates before this year are sentinels (e.g. the epoch "installed since
/// beginning" installation), not points in the sample's timeline.
const int _firstShiftedYear = 2000;

/// Days to add to every date in [json] so its newest date lands
/// [daysBeforeToday] days before [today].
int sampleShiftDays(Object? json, {required DateTime today, int daysBeforeToday = 1}) {
  DateTime? newest;
  _visitDates(json, (date) {
    if (newest == null || date.isAfter(newest!)) newest = date;
  });
  if (newest == null) return 0;

  final target = DateTime.utc(today.year, today.month, today.day - daysBeforeToday);
  final newestDay = DateTime.utc(newest!.year, newest!.month, newest!.day);
  return target.difference(newestDay).inDays;
}

/// Returns a copy of [json] with every ISO-8601 date-time string moved by [days].
Object? shiftSampleDates(Object? json, int days) {
  if (json is Map<String, dynamic>) {
    return json.map((key, value) => MapEntry(key, shiftSampleDates(value, days)));
  }
  if (json is List) return json.map((value) => shiftSampleDates(value, days)).toList();
  if (json is String) {
    final date = _parseWallClock(json);
    if (date == null) return json;
    final shifted = date.add(Duration(days: days)).toIso8601String();
    return json.endsWith('Z') ? shifted : shifted.substring(0, shifted.length - 1);
  }
  return json;
}

void _visitDates(Object? json, void Function(DateTime date) visit) {
  if (json is Map) {
    for (final value in json.values) {
      _visitDates(value, visit);
    }
  } else if (json is List) {
    for (final value in json) {
      _visitDates(value, visit);
    }
  } else if (json is String) {
    final date = _parseWallClock(json);
    if (date != null) visit(date);
  }
}

/// Parses the wall-clock fields of [value] into a UTC [DateTime], whether or
/// not [value] carries a `Z`, so day arithmetic never crosses a DST change.
DateTime? _parseWallClock(String value) {
  final match = _isoDateTime.firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match[1]!);
  if (year < _firstShiftedYear) return null;
  final fraction = (match[7] ?? '').padRight(6, '0');
  return DateTime.utc(
    year,
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
    int.parse(match[6]!),
    int.parse(fraction.substring(0, 3)),
    int.parse(fraction.substring(3)),
  );
}
