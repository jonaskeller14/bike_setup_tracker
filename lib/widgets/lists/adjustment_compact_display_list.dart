import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../theme.dart';
import '../notes_text.dart';

class AdjustmentCompactSummary {
  final bool hasContent;
  final bool collapsedHasContent;
  final bool collapsedHidesSomething;

  const AdjustmentCompactSummary({
    required this.hasContent,
    required this.collapsedHasContent,
    required this.collapsedHidesSomething,
  });
}

class AdjustmentCompactDisplayList extends StatelessWidget {
  static const double _contentInset = 16;
  static const double _errorBorderWidth = 1;
  static const double _errorContentPadding = 6;
  static const double _rowIndent = _errorBorderWidth + _errorContentPadding;
  static const double _outerPadding = _contentInset - _rowIndent;

  final Iterable<Component> components;
  final Iterable<Person> persons;
  final Iterable<Component> danglingComponents;
  final Iterable<Person> danglingPersons;

  final Map<String, dynamic> adjustmentValues;
  final Map<String, dynamic> previousAdjustmentValues;
  final bool showRowIcons;
  final bool highlightInitialValues;
  final bool displayOnlyChanges;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool missingValuesPlaceholder;

  /// Where the value rows start relative to this widget's own left edge.
  /// Defaults to [_contentInset].
  final double? contentInset;

  const AdjustmentCompactDisplayList({
    super.key,
    this.components = const [],
    this.persons = const [],
    this.danglingComponents = const [],
    this.danglingPersons = const [],
    required this.adjustmentValues,
    this.previousAdjustmentValues = const {},
    this.showRowIcons = false,
    this.highlightInitialValues = false,
    this.displayOnlyChanges = false,
    this.displayBikeAdjustmentValues = true,
    this.displayPersonAdjustmentValues = true,
    this.missingValuesPlaceholder = false,
    this.contentInset,
  });

  static List<_ResolvedItem> _resolveItems({
    required Iterable<Component> components,
    required Iterable<Person> persons,
    required Iterable<Component> danglingComponents,
    required Iterable<Person> danglingPersons,
    required Map<String, dynamic> adjustmentValues,
    required Map<String, dynamic> previousAdjustmentValues,
    required bool displayOnlyChanges,
    required bool displayBikeAdjustmentValues,
    required bool displayPersonAdjustmentValues,
    required bool missingValuesPlaceholder,
  }) {
    final items = <_Item>[
      if (displayBikeAdjustmentValues) ...[
        ...components.map((c) => _ComponentItem(c)),
        ...danglingComponents.map((c) => _ComponentItem(c, isError: true)),
      ],
      if (displayPersonAdjustmentValues) ...[
        ...persons.map((p) => _PersonItem(p)),
        ...danglingPersons.map((p) => _PersonItem(p, isError: true)),
      ],
    ];

    final resolved = <_ResolvedItem>[];
    for (final item in items) {
      // Dangling rows only ever appear when everything is shown.
      if (displayOnlyChanges && item.isError) continue;

      // Values whose adjustment still belongs to this owner. Adjustments of
      // deleted components/persons never appear here, so their (dangling)
      // values are dropped rather than shown.
      final entries = <MapEntry<Adjustment, dynamic>>[];
      for (final adjustment in item.adjustments) {
        final bool hasValue = adjustmentValues.containsKey(adjustment.id);
        // Values carried over from earlier setups are shown for owners that are
        // still present (currently-installed components / linked persons), never
        // for dangling ones. They render unchanged (no highlight) as the inherited
        // state; an explicit `[]` in the current setup overrides them as a change.
        final bool hasPrevious =
            !item.isError && previousAdjustmentValues.containsKey(adjustment.id);
        if (!hasValue && !hasPrevious && !missingValuesPlaceholder) continue;
        final dynamic value = hasValue
            ? adjustmentValues[adjustment.id]
            : (hasPrevious ? previousAdjustmentValues[adjustment.id] : null);
        entries.add(MapEntry(adjustment, value ?? '-'));
      }
      if (entries.isEmpty) continue;

      final visibleEntries = displayOnlyChanges
          ? entries.where((entry) {
              final previousValue = previousAdjustmentValues[entry.key.id];
              return previousValue == null || !adjustmentValuesEqual(entry.value, previousValue);
            }).toList()
          : entries;
      if (visibleEntries.isEmpty) continue;

      final previousValues = <Adjustment, dynamic>{
        for (final adjustment in item.adjustments)
          if (previousAdjustmentValues.containsKey(adjustment.id))
            adjustment: previousAdjustmentValues[adjustment.id],
      };

      resolved.add(_ResolvedItem(
        item: item,
        visibleEntries: visibleEntries,
        previousValues: previousValues,
      ));
    }
    return resolved;
  }

