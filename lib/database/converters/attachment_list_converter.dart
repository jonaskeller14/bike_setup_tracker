import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/attachment.dart';

export '../../models/attachment.dart';

class AttachmentListConverter extends TypeConverter<List<Attachment>, String> {
  const AttachmentListConverter();

  @override
  List<Attachment> fromSql(String fromDb) {
    if (fromDb.isEmpty || fromDb == '[]') return [];
    final decoded = json.decode(fromDb);
    if (decoded is! List) return [];
    // Skip malformed entries so one bad attachment doesn't hide the owner row.
    return decoded.map(Attachment.tryFromJson).nonNulls.toList();
  }

  @override
  String toSql(List<Attachment> value) => json.encode(value.map((a) => a.toJson()).toList());
}
