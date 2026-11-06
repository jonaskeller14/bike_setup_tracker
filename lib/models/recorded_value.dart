import 'package:flutter/foundation.dart';

import 'adjustment/adjustment.dart';

/// One value of an adjustment as stored in a setup.
@immutable
class RecordedValue {
  final String recordId;
  /// The setup's name, `null` for an unnamed one.
  final String? name;
  final DateTime dateTimeLocal;
  final AdjustmentValue value;
  final bool isDeleted;

  const RecordedValue({
    required this.recordId,
    required this.name,
    required this.dateTimeLocal,
    required this.value,
    required this.isDeleted,
  });
}
