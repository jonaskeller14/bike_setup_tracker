import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../services/dangling_adjustment_service.dart';
import '../utils/component_actions.dart';
import 'display_adjustment/display_adjustment_list.dart';
import 'empty_state_placeholder2.dart';
import 'items/card_header_tile.dart';
import 'lists/adjustment_set_list.dart';
import 'setup_page_tab.dart';

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

    return SetupTabScaffold(
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
            danglingValuesCard(
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
              label: cardErrorBadgeDot(context),
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
