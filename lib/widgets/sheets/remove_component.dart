import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/subcomponent_detach.dart';
import '../../repositories/app_repository.dart';
import '../component_tree_preview.dart';
import 'radio_option_card.dart';
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
  bool _withSubcomponents = true;
  SubcomponentDetach _detach = SubcomponentDetach.uninstall;

  ComponentOutcome? _outcomeFor({required int depth, required SubcomponentDetach detach, required Bike? bike}) {
    const trash = ComponentOutcome(icon: Icons.delete_outline, label: 'Trash', isDestructive: true);
    if (depth == 0 || _withSubcomponents) return trash;
    // Deeper levels stay on their own parent and follow it.
    if (depth > 1) return null;
    return switch (detach) {
      SubcomponentDetach.uninstall => const ComponentOutcome(icon: Icons.shelves, label: 'Uninstalled'),
      SubcomponentDetach.installOnBike => ComponentOutcome(icon: Bike.iconData, label: bike?.name ?? ''),
      SubcomponentDetach.keepLinked => const ComponentOutcome(
        icon: Icons.error_outline,
        label: 'Missing parent',
        isDestructive: true,
      ),
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
                  const SizedBox(height: 16),
                  Column(
                    spacing: 8,
                    children: [
                      RadioOptionCard(
                        selected: _withSubcomponents,
                        onTap: () => setState(() => _withSubcomponents = true),
                        title: "Remove with subcomponents",
                        subtitle: "All ${subcomponentCount + 1} components are moved to the trash.",
                      ),
                      RadioOptionCard(
                        selected: !_withSubcomponents,
                        onTap: () => setState(() => _withSubcomponents = false),
                        title: "Remove only '$name'",
                        subtitle: "Subcomponents are kept. Choose what happens to them below.",
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: _withSubcomponents
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  spacing: 8,
                                  children: [
                                    RadioOptionCard(
                                      compact: true,
                                      selected: detach == SubcomponentDetach.uninstall,
                                      onTap: () => setState(() => _detach = SubcomponentDetach.uninstall),
                                      title: "Uninstall subcomponents",
                                      subtitle: "They move to your uninstalled components.",
                                    ),
                                    if (bike != null)
                                      RadioOptionCard(
                                        compact: true,
                                        selected: detach == SubcomponentDetach.installOnBike,
                                        onTap: () => setState(() => _detach = SubcomponentDetach.installOnBike),
                                        title: "Install subcomponents on '${bike.name}'",
                                        subtitle: "They are installed directly on the bike.",
                                      ),
                                    RadioOptionCard(
                                      compact: true,
                                      selected: detach == SubcomponentDetach.keepLinked,
                                      onTap: () => setState(() => _detach = SubcomponentDetach.keepLinked),
                                      title: "Keep subcomponents linked",
                                      subtitle:
                                          "They stay mounted on '$name' and return with it when restored from the trash. "
                                          "Until then they are shown under uninstalled components with a missing parent.",
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
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
