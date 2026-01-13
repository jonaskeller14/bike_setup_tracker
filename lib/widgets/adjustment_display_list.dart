import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/adjustment/adjustment.dart';
import 'package:flutter/material.dart';

class AdjustmentDisplayList extends StatelessWidget {
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

  AdjustmentDisplayList({
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
    List<Widget> children = [];
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
                .map((adj) => MapEntry<Adjustment, dynamic>(adj, adjustmentValues[adj.id]!))
          );
      if (componentAdjustmentValues.isEmpty) continue;

      final Map<Adjustment, dynamic> componentPreviousAdjustmentValues = Map.fromEntries(
        componentAdjustments
            .where((adj) => previousAdjustmentValues.containsKey(adj.id))
            .map((adj) => MapEntry(adj, previousAdjustmentValues[adj.id]!)),
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
        children.add(const Divider(
          height: 6, 
          thickness: 1, 
          indent: 0,
          endIndent: 0,
        ));
      }

      children.add(_AdjustmentTableRow(
        component: component,
        adjustmentValues: componentAdjustmentValues,
        previousAdjustmentValues: componentPreviousAdjustmentValues,
        showComponentIcons: showComponentIcons,
        highlightInitialValues: highlightInitialValues,
        displayOnlyChanges: displayOnlyChanges,
      ));
      insertDivider = true;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children);
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
          maxWidth: items.length > 1 ? 120 : double.infinity,
        ),
      );
    }
    // Add dividers
    children = children.expand((item) sync* { yield item; if (item != children.last) yield _VerticalDivider(); }).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showComponentIcons) ... [
          Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            preferBelow: false,
            showDuration: const Duration(seconds: 5),
            message: component.name,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: switch (component) {
                Component() => Icon(component.componentType.getIconData()),
                Person() => const Icon(Person.iconData),
                Rating() => const Icon(Rating.iconData),
                _ => const Icon(Icons.question_mark),
              },
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.start,
            children: children,
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

    // Use individual Text widgets so we can apply overflow to the main value
    // while keeping the change indicator visible.
    final valueDisplay = Row(
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
              color: (valueIsInitial && highlightInitialValues) ? Colors.green : null,
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
                color: valueHasChanged ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                decoration: isCrossed ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: Colors.red,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (adjustment.unit != null)
          Text(adjustment.unit!),
      ],
    );

    Widget finalLabelWidget = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
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
              // maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    Widget finalValueWidget = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // The Row is necessary to ensure the SingleChildScrollView's child 
        // (the Text.rich) only takes the space it needs when it's shorter 
        // than _max_value_width.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [valueDisplay],
        ),
      ),
    );

    final highlightColor = valueIsInitial ? Colors.green : (valueHasChanged ? Colors.orange: null);
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
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
            Text(
              adjustment.unit == null
                    ? Adjustment.formatValue(value)
                    : "${Adjustment.formatValue(value)} ${adjustment.unit}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: highlightColor ?? Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (valueHasChanged)
              Text(
                adjustment.unit == null
                    ? Adjustment.formatValue(previousValue)
                    : "${Adjustment.formatValue(previousValue)} ${adjustment.unit}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
      child: Container(
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