  /// Describes what would be rendered without building any widgets.
  static AdjustmentCompactSummary summarize({
    Iterable<Component> components = const [],
    Iterable<Person> persons = const [],
    Iterable<Component> danglingComponents = const [],
    Iterable<Person> danglingPersons = const [],
    required Map<String, dynamic> adjustmentValues,
    Map<String, dynamic> previousAdjustmentValues = const {},
    bool displayBikeAdjustmentValues = true,
    bool displayPersonAdjustmentValues = true,
    bool missingValuesPlaceholder = false,
  }) {
    int visibleCells(bool displayOnlyChanges) {
      final resolved = _resolveItems(
        components: components,
        persons: persons,
        danglingComponents: danglingComponents,
        danglingPersons: danglingPersons,
        adjustmentValues: adjustmentValues,
        previousAdjustmentValues: previousAdjustmentValues,
        displayOnlyChanges: displayOnlyChanges,
        displayBikeAdjustmentValues: displayBikeAdjustmentValues,
        displayPersonAdjustmentValues: displayPersonAdjustmentValues,
        missingValuesPlaceholder: missingValuesPlaceholder,
      );
      return resolved.fold(0, (count, item) => count + item.visibleEntries.length);
    }

    final expandedCells = visibleCells(false);
    final collapsedCells = visibleCells(true);
    return AdjustmentCompactSummary(
      hasContent: expandedCells > 0,
      collapsedHasContent: collapsedCells > 0,
      collapsedHidesSomething: expandedCells > collapsedCells,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedItems = _resolveItems(
      components: components,
      persons: persons,
      danglingComponents: danglingComponents,
      danglingPersons: danglingPersons,
      adjustmentValues: adjustmentValues,
      previousAdjustmentValues: previousAdjustmentValues,
      displayOnlyChanges: displayOnlyChanges,
      displayBikeAdjustmentValues: displayBikeAdjustmentValues,
      displayPersonAdjustmentValues: displayPersonAdjustmentValues,
      missingValuesPlaceholder: missingValuesPlaceholder,
    );

    if (resolvedItems.isEmpty) return const SizedBox.shrink();

    final normalItems = resolvedItems.where((r) => !r.item.isError).toList();
    final errorItems = resolvedItems.where((r) => r.item.isError).toList();

    Widget buildRow(_ResolvedItem resolved) => _AdjustmentTableRow(
          item: resolved.item,
          entries: resolved.visibleEntries,
          previousAdjustmentValues: resolved.previousValues,
          showRowIcons: showRowIcons,
          highlightInitialValues: highlightInitialValues,
        );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: contentInset == null
            ? _outerPadding
            : math.max(0, contentInset! - _rowIndent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          if (normalItems.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < normalItems.length; i++) ...[
                  buildRow(normalItems[i]),
                  if (i < normalItems.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1.3,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                ],
              ],
            ),
          ...errorItems.map(buildRow),
        ],
      ),
    );
  }
}

class _AdjustmentTableRow extends StatelessWidget {
  static const double _rowWidthSafetyMargin = 2;
  static const double _lineSpacing = 2;

