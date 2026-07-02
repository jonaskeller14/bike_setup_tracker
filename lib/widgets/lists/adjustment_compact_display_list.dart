import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/component.dart';
import '../../models/person.dart';

class AdjustmentCompactSummary {
  final bool hasContent;
  final bool collapsedHidesSomething;

  const AdjustmentCompactSummary({
    required this.hasContent,
    required this.collapsedHidesSomething,
  });
}

class AdjustmentCompactDisplayList extends StatelessWidget {
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
        if (!hasValue && !missingValuesPlaceholder) continue;
        entries.add(MapEntry(adjustment, adjustmentValues[adjustment.id] ?? '-'));
      }
      if (entries.isEmpty) continue;

      final visibleEntries = displayOnlyChanges
          ? entries.where((entry) {
              final previousValue = previousAdjustmentValues[entry.key.id];
              return previousValue == null || entry.value != previousValue;
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

    final columnChildren = [
      for (final resolved in resolvedItems)
        _AdjustmentTableRow(
          item: resolved.item,
          entries: resolved.visibleEntries,
          previousAdjustmentValues: resolved.previousValues,
          showRowIcons: showRowIcons,
          highlightInitialValues: highlightInitialValues,
        ),
    ];

    final horizontalDivider = const Divider(
      height: 6,
      thickness: 1,
      indent: 0,
      endIndent: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < columnChildren.length; i++) ...[
          columnChildren[i],
          if (i < columnChildren.length - 1) horizontalDivider,
        ],
      ],
    );
  }
}

class _AdjustmentTableRow extends StatelessWidget {
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
    final dividerColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
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
                    color: Theme.of(context).colorScheme.onSecondary,
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
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          item.notes!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 13,
                          ),
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
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: item.buildIcon(context),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.start,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    _AdjustmentTableCell(
                      adjustment: entries[i].key,
                      value: entries[i].value,
                      previousValue: previousAdjustmentValues[entries[i].key],
                      highlightInitialValues: highlightInitialValues,
                      isError: item.isError,
                      maxWidth: i == entries.length - 1
                          ? double.infinity
                          : ((constraints.maxWidth - 2) / 2),
                    ),
                    if (i < entries.length - 1)
                      _VerticalDivider(color: dividerColor),
                  ],
                ],
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
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (adjustment is StepAdjustment)
                    TextSpan(
                      text: "  [${Adjustment.formatValue((adjustment as StepAdjustment).min)}..${Adjustment.formatValue((adjustment as StepAdjustment).max)}]",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool valueHasChanged = previousValue == null ? false : value != previousValue;
    final bool valueIsInitial = previousValue == null;
    final Color? highlightColor = isError
        ? Theme.of(context).colorScheme.error
        : (highlightInitialValues ? (valueIsInitial ? Colors.green : (valueHasChanged ? Colors.orange : null)) : null);

    final String valueText = Adjustment.formatValue(value);
    String changeText = "";
    TextDecoration changeDecoration = TextDecoration.none;
    if (valueHasChanged) {
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
    }

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
                changeText.replaceAll(RegExp(r'\n|\r'), ' '),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  decoration: changeDecoration,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (adjustment.unit != null)
            Text(
              adjustment.unit!,
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
              color: isError ? Theme.of(context).colorScheme.error : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return _cellToolTip(
      context: context,
      highlightColor: isError ? null : highlightColor,
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
  final Color color;

  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
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
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSecondaryContainer,
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
