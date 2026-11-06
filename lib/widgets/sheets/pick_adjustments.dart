import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/component/component_ancestor.dart';
import '../component_ancestor_display.dart';
import '../empty_state_placeholder.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// The adjustments of one owner (e.g. a component). [ancestors] is what it is
/// installed on, from its parent upwards, and places it in the sheet's hierarchy.
class PickAdjustmentsGroup {
  final String id;
  final String title;
  final IconData icon;
  final List<ComponentAncestor> ancestors;
  final List<Adjustment> adjustments;

  const PickAdjustmentsGroup({
    required this.id,
    required this.title,
    required this.icon,
    this.ancestors = const [],
    required this.adjustments,
  });
}

/// Lets the user pick adjustments across [groups], in the order they tap them.
/// [onChanged] gets the whole selection after every tap so the caller can follow
/// along; closing the sheet keeps it. [warningFor] returns a message to show for
/// the current selection count. Without [groups], [onEmptyAction] offers a way
/// out of the empty sheet, which closes first.
Future<void> showPickAdjustmentsSheet(
  BuildContext context, {
  required String title,
  required List<PickAdjustmentsGroup> groups,
  required List<String> selectedIds,
  required ValueChanged<List<String>> onChanged,
  String? Function(int selectedCount)? warningFor,
  String? emptyTitle,
  String? emptyHint,
  String? emptyActionLabel,
  VoidCallback? onEmptyAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _PickAdjustmentsSheet(
      title: title,
      groups: groups,
      selectedIds: selectedIds,
      onChanged: onChanged,
      warningFor: warningFor,
      emptyTitle: emptyTitle ?? context.l10n.pickAdjustmentsEmptyTitle,
      emptyHint: emptyHint,
      emptyActionLabel: emptyActionLabel,
      onEmptyAction: onEmptyAction,
    ),
  );
}

class _Node {
  final String name;
  final IconData icon;
  final List<Adjustment> adjustments = [];
  final List<_Node> children = [];

  _Node(this.name, this.icon);
}

/// A parent without adjustments of its own still gets a node, so the path down
/// to its children stays visible.
List<_Node> _buildTree(List<PickAdjustmentsGroup> groups) {
  final nodes = <String, _Node>{};
  final roots = <_Node>[];

  _Node nodeFor(String id, String name, IconData icon, _Node? parent) {
    final existing = nodes[id];
    if (existing != null) return existing;
    final node = nodes[id] = _Node(name, icon);
    (parent?.children ?? roots).add(node);
    return node;
  }

  for (final group in groups) {
    _Node? parent;
    final path = group.ancestors.whereType<ParentComponentAncestor>().toList().reversed;
    for (final ancestor in path) {
      parent = nodeFor(ancestor.component.id, ancestor.component.name, ancestor.iconData, parent);
    }
    nodeFor(group.id, group.title, group.icon, parent).adjustments.addAll(group.adjustments);
  }
  return roots;
}

/// [node] and everything below it with its depth, parents before their children.
Iterable<(int, _Node)> _flatten(_Node node, [int depth = 0]) sync* {
  yield (depth, node);
  for (final child in node.children) {
    yield* _flatten(child, depth + 1);
  }
}

class _PickAdjustmentsSheet extends StatefulWidget {
  final String title;
  final List<PickAdjustmentsGroup> groups;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String? Function(int selectedCount)? warningFor;
  final String emptyTitle;
  final String? emptyHint;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  const _PickAdjustmentsSheet({
    required this.title,
    required this.groups,
    required this.selectedIds,
    required this.onChanged,
    required this.warningFor,
    required this.emptyTitle,
    required this.emptyHint,
    required this.emptyActionLabel,
    required this.onEmptyAction,
  });

  @override
  State<_PickAdjustmentsSheet> createState() => _PickAdjustmentsSheetState();
}

class _PickAdjustmentsSheetState extends State<_PickAdjustmentsSheet> {
  /// Apart from the gap inside a component, so its sub-components read as one block.
  static const double _componentGap = 20;
  static const double _subComponentGap = 12;

  late final List<String> _selected = List.of(widget.selectedIds);
  late final List<_Node> _tree = _buildTree(widget.groups);

  void _toggle(String id) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
    widget.onChanged(List.of(_selected));
  }

  void _emptyAction() {
    Navigator.pop(context);
    widget.onEmptyAction!();
  }

  Widget _component(int depth, _Node node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        _ComponentHeader(node: node, depth: depth),
        if (node.adjustments.isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.only(start: depth * _ComponentHeader.indent),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final adjustment in node.adjustments)
                  _AdjustmentTile(
                    adjustment: adjustment,
                    selected: _selected.contains(adjustment.id),
                    order: _selected.indexOf(adjustment.id) + 1,
                    onTap: () => _toggle(adjustment.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final warning = widget.warningFor?.call(_selected.length);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: _selected.isEmpty ? widget.title : '${widget.title} (${_selected.length})',
              titleMaxLines: 2,
            ),
            if (warning != null) SheetWarning(message: warning),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _tree.isEmpty
                    ? EmptyStatePlaceholder(
                        icon: Icons.tune,
                        title: widget.emptyTitle,
                        subtitle: widget.emptyHint,
                        actionLabel: widget.emptyActionLabel,
                        onAction: widget.onEmptyAction == null ? null : _emptyAction,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: _componentGap,
                        children: [
                          for (final root in _tree)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: _subComponentGap,
                              children: [for (final (depth, node) in _flatten(root)) _component(depth, node)],
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A top-level component, or a sub-component marked with the arrow. Each level
/// moves the icon one [indent] to the right.
class _ComponentHeader extends StatelessWidget {
  static const double indent = 18;
  static const double _arrowSize = 14;

  final _Node node;
  final int depth;

  const _ComponentHeader({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: isRoot ? 0 : (depth - 1) * indent),
      child: Row(
        children: [
          if (!isRoot) ...[
            Icon(Icons.subdirectory_arrow_right, size: _arrowSize, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: indent - _arrowSize),
          ],
          Icon(node.icon, size: isRoot ? 20 : 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              node.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isRoot ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// As wide as its name. A picked tile shows its [order], the place in the test
/// order the form numbers the adjustments by.
class _AdjustmentTile extends StatelessWidget {
  final Adjustment adjustment;
  final bool selected;
  final int order;
  final VoidCallback onTap;

  const _AdjustmentTile({required this.adjustment, required this.selected, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? scheme.secondaryContainer : scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(adjustment.getIconData(), size: 16, color: foreground),
                  Flexible(
                    child: Text(
                      adjustment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
                    ),
                  ),
                  if (selected)
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: Text('$order', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimary)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
