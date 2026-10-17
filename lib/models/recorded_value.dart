import 'package:flutter/foundation.dart';

import 'adjustment/adjustment.dart';

enum RecordedValueSource { setup, ratingEntry }

/// One value of an adjustment or rating metric as stored in a setup or rating entry.
@immutable
class RecordedValue {
  final String recordId;
  final RecordedValueSource source;
  final String label;
  final DateTime dateTimeLocal;
  final AdjustmentValue value;
  final bool isDeleted;

  const RecordedValue({
    required this.recordId,
    required this.source,
    required this.label,
    required this.dateTimeLocal,
    required this.value,
    required this.isDeleted,
  });
}
