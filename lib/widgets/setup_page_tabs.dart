import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../services/dangling_adjustment_service.dart';
import '../utils/component_actions.dart';
import 'display_adjustment/display_adjustment_list.dart';
import 'display_adjustment/display_dangling_adjustment.dart';
import 'empty_state_placeholder2.dart';
import 'initial_changed_value_legend.dart';
import 'items/card_header_tile.dart';
import 'lists/adjustment_set_list.dart';

Widget _errorBadgeDot(BuildContext context, {double size = 9}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      color: scheme.surface,
      shape: BoxShape.circle,
      border: Border.all(color: scheme.error, width: 1),
    ),
    child: Icon(Icons.error, size: size, color: scheme.error),
  );
}

Widget _danglingComponentCard(BuildContext context, {
  required DanglingComponentGroup group,
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
              label: _errorBadgeDot(context),
              backgroundColor: Colors.transparent,
              largeSize: 20,
              child: Icon(group.component.componentType.getIconData(), color: scheme.error),
            ),
            title: Text(group.component.name, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
            subtitle: Text("Component was not installed at setup time", style: TextStyle(color: scheme.error)),
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
              label: _errorBadgeDot(context),
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

Widget _danglingValuesCard(BuildContext context, {
  required Map<String, dynamic> values,
  required String title,
  required String cause,
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
            leading: Icon(Icons.error_outline, color: scheme.error),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
            subtitle: Text(cause, style: TextStyle(color: scheme.error)),
          ),
        ),
        ...values.entries.map((danglingAdjustmentValue) {
          return DisplayDanglingAdjustmentWidget(
            name: danglingAdjustmentValue.key,
            value: danglingAdjustmentValue.value,
            onRemove: () => onRemove(danglingAdjustmentValue.key),
          );
        }),
      ],
    ),
  );
}

/// A shared scaffold for all setup page tabs to ensure consistent layout and
/// behavior. The tabs are laid out inside the setup page's single scroll view,
/// so they must not scroll themselves.
class _SetupTabScaffold extends StatelessWidget {
  final List<Widget> children;
  final bool showLegend;

  const _SetupTabScaffold({
    required this.children,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          if (showLegend) const InitialChangedValueLegend(),
        ],
      ),
    );
  }
}

class SetupBikeTab extends StatefulWidget {
  final String bike;
  final List<Component> bikeComponents;
  final Map<String, Component> allComponents;
  final Map<String, dynamic> bikeAdjustmentValues;
  final Map<String, dynamic> previousBikeAdjustmentValues;
  final Map<String, dynamic> initialBikeAdjustmentValues;
  final Map<String, dynamic> danglingBikeAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) onRemoveFromAdjustmentValues;
  final void Function(String) onDanglingRemove;
  final Future<void> Function({required CategoricalAdjustment adjustment, required String option})? onAddCategoricalOption;

  const SetupBikeTab({
    super.key,
    required this.bike,
    required this.bikeComponents,
    required this.allComponents,
    required this.bikeAdjustmentValues,
    required this.previousBikeAdjustmentValues,
    required this.initialBikeAdjustmentValues,
    required this.danglingBikeAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.onRemoveFromAdjustmentValues,
    required this.onDanglingRemove,
    this.onAddCategoricalOption,
  });

  @override
  State<SetupBikeTab> createState() => _SetupBikeTabState();
}

class _SetupBikeTabState extends State<SetupBikeTab> {
  late Set<String> _initiallyEmptyComponentIds;

  @override
  void initState() {
    super.initState();
    _initiallyEmptyComponentIds = widget.bikeComponents
        .where((c) => c.adjustments.isEmpty)
        .map((c) => c.id)
        .toSet();
  }

  @override
  void didUpdateWidget(SetupBikeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.bikeComponents.map((c) => c.id).toSet();
    final newIds = widget.bikeComponents.map((c) => c.id).toSet();
    if (!setEquals(oldIds, newIds)) {
      _initiallyEmptyComponentIds
        ..removeWhere((id) => !newIds.contains(id))
        ..addAll(widget.bikeComponents.where((c) => c.adjustments.isEmpty).map((c) => c.id));
    }
  }