  final _Item item;
  final List<MapEntry<Adjustment, dynamic>> entries;
  final Map<Adjustment, dynamic> previousAdjustmentValues;
  final bool showRowIcons;
  final bool highlightInitialValues;

  const _AdjustmentTableRow({
    required this.item,
    required this.entries,
    this.previousAdjustmentValues = const {},
    required this.showRowIcons,
    required this.highlightInitialValues,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (showRowIcons)
          _infoTooltip(
            context: context,
            message: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.notes != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3), // tweak to match font size
                        child: Icon(
                          Icons.notes,
                          size: 13,
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: NotesText(
                          item.notes!,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          maxLines: 10,
                        ),
                      ),
                    ],
                  ),
                if (item.errorDescription != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 15,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        Text(
                          item.errorDescription!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(top: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.isError
                    ? scheme.errorContainer
                    : scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(5),
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  size: 18,
                  color: item.isError ? scheme.onErrorContainer : scheme.onSurfaceVariant,
                ),
                child: item.buildIcon(context),
              ),
            ),
          ),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lines = _layoutAdjustmentCells(
                context: context,
                entries: entries,
                previousAdjustmentValues: previousAdjustmentValues,
                availableWidth: constraints.maxWidth,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: _AdjustmentTableRow._lineSpacing,
                children: [
                  for (final line in lines)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var pos = 0; pos < line.length; pos++) ...[
                          _AdjustmentTableCell(
                            adjustment: line[pos].entry.key,
                            value: line[pos].entry.value,
                            previousValue: previousAdjustmentValues[line[pos].entry.key],
                            highlightInitialValues: highlightInitialValues,
                            isError: item.isError,
                            maxWidth: line[pos].maxWidth,
                          ),
                          if (pos < line.length - 1)
                            _VerticalDivider(color: dividerColor),
                        ],
                      ],
                    ),
                ],
              );
            },
          ),
        )
      ],
    );

    if (item.isError) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdjustmentCompactDisplayList._errorContentPadding,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            width: AdjustmentCompactDisplayList._errorBorderWidth,
            color: scheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: content,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdjustmentCompactDisplayList._rowIndent,
          vertical: 3,
        ),
        child: content,
      );
    }
  }
}

/// The text/decoration a cell's value row renders, computed once so both the
/// real widget (_AdjustmentTableCell) and the width-measurement pass
/// (_measureCellNaturalWidth) always use identical content.
class _CellText {
  final String value;
  final String? change;
  final TextDecoration changeDecoration;

  const _CellText({required this.value, this.change, this.changeDecoration = TextDecoration.none});

  bool get hasChange => change != null;
}

_CellText _cellDisplayText(Adjustment adjustment, dynamic value, dynamic previousValue) {
  final bool valueHasChanged = previousValue == null ? false : !adjustmentValuesEqual(value, previousValue);
  String normalize(String s) => s.replaceAll(RegExp(r'\n|\r'), ' ');

  final String valueText = normalize(Adjustment.formatValue(value));
  if (!valueHasChanged) return _CellText(value: valueText);

  String changeText = "";
  TextDecoration changeDecoration = TextDecoration.none;
  switch (adjustment) {
    case BooleanAdjustment():
    case TextAdjustment():
    case CategoricalAdjustment():
      changeDecoration = TextDecoration.lineThrough;
      changeText = Adjustment.formatValue(previousValue);
    case NumericalAdjustment():
    case DurationAdjustment():
    case StepAdjustment():
      if ((value is num && previousValue is num) || (value is Duration && previousValue is Duration)) {
        final dynamic changeValue = value - previousValue;
        changeText = (changeValue is num ? changeValue > 0 : !changeValue.isNegative)
            ? "+${Adjustment.formatValue(changeValue)}"
            : Adjustment.formatValue(changeValue);
      } else {
        changeDecoration = TextDecoration.lineThrough;
        changeText = Adjustment.formatValue(previousValue);
      }
  }
  return _CellText(value: valueText, change: normalize(changeText), changeDecoration: changeDecoration);
}

