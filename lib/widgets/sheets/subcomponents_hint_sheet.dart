import 'package:flutter/material.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../utils/garage_component_grouping.dart';
import '../items/garage_component_cell.dart';
import '../items/garage_component_group.dart';
import '../items/garage_component_icon_card.dart';
import 'sheet_header.dart';

/// Settings sheet with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showSubcomponentsSettingSheet(
  BuildContext context, {
  required bool value,
}) {
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _SubcomponentsHintSheet(value: value),
  );
}

class _SubcomponentsHintSheet extends StatelessWidget {
  const _SubcomponentsHintSheet({required this.value});

  final bool value;

  static Component _component(AppLocalizations l10n, String id, ComponentType type) =>
      Component(id: id, name: type.label(l10n), componentType: type, installations: const []);

  /// The same bike as the garage shows it with the feature off: every component a separate cell.
  static List<GarageComponentGroupData> _flatGroups(AppLocalizations l10n) => [
    for (final component in [..._nestedGroups(l10n).expand((group) => group.components)])
      GarageComponentGroupData(parent: component),
  ];

  static List<GarageComponentGroupData> _nestedGroups(AppLocalizations l10n) => [
    GarageComponentGroupData(parent: _component(l10n, 'frame', ComponentType.frame)),
    GarageComponentGroupData(parent: _component(l10n, 'fork', ComponentType.fork)),
    GarageComponentGroupData(
      parent: _component(l10n, 'front-wheel', ComponentType.wheelFront),
      children: [
        _component(l10n, 'front-tire', ComponentType.tire),
        _component(l10n, 'front-disc', ComponentType.brakeDisc),
      ],
    ),
    GarageComponentGroupData(
      parent: _component(l10n, 'rear-wheel', ComponentType.wheelRear),
      children: [
        _component(l10n, 'rear-tire', ComponentType.tire),
        _component(l10n, 'rear-disc', ComponentType.brakeDisc),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: context.l10n.featuresSubcomponents,
            leadingIcon: const Icon(Icons.account_tree_outlined),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.subcomponentsSheetIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _ExampleLabel(context.l10n.subcomponentsSheetWithout),
                  const SizedBox(height: 8),
                  _ExampleBikeCard(groups: _flatGroups(context.l10n)),
                  const SizedBox(height: 16),
                  _ExampleLabel(context.l10n.subcomponentsSheetWith),
                  const SizedBox(height: 8),
                  _ExampleBikeCard(groups: _nestedGroups(context.l10n)),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.subcomponentsSheetCaption,
                    style: captionStyle,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          RadioGroup<bool>(
            groupValue: value,
            onChanged: (selected) => Navigator.pop(context, selected),
            child: Column(
              children: [
                RadioListTile(value: false, title: Text(context.l10n.valueOff)),
                RadioListTile(value: true, title: Text(context.l10n.valueOn)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleLabel extends StatelessWidget {
  const _ExampleLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Static look-alike of the garage bike card.
class _ExampleBikeCard extends StatelessWidget {
  const _ExampleBikeCard({required this.groups});

  final List<GarageComponentGroupData> groups;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Bike.iconData),
            title: Text(
              context.l10n.subcomponentsExampleBike,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final cellWidth = GarageComponentIconCard.widthFor(
                  constraints.maxWidth,
                  spacing: spacing,
                );
                final cardsPerRow = GarageComponentIconCard.cardsPerRow(
                  constraints.maxWidth,
                  spacing: spacing,
                );
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final group in groups)
                      group.isGroup
                          ? GarageComponentGroup(
                              group: group,
                              componentToShowDetails: null,
                              cellWidth: cellWidth,
                              spacing: spacing,
                              cardsPerRow: cardsPerRow,
                              onPressedComponent: (_) {},
                              setDraggedComponent: (_) {},
                              isSnapshot: true,
                            )
                          : GarageComponentCell(
                              component: group.parent,
                              componentToShowDetails: null,
                              width: cellWidth,
                            ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
