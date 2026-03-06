import 'dart:convert';
import 'package:drift/drift.dart';

class StringListConverter extends TypeConverter<Set<String>, String> {
  const StringListConverter();

  @override
  Set<String> fromSql(String fromDb) {
    if (fromDb.isEmpty || fromDb == '[]') return {};
    return (json.decode(fromDb) as List).cast<String>().toSet();
  }

  @override
  String toSql(Set<String> value) {
    return json.encode(value.toList());
  }
}