// Keyed by content (role + text + scale), not by adjustment identity — an
// edited adjustment name/value is a different string, so it's automatically
// a cache miss (freshly measured), never a stale hit. Do not key this by
// adjustment.id instead; that would go stale on rename/edit.
final Map<String, double> _textWidthCache = {};

TextStyle _resolveTextStyle(BuildContext context, TextStyle? style) {
  final ambient = DefaultTextStyle.of(context).style;
  return style == null ? ambient : ambient.merge(style);
}

double _measureTextWidth({
  required BuildContext context,
  required String role, // disambiguates e.g. "5" as a label vs. as a value
  required String text,
  required TextStyle style,
  required TextDirection textDirection,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final key = '$role|$text|${scaler.scale(100).toStringAsFixed(2)}';
  final cached = _textWidthCache[key];
  if (cached != null) return cached;

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: scaler,
    maxLines: 1,
  )..layout();

  // Simple unbounded-growth safeguard; in practice the number of distinct
  // adjustment values ever displayed in one app session stays small.
  if (_textWidthCache.length > 2000) _textWidthCache.clear();
  return _textWidthCache[key] = painter.width;
}

double _measureCellNaturalWidth({
  required BuildContext context,
  required Adjustment adjustment,
  required dynamic value,
  required dynamic previousValue,
  required TextDirection textDirection,
}) {
  final display = _cellDisplayText(adjustment, value, previousValue);

  final labelStyle = _resolveTextStyle(
    context, Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0));
  final labelWidth = _measureTextWidth(
    context: context, role: 'label', text: adjustment.name, style: labelStyle, textDirection: textDirection);

  final valueStyle = _resolveTextStyle(context,
    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFeatures: [FontFeature.tabularFigures()]));
  var valueRowWidth = _measureTextWidth(
    context: context, role: 'value', text: display.value, style: valueStyle, textDirection: textDirection);

  if (display.hasChange) {
    final changeStyle = _resolveTextStyle(context,
      const TextStyle(fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]));
    valueRowWidth += _AdjustmentTableCell._valueRowSpacing +
      _measureTextWidth(context: context, role: 'change', text: display.change!, style: changeStyle, textDirection: textDirection);
  }
  if (adjustment.unit != null) {
    final unitStyle = _resolveTextStyle(context, null);
    valueRowWidth += _AdjustmentTableCell._valueRowSpacing +
      _measureTextWidth(context: context, role: 'unit', text: adjustment.unit!.label, style: unitStyle, textDirection: textDirection);
  }

  return math.max(labelWidth, valueRowWidth) + 2 * _AdjustmentTableCell._horizontalPadding;
}

/// One entry positioned within a computed visual line, with its final
/// render-time maxWidth already resolved.
class _LaidOutCell {
  final MapEntry<Adjustment, dynamic> entry;
  final double maxWidth;
  const _LaidOutCell({required this.entry, required this.maxWidth});
}

