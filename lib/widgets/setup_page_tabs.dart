import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../utils/component_actions.dart';
import 'dashed_border_painter.dart';
import 'display_adjustment/display_dangling_adjustment.dart';
import 'initial_changed_value_legend.dart';
import 'lists/adjustment_set_list.dart';

class TabContentWrapper extends StatefulWidget {
  final Widget child;
  const TabContentWrapper({super.key, required this.child});

  @override
  State<TabContentWrapper> createState() => _TabContentWrapperState();
}

class _TabContentWrapperState extends State<TabContentWrapper> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A shared scaffold for all setup page tabs to ensure consistent layout and behavior.
class _SetupTabScaffold extends StatelessWidget {
  final String scrollKey;
  final List<Widget> children;
  final bool showLegend;

  const _SetupTabScaffold({
    required this.scrollKey,
    required this.children,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return TabContentWrapper(
      child: CustomScrollView(
        key: PageStorageKey<String>(scrollKey),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...children,
                  if (showLegend) const InitialChangedValueLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SetupBikeTab extends StatefulWidget {
  final String bike;
  final List<Component> bikeComponents;
  final Map<String, dynamic> bikeAdjustmentValues;
  final Map<String, dynamic> previousBikeAdjustmentValues;
  final Map<String, dynamic> initialBikeAdjustmentValues;
  final Map<String, dynamic> danglingBikeAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) onRemoveFromAdjustmentValues;
  final Function(String) onDanglingRemove;

  const SetupBikeTab({
    super.key,
    required this.bike,
    required this.bikeComponents,
    required this.bikeAdjustmentValues,
    required this.previousBikeAdjustmentValues,
    required this.initialBikeAdjustmentValues,
    required this.danglingBikeAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.onRemoveFromAdjustmentValues,
    required this.onDanglingRemove,
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
        InkWell(
          onTap: () => ComponentActions.addComponent(context, initialBike: bike),
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1.5,
              dashWidth: 6,
              dashSpace: 4,
              borderRadius: 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Component.iconData,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No components yet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Add a component to this bike to start tracking adjustments",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return _SetupTabScaffold(
      scrollKey: 'tab1_bike',
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
                  ListTile(
                    title: Text(bikeComponent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      bikeComponent.adjustments.length,
                      zero: "No adjustments yet.",
                      one: "1 adjustment",
                      other: '${bikeComponent.adjustments.length} adjustments',
                    )),
                    leading: Icon(bikeComponent.componentType.getIconData()),
                    enabled: bikeComponent.adjustments.isNotEmpty,
                    trailing: _initiallyEmptyComponentIds.contains(bikeComponent.id)
                        ? IconButton(
                            onPressed: () => ComponentActions.addAdjustmentForComponent(context, component: bikeComponent),
                            icon: const Icon(Icons.add),
                          )
                        : null,
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  AdjustmentSetList(
                    key: ValueKey(Object.hash(bikeComponent.id, Object.hashAll(widget.previousBikeAdjustmentValues.values))),
                    adjustments: bikeComponent.adjustments,
                    initialAdjustmentValues: widget.previousBikeAdjustmentValues,
                    adjustmentValues: widget.bikeAdjustmentValues,
                    onAdjustmentValueChanged: widget.onAdjustmentValueChanged,
                    removeFromAdjustmentValues: widget.onRemoveFromAdjustmentValues,
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
        if (widget.danglingBikeAdjustmentValues.isNotEmpty) ...[
          const Divider(height: 50),
          Opacity(
            opacity: 0.4,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Dangling Adjustment Values", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      widget.danglingBikeAdjustmentValues.length,
                      one: "1 adjustment value found that is not associated with this bike. Cannot be edited.",
                      other: "${widget.danglingBikeAdjustmentValues.length} adjustment values found that are not associated with this bike. Cannot be edited.",
                    )),
                    leading: const Icon(Icons.question_mark),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  ...widget.danglingBikeAdjustmentValues.entries.map((danglingAdjustmentValue) {
                    return DisplayDanglingAdjustmentWidget(
                      name: danglingAdjustmentValue.key,
                      initialValue: widget.initialBikeAdjustmentValues[danglingAdjustmentValue.key],
                      value: danglingAdjustmentValue.value,
                      onRemove: () {
                        widget.onDanglingRemove(danglingAdjustmentValue.key);
                      },
                    );
                  }),
                ],
              ),
            ),
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
  final Function(String) onDanglingRemove;

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
  });

  Widget _buildEmptyPersonPlaceholder(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Theme.of(context).colorScheme.outlineVariant,
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Person.iconData,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "No person linked",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "No person linked to this bike. \nExit and edit bike to link a person.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = persons[personId];
    return _SetupTabScaffold(
      scrollKey: 'tab2_person',
      showLegend: person != null || danglingPersonAdjustmentValues.isNotEmpty,
      children: [
        if (person == null)
          _buildEmptyPersonPlaceholder(context)
        else
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(Intl.plural(
                    person.adjustments.length,
                    zero: "No attributes yet.",
                    one: "1 attribute",
                    other: '${person.adjustments.length} attributes',
                  )),
                  leading: const Icon(Person.iconData),
                  enabled: person.adjustments.isNotEmpty,
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                AdjustmentSetList(
                  key: ValueKey(Object.hash(personId, Object.hashAll(previousPersonAdjustmentValues.values))),
                  adjustments: person.adjustments,
                  initialAdjustmentValues: previousPersonAdjustmentValues,
                  adjustmentValues: personAdjustmentValues,
                  onAdjustmentValueChanged: onAdjustmentValueChanged,
                  removeFromAdjustmentValues: onRemoveFromAdjustmentValues,
                ),
              ],
            ),
          ),
        if (danglingPersonAdjustmentValues.isNotEmpty) ...[
          const Divider(height: 50),
          Opacity(
            opacity: 0.4,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Dangling Attribute Values", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      danglingPersonAdjustmentValues.length,
                      one: "1 attribute value found that is not associated with this person. Cannot be edited.",
                      other: "${danglingPersonAdjustmentValues.length} attribute values found that are not associated with this person. Cannot be edited.",
                    )),
                    leading: const Icon(Icons.question_mark),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  ...danglingPersonAdjustmentValues.entries.map((danglingAdjustmentValue) {
                    return DisplayDanglingAdjustmentWidget(
                      name: danglingAdjustmentValue.key,
                      initialValue: initialPersonAdjustmentValues[danglingAdjustmentValue.key],
                      value: danglingAdjustmentValue.value,
                      onRemove: () {
                        onDanglingRemove(danglingAdjustmentValue.key);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
