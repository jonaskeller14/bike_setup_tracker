import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/adjustment_activity_histogram.dart';
import '../../services/setup_activity_analysis_service.dart';
import '../display_data/adjustment_activity_histogram_chart.dart';
import '../items/adjustment_properties.dart';
import '../items/adjustment_type_icon.dart';

class AdjustmentIconNameNotes extends StatefulWidget {
  final Adjustment adjustment;
  final Color? color;
  final bool compact;

  const AdjustmentIconNameNotes({super.key, required this.adjustment, this.color, this.compact = false});

  @override
  State<AdjustmentIconNameNotes> createState() => _AdjustmentIconNameNotesState();
}

class _AdjustmentIconNameNotesState extends State<AdjustmentIconNameNotes> {
  SetupActivityAnalysisService? _analysisService;
  Future<AdjustmentActivityHistogram>? _histogramFuture;
  AdjustmentActivityHistogram? _histogram;
  bool _isLoading = false;

  @override
  void didUpdateWidget(covariant AdjustmentIconNameNotes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adjustment.id != widget.adjustment.id) {
      _histogramFuture = null;
      _histogram = null;
      _isLoading = false;
    }
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
    if (!identical(service, _analysisService) || service?.hasAnyActivity != true) {
      _histogramFuture = null;
      _histogram = null;
      _isLoading = false;
    }
    _analysisService = service;
  }

  void _loadHistogram() {
    final service = _analysisService;
    if (service == null || !service.hasAnyActivity) return;

    final future = service.getAdjustmentHistogram(widget.adjustment.id);
    setState(() {
      _histogramFuture = future;
      _histogram = null;
      _isLoading = true;
    });
    unawaited(_resolveHistogram(future));
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
                    if (_analysisService?.hasAnyActivity == true && _isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSecondary),
                          ),
                        ),
                      ),
                    if (_analysisService?.hasAnyActivity == true && _histogram?.isEmpty == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AdjustmentActivityHistogramChart(histogram: _histogram!),
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

Widget nameSetAdjustmentWidget({required BuildContext context, required String name, required Color? highlightColor}) {
  return Expanded(
    child: Align(
      alignment: Alignment.centerLeft,
      child: SelectableText(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor)),
    ),
  );
}
