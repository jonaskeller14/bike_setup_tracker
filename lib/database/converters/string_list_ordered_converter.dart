import 'dart:convert';
import 'package:drift/drift.dart';

class StringListOrderedConverter extends TypeConverter<List<String>, String> {
  const StringListOrderedConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty || fromDb == '[]') return [];
    return (json.decode(fromDb) as List).cast<String>();
  }

  @override
  String toSql(List<String> value) => json.encode(value);
}
