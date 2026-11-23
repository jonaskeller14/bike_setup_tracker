import "package:flutter/material.dart";
import "package:provider/provider.dart";

import '../../l10n/l10n.dart';

import '../../models/app_settings.dart';
import '../../models/selected_data.dart';
import '../../models/syncable.dart';
import '../../repositories/app_repository.dart';
import '../../services/data_selection_dependencies.dart';
import '../items/data_select_bike.dart';
import '../items/data_select_component.dart';
import '../items/data_select_feedback.dart';
import '../items/data_select_person.dart';
import '../items/data_select_setup.dart';
import '../items/data_select_task_entry.dart';
import '../items/data_select_task_rule.dart';
import '../items/data_select_test_session.dart';
import 'data_select_flash.dart';
import 'sheet_header.dart';

Future<SelectedData?> showDataSelectSheet({required BuildContext context, required AppRepository data}) async {
  return showModalBottomSheet<SelectedData?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DataSelectFlow(allData: data);
    },
  );
}

class DataSelectFlow extends StatefulWidget {
  final AppRepository allData;
  const DataSelectFlow({super.key, required this.allData});

  @override
  State<DataSelectFlow> createState() => _DataSelectFlowState();
}

class _DataSelectFlowState extends State<DataSelectFlow> {
  bool isManualSelection = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 'canPop' is true if we are on Step One (let it close).
      // 'canPop' is false if we are on Step Two (we want to intercept it).
      canPop: !isManualSelection,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;  // If the pop already happened (Step One), do nothing.
        setState(() => isManualSelection = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isManualSelection
            ? SelectDataItemsSheetContent(
                allData: SelectedData(
                  persons: widget.allData.persons,
                  bikes: widget.allData.bikes,
                  components: widget.allData.components,
                  setups: widget.allData.setups,
                  taskRules: widget.allData.taskRules,
                  taskEntries: widget.allData.taskEntries,
                  feedbacks: widget.allData.feedbacks,
                  testSessions: widget.allData.testSessions,
                ),
                onBack: () => setState(() => isManualSelection = false),
                onConfirm: (data) => Navigator.of(context).pop(data),
              )
            : SelectDataMethodSheetContent(
                onAllSelected: () => Navigator.of(context).pop(SelectedData(
                  persons: widget.allData.persons,
                  bikes: widget.allData.bikes,
                  components: widget.allData.components,
                  setups: widget.allData.setups,
                  taskRules: widget.allData.taskRules,
                  taskEntries: widget.allData.taskEntries,
                  feedbacks: widget.allData.feedbacks,
                  testSessions: widget.allData.testSessions,
                )),
                onManualSelected: () => setState(() => isManualSelection = true),
              ),
      ),
    );
  }
}

class SelectDataMethodSheetContent extends StatelessWidget {
  final VoidCallback onAllSelected;
  final VoidCallback onManualSelected;
  final VoidCallback? onBack;

  const SelectDataMethodSheetContent({
    super.key,
    required this.onAllSelected,
    required this.onManualSelected,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: context.l10n.dataSelectTitle,
            onBack: onBack,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.select_all, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.dataSelectAll),
                    subtitle: Text(context.l10n.dataSelectAllSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onAllSelected,
                  ),
                  ListTile(
                    leading: Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.dataSelectChoose),
                    subtitle: Text(context.l10n.dataSelectChooseSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onManualSelected,
                  ),
                ],
              ),
            )
          ),
        ],
      ),
    );
  }
}

class SelectDataItemsSheetContent extends StatefulWidget {
  final SelectedData allData;
  final void Function(SelectedData) onConfirm;
  final VoidCallback onBack;

