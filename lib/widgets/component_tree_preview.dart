import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/component/component.dart';

/// What an action does to one component, shown as a badge next to its row.
class ComponentOutcome {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const ComponentOutcome({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });
}

/// A component with everything mounted on it, drawn as an indented tree.
class ComponentTreePreview extends StatelessWidget {
  final Component root;
  final Map<String, Component> components;
  final Set<String> Function(String parentId) childrenOf;

  /// Depth 0 is [root], 1 its direct children, and so on.
  final ComponentOutcome? Function(int depth) outcomeForDepth;

  const ComponentTreePreview({
    super.key,
    required this.root,
    required this.components,
    required this.childrenOf,
    required this.outcomeForDepth,
  });

  static const _maxIndentDepth = 4;

  List<(Component, int)> _flatten() {
    final rows = <(Component, int)>[];
    final visited = <String>{};
    void visit(Component component, int depth) {
      if (!visited.add(component.id)) return;
      rows.add((component, depth));
      final children = childrenOf(component.id).map((id) => components[id]).whereType<Component>().toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      for (final child in children) {
        visit(child, depth + 1);
      }
    }

    visit(root, 0);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rows = _flatten();
    final subcomponentCount = rows.length - 1;

    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(Icons.account_tree_outlined, size: 20, color: cs.onSurfaceVariant),
                Expanded(
                  child: Text(
                    Intl.plural(
                      subcomponentCount,
                      one: "1 subcomponent",
                      other: "$subcomponentCount subcomponents",
                    ),
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            for (final (component, depth) in rows)
              _TreeRow(
                component: component,
                depth: depth,
                outcome: outcomeForDepth(depth),
              ),
          ],
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  final Component component;
  final int depth;
  final ComponentOutcome? outcome;

  const _TreeRow({
    required this.component,
    required this.depth,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      // Deep trees stop indenting so names keep room on narrow screens.
      padding: EdgeInsets.only(left: (depth.clamp(1, ComponentTreePreview._maxIndentDepth) - 1) * 20.0),
      child: Row(
        spacing: 6,
        children: [
          if (depth > 0) Icon(Icons.subdirectory_arrow_right, size: 16, color: cs.outline),
          Icon(component.componentType.getIconData(), size: 20),
          Expanded(
            child: Text(
              component.name,
              overflow: TextOverflow.ellipsis,
              style: depth == 0 ? const TextStyle(fontWeight: FontWeight.bold) : null,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: outcome == null
                ? const SizedBox.shrink()
                : _OutcomeBadge(key: ValueKey(outcome!.label), outcome: outcome!),
          ),
        ],
      ),
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  final ComponentOutcome outcome;

  const _OutcomeBadge({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final background = outcome.isDestructive ? cs.errorContainer : cs.surfaceContainerHighest;
    final foreground = outcome.isDestructive ? cs.onErrorContainer : cs.onSurfaceVariant;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(outcome.icon, size: 14, color: foreground),
            Flexible(
              child: Text(
                outcome.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
