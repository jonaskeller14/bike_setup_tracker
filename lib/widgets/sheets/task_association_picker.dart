import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/task/task_association.dart';
import '../../repositories/app_repository.dart';
import '../../theme.dart';
import '../../utils/component_preset_search.dart';
import 'sheet.dart';
import 'sheet_header.dart';

Future<TaskAssociation?> showTaskAssociationSheet({
  required BuildContext context,
  required TaskAssociation selected,
  TaskAssociation? initial,
}) {
  return showModalBottomSheet<TaskAssociation>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _TaskAssociationPickerSheet(selected: selected, initial: initial),
  );
}

const double _chipSpacing = 8;

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
      '${component.name} ${component.componentType.label} ${bike?.name ?? ''}'.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;

    final groups = _buildGroups(bikes, components);
    final showGeneral = _matches('general task');
    final dangling = _danglingAssociations(bikes, components);
    final isEmpty = groups.isEmpty && !showGeneral && dangling.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Link task to'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Tap a bike or a component to link this task to it.',
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: isEmpty
                    ? SheetFilterEmptyHint(
                        icon: Icons.search_off,
                        title: 'No matches for "$_query"',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showGeneral) _generalChipRow(),
                          ...dangling.map(_danglingChipRow),
                          ...groups.map(_groupCard),
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
          hintText: 'Search bikes and parts…',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // --- rows and cards --------------------------------------------------------

  Widget _generalChipRow() {
    const association = GeneralTaskAssociation();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _chipFor(
          association: association,
          icon: Icons.circle_outlined,
          label: 'General Task',
          tooltip: 'A task that is not linked to a bike or component',
          emphasized: true,
        ),
      ),
    );
  }

  Widget _danglingChipRow(TaskAssociation association) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _chipFor(
          association: association,
          icon: Icons.error_outline,
          label: association.bikeId != null ? 'BIKE NOT FOUND' : 'COMPONENT NOT FOUND',
          tooltip: 'This entry no longer exists',
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
          borderColor: scheme.error,
        ),
      ),
    );
  }

  Widget _groupCard(_Group group) {
    final scheme = Theme.of(context).colorScheme;
    final bike = group.bike;
    // Outlined: a filled Card defaults to the same `surfaceContainerLow` as the
    // sheet and disappears, and any fill that fixes that has to flip direction
    // between light and dark. An outline defines the card the same way in both.
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        // A chip header brings its own tap padding, so the card needs less of
        // its own; a plain text header does not.
        padding: EdgeInsets.fromLTRB(12, bike != null ? 8 : 12, 12, bike != null ? 8 : 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chipMaxWidth = (constraints.maxWidth - _chipSpacing) / 2;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A bike header is a chip because the bike itself is selectable;
                // a bucket header is plain text because it is not.
                if (bike != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _chipFor(
                      association: BikeTaskAssociation(bike.id),
                      icon: Bike.iconData,
                      label: bike.name,
                      tooltip: bike.name,
                      emphasized: true,
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(group.icon, size: 18, color: group.color ?? scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          group.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: group.color ?? scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (group.components.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // `MaterialTapTargetSize.padded` pads every chip out to a 48dp
                  // tap target, and that padding stacks on top of `runSpacing` —
                  // which is why a symmetric spacing/runSpacing renders with a
                  // far bigger vertical gap. Let the tap padding be the run gap.
                  Wrap(
                    spacing: _chipSpacing,
                    runSpacing: 0,
                    children: [
                      for (final component in group.components)
                        _chipFor(
                          association: ComponentTaskAssociation(component.id),
                          icon: component.componentType.getIconData(),
                          label: component.name,
                          tooltip: '${component.name} · ${component.componentType.label}'
                              '${bike != null ? ' · ${bike.name}' : ' · ${group.label}'}',
                          maxWidth: chipMaxWidth,
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chipFor({
    required TaskAssociation association,
    required IconData icon,
    required String label,
    required String tooltip,
    double? maxWidth,
    bool emphasized = false,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
  }) {
    final isSelected = association == _selected;
    return _AssociationChip(
      key: isSelected ? _selectedKey : null,
      icon: icon,
      label: label,
      tooltip: tooltip,
      selected: isSelected,
      maxWidth: maxWidth,
      emphasized: emphasized,
      highlightColor: _highlightColorFor(association),
      isPrevious: _isPrevious(association),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
      onTap: () => _select(association),
    );
  }

  // --- grouping --------------------------------------------------------------

  /// Garage order: bikes in repository order, components by `orderIndex`.
  /// Never sorted by `Component.bike` — that is a UUID, and sorting by it is
  /// what made the old dropdown look randomly ordered.
  List<_Group> _buildGroups(Map<String, Bike> bikes, Map<String, Component> components) {
    final byBike = <String, List<Component>>{for (final id in bikes.keys) id: []};
    final shelf = <Component>[];
    final orphaned = <Component>[];
    final archived = <Component>[];

    for (final component in components.values) {
      if (component.isArchived) {
        // The archive stays out of the way; only the component this rule already
        // points at is offered, so an existing link stays visible and editable.
        if (component.id == _selected.componentId || component.id == widget.initial?.componentId) {
          archived.add(component);
        }
        continue;
      }
      final bikeId = component.bike;
      if (bikeId == null) {
        shelf.add(component);
      } else if (byBike.containsKey(bikeId)) {
        byBike[bikeId]!.add(component);
      } else {
        orphaned.add(component);
      }
    }

    int byOrderIndex(Component a, Component b) => a.orderIndex.compareTo(b.orderIndex);
    for (final list in [...byBike.values, shelf, orphaned, archived]) {
      list.sort(byOrderIndex);
    }

    final scheme = Theme.of(context).colorScheme;
    final groups = <_Group>[];

    for (final bike in bikes.values) {
      final bikeMatches = _matches(bike.name.toLowerCase());
      final all = byBike[bike.id] ?? const <Component>[];
      // A matching bike shows its whole card; otherwise only matching parts.
      final visible = bikeMatches
          ? all
          : all.where((c) => _matches(_componentHaystack(c, bike))).toList();
      if (!bikeMatches && visible.isEmpty) continue;
      groups.add(_Group(bike: bike, label: bike.name, icon: Bike.iconData, components: visible));
    }

    void addBucket(List<Component> source, String label, IconData icon, {Color? color}) {
      final visible = source.where((c) => _matches(_componentHaystack(c, null))).toList();
      if (visible.isEmpty) return;
      groups.add(_Group(label: label, icon: icon, components: visible, color: color));
    }

    addBucket(shelf, 'Not installed', Icons.shelves);
    addBucket(orphaned, 'Bike not found', Icons.error_outline, color: scheme.error);
    addBucket(archived, 'Archived', Icons.inventory_2_outlined);

    return groups;
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

/// One card on the sheet: a bike and its components, or a bucket of components
/// (shelf / archived) with a plain, non-selectable header.
class _Group {
  final Bike? bike;
  final String label;
  final IconData icon;
  final Color? color;
  final List<Component> components;

  const _Group({
    this.bike,
    required this.label,
    required this.icon,
    required this.components,
    this.color,
  });
}

class _AssociationChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool selected;

  /// Hard cap on the whole chip. A chip re-lays its label against whatever
  /// bounded width it is handed, so constraining the chip is enough to make the
  /// label ellipsize — and it is the only way to know what a chip actually
  /// costs a row. `null` lets it take the full width its parent offers, which
  /// is already bounded by the row, so it can never overflow.
  final double? maxWidth;

  /// Tint for a picked chip that differs from the saved association; `null`
  /// leaves the plain selected look (unchanged, or not editing).
  final Color? highlightColor;

  /// The saved association, currently not picked. Stays a normal, tappable
  /// chip, just marked so the old value stays visible.
  final bool isPrevious;

  /// A bike chip heads its card, so it is stepped up typographically to read as
  /// a header rather than as a peer of the component chips below it.
  final bool emphasized;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _AssociationChip({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.maxWidth,
    required this.highlightColor,
    required this.isPrevious,
    required this.onTap,
    this.emphasized = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color? labelColor =
        highlightColor ?? (isPrevious ? scheme.onSurfaceVariant : foregroundColor);
    // Component chips sit one step below the chip default (labelLarge), which
    // buys a couple of characters inside the half-row cap. The bike and General
    // Task chips keep the default size and go semi-bold, so they read as
    // headers rather than as peers of the components.
    final TextStyle? baseStyle = emphasized
        ? theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.labelMedium;
    final TextStyle? labelStyle =
        labelColor == null ? baseStyle : baseStyle?.copyWith(color: labelColor);
    final BorderSide? side = highlightColor != null
        ? BorderSide(color: highlightColor!)
        : isPrevious
            ? BorderSide(color: scheme.outline)
            : borderColor != null
                ? BorderSide(color: borderColor!)
                : null;

    final Widget chip = ChoiceChip(
      // Selected chips drop the avatar so the checkmark can take its place.
      avatar: selected
          ? null
          : Icon(
              isPrevious ? Icons.history : icon,
              size: emphasized ? 18 : 16,
              color: labelColor,
            ),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      labelStyle: labelStyle,
      side: side,
      // No fill by default: the chip's own outline carries it against the card,
      // and it reads the same in light and dark. Only the dangling chip passes
      // one, to earn its error tone.
      backgroundColor: backgroundColor,
      selectedColor: highlightColor?.withValues(alpha: 0.18),
      checkmarkColor: highlightColor ?? foregroundColor,
      // Only the component chips are shrunk to fit two per row; the header chips
      // keep the default chip size.
      visualDensity: emphasized ? VisualDensity.standard : VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) => onTap(),
    );

    return Tooltip(
      message: isPrevious ? 'Previous value' : tooltip,
      child: maxWidth == null
          ? chip
          : ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: chip),
    );
  }
}
