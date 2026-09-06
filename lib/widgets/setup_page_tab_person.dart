import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/adjustment/adjustment.dart';
import '../models/person.dart';
import '../services/dangling_adjustment_service.dart';
import '../utils/person_actions.dart';
import 'display_adjustment/display_adjustment_list.dart';
import 'empty_state_placeholder2.dart';
import 'items/card_header_tile.dart';
import 'lists/adjustment_set_list.dart';
import 'setup_page_tab.dart';

class SetupPersonTab extends StatelessWidget {
  final String bike;
  final String? personId;
  final Map<String, Person> persons;
  final Map<String, dynamic> personAdjustmentValues;
  final Map<String, dynamic> previousPersonAdjustmentValues;
  final Map<String, dynamic> initialPersonAdjustmentValues;
  final Map<String, dynamic> danglingPersonAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) onRemoveFromAdjustmentValues;
  final VoidCallback changeListener;
  final void Function(String) onDanglingRemove;
  final Future<void> Function({required CategoricalAdjustment adjustment, required String option})? onAddCategoricalOption;

  const SetupPersonTab({
    super.key,
    required this.bike,
    required this.personId,
    required this.persons,
    required this.personAdjustmentValues,
    required this.previousPersonAdjustmentValues,
    required this.initialPersonAdjustmentValues,
    required this.danglingPersonAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.onRemoveFromAdjustmentValues,
    required this.changeListener,
    required this.onDanglingRemove,
    this.onAddCategoricalOption,
  });

  @override
  Widget build(BuildContext context) {
    final person = persons[personId];

    final personSplit = DanglingAdjustmentService.splitPersons(
      danglingValues: danglingPersonAdjustmentValues,
      persons: persons.values,
    );

    return SetupTabScaffold(
      showLegend: person != null || danglingPersonAdjustmentValues.isNotEmpty,
      children: [
        if (person == null)
          _LinkPersonPlaceholder(bike: bike, persons: persons)
        else
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CardHeaderTile(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      person.adjustments.length,
                      zero: "No attributes yet.",
                      one: "1 attribute",
                      other: '${person.adjustments.length} attributes',
                    )),
                    leading: const Icon(Person.iconData),
                    enabled: person.adjustments.isNotEmpty,
                    trailing: IconButton(
                      onPressed: () => PersonActions.addAdjustmentForPerson(context, person: person),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
                AdjustmentSetList(
                  key: ValueKey(Object.hash(personId, Object.hashAll(previousPersonAdjustmentValues.values))),
                  adjustments: person.adjustments,
                  initialAdjustmentValues: previousPersonAdjustmentValues,
                  adjustmentValues: personAdjustmentValues,
                  onAdjustmentValueChanged: onAdjustmentValueChanged,
                  removeFromAdjustmentValues: onRemoveFromAdjustmentValues,
                  prefillFromInitial: false,
                  onAddCategoricalOption: onAddCategoricalOption,
                ),
              ],
            ),
          ),
        if (personSplit.groups.isNotEmpty || personSplit.deletedValues.isNotEmpty) ...[
          const Divider(height: 50),
          ...personSplit.groups.map((group) => _danglingPersonCard(
            context,
            group: group,
            adjustmentValues: personAdjustmentValues,
            initialAdjustmentValues: previousPersonAdjustmentValues,
            onRemove: onDanglingRemove,
          )),
          if (personSplit.deletedValues.isNotEmpty)
            danglingValuesCard(
              context,
              values: personSplit.deletedValues,
              title: "Dangling Attribute Values",
              cause: "Attribute was deleted",
              onRemove: onDanglingRemove,
            ),
        ],
      ],
    );
  }
}

Widget _danglingPersonCard(BuildContext context, {
  required DanglingPersonGroup group,
  required Map<String, dynamic> adjustmentValues,
  required Map<String, dynamic> initialAdjustmentValues,
  required void Function(String) onRemove,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CardHeaderTile(
          color: scheme.errorContainer,
          child: ListTile(
            leading: Badge(
              label: cardErrorBadgeDot(context),
              backgroundColor: Colors.transparent,
              largeSize: 20,
              child: Icon(Person.iconData, color: scheme.error),
            ),
            title: Text(group.person.name, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
            subtitle: Text("Person is not linked to this setup", style: TextStyle(color: scheme.error)),
          ),
        ),
        AdjustmentDisplayList(
          adjustments: group.adjustments,
          initialAdjustmentValues: initialAdjustmentValues,
          adjustmentValues: adjustmentValues,
          isError: true,
          onRemove: onRemove,
        ),
      ],
    ),
  );
}

/// Empty state of the person tab: the bike has no rider yet, so it offers to
/// link an existing person or to create one for this bike.
class _LinkPersonPlaceholder extends StatefulWidget {
  final String bike;
  final Map<String, Person> persons;

  const _LinkPersonPlaceholder({required this.bike, required this.persons});

  @override
  State<_LinkPersonPlaceholder> createState() => _LinkPersonPlaceholderState();
}

class _LinkPersonPlaceholderState extends State<_LinkPersonPlaceholder> {
  final MenuController _menuController = MenuController();

  void _toggleMenu() => _menuController.isOpen ? _menuController.close() : _menuController.open();

  /// [MenuAnchor] pins the menu's top edge to the anchor, so opening it above
  /// the button means offsetting it by the menu's own height. Overestimating
  /// only costs a gap: a menu that no longer fits above is placed below.
  double _estimatedMenuHeight(BuildContext context) {
    final itemHeight = MediaQuery.textScalerOf(context).scale(kMinInteractiveDimension);
    return (widget.persons.length + 1) * itemHeight + (widget.persons.isEmpty ? 0 : 1) + 8;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyStatePlaceholder2(
          iconData: Person.iconData,
          title: "No person linked",
          subtitle: "Link a person to this bike to track rider attributes",
          onTap: _toggleMenu,
        ),
        const SizedBox(height: 8),
        MenuAnchor(
          controller: _menuController,
          alignmentOffset: Offset(0, -_estimatedMenuHeight(context) - 4),
          style: MenuStyle(
            alignment: AlignmentDirectional.topStart,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
          ),
          menuChildren: [
            ...widget.persons.values.map((person) {
              return MenuItemButton(
                leadingIcon: const Icon(Icons.link),
                onPressed: () => PersonActions.linkPersonToBike(context, bikeId: widget.bike, person: person),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text("Link '${person.name}'", overflow: TextOverflow.ellipsis),
                ),
              );
            }),
            if (widget.persons.isNotEmpty) const Divider(height: 1),
            MenuItemButton(
              leadingIcon: const Icon(Icons.add),
              onPressed: () => PersonActions.addPersonForBike(context, bikeId: widget.bike),
              child: const Text("Create new Person"),
            ),
          ],
          builder: (context, controller, child) => FilledButton.icon(
            onPressed: _toggleMenu,
            icon: const Icon(Icons.person_add_alt),
            label: const Text("Link Person"),
          ),
        ),
      ],
    );
  }
}
