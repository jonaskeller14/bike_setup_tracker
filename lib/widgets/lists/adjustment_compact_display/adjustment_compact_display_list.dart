import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../../models/component.dart';
import '../../../models/person.dart';
import 'adjustment_display_item.dart';
import 'adjustment_table_row.dart';

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
  static const double _outerPadding = _contentInset - AdjustmentTableRow.rowIndent;

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
    final items = <AdjustmentDisplayItem>[
      if (displayBikeAdjustmentValues) ...[
        ...components.map((c) => ComponentDisplayItem(c)),
        ...danglingComponents.map((c) => ComponentDisplayItem(c, isError: true)),
      ],
      if (displayPersonAdjustmentValues) ...[
        ...persons.map((p) => PersonDisplayItem(p)),
        ...danglingPersons.map((p) => PersonDisplayItem(p, isError: true)),
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

    Widget buildRow(_ResolvedItem resolved) => AdjustmentTableRow(
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
            : math.max(0, contentInset! - AdjustmentTableRow.rowIndent),
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

/// A resolved row: the owner plus the value entries that should be shown for it,
/// already filtered for the requested collapsed/expanded state.
class _ResolvedItem {
  final AdjustmentDisplayItem item;
  final List<MapEntry<Adjustment, dynamic>> visibleEntries;
  final Map<Adjustment, dynamic> previousValues;

  const _ResolvedItem({
    required this.item,
    required this.visibleEntries,
    required this.previousValues,
  });
}
