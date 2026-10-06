import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/subcomponent_detach.dart';
import '../../repositories/app_repository.dart';
import '../component_tree_preview.dart';
import 'sheet_header.dart';

typedef RemoveComponentChoice = ({bool withSubcomponents, SubcomponentDetach detach});

/// Asks how to remove a component that has subcomponents mounted on it.
/// Returns null when dismissed.
Future<RemoveComponentChoice?> showRemoveComponentSheet(
  BuildContext context, {
  required Component component,
}) {
  return showModalBottomSheet<RemoveComponentChoice>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _RemoveComponentSheet(component: component),
  );
}

class _RemoveComponentSheet extends StatefulWidget {
  final Component component;

  const _RemoveComponentSheet({required this.component});

  @override
  State<_RemoveComponentSheet> createState() => _RemoveComponentSheetState();
}

class _RemoveComponentSheetState extends State<_RemoveComponentSheet> {
  bool _withSubcomponents = false;
  SubcomponentDetach _detach = SubcomponentDetach.uninstall;

  ComponentOutcome? _outcomeFor({required int depth, required SubcomponentDetach detach, required Bike? bike}) {
    const trash = ComponentOutcome(icon: Icons.delete_outline, label: 'Trash', isDestructive: true);
    if (depth == 0 || _withSubcomponents) return trash;
    // Deeper levels stay on their own parent and follow it.
    if (depth > 1) return null;
    return switch (detach) {
      SubcomponentDetach.uninstall => const ComponentOutcome(icon: Icons.shelves, label: 'Uninstalled'),
      SubcomponentDetach.installOnBike => ComponentOutcome(icon: Bike.iconData, label: bike?.name ?? ''),
      SubcomponentDetach.keepLinked => const ComponentOutcome(icon: Icons.link, label: 'Linked'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final hierarchy = appRepository.componentHierarchy;
    final name = widget.component.name;
    final bike = appRepository.bikes[hierarchy.currentBike(widget.component.id)];
    final subcomponentCount = hierarchy.descendantsOf(widget.component.id).length;
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    // The bike option disappears when the component leaves its bike while the sheet is open.
    final detach = bike == null && _detach == SubcomponentDetach.installOnBike ? SubcomponentDetach.uninstall : _detach;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: "Remove '$name'"),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Other components are mounted on '$name'. Choose what happens to them.",
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ComponentTreePreview(
                    root: widget.component,
                    components: appRepository.components,
                    childrenOf: hierarchy.childrenOf,
                    outcomeForDepth: (depth) => _outcomeFor(depth: depth, detach: detach, bike: bike),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<bool>(
                    groupValue: _withSubcomponents,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _withSubcomponents = value);
                    },
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Remove with subcomponents"),
                          subtitle: Text("All ${subcomponentCount + 1} components are moved to the trash."),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          contentPadding: EdgeInsets.zero,
                          title: Text("Remove only '$name'", overflow: TextOverflow.ellipsis),
                          subtitle: const Text("Subcomponents stay in your garage."),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.topCenter,
                          child: _withSubcomponents
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: RadioGroup<SubcomponentDetach>(
                                    groupValue: detach,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _detach = value);
                                    },
                                    child: Column(
                                      children: [
                                        const RadioListTile<SubcomponentDetach>(
                                          value: SubcomponentDetach.uninstall,
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          title: Text("Uninstall"),
                                          subtitle: Text("Shown under Uninstalled components."),
                                        ),
                                        if (bike != null)
                                          RadioListTile<SubcomponentDetach>(
                                            value: SubcomponentDetach.installOnBike,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            title: Text("Install on '${bike.name}'", overflow: TextOverflow.ellipsis),
                                            subtitle: const Text("Installed directly on the bike."),
                                          ),
                                        RadioListTile<SubcomponentDetach>(
                                          value: SubcomponentDetach.keepLinked,
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          title: const Text("Keep linked"),
                                          subtitle: Text(
                                            "Stay mounted on '$name' and return with it when restored from the trash. "
                                            "Until then they are shown under Uninstalled components with a missing parent.",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => Navigator.pop(context, (withSubcomponents: _withSubcomponents, detach: detach)),
              label: Text(
                _withSubcomponents ? 'Move ${subcomponentCount + 1} components to trash' : 'Move to trash',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
