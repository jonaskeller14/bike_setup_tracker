import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../repositories/app_repository.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import '../../models/adjustment/adjustment.dart';

class AdjustmentCompactDisplayList extends StatelessWidget {
  final Iterable<Component> components;
  final Iterable<Person> persons;
  final Iterable<Rating> ratings;
  final Map<String, dynamic> adjustmentValues;
  final Map<String, dynamic> previousAdjustmentValues;
  final bool showRowIcons;
  final bool highlightInitialValues;
  final bool displayOnlyChanges;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;
  final bool missingValuesPlaceholder;

  const AdjustmentCompactDisplayList({
    super.key,
    this.components = const [],
    this.persons = const [],
    this.ratings = const [],
    required this.adjustmentValues,
    this.previousAdjustmentValues = const {},
    this.showRowIcons = false,
    this.highlightInitialValues = false,
    this.displayOnlyChanges = false,
    this.displayBikeAdjustmentValues = true,
    this.displayPersonAdjustmentValues = true,
    this.displayRatingAdjustmentValues = true,
    this.missingValuesPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_Item>[
      if (displayBikeAdjustmentValues)
        ...components.map((c) => _ComponentItem(c)),
      if (displayPersonAdjustmentValues)
        ...persons.map((p) => _PersonItem(p)),
      if (displayRatingAdjustmentValues)
        ...ratings.map((r) => _RatingItem(r)),
    ];

    List<Widget> columnChildren = [];
    for (final item in items) {
      final itemAdjustments = item.adjustments;
      final Map<Adjustment, dynamic> itemAdjustmentValues = missingValuesPlaceholder
          ? Map.fromEntries(  // keep order of item.adjustments
            itemAdjustments
                .map((adj) => MapEntry<Adjustment, dynamic>(adj, adjustmentValues[adj.id] ?? '-'))
          )
          : Map.fromEntries(  // keep order of item.adjustments
            itemAdjustments
                .where((adj) => adjustmentValues.containsKey(adj.id))
                .map((adj) => MapEntry<Adjustment, dynamic>(adj, adjustmentValues[adj.id] ?? '-'))
          );
      if (itemAdjustmentValues.isEmpty) continue;

      final Map<Adjustment, dynamic> itemPreviousAdjustmentValues = Map.fromEntries(
        itemAdjustments
            .where((adj) => previousAdjustmentValues.containsKey(adj.id))
            .map((adj) => MapEntry(adj, previousAdjustmentValues[adj.id])),
      );

      if (displayOnlyChanges) {
        bool keepItem = false;

        for (final entry in itemAdjustmentValues.entries) {
          final adjustment = entry.key;
          final value = entry.value;
          final previousValue = previousAdjustmentValues[adjustment.id];

          final bool valueHasChangedOrInitial = previousValue == null || value != previousValue;
          if (valueHasChangedOrInitial) {
            keepItem = true;
            break;
          }
        }
        if (!keepItem) continue;
      }

      columnChildren.add(_AdjustmentTableRow(
        item: item,
        adjustmentValues: itemAdjustmentValues,
        previousAdjustmentValues: itemPreviousAdjustmentValues,
        showRowIcons: showRowIcons,
        highlightInitialValues: highlightInitialValues,
        displayOnlyChanges: displayOnlyChanges,
      ));
    }

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
  final Map<Adjustment, dynamic> adjustmentValues;
  final Map<Adjustment, dynamic> previousAdjustmentValues;
  final bool showRowIcons;
  final bool highlightInitialValues;
  final bool displayOnlyChanges;

  const _AdjustmentTableRow({
    required this.item,
    required this.adjustmentValues,
    this.previousAdjustmentValues = const {},
    required this.showRowIcons,
    required this.highlightInitialValues,
    required this.displayOnlyChanges,
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
          Tooltip(
            triggerMode: TooltipTriggerMode.longPress,
            preferBelow: false,
            showDuration: const Duration(seconds: 5),
            message: item.name,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: item.buildIcon(context),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final items = adjustmentValues.entries.where((entry) {
                if (!displayOnlyChanges) return true;
                final previousValue = previousAdjustmentValues[entry.key];
                return previousValue == null || entry.value != previousValue;
              }).toList();
              
              return items.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          _AdjustmentTableCell(
                            adjustment: items[i].key,
                            value: items[i].value,
                            previousValue: previousAdjustmentValues[items[i].key],
                            highlightInitialValues: highlightInitialValues,
                            maxWidth: items.length > 1
                                ? ((constraints.maxWidth - 2) / 2) 
                                : double.infinity,
                          ),
                          if (i < items.length - 1)
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
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool valueHasChanged = previousValue == null ? false : value != previousValue;
    final bool valueIsInitial = previousValue == null;
    final highlightColor = highlightInitialValues ? (valueIsInitial ? Colors.green : (valueHasChanged ? Colors.orange: null)) : null;

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
            style: Theme.of(context).textTheme.labelSmall,
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

sealed class _Item {
  List<Adjustment> get adjustments;
  String get name;
  Widget buildIcon(BuildContext context);
}

class _ComponentItem extends _Item {
  final Component _component;
  @override List<Adjustment> get adjustments => _component.adjustments;
  @override String get name => _component.name;
  @override Icon buildIcon(BuildContext _) => Icon(_component.componentType.getIconData());
  _ComponentItem(this._component);
}

class _PersonItem extends _Item {
  final Person _person;
  @override List<Adjustment> get adjustments => _person.adjustments;
  @override String get name => _person.name;
  @override Icon buildIcon(BuildContext _) => Icon(Person.iconData);
  _PersonItem(this._person);
}

class _RatingItem extends _Item {
  final Rating _rating;
  @override List<Adjustment> get adjustments => _rating.adjustments;
  @override String get name => _rating.name;
  @override Widget buildIcon(BuildContext context) {
    final appRepository = context.read<AppRepository>();
    final components = appRepository.components;
    return Badge(
      label: switch(_rating.filterType) {
        FilterType.global => Text("*", style: Theme.of(context).textTheme.labelMedium),
        FilterType.bike => const Icon(Bike.iconData, size: 14),
        FilterType.componentType => Icon(ComponentType.fromString(_rating.filter).getIconData(), size: 14),
        FilterType.component => Icon((components[_rating.filter]?.componentType ?? ComponentType.other).getIconData(), size: 14),
        FilterType.person => const Icon(Person.iconData, size: 14),
      }, 
      backgroundColor: Colors.transparent,
      child: const Icon(Rating.iconData)
    );
  }
  _RatingItem(this._rating);
}
