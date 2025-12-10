import '../models/component.dart';
import '../models/adjustment.dart';
import 'package:flutter/material.dart';

class AdjustmentDisplayList extends StatelessWidget {
  final List<Component> components;
  final Map<Adjustment, dynamic> adjustmentValues;
  final Map<Adjustment, dynamic> previousAdjustmentValues;
  final bool showComponentIcons;
  final bool highlightInitialValues;
  final bool displayOnlyChanges;
  final bool missingValuesPlaceholder;

  AdjustmentDisplayList({
    super.key,
    required this.components,
    required this.adjustmentValues,
    Map<Adjustment, dynamic>? previousAdjustmentValues,
    this.showComponentIcons = false,
    this.highlightInitialValues = false,
    this.displayOnlyChanges = false,
    this.missingValuesPlaceholder = false,
  }) : previousAdjustmentValues = previousAdjustmentValues ?? {};

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    bool insertDivider = false;
    for (int index = 0; index < components.length; index++) {
      final component = components[index];
      final componentAdjustmentValues = missingValuesPlaceholder
          ? Map.fromEntries(  // keep order of component.adjustments
            component.adjustments
                .map((adj) => MapEntry(adj, adjustmentValues[adj] ?? '-')),
          )
          : Map.fromEntries(  // keep order of component.adjustments
            component.adjustments
                .where((adj) => adjustmentValues.containsKey(adj))
                .map((adj) => MapEntry(adj, adjustmentValues[adj]!)),
          );
      if (componentAdjustmentValues.isEmpty) continue;

      if (displayOnlyChanges) {
        bool keepComponent = false;
        final items = componentAdjustmentValues.entries.toList();
        for (int index = 0; index < items.length; index++) {
          final entry = items[index];
          final adjustment = entry.key;
          final value = entry.value;
          final previousValue = previousAdjustmentValues[adjustment];

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
        previousAdjustmentValues: previousAdjustmentValues,
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
  final Component component;
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
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Component.getIcon(component.componentType),
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
    final bool valueHasChanged = previousValue == null ? false : value != previousValue;
    final bool valueIsInitial = previousValue == null;
    bool isCrossed = false;
    String change = "";
    if (valueHasChanged) {
      if (value is String || value is bool) {
        isCrossed = true;
        change = Adjustment.formatValue(previousValue);
      } else {
        dynamic changeValue = value - previousValue;
        change = changeValue > 0 ? "+${Adjustment.formatValue(changeValue)}" : Adjustment.formatValue(changeValue);
      }
    }

    final valueDisplay = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: Adjustment.formatValue(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: (valueIsInitial && highlightInitialValues) ? Colors.green : null,
            ),
          ),
          if (valueHasChanged) ...[
            TextSpan(text: " "),
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Transform.translate(
                offset: const Offset(0, -6),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: valueHasChanged ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                    decoration: isCrossed ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: Colors.red,
                  ),
                ),
              ),
            )
          ],
          if (adjustment.unit != null) ...[
            TextSpan(text: " ${adjustment.unit}"),
          ]
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          finalLabelWidget,
          finalValueWidget,
        ],
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
