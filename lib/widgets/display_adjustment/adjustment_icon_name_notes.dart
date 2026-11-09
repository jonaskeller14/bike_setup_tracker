import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/adjustment_activity_histogram.dart';
import '../../services/setup_activity_analysis_service.dart';
import '../../services/subscription_service.dart';
import '../../theme.dart';
import '../display_data/adjustment_activity_histogram_chart.dart';
import '../items/adjustment_properties.dart';
import '../items/adjustment_type_icon.dart';
import '../setup_guide_scope.dart';
import '../setup_guide_status.dart';

class AdjustmentIconNameNotes extends StatefulWidget {
  final Adjustment adjustment;
  final AdjustmentValue? value;
  final Color? color;
  final bool compact;

  const AdjustmentIconNameNotes({super.key, required this.adjustment, this.value, this.color, this.compact = false});

  @override
  State<AdjustmentIconNameNotes> createState() => _AdjustmentIconNameNotesState();
}

class _AdjustmentIconNameNotesState extends State<AdjustmentIconNameNotes> {
  SetupActivityAnalysisService? _analysisService;
  SubscriptionService? _subscription;
  Future<AdjustmentActivityHistogram>? _histogramFuture;
  AdjustmentActivityHistogram? _histogram;
  bool _isLoading = false;
  bool _loadFailed = false;

  bool get _canAnalyse =>
      widget.adjustment is! TextAdjustment &&
      _analysisService?.hasAnyActivity == true &&
      _subscription?.hasStravaEntitlement == true;

  void _resetHistogram() {
    _histogramFuture = null;
    _histogram = null;
    _isLoading = false;
    _loadFailed = false;
  }

  @override
  void didUpdateWidget(covariant AdjustmentIconNameNotes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adjustment.id != widget.adjustment.id) _resetHistogram();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SetupActivityAnalysisService? service;
    try {
      service = Provider.of<SetupActivityAnalysisService>(context);
    } on ProviderNotFoundException {
      service = null;
    }
    SubscriptionService? subscription;
    try {
      subscription = Provider.of<SubscriptionService>(context);
    } on ProviderNotFoundException {
      subscription = null;
    }
    final serviceChanged = !identical(service, _analysisService);
    _analysisService = service;
    _subscription = subscription;
    if (serviceChanged || !_canAnalyse) _resetHistogram();
  }

  void _loadHistogram() {
    final service = _analysisService;
    if (service == null || !_canAnalyse) return;

    final future = service.getAdjustmentHistogram(widget.adjustment.id);
    setState(() {
      _histogramFuture = future;
      _histogram = null;
      _isLoading = true;
      _loadFailed = false;
    });
    unawaited(_resolveHistogram(future));
  }

  /// Why there is no histogram, or null while it loads, is shown, or does not apply.
  String? _histogramHint() {
    final service = _analysisService;
    final subscription = _subscription;
    if (widget.adjustment is TextAdjustment || service == null || subscription == null) return null;

    final l10n = context.l10n;
    if (!subscription.hasStravaEntitlement) return l10n.chartHistogramHintSubscribe;
    if (!service.hasAnyActivity) return l10n.chartHistogramHintNoActivities;
    if (_loadFailed) return l10n.chartHistogramHintLoadFailed;
    if (_histogram?.isEmpty == true) return l10n.chartHistogramHintNoLinked;
    return null;
  }

  Future<void> _resolveHistogram(Future<AdjustmentActivityHistogram> future) async {
    try {
      final histogram = await future;
      if (!mounted || !identical(_histogramFuture, future)) return;
      setState(() {
        _histogram = histogram;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load adjustment activity histogram: $error\n$stackTrace');
      if (!mounted || !identical(_histogramFuture, future)) return;
      setState(() {
        _histogram = null;
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textStyle = widget.compact
        ? textTheme.bodyMedium?.copyWith(color: widget.color)
        : textTheme.bodyLarge?.copyWith(color: widget.color);
    final colorScheme = Theme.of(context).colorScheme;
    final guide = SetupGuideScope.recommendationFor(context, widget.adjustment.id);
    final guideStatus = guide == null ? null : GuideStatus.of(guide.$1, context.l10n);

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: widget.compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      spacing: widget.compact ? 8 : 10,
      children: [
        AdjustmentTypeIcon(widget.adjustment, size: widget.compact ? 20 : 24, color: widget.color),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              onTriggered: _loadHistogram,
              preferBelow: false,
              showDuration: const Duration(seconds: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(12),
              richMessage: WidgetSpan(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      widget.adjustment.name,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AdjustmentProperties(
                      widget.adjustment,
                      color: colorScheme.onSecondary,
                    ),
                    if (widget.adjustment.notes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3), // tweak to match font size
                            child: Icon(
                              Icons.notes,
                              size: 13,
                              color: colorScheme.onSecondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              widget.adjustment.notes!,
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (guide case (final recommendation, final component))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Icon(Icons.tips_and_updates_outlined, size: 13, color: colorScheme.onSecondary),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              recommendedValueLine(recommendation, component, context.l10n),
                              style: TextStyle(color: colorScheme.onSecondary, fontSize: 13),
                            ),
                          ),
                          if (guideStatus != null) ...[
                            const SizedBox(width: 6),
                            // The tooltip is an inverse surface, so the pill takes the other
                            // theme's status colours.
                            Theme(
                              data: Theme.of(context).brightness == Brightness.light
                                  ? materialAppDarkTheme
                                  : materialAppTheme,
                              child: GuideStatusPill(guideStatus),
                            ),
                          ],
                        ],
                      ),
                    if (guideStatus?.detail(context.l10n) case final detail?)
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(detail, style: TextStyle(color: colorScheme.onSecondary, fontSize: 12)),
                      ),
                    if (_histogramHint() case final hint?)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _HistogramHint(hint, color: colorScheme.onSecondary),
                      ),
                    if (_canAnalyse && _isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSecondary),
                          ),
                        ),
                      ),
                    if (_canAnalyse && _histogram?.isEmpty == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AdjustmentActivityHistogramChart(
                          histogram: _histogram!,
                          currentValue: widget.value,
                          guideValue: guide?.$1.value,
                        ),
                      ),
                  ],
                ),
              ),
              child: Text.rich(
                // not selectable because conflict with tooltip
                TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: widget.adjustment.name),
                    if (widget.adjustment.notes != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Opacity(
                            opacity: 0.5,
                            child: Icon(
                              Icons.info_outline,
                              color: widget.color,
                              size: textTheme.bodyMedium?.fontSize,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistogramHint extends StatelessWidget {
  final String text;
  final Color color;

  const _HistogramHint(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.bar_chart_rounded, size: 13, color: color),
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

Widget nameSetAdjustmentWidget({required BuildContext context, required String name, required Color? highlightColor}) {
  return Expanded(
    child: Align(
      alignment: Alignment.centerLeft,
      child: SelectableText(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor)),
    ),
  );
}