  Widget _buildEmptyComponentsPlaceholder(BuildContext context, String bike) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyStatePlaceholder2(
          iconData: Component.iconData,
          title: "No components yet",
          subtitle: "Add a component to this bike to start tracking adjustments",
          onTap: () => ComponentActions.addComponent(context, initialBike: bike)
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => ComponentActions.addComponent(context, initialBike: bike),
          icon: const Icon(Icons.add),
          label: const Text("Add Component"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final componentSplit = DanglingAdjustmentService.splitComponents(
      danglingValues: widget.danglingBikeAdjustmentValues,
      components: widget.allComponents.values,
    );

    return _SetupTabScaffold(
      showLegend: widget.bikeComponents.isNotEmpty || widget.danglingBikeAdjustmentValues.isNotEmpty,
      children: [
        if (widget.bikeComponents.isEmpty) ...[
          _buildEmptyComponentsPlaceholder(context, widget.bike),
        ] else ...[
          ...widget.bikeComponents.map((bikeComponent) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CardHeaderTile(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      title: Text(bikeComponent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(Intl.plural(
                        bikeComponent.adjustments.length,
                        zero: "No adjustments yet.",
                        one: "1 adjustment",
                        other: '${bikeComponent.adjustments.length} adjustments',
                      )),
                      leading: Icon(bikeComponent.componentType.getIconData()),
                      enabled: bikeComponent.adjustments.isNotEmpty,
                      trailing: IconButton(
                        onPressed: () => ComponentActions.addAdjustmentForComponent(context, component: bikeComponent),
                        icon: const Icon(Icons.add),
                      ),
                      // trailing: _initiallyEmptyComponentIds.contains(bikeComponent.id)
                      //     ? IconButton(
                      //         onPressed: () => ComponentActions.addAdjustmentForComponent(context, component: bikeComponent),
                      //         icon: const Icon(Icons.add),
                      //       )
                      //     : null,
                    ),
                  ),
                  AdjustmentSetList(
                    key: ValueKey(Object.hash(bikeComponent.id, Object.hashAll(widget.previousBikeAdjustmentValues.values))),
                    adjustments: bikeComponent.adjustments,
                    initialAdjustmentValues: widget.previousBikeAdjustmentValues,
                    adjustmentValues: widget.bikeAdjustmentValues,
                    onAdjustmentValueChanged: widget.onAdjustmentValueChanged,
                    removeFromAdjustmentValues: widget.onRemoveFromAdjustmentValues,
                    onAddCategoricalOption: widget.onAddCategoricalOption,
                  ),
                ],
              ),
            );
          }),
          Center(
            child: TextButton.icon(
              onPressed: () => ComponentActions.addComponent(context, initialBike: widget.bike),
              icon: const Icon(Icons.add),
              label: const Text("Add Component"),
            ),
          ),
        ],
        if (componentSplit.groups.isNotEmpty || componentSplit.deletedValues.isNotEmpty) ...[
          const Divider(height: 50),
          ...componentSplit.groups.map((group) => _danglingComponentCard(
            context,
            group: group,
            adjustmentValues: widget.bikeAdjustmentValues,
            initialAdjustmentValues: widget.previousBikeAdjustmentValues,
            onRemove: widget.onDanglingRemove,
          )),
          if (componentSplit.deletedValues.isNotEmpty)
            _danglingValuesCard(
              context,
              values: componentSplit.deletedValues,
              title: "Dangling Adjustment Values",
              cause: "Component with adjustment was deleted",
              onRemove: widget.onDanglingRemove,
            ),
        ],
      ],
    );
  }
}

class SetupPersonTab extends StatelessWidget {
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

    return _SetupTabScaffold(
      showLegend: person != null || danglingPersonAdjustmentValues.isNotEmpty,
      children: [
        if (person == null)
          const EmptyStatePlaceholder2(
            iconData: Person.iconData,
            title: "No person linked",
            subtitle: "No person linked to this bike. \nExit and edit bike to link a person.",
          )
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
            _danglingValuesCard(
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
