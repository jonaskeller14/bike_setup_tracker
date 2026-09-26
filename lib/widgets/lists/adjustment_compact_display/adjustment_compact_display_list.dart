import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../../models/component/component.dart';
import '../../../models/person.dart';
import 'adjustment_cell.dart';
import 'adjustment_display_item.dart';
import 'adjustment_group_card.dart';

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
  static const double _horizontalInset = 16;
  static const double _groupSpacing = 6;

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
  });

  static List<AdjustmentCellGroup> _resolveGroups({
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
    final owners = <AdjustmentDisplayItem>[
      if (displayBikeAdjustmentValues) ...[
        ...components.map((c) => ComponentDisplayItem(c)),
        ...danglingComponents.map((c) => ComponentDisplayItem(c, isError: true)),
      ],
      if (displayPersonAdjustmentValues) ...[
        ...persons.map((p) => PersonDisplayItem(p)),
        ...danglingPersons.map((p) => PersonDisplayItem(p, isError: true)),
      ],
    ];

    final groups = <AdjustmentCellGroup>[];
    for (final owner in owners) {
      // Dangling owners only ever appear when everything is shown.
      if (displayOnlyChanges && owner.isError) continue;

      // Adjustments of deleted components/persons never appear here, so their
      // (dangling) values are dropped rather than shown.
      final cells = <AdjustmentCell>[];
      for (final Adjustment adjustment in owner.adjustments) {
        final bool hasValue = adjustmentValues.containsKey(adjustment.id);
        // Values carried over from earlier setups are shown for owners that are
        // still present (currently-installed components / linked persons), never
        // for dangling ones. They render unchanged (no highlight) as the inherited
        // state; an explicit `[]` in the current setup overrides them as a change.
        final bool hasPrevious = !owner.isError && previousAdjustmentValues.containsKey(adjustment.id);
        if (!hasValue && !hasPrevious && !missingValuesPlaceholder) continue;

        final previousValue = previousAdjustmentValues[adjustment.id];
        final dynamic value = hasValue ? adjustmentValues[adjustment.id] : (hasPrevious ? previousValue : null);
        final cell = AdjustmentCell.resolve(
          adjustment: adjustment,
          value: value ?? '-',
          previousValue: previousValue,
          isError: owner.isError,
        );
        if (displayOnlyChanges && !cell.isChange) continue;
        cells.add(cell);
      }
      if (cells.isNotEmpty) groups.add(AdjustmentCellGroup(owner: owner, cells: cells));
    }
    return groups;
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
      final groups = _resolveGroups(
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
      return groups.fold(0, (count, group) => count + group.cells.length);
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
    final groups = _resolveGroups(
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
    if (groups.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _groupSpacing,
        children: [
          // Dangling owners are listed after all regular ones.
          for (final group in [
            ...groups.where((g) => !g.owner.isError),
            ...groups.where((g) => g.owner.isError),
          ])
            AdjustmentGroupCard(
              group: group,
              showIcon: showRowIcons,
              highlightInitialValues: highlightInitialValues,
            ),
        ],
      ),
    );
  }
}
