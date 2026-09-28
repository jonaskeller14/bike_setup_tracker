import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bike.dart';
import '../../models/component/component_ancestor.dart';
import '../../models/component/installation.dart';
import '../../theme.dart';
import '../../utils/component_preset_search.dart';
import '../component_ancestors_column.dart';
import '../sticky_section.dart';
import 'sheet.dart';
import 'sheet_header.dart';

@immutable
class InstallationParentOption {
  final Installation value;
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;
  final String? typeLabel;
  final Color? color;
  final List<ComponentAncestor> ancestors;
  final bool isMissing;
  /// False moves the option behind the "Show all" row.
  final bool isSuggested;

  const InstallationParentOption({
    required this.value,
    required this.icon,
    required this.label,
    this.subtitle,
    this.subtitleColor,
    this.typeLabel,
    this.color,
    this.ancestors = const [],
    this.isMissing = false,
    this.isSuggested = true,
  });
}

Future<Installation?> showInstallationParentPickerSheet({
  required BuildContext context,
  required List<InstallationParentOption> options,
  required Map<String, Bike> bikes,
  required Installation selected,
  Installation? initial,
  String? currentBikeId,
  String? depthCapHint,
  String? componentTypeLabel,
}) {
  return showModalBottomSheet<Installation>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _InstallationParentPickerSheet(
      options: options,
      bikes: bikes,
      selected: selected,
      initial: initial,
      currentBikeId: currentBikeId,
      depthCapHint: depthCapHint,
      componentTypeLabel: componentTypeLabel,
    ),
  );
}

const int _searchThreshold = 8;

class _InstallationParentPickerSheet extends StatefulWidget {
  final List<InstallationParentOption> options;
  final Map<String, Bike> bikes;
  final Installation selected;
  final Installation? initial;
  final String? currentBikeId;
  final String? depthCapHint;
  final String? componentTypeLabel;

  const _InstallationParentPickerSheet({
    required this.options,
    required this.bikes,
    required this.selected,
    this.initial,
    this.currentBikeId,
    this.depthCapHint,
    this.componentTypeLabel,
  });

  @override
  State<_InstallationParentPickerSheet> createState() => _InstallationParentPickerSheetState();
}

