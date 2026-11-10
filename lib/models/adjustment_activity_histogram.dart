import '../services/component_slot.dart';
import 'adjustment/adjustment.dart';

class AdjustmentActivityValue {
  final String setupId;
  final AdjustmentValue? value;
  final int activityCount;

  /// Where the adjustment's component was mounted at the setup; `null` when
  /// unknown or not installed.
  final ComponentSlot? slot;

  const AdjustmentActivityValue({
    required this.setupId,
    required this.value,
    required this.activityCount,
    this.slot,
  });
}

typedef AdjustmentActivityHistogramSegment = ({ComponentSlot? slot, int activityCount});

class AdjustmentActivityHistogramBar {
  final int activityCount;
  final AdjustmentValue? exactValue;
  final num? lowerBound;
  final num? upperBound;
  final bool includesUpperBound;

  /// [activityCount] split by slot, in [AdjustmentActivityHistogram.slots]
  /// order without empty segments. Empty when the histogram is not stacked.
  final List<AdjustmentActivityHistogramSegment> segments;

  const AdjustmentActivityHistogramBar.exact({
    required this.activityCount,
    required this.exactValue,
    this.segments = const [],
  }) : lowerBound = null,
       upperBound = null,
       includesUpperBound = false;

  const AdjustmentActivityHistogramBar.range({
    required this.activityCount,
    required this.lowerBound,
    required this.upperBound,
    required this.includesUpperBound,
    this.segments = const [],
  }) : exactValue = null;

  bool get isRange => lowerBound != null;
}

class AdjustmentActivityHistogram {
  final String adjustmentId;
  final List<AdjustmentActivityHistogramBar> bars;
  final bool isBinned;
  final String? unitLabel;

  /// Whether range bounds are seconds of a duration.
  final bool hasDurationBounds;

  /// The slots the bars are stacked by, in display order; empty when all
  /// activities share one slot.
  final List<ComponentSlot?> slots;

  const AdjustmentActivityHistogram({
    required this.adjustmentId,
    required this.bars,
    required this.isBinned,
    this.unitLabel,
    this.hasDurationBounds = false,
    this.slots = const [],
  });

  factory AdjustmentActivityHistogram.empty(String adjustmentId) {
    return AdjustmentActivityHistogram(
      adjustmentId: adjustmentId,
      bars: const [],
      isBinned: false,
    );
  }

  bool get isEmpty => bars.isEmpty;

  bool get isStacked => slots.isNotEmpty;
}
