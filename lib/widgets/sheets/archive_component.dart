import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/subcomponent_detach.dart';
import '../../repositories/app_repository.dart';
import '../component_tree_preview.dart';
import 'radio_option_card.dart';
import 'sheet_header.dart';

typedef ArchiveComponentChoice = ({bool withSubcomponents, SubcomponentDetach detach});

/// Asks how to archive a component that has subcomponents mounted on it at
/// [atUTC]. Returns null when dismissed.
Future<ArchiveComponentChoice?> showArchiveComponentSheet(
  BuildContext context, {
  required Component component,
  required DateTime atUTC,
}) {
  return showModalBottomSheet<ArchiveComponentChoice>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _ArchiveComponentSheet(component: component, atUTC: atUTC),
  );
}

class _ArchiveComponentSheet extends StatefulWidget {
  final Component component;
  final DateTime atUTC;

  const _ArchiveComponentSheet({required this.component, required this.atUTC});

  @override
  State<_ArchiveComponentSheet> createState() => _ArchiveComponentSheetState();
}

class _ArchiveComponentSheetState extends State<_ArchiveComponentSheet> {
  bool _withSubcomponents = true;
  SubcomponentDetach _detach = SubcomponentDetach.uninstall;

  ComponentOutcome? _outcomeFor({required int depth, required SubcomponentDetach detach, required Bike? bike}) {
    const archived = ComponentOutcome(icon: Icons.inventory_2_outlined, label: 'Archived');
    if (depth == 0 || _withSubcomponents) return archived;
    // Deeper levels stay on their own parent and follow it.
    if (depth > 1) return null;
    return switch (detach) {
      SubcomponentDetach.installOnBike => ComponentOutcome(icon: Bike.iconData, label: bike?.name ?? ''),
      SubcomponentDetach.uninstall ||
      SubcomponentDetach.keepLinked => const ComponentOutcome(icon: Icons.shelves, label: 'Uninstalled'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final hierarchy = appRepository.componentHierarchy;
    final name = widget.component.name;
    final bike = appRepository.bikes[hierarchy.bikeAt(widget.component.id, widget.atUTC)];
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final detach = bike == null ? SubcomponentDetach.uninstall : _detach;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: "Archive '$name'"),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Other components are mounted on '$name'. Choose whether they are archived along with it.",
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ComponentTreePreview(
                    root: widget.component,
                    components: appRepository.components,
                    childrenOf: (id) => hierarchy.childrenOf(id, atUTC: widget.atUTC),
                    outcomeForDepth: (depth) => _outcomeFor(depth: depth, detach: detach, bike: bike),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    spacing: 8,
                    children: [
                      RadioOptionCard(
                        selected: _withSubcomponents,
                        onTap: () => setState(() => _withSubcomponents = true),
                        title: "Archive with subcomponents",
                        subtitle: "They stay mounted and are archived along with it.",
                      ),
                      RadioOptionCard(
                        selected: !_withSubcomponents,
                        onTap: () => setState(() => _withSubcomponents = false),
                        title: "Archive only '$name'",
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
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => Navigator.pop(context, (withSubcomponents: _withSubcomponents, detach: detach)),
              label: const Text('Archive'),
            ),
          ),
        ],
      ),
    );
  }
}
