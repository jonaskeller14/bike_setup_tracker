import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/adjustment/adjustment.dart';

class AdjustmentCompactDisplayList extends StatelessWidget {
  final List<dynamic> components; // List<Component OR Person OR Rating>
  final Map<String, dynamic> adjustmentValues;
  final Map<String, dynamic> previousAdjustmentValues;
  final bool showComponentIcons;
  final bool highlightInitialValues;
  final bool displayOnlyChanges;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;
  final bool missingValuesPlaceholder;

  AdjustmentCompactDisplayList({
    super.key,
    required this.components,
    required this.adjustmentValues,
    Map<String, dynamic>? previousAdjustmentValues,
    this.showComponentIcons = false,
    this.highlightInitialValues = false,
    this.displayOnlyChanges = false,
    this.displayBikeAdjustmentValues = true,
    this.displayPersonAdjustmentValues = true,
    this.displayRatingAdjustmentValues = true,
    this.missingValuesPlaceholder = false,
  }) : previousAdjustmentValues = previousAdjustmentValues ?? {};

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [];
    bool insertDivider = false;
    for (int index = 0; index < components.length; index++) {
      final component = components[index];
      if (component is Component && !displayBikeAdjustmentValues) continue;
      if (component is Person && !displayPersonAdjustmentValues) continue;
      if (component is Rating && !displayRatingAdjustmentValues) continue;

      final componentAdjustments = component.adjustments as List<Adjustment>;
      final Map<Adjustment, dynamic> componentAdjustmentValues = missingValuesPlaceholder
          ? Map.fromEntries(  // keep order of component.adjustments
            componentAdjustments
                .map((adj) => MapEntry<Adjustment, dynamic>(adj, adjustmentValues[adj.id] ?? '-'))
          )
          : Map.fromEntries(  // keep order of component.adjustments
            componentAdjustments
                .where((adj) => adjustmentValues.containsKey(adj.id))
                .map((adj) => MapEntry<Adjustment, dynamic>(adj, adjustmentValues[adj.id] ?? '-'))
          );
      if (componentAdjustmentValues.isEmpty) continue;

      final Map<Adjustment, dynamic> componentPreviousAdjustmentValues = Map.fromEntries(
        componentAdjustments
            .where((adj) => previousAdjustmentValues.containsKey(adj.id))
            .map((adj) => MapEntry(adj, previousAdjustmentValues[adj.id])),
      );

      if (displayOnlyChanges) {
        bool keepComponent = false;
        final items = componentAdjustmentValues.entries.toList();
        for (int index = 0; index < items.length; index++) {
          final entry = items[index];
          final adjustment = entry.key;
          final value = entry.value;
          final previousValue = previousAdjustmentValues[adjustment.id];

          final bool valueHasChanged = previousValue == null ? false : value != previousValue;
          final bool valueIsInitial = previousValue == null;
          if (valueHasChanged || valueIsInitial) {
            keepComponent = true;
            break;
          }
        }
        if (!keepComponent) continue;
      }
      
      if (insertDivider) {
        columnChildren.add(const Divider(
          height: 6, 
          thickness: 1, 
          indent: 0,
          endIndent: 0,
        ));
      }

      columnChildren.add(_AdjustmentTableRow(
        component: component,
        adjustmentValues: componentAdjustmentValues,
        previousAdjustmentValues: componentPreviousAdjustmentValues,
        showComponentIcons: showComponentIcons,
        highlightInitialValues: highlightInitialValues,
        displayOnlyChanges: displayOnlyChanges,
      ));
      insertDivider = true;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: columnChildren);
  }
}

class _AdjustmentTableRow extends StatelessWidget {
  final dynamic component; // Component or Person
  final Map<Adjustment, dynamic> adjustmentValues;
  final Map<Adjustment, dynamic> previousAdjustmentValues;
  final bool showComponentIcons;
  final bool highlightInitialValues;
  final bool displayOnlyChanges;

  _AdjustmentTableRow({
    required this.component,
    required this.adjustmentValues,
    Map<Adjustment, dynamic>? previousAdjustmentValues,
    required this.showComponentIcons,
    required this.highlightInitialValues,
    required this.displayOnlyChanges,
  }) : previousAdjustmentValues = previousAdjustmentValues ?? {};