/// Packs [entries] into order-preserving visual lines that fit within
/// [availableWidth], applying the "50% cap, except the last cell in its own
/// line may use leftover space" rule. Pure & synchronous — safe to call
/// directly from LayoutBuilder's builder.
List<List<_LaidOutCell>> _layoutAdjustmentCells({
  required BuildContext context,
  required List<MapEntry<Adjustment, dynamic>> entries,
  required Map<Adjustment, dynamic> previousAdjustmentValues,
  required double availableWidth,
}) {
  if (entries.isEmpty) return const [];

  final textDirection = Directionality.of(context);
  final naturalWidths = [
    for (final e in entries)
      _measureCellNaturalWidth(
        context: context,
        adjustment: e.key,
        value: e.value,
        previousValue: previousAdjustmentValues[e.key],
        textDirection: textDirection,
      ),
  ];

  // "generally 50%" — a flat cap on the *full row's* available width, not a
  // per-line 1/N share.
  final halfCap = math.max(0.0, availableWidth - _AdjustmentTableRow._rowWidthSafetyMargin) / 2;

  // 1) Greedy, order-preserving line packing using capped provisional widths.
  final lineIndices = <List<int>>[];
  var current = <int>[];
  var currentWidth = 0.0;
  for (var i = 0; i < entries.length; i++) {
    final provisional = math.min(naturalWidths[i], halfCap);
    final extra = current.isEmpty ? provisional : _VerticalDivider.width + provisional;
    if (current.isNotEmpty && currentWidth + extra > availableWidth) {
      lineIndices.add(current);
      current = [i];
      currentWidth = provisional;
    } else {
      current.add(i);
      currentWidth += extra;
    }
  }
  if (current.isNotEmpty) lineIndices.add(current);

  // 2) Per-line width assignment: every cell but the line's last gets the
  //    50% cap; the last cell gets the line's leftover slack, never more
  //    than it actually needs.
  return [
    for (final line in lineIndices)
      [
        for (var pos = 0; pos < line.length; pos++)
          if (pos < line.length - 1)
            _LaidOutCell(entry: entries[line[pos]], maxWidth: math.min(naturalWidths[line[pos]], halfCap))
          else
            _LaidOutCell(
              entry: entries[line[pos]],
              maxWidth: math.max(0.0, math.min(
                naturalWidths[line[pos]],
                availableWidth -
                    [for (var p = 0; p < line.length - 1; p++) math.min(naturalWidths[line[p]], halfCap)]
                        .fold(0.0, (a, b) => a + b) -
                    (line.length - 1) * _VerticalDivider.width,
              )),
            ),
      ],
  ];
}

class _AdjustmentTableCell extends StatelessWidget {
  static const double _horizontalPadding = 8;
  static const double _valueRowSpacing = 4;

  final double maxWidth;
  final Adjustment adjustment;
  final dynamic value;
  final dynamic previousValue;
  final bool highlightInitialValues;
  final bool isError;

  const _AdjustmentTableCell({
    required this.adjustment,
    required this.value,
    required this.previousValue,
    required this.highlightInitialValues,
    this.isError = false,
    this.maxWidth = 120.0,
  });

  Tooltip _cellToolTip({
    required BuildContext context,
    required bool valueHasChanged,
    required Color? highlightColor,
    required Widget child,
  }) {
    return _infoTooltip(
      context: context,
      child: child,
      message: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: adjustment.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (adjustment is StepAdjustment)
                    TextSpan(
                      text: "  [${Adjustment.formatValue((adjustment as StepAdjustment).min)}..${Adjustment.formatValue((adjustment as StepAdjustment).max)}]",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Adjustment.formatValue(value),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: (highlightInitialValues ? highlightColor : null) ?? Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: adjustment.unitSuffix(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ]
              ),
            ),
            if (valueHasChanged)
              Text(
                Adjustment.formatValue(previousValue) + adjustment.unitSuffix(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                  decoration: TextDecoration.lineThrough,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = _cellDisplayText(adjustment, value, previousValue);
    final bool valueHasChanged = display.hasChange;
    final bool valueIsInitial = previousValue == null;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    final Color? highlightColor = isError
        ? Theme.of(context).colorScheme.error
        : (highlightInitialValues
            ? (valueIsInitial
                ? (highlights?.initial ?? Colors.green)
                : (valueHasChanged ? (highlights?.changed ?? Colors.orange) : null))
            : null);

    // The tooltip renders on colorScheme.inverseSurface, which is the opposite
    // brightness of the current theme, so it needs the highlight variant made
    // for that opposite brightness rather than the current theme's.
    final tooltipHighlights = Theme.of(context).brightness == Brightness.dark
        ? ValueHighlightColors.light
        : ValueHighlightColors.dark;
    final Color? tooltipHighlightColor = isError
        ? null
        : (highlightInitialValues
            ? (valueIsInitial
                ? tooltipHighlights.initial
                : (valueHasChanged ? tooltipHighlights.changed : null))
            : null);

    final finalValueWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // The Row is necessary to ensure the SingleChildScrollView's child
        // (the Text.rich) only takes the space it needs when it's shorter
        // than _max_value_width.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: _valueRowSpacing,
        children: [
          Flexible(
            child: Text(
              display.value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: highlightColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
            ),
          ),
          if (valueHasChanged) ...[
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                display.change!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  decoration: display.changeDecoration,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
              ),
            ),
          ],
          if (adjustment.unit != null)
            Text(
              adjustment.unit!.label,
              style: isError
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
        ],
      ),
    );

