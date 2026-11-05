import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/component_ancestor.dart';
import '../../models/task/task_association.dart';
import '../../repositories/app_repository.dart';
import '../../services/component_hierarchy_resolver.dart';
import '../../theme.dart';
import '../../utils/component_catalog_search.dart';
import '../component_ancestors_column.dart';
import 'picker_tile.dart';
import 'sheet.dart';
import 'sheet_header.dart';

Future<TaskAssociation?> showTaskAssociationSheet({
  required BuildContext context,
  required TaskAssociation selected,
  TaskAssociation? initial,
}) {
  return showModalBottomSheet<TaskAssociation>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _TaskAssociationPickerSheet(selected: selected, initial: initial),
  );
}

class _TaskAssociationPickerSheet extends StatefulWidget {
  final TaskAssociation selected;
  final TaskAssociation? initial;

  const _TaskAssociationPickerSheet({required this.selected, this.initial});

  @override
  State<_TaskAssociationPickerSheet> createState() => _TaskAssociationPickerSheetState();
}

class _TaskAssociationPickerSheetState extends State<_TaskAssociationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _selectedKey = GlobalKey();

  late TaskAssociation _selected = widget.selected;
  String _query = '';
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selectedKey.currentContext;
      if (target == null) return;
      unawaited(Scrollable.ensureVisible(target, alignment: 0.3, duration: const Duration(milliseconds: 250)));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _select(TaskAssociation association) {
    if (_popping) return;
    _popping = true;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _selected = association);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) Navigator.pop(context, association);
    });
  }

  bool get _highlighting => widget.initial != null;

  Color? _highlightColorFor(TaskAssociation association) {
    if (!_highlighting) return null;
    if (association != _selected) return null;
    if (association == widget.initial) return null;
    return Theme.of(context).extension<ValueHighlightColors>()?.changed ?? Colors.orange;
  }

  /// The saved association, currently not picked: stays tappable, just marked.
  bool _isPrevious(TaskAssociation association) =>
      _highlighting && association != _selected && association == widget.initial;

  bool _matches(String haystack) =>
      _query.isEmpty || presetHaystackMatches(haystack, _query);

  String _componentHaystack(Component component, Bike? bike) =>
      '${component.name} ${component.componentType.label(context.l10n)} ${component.componentType.label(englishL10n)} ${bike?.name ?? ''}'
          .toLowerCase();

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;

    final groups = _buildGroups(bikes, components, appRepository.componentHierarchy);
    final showGeneral = _matches('${context.l10n.taskGeneral} ${englishL10n.taskGeneral}'.toLowerCase());
    final dangling = _danglingAssociations(bikes, components);
    final isEmpty = groups.isEmpty && !showGeneral && dangling.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: context.l10n.taskAssociationTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                context.l10n.taskAssociationHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _searchField(),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                child: isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SheetFilterEmptyHint(
                          icon: Icons.search_off,
                          title: context.l10n.taskAssociationNoMatches(_query),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          if (showGeneral) _generalTile(),
                          ...dangling.map(_danglingTile),
                          for (final group in groups) _group(group, bikes),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          hintText: context.l10n.taskAssociationSearchHint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // --- rows ------------------------------------------------------------------

  Widget _generalTile() {
    return _tile(
      association: const GeneralTaskAssociation(),
      icon: Icons.circle_outlined,
      label: context.l10n.taskGeneral,
      subtitle: _subtitleText(context.l10n.taskAssociationGeneralTooltip),
    );
  }

  Widget _danglingTile(TaskAssociation association) {
    return _tile(
      association: association,
      icon: Icons.error_outline,
      label: association.bikeId != null ? context.l10n.bikeNotFound : context.l10n.componentNotFound,
      subtitle: _subtitleText(context.l10n.taskAssociationMissingTooltip),
      color: Theme.of(context).colorScheme.error,
    );
  }

  Widget _subtitleText(String text) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }

  Widget _group(_Group group, Map<String, Bike> bikes) {
    final bike = group.bike;
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in group.rows)
          _tile(
            association: ComponentTaskAssociation(row.component.id),
            icon: row.component.componentType.getIconData(),
            label: row.component.name,
            subtitle: ComponentAncestorsColumn(ancestors: row.ancestors, bikes: bikes),
            depth: row.depth + 1,
            showArrow: row.depth > 0,
            compact: true,
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bike != null)
          _tile(association: BikeTaskAssociation(bike.id), icon: group.icon, label: group.label)
        else
          PickerTile(icon: group.icon, label: group.label, enabled: false),
        rows,
      ],
    );
  }

  Widget _tile({
    required TaskAssociation association,
    required IconData icon,
    required String label,
    Widget? subtitle,
    Color? color,
    int depth = 0,
    bool showArrow = false,
    bool compact = false,
  }) {
    final isSelected = association == _selected;
    return PickerTile(
      key: isSelected ? _selectedKey : null,
      icon: icon,
      label: label,
      color: color,
      subtitle: subtitle,
      selected: isSelected,
      highlightColor: _highlightColorFor(association),
      isPrevious: _isPrevious(association),
      depth: depth,
      showArrow: showArrow,
      compact: compact,
      onTap: () => _select(association),
    );
  }

  // --- grouping --------------------------------------------------------------

  /// Garage order: bikes in repository order, components by `orderIndex`.
  /// Never sorted by `Component.parentId` — that is a UUID, and sorting by it is
  /// what made the old dropdown look randomly ordered.
  List<_Group> _buildGroups(
    Map<String, Bike> bikes,
    Map<String, Component> components,
    ComponentHierarchyResolver hierarchy,
  ) {
    final byBike = <String, List<Component>>{for (final id in bikes.keys) id: []};
    final shelf = <Component>[];
    final archived = <Component>[];

    for (final component in components.values) {
      if (hierarchy.isEffectivelyArchived(component.id)) {
        // The archive stays out of the way; only the component this rule already
        // points at is offered, so an existing link stays visible and editable.
        if (component.id == _selected.componentId || component.id == widget.initial?.componentId) {
          archived.add(component);
        }
        continue;
      }
      // As in the garage, a component on a bike that no longer exists counts as
      // not installed.
      (byBike[hierarchy.currentBike(component.id)] ?? shelf).add(component);
    }

    int byOrderIndex(Component a, Component b) => a.orderIndex.compareTo(b.orderIndex);
    for (final list in [...byBike.values, shelf, archived]) {
      list.sort(byOrderIndex);
    }

    final groups = <_Group>[];

    for (final bike in bikes.values) {
      final bikeMatches = _matches(bike.name.toLowerCase());
      final all = byBike[bike.id] ?? const <Component>[];
      // A matching bike shows its whole card; otherwise only matching parts.
      final visible = bikeMatches
          ? all
          : all.where((c) => _matches(_componentHaystack(c, bike))).toList();
      if (!bikeMatches && visible.isEmpty) continue;
      groups.add(_Group(bike: bike, label: bike.name, icon: Bike.iconData, rows: _nest(visible, hierarchy)));
    }

    void addBucket(List<Component> source, String label, IconData icon) {
      final visible = source.where((c) => _matches(_componentHaystack(c, null))).toList();
      if (visible.isEmpty) return;
      groups.add(_Group(label: label, icon: icon, rows: _nest(visible, hierarchy)));
    }

    addBucket(shelf, context.l10n.timelineNotInstalled, Icons.shelves);
    addBucket(archived, context.l10n.timelineArchived, Icons.inventory_2_outlined);

    return groups;
  }

  /// [components] with each one right below the nearest listed component it is
  /// installed on, siblings keeping their order. A parent hidden by the search
  /// takes no level, so a row is only indented below a row that is really there.
  List<_ComponentRow> _nest(List<Component> components, ComponentHierarchyResolver hierarchy) {
    final listedIds = {for (final component in components) component.id};
    final ancestors = {for (final component in components) component.id: hierarchy.currentAncestors(component.id)};
    final childrenOf = <String?, List<Component>>{};
    for (final component in components) {
      final parentId = ancestors[component.id]!
          .whereType<ParentComponentAncestor>()
          .map((ancestor) => ancestor.component.id)
          .where(listedIds.contains)
          .firstOrNull;
      (childrenOf[parentId] ??= []).add(component);
    }

    final rows = <_ComponentRow>[];
    final placed = <String>{};
    void place(Component component, int depth) {
      if (!placed.add(component.id)) return;
      rows.add(_ComponentRow(component: component, ancestors: ancestors[component.id]!, depth: depth));
      for (final child in childrenOf[component.id] ?? const <Component>[]) {
        place(child, depth + 1);
      }
    }

    for (final root in childrenOf[null] ?? const <Component>[]) {
      place(root, 0);
    }
    // A cycle has no root, so its components are only reached here.
    for (final component in components) {
      place(component, 0);
    }
    return rows;
  }

  /// Associations pointing at an id that no longer exists at all.
  List<TaskAssociation> _danglingAssociations(
    Map<String, Bike> bikes,
    Map<String, Component> components,
  ) {
    bool isDangling(TaskAssociation? association) => switch (association) {
      BikeTaskAssociation(:final id) => !bikes.containsKey(id),
      ComponentTaskAssociation(:final id) => !components.containsKey(id),
      _ => false,
    };

    return <TaskAssociation>{
      if (isDangling(_selected)) _selected,
      if (isDangling(widget.initial)) widget.initial!,
    }.toList();
  }
}

/// A bike with its components, or a bucket of components (shelf / archived)
/// under a non-selectable header.
class _Group {
  final Bike? bike;
  final String label;
  final IconData icon;
  final List<_ComponentRow> rows;

  const _Group({this.bike, required this.label, required this.icon, required this.rows});
}

class _ComponentRow {
  final Component component;
  final List<ComponentAncestor> ancestors;

  /// Levels below the group's top-level components.
  final int depth;

  const _ComponentRow({required this.component, required this.ancestors, required this.depth});
}