class _InstallationParentPickerSheetState extends State<_InstallationParentPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _selectedKey = GlobalKey();

  late Installation _selected = widget.selected;
  String _query = '';
  bool _showAll = false;
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

  void _select(Installation value) {
    if (_popping) return;
    _popping = true;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _selected = value);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) Navigator.pop(context, value);
    });
  }

  /// Options carry the entry's current id and date, while the saved entry may
  /// differ in both, so rows compare by parent only.
  static bool _sameParent(Installation a, Installation? b) =>
      b != null && a.parentType == b.parentType && a.parent == b.parent;

  bool get _highlighting => widget.initial != null;

  Color? _highlightColorFor(Installation value) {
    if (!_highlighting) return null;
    if (!_sameParent(value, _selected)) return null;
    if (_sameParent(value, widget.initial)) return null;
    return Theme.of(context).extension<ValueHighlightColors>()?.changed ?? Colors.orange;
  }

  /// The saved parent, currently not picked: stays tappable, just marked.
  bool _isPrevious(Installation value) =>
      _highlighting && !_sameParent(value, _selected) && _sameParent(value, widget.initial);

  bool _matches(InstallationParentOption option) {
    if (_query.isEmpty) return true;
    final haystack = [
      option.label,
      option.typeLabel,
      option.subtitle,
    ].whereType<String>().join(' ').toLowerCase();
    return presetHaystackMatches(haystack, _query);
  }

  @override
  Widget build(BuildContext context) {
    // Searching also looks through the hidden options.
    final showOthers = _showAll || _query.isNotEmpty;
    final sections = _buildSections(showOthers: showOthers);
    final hiddenCount = showOthers ? 0 : widget.options.where((o) => !o.isSuggested).length;
    final showSearch = widget.options.length > _searchThreshold;
    final showDepthCapHint = widget.depthCapHint != null && _query.isEmpty;
    var selectedKeyUsed = false;

    Widget row(InstallationParentOption option) {
      final isSelected = !selectedKeyUsed && _sameParent(option.value, _selected);
      if (isSelected) selectedKeyUsed = true;
      return _ParentRow(
        key: isSelected ? _selectedKey : null,
        option: option,
        bikes: widget.bikes,
        selected: isSelected,
        highlightColor: _highlightColorFor(option.value),
        isPrevious: _isPrevious(option.value),
        onTap: () => _select(option.value),
      );
    }

    Widget section(_Section section) => StickySection(
          header: sheetSectionHeader(context, section.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: section.options.map(row).toList(),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Installed on'),
            if (showSearch) ...[
              const SizedBox(height: 12),
              _searchField(),
            ],
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                // ListTile paints its tile color on the nearest Material; without
                // one inside the scroll view, it leaks over the header and search field.
                child: Material(
                  type: MaterialType.transparency,
                  child: sections.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SheetFilterEmptyHint(
                          icon: Icons.search_off,
                          title: 'No matches for "$_query"',
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final s in sections) ...[
                            section(s),
                            if (s.isBikes && showDepthCapHint)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: SheetFilterEmptyHint(
                                  icon: Icons.account_tree_outlined,
                                  title: widget.depthCapHint!,
                                ),
                              ),
                          ],
                          if (hiddenCount > 0) _showAllRow(hiddenCount),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showAllRow(int hiddenCount) {
    final theme = Theme.of(context);
    final typeLabel = widget.componentTypeLabel;
    final parts = hiddenCount == 1 ? 'part' : 'parts';
    return Padding(
      // Lines the text up with the row titles.
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              typeLabel == null ? '$hiddenCount $parts hidden' : '$hiddenCount $parts hidden · unusual for a $typeLabel',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showAll = true),
            child: const Text('Show all'),
          ),
        ],
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

  /// Not installed · Bikes · Components on the current bike · Components on
  /// the other bikes (garage order) · Components on missing bikes ·
  /// Components with a missing parent · Uninstalled components · Archived
  /// components. Empty sections are left out. With [showOthers], unsuggested
  /// components join their section after the suggested ones, so expanding
  /// doesn't reshuffle the rows already shown.
  List<_Section> _buildSections({required bool showOthers}) {
    final notInstalled = <InstallationParentOption>[];
    final bikeOptions = <InstallationParentOption>[];
    // Keyed by bike id, or by a [_Root] for chains that don't end on a bike.
    final componentsByRoot = <Object, List<InstallationParentOption>>{};

    final options = [
      ...widget.options.where((o) => o.isSuggested),
      if (showOthers) ...widget.options.where((o) => !o.isSuggested),
    ];
    for (final option in options.where(_matches)) {
      switch (option.value) {
        case Uninstallation() || Archival():
          notInstalled.add(option);
        case BikeInstallation():
          bikeOptions.add(option);
        case ComponentInstallation() when option.isMissing:
          notInstalled.add(option);
        case ComponentInstallation():
          (componentsByRoot[_rootKey(option)] ??= []).add(option);
      }
    }

    final currentBikeId = widget.currentBikeId;
    final order = <Object>[
      ?currentBikeId,
      ...widget.bikes.keys.where((id) => id != currentBikeId),
      ...componentsByRoot.keys.whereType<String>().where((id) => id != currentBikeId && !widget.bikes.containsKey(id)),
      ..._Root.values,
    ];

    return [
      if (notInstalled.isNotEmpty) _Section('Not installed', notInstalled),
      if (bikeOptions.isNotEmpty) _Section('Bikes', bikeOptions, isBikes: true),
      for (final key in order)
        if (componentsByRoot[key] case final options?)
          _Section(
            switch (key) {
              _Root.brokenChain => 'Components with a missing parent',
              _Root.uninstalled => 'Uninstalled components',
              _Root.archived => 'Archived components',
              _ => 'Components on ${widget.bikes[key]?.name ?? 'BIKE NOT FOUND'}',
            },
            options,
          ),
    ];
  }

  static Object _rootKey(InstallationParentOption option) => switch (option.ancestors.lastOrNull) {
        BikeAncestor(:final bikeId) => bikeId,
        ArchivedAncestor() => _Root.archived,
        UninstalledAncestor() || null => _Root.uninstalled,
        // A chain ending on a component is cut short by a cycle.
        MissingParentAncestor() || ParentComponentAncestor() => _Root.brokenChain,
      };
}

enum _Root { brokenChain, uninstalled, archived }

class _Section {
  final String title;
  final List<InstallationParentOption> options;
  final bool isBikes;

  const _Section(this.title, this.options, {this.isBikes = false});
}

class _ParentRow extends StatelessWidget {
  final InstallationParentOption option;
  final Map<String, Bike> bikes;
  final bool selected;
  final Color? highlightColor;
  final bool isPrevious;
  final VoidCallback onTap;

  const _ParentRow({
    super.key,
    required this.option,
    required this.bikes,
    required this.selected,
    required this.highlightColor,
    required this.isPrevious,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsetsDirectional.only(start: 8, end: 16),
        leading: Icon(option.icon, color: option.color),
        title: Text(
          option.label,
          style: TextStyle(color: option.color, fontWeight: selected ? FontWeight.w600 : null),
        ),
        subtitle: option.ancestors.isEmpty ? null : ComponentAncestorsColumn(ancestors: option.ancestors, bikes: bikes),
        selected: selected,
        selectedColor: highlightColor == null ? scheme.onSecondaryContainer : scheme.onSurface,
        selectedTileColor: highlightColor?.withValues(alpha: 0.18) ?? scheme.secondaryContainer,
        trailing: selected
            ? Icon(Icons.check, color: highlightColor)
            : isPrevious
                ? Tooltip(
                    message: 'Previous value',
                    child: Icon(Icons.history, color: scheme.onSurfaceVariant),
                  )
                : null,
        onTap: onTap,
      ),
    );
  }
}