  const SelectDataItemsSheetContent({
    super.key,
    required this.allData,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  State<SelectDataItemsSheetContent> createState() => _SelectDataItemsSheetContentState();
}

class _SelectDataItemsSheetContentState extends State<SelectDataItemsSheetContent> {
  late final DataSelectionDependencies _dependencies = DataSelectionDependencies(widget.allData);
  final DataSelection _selection = DataSelection();

  /// The items the last tick selected automatically. Each tick bumps [_tick],
  /// so a row that is added again flashes again.
  Set<DataRef> _autoSelected = const {};
  int _tick = 0;

  void _select(Iterable<DataRef> refs) {
    final ticked = refs.toSet();
    setState(() {
      _autoSelected = _selection.addAll(_dependencies.closureOf(ticked)).difference(ticked);
      _tick++;
    });
  }

  void _deselect(Iterable<DataRef> refs) {
    setState(() {
      for (final ref in refs) {
        _selection.remove(ref);
      }
    });
  }

  Widget _group<T extends Syncable>(
    BuildContext context, {
    required DataKind kind,
    required Iterable<T> items,
    required String Function(int selected, int total) title,
    required Widget Function(T item, bool isSelected, ValueChanged<bool?> onChanged) row,
  }) {
    final entries = [for (final item in items) (DataRef(kind, item.id), item)];
    final refs = [for (final (ref, _) in entries) ref];
    final selected = _selection.count(kind);
    return ExpansionTile(
      title: DataSelectFlash(
        flash: _autoSelected.any((ref) => ref.kind == kind) ? _tick : null,
        builder: (context, tint, child) => DecoratedBox(
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(4)),
          child: child,
        ),
        child: Text(title(selected, refs.length), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
      tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
      controlAffinity: ListTileControlAffinity.leading,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const Border(),
      collapsedShape: const Border(),
      trailing: Checkbox(
        tristate: true,
        value: selected == 0 && refs.isNotEmpty
            ? false
            : (selected == refs.length ? true : null),
        onChanged: (bool? newValue) => newValue == true ? _select(refs) : _deselect(refs),
      ),
      children: [
        for (final (ref, item) in entries)
          DataSelectFlash.card(
            flash: _autoSelected.contains(ref) ? _tick : null,
            child: row(
              item,
              _selection.contains(ref),
              (checked) => checked == true ? _select([ref]) : _deselect([ref]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    final allCount = widget.allData.bikes.length +
        widget.allData.components.length +
        widget.allData.setups.length +
        widget.allData.persons.length +
        widget.allData.taskRules.length +
        widget.allData.taskEntries.length +
        widget.allData.feedbacks.length +
        widget.allData.testSessions.length;
    final selectedCount = DataKind.values.fold(0, (sum, kind) => sum + _selection.count(kind));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: context.l10n.dataSelectItemsTitle,
            onBack: widget.onBack,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _group(
                    context,
                    kind: DataKind.bike,
                    items: widget.allData.bikes.values,
                    title: context.l10n.dataSelectBikes,
                    row: (b, isSelected, onChanged) => DataSelectBike(
                      bike: b,
                      persons: widget.allData.persons,
                      isSelected: isSelected,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _group(
                    context,
                    kind: DataKind.component,
                    items: widget.allData.components.values,
                    title: context.l10n.dataSelectComponents,
                    row: (c, isSelected, onChanged) => DataSelectComponent(
                      component: c,
                      bikes: widget.allData.bikes,
                      components: widget.allData.components,
                      isSelected: isSelected,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _group(
                    context,
                    kind: DataKind.setup,
                    items: widget.allData.setups.values.toList().reversed,
                    title: context.l10n.dataSelectSetups,
                    row: (s, isSelected, onChanged) => DataSelectSetup(
                      setup: s,
                      bikes: widget.allData.bikes,
                      isSelected: isSelected,
                      onChanged: onChanged,
                    ),
                  ),
                  if (appSettings.enablePerson || widget.allData.persons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _group(
                      context,
                      kind: DataKind.person,
                      items: widget.allData.persons.values,
                      title: context.l10n.dataSelectRiders,
                      row: (p, isSelected, onChanged) => DataSelectPerson(
                        item: p,
                        isSelected: isSelected,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                  if (appSettings.enableTask || widget.allData.taskRules.isNotEmpty) ... [
                    const SizedBox(height: 16),
                    _group(
                      context,
                      kind: DataKind.taskRule,
                      items: widget.allData.taskRules.values,
                      title: context.l10n.dataSelectTasks,
                      row: (tr, isSelected, onChanged) => DataSelectTaskRule(
                        item: tr,
                        bikes: widget.allData.bikes,
                        components: widget.allData.components,
                        isSelected: isSelected,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                  if (appSettings.enableTask || widget.allData.taskEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _group(
                      context,
                      kind: DataKind.taskEntry,
                      items: widget.allData.taskEntries.values,
                      title: context.l10n.dataSelectTaskEntries,
                      row: (te, isSelected, onChanged) => DataSelectTaskEntry(
                        item: te,
                        taskRules: widget.allData.taskRules,
                        isSelected: isSelected,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                  if (appSettings.enableRating || widget.allData.feedbacks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _group(
                      context,
                      kind: DataKind.feedback,
                      items: widget.allData.feedbacks.values,
                      title: context.l10n.dataSelectFeedback,
                      row: (item, isSelected, onChanged) => DataSelectFeedback(
                        item: item,
                        bikes: widget.allData.bikes,
                        isSelected: isSelected,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                  if (appSettings.enableRating || widget.allData.testSessions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _group(
                      context,
                      kind: DataKind.testSession,
                      items: widget.allData.testSessions.values,
                      title: context.l10n.dataSelectTestSessions,
                      row: (item, isSelected, onChanged) => DataSelectTestSession(
                        item: item,
                        bikes: widget.allData.bikes,
                        isSelected: isSelected,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedCount == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  context.l10n.dataSelectEmptyHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedCount == 0 ? null : () => widget.onConfirm(_selection.toSelectedData(widget.allData)),
              child: Text(context.l10n.dataSelectConfirm(selectedCount, allCount)),
            ),
          ),
        ],
      ),
    );
  }
}