    final finalLabelWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The Row is necessary to ensure the SingleChildScrollView's child
      // (the Text.rich) only takes the space it needs when it's shorter
      // than _max_value_width.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            adjustment.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    return _cellToolTip(
      context: context,
      highlightColor: tooltipHighlightColor,
      valueHasChanged: valueHasChanged,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            finalLabelWidget,
            finalValueWidget,
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  static const double width = 1;

  final Color color;

  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 28,
      color: color,
    );
  }
}

/// A resolved row: the owner plus the value entries that should be shown for it,
/// already filtered for the requested collapsed/expanded state.
class _ResolvedItem {
  final _Item item;
  final List<MapEntry<Adjustment, dynamic>> visibleEntries;
  final Map<Adjustment, dynamic> previousValues;

  const _ResolvedItem({
    required this.item,
    required this.visibleEntries,
    required this.previousValues,
  });
}

Widget _errorBadgeDot(BuildContext context, {double size = 9}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      color: scheme.error,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.error, size: size, color: scheme.errorContainer),
  );
}

Tooltip _infoTooltip({
  required BuildContext context,
  required Widget message,
  required Widget child,
}) {
  return Tooltip(
    triggerMode: TooltipTriggerMode.longPress,
    preferBelow: false,
    showDuration: const Duration(seconds: 5),
    enableTapToDismiss: false,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.inverseSurface,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(12),
    richMessage: WidgetSpan(child: message),
    child: child,
  );
}

sealed class _Item {
  final bool isError;
  _Item({this.isError = false});

  List<Adjustment> get adjustments;
  String get name;
  String? get notes;
  String? get errorDescription;

  Widget buildIcon(BuildContext context);
}

class _ComponentItem extends _Item {
  final Component _component;
  @override List<Adjustment> get adjustments => _component.adjustments;
  @override String get name => _component.name;
  @override String? get notes => _component.notes;
  @override String? get errorDescription => isError ? "Component was not installed at setup time" : null;
  @override
  Widget buildIcon(BuildContext context) {
    final icon = Icon(
      _component.componentType.getIconData(),
      color: isError ? Theme.of(context).colorScheme.error : null,
    );
    if (!isError) return icon;
    return Badge(
      label: _errorBadgeDot(context),
      backgroundColor: Colors.transparent,
      largeSize: 20,
      child: icon,
    );
  }
  _ComponentItem(this._component, {super.isError});
}

class _PersonItem extends _Item {
  final Person _person;
  @override List<Adjustment> get adjustments => _person.adjustments;
  @override String get name => _person.name;
  @override String? get notes => _person.notes;
  @override String? get errorDescription => isError ? "Person is not linked to this setup" : null;
  @override
  Widget buildIcon(BuildContext context) {
    final icon = Icon(
      Person.iconData,
      color: isError ? Theme.of(context).colorScheme.error : null,
    );
    if (!isError) return icon;
    return Badge(
      label: _errorBadgeDot(context),
      backgroundColor: Colors.transparent,
      largeSize: 20,
      child: icon,
    );
  }
  _PersonItem(this._person, {super.isError});
}
