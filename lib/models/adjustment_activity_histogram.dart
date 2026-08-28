class AdjustmentActivityValue {
  final String setupId;
  final dynamic value;
  final int activityCount;

  const AdjustmentActivityValue({
    required this.setupId,
    required this.value,
    required this.activityCount,
  });
}

class AdjustmentActivityHistogramBar {
  final String label;
  final int activityCount;
  final dynamic exactValue;
  final num? lowerBound;
  final num? upperBound;
  final bool includesUpperBound;

  const AdjustmentActivityHistogramBar.exact({
    required this.label,
    required this.activityCount,
    required this.exactValue,
  }) : lowerBound = null,
       upperBound = null,
       includesUpperBound = false;

  const AdjustmentActivityHistogramBar.range({
    required this.label,
    required this.activityCount,
    required this.lowerBound,
    required this.upperBound,
    required this.includesUpperBound,
  }) : exactValue = null;

  bool get isRange => lowerBound != null;
}

class AdjustmentActivityHistogram {
  final String adjustmentId;
  final List<AdjustmentActivityHistogramBar> bars;
  final bool isBinned;

  const AdjustmentActivityHistogram({
    required this.adjustmentId,
    required this.bars,
    required this.isBinned,
  });

  factory AdjustmentActivityHistogram.empty(String adjustmentId) {
    return AdjustmentActivityHistogram(
      adjustmentId: adjustmentId,
      bars: const [],
      isBinned: false,
    );
  }

  bool get isEmpty => bars.isEmpty;
}
