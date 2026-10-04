import 'package:flutter/foundation.dart';

import 'adjustment/adjustment.dart';

/// Per-setup state derived from the whole setup timeline, rebuilt whenever
/// setups, bikes, persons or components change.
@immutable
class SetupHistory {
  final Set<String> currentSetupIds;
  final Map<String, Map<String, AdjustmentValue>> previousBikeValues;
  final Map<String, Map<String, AdjustmentValue>> previousPersonValues;

  const SetupHistory({
    this.currentSetupIds = const {},
    this.previousBikeValues = const {},
    this.previousPersonValues = const {},
  });

  static const empty = SetupHistory();

  bool isCurrent(String setupId) => currentSetupIds.contains(setupId);

  Map<String, AdjustmentValue> previousBikeValuesOf(String setupId) => previousBikeValues[setupId] ?? const {};

  Map<String, AdjustmentValue> previousPersonValuesOf(String setupId) => previousPersonValues[setupId] ?? const {};

  Map<String, AdjustmentValue> previousValuesOf(String setupId) => {
    ...previousBikeValuesOf(setupId),
    ...previousPersonValuesOf(setupId),
  };
}
