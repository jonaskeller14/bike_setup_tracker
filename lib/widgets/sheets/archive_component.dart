import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/subcomponent_detach.dart';
import '../../repositories/app_repository.dart';
import '../component_tree_preview.dart';
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
                  const SizedBox(height: 8),
                  RadioGroup<bool>(
                    groupValue: _withSubcomponents,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _withSubcomponents = value);
                    },
                    child: Column(
                      children: [
                        const RadioListTile<bool>(
                          value: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text("Archive with subcomponents"),
                          subtitle: Text("They stay mounted and are archived along with it."),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          contentPadding: EdgeInsets.zero,
                          title: Text("Archive only '$name'", overflow: TextOverflow.ellipsis),
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
