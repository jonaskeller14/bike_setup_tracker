import 'package:flutter/material.dart';

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

  static Component _component(String id, ComponentType type) =>
      Component(id: id, name: type.label, componentType: type, installations: const []);

  static final _frame = _component('frame', ComponentType.frame);
  static final _fork = _component('fork', ComponentType.fork);
  static final _frontWheel = GarageComponentGroupData(
    parent: _component('front-wheel', ComponentType.wheelFront),
    children: [
      _component('front-tire', ComponentType.tire),
      _component('front-disc', ComponentType.brakeDisc),
    ],
  );
  static final _rearWheel = GarageComponentGroupData(
    parent: _component('rear-wheel', ComponentType.wheelRear),
    children: [
      _component('rear-tire', ComponentType.tire),
      _component('rear-disc', ComponentType.brakeDisc),
    ],
  );

  /// The same bike as the garage shows it with the feature off: every component a separate cell.
  static final _flatGroups = [
    for (final component in [_frame, _fork, ..._frontWheel.components, ..._rearWheel.components])
      GarageComponentGroupData(parent: component),
  ];

  static final _nestedGroups = [
    GarageComponentGroupData(parent: _frame),
    GarageComponentGroupData(parent: _fork),
    _frontWheel,
    _rearWheel,
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
          const SheetHeader(
            title: 'Subcomponents',
            leadingIcon: Icon(Icons.account_tree_outlined),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Install components on other components, e.g. a tire and a brake disc on a wheel. '
                    'In the Garage, they are grouped with their parent.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('Requires the Installation Timeline.', style: captionStyle),
                  const SizedBox(height: 20),
                  const _ExampleLabel('Without subcomponents'),
                  const SizedBox(height: 8),
                  _ExampleBikeCard(groups: _flatGroups),
                  const SizedBox(height: 16),
                  const _ExampleLabel('With subcomponents'),
                  const SizedBox(height: 8),
                  _ExampleBikeCard(groups: _nestedGroups),
                  const SizedBox(height: 12),
                  Text(
                    'Move a wheel and its tire and brake disc come along. '
                    'They are credited with the same rides.',
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
            child: const Column(
              children: [
                RadioListTile(value: false, title: Text('Off')),
                RadioListTile(value: true, title: Text('On')),
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
              'Trail bike',
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