  @override
  Widget build(BuildContext context) {
    final appData = context.read<AppData>();
    final components = Map.fromEntries(appData.components.entries.where((e) => !e.value.isDeleted));
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      spacing: 6,
      children: [
        if (showComponentIcons)
          Tooltip(
            triggerMode: TooltipTriggerMode.longPress,
            preferBelow: false,
            showDuration: const Duration(seconds: 5),
            message: component.name,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: switch (component) {
                Component() => Icon(component.componentType.getIconData()),
                Person() => const Icon(Person.iconData),
                Rating() => Badge(
                  label: switch(component.filterType as FilterType) {
                    FilterType.global => Text("*", style: Theme.of(context).textTheme.labelMedium),
                    FilterType.bike => const Icon(Bike.iconData, size: 14),
                    FilterType.componentType => Icon((ComponentType.values.firstWhereOrNull((ct) => ct.toString() == component.filter) ?? ComponentType.other).getIconData(), size: 14),
                    FilterType.component => Icon((components[component.filter]?.componentType ?? ComponentType.other).getIconData(), size: 14),
                    FilterType.person => const Icon(Person.iconData, size: 14),
                  }, 
                  backgroundColor: Colors.transparent,
                  child: const Icon(Rating.iconData)
                ),
                _ => const Icon(Icons.question_mark),
              },
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final items = adjustmentValues.entries.toList();
              List<Widget> children = [];

              for (int index = 0; index < items.length; index++) {
                final entry = items[index];
                final adjustment = entry.key;
                final value = entry.value;
                final previousValue = previousAdjustmentValues[adjustment];

                final bool valueHasChanged = previousValue == null ? false : value != previousValue;
                final bool valueIsInitial = previousValue == null;
                if (displayOnlyChanges && !valueHasChanged && !valueIsInitial) continue;

                children.add(
                  _AdjustmentTableCell(
                    adjustment: adjustment,
                    value: value,
                    previousValue: previousValue,
                    highlightInitialValues: highlightInitialValues,
                    maxWidth: items.length > 1 ? ((constraints.maxWidth - 2) / 2) : double.infinity,  // Vertical divider width = 1, rounding errors +1
                  ),
                );
              }
              // Add dividers
              children = children.expand((item) sync* { yield item; if (item != children.last) yield _VerticalDivider(); }).toList();

              return Wrap(
                alignment: WrapAlignment.start,
                children: children,
              );
            },
          ),
        )
      ],
    );
  }
}

class _AdjustmentTableCell extends StatelessWidget {
  final double maxWidth;
  final Adjustment adjustment;
  final dynamic value;
  final dynamic previousValue;
  final bool highlightInitialValues;

  const _AdjustmentTableCell({
    required this.adjustment,
    required this.value,
    required this.previousValue,
    required this.highlightInitialValues,
    this.maxWidth = 120.0,
  });

  Tooltip _cellToolTip({
    required BuildContext context,
    required bool valueHasChanged,
    required Color? highlightColor,
    required Widget child,
  }) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      showDuration: const Duration(seconds: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      richMessage: WidgetSpan(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              adjustment.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Adjustment.formatValue(value),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: (highlightInitialValues ? highlightColor : null) ?? Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: adjustment.unitSuffix(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ]
              ),
            ),
            if (valueHasChanged)
              Text(
                Adjustment.formatValue(previousValue) + adjustment.unitSuffix(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7),
                  decoration: TextDecoration.lineThrough,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Requirement: Handle all Adjustment types, long values, multi lines values (TextAdjustment)
    final bool valueHasChanged = previousValue == null ? false : value != previousValue;
    final bool valueIsInitial = previousValue == null;
    bool isCrossed = false;
    String change = "";
    final String valueText = Adjustment.formatValue(value);
    if (valueHasChanged) {
      if (value is String || value is bool) { // Boolean, Text, Categorical
        isCrossed = true;
        change = Adjustment.formatValue(previousValue);
      } else { // Numerical, Step, Duration
        dynamic changeValue = value - previousValue;
        change = changeValue > 0 ? "+${Adjustment.formatValue(changeValue)}" : Adjustment.formatValue(changeValue);
      }
    }

    final highlightColor = highlightInitialValues ? (valueIsInitial ? Colors.green : (valueHasChanged ? Colors.orange: null)) : null;

    // Use individual Text widgets so we can apply overflow to the main value
    // while keeping the change indicator visible.

    final finalValueWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // The Row is necessary to ensure the SingleChildScrollView's child 
        // (the Text.rich) only takes the space it needs when it's shorter 
        // than _max_value_width.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 4,
        children: [
          Flexible(
            child: Text(
              valueText.replaceAll(RegExp(r'\n|\r'), ' '),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: highlightColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (valueHasChanged) ...[
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                change.replaceAll(RegExp(r'\n|\r'), ' '),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  decoration: isCrossed ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (adjustment.unit != null)
            Text(adjustment.unit!),
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
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return _cellToolTip(
      context: context,
      highlightColor: highlightColor,
      valueHasChanged: valueHasChanged,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
    );
  }
}
