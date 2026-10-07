import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/component_ancestor.dart';
import '../../models/component/installation.dart';
import '../../models/component/resolved_installation.dart';
import '../../repositories/app_repository.dart';
import '../../utils/component_actions.dart';
import '../../utils/installation_timeline_validation.dart';
import '../component_ancestors_column.dart';
import '../set_installation_timeline.dart';
import 'sheet_header.dart';

Future<void> showAddInstallationSheet(BuildContext context, {
  required Component component,
  required String? targetBikeId,
  bool isArchiving = false,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return InstallationSheet.add(
        component: component,
        targetBikeId: targetBikeId,
        isArchiving: isArchiving,
      );
    },
  );
}

Future<void> showEditInstallationSheet(BuildContext context, {
  required Component component, 
  required ResolvedInstallation editEntry,
  Installation? editEnd,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return InstallationSheet.edit(
        component: component,
        editEntry: editEntry,
        editEnd: editEnd,
      );
    },
  );
}

class InstallationSheet extends StatefulWidget {
  final Component component;
  final String? targetBikeId;
  final ResolvedInstallation? editEntry;
  final Installation? editEnd;
  final bool isArchiving;

  const InstallationSheet._({
    super.key,
    required this.component,
    this.targetBikeId,
    this.editEntry,
    this.editEnd,
    this.isArchiving = false,
  });

  factory InstallationSheet.add({
    Key? key,
    required Component component,
    required String? targetBikeId,
    bool isArchiving = false,
  }) => InstallationSheet._(key: key, component: component, targetBikeId: targetBikeId, isArchiving: isArchiving);

  factory InstallationSheet.edit({
    Key? key,
    required Component component,
    required ResolvedInstallation editEntry,
    Installation? editEnd,
  }) => InstallationSheet._(key: key, component: component, editEntry: editEntry, editEnd: editEnd);

  @override
  State<InstallationSheet> createState() => _InstallationSheetState();
}

class _InstallationSheetState extends State<InstallationSheet> {
  late List<Installation> _installations;
  late Installation _editableInstallation;
  Installation? _editableEnd;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Start with current installations
    _installations = List.from(widget.component.installations);
    
    if (widget.editEntry != null) {
      _editableInstallation = widget.editEntry!.installation;
      _editableEnd = widget.editEnd;
    } else {
      final at = stampInstallationNow(_installations);
      _editableInstallation = widget.isArchiving
          ? Archival(dateTimeUTC: at.utc, dateTimeLocal: at.local)
          : Installation(parent: widget.targetBikeId, dateTimeUTC: at.utc, dateTimeLocal: at.local);
      _installations.add(_editableInstallation);
    }
  }

  void _onConfirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updatedComponent = widget.component.copyWith(
      installations: _installations,
    );
    final appRepository = context.read<AppRepository>();
    var subcomponentEdits = const <Component>[];
    if (!widget.component.isArchived && updatedComponent.isArchived) {
      final edits = await ComponentActions.archiveSubcomponentEdits(
        context,
        component: widget.component,
        atUTC: _editableInstallation.dateTimeUTC,
      );
      if (edits == null || !mounted) return;
      subcomponentEdits = edits;
    }
    if (!mounted) return;
    // Closes before saving, so the write does not hold the sheet open.
    Navigator.pop(context);
    await appRepository.editComponents([updatedComponent, ...subcomponentEdits]);
  }

  bool get _hasChanges =>
      !listEquals(_installations, widget.component.installations);

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    // Origin is the state before this event. In edit mode that is the entry's
    // recorded origin; in add mode it is the component's latest installation.
    final originInstallation = widget.editEntry == null
        ? widget.component.latestInstallation
        : null;
    final originParentType = widget.editEntry != null
        ? widget.editEntry!.originParentType
        : originInstallation?.parentType;
    final originParentId = widget.editEntry != null
        ? widget.editEntry!.originParent
        : originInstallation?.parent;

    // Target is derived from the actual installation subtype being edited, so
    // Uninstallation vs Archival are never confused.
    final targetParentType = _editableInstallation.parentType;
    final targetParentId = _editableInstallation.parent;

    // "From beginning" (epoch 0) predates every installation, so show the current chain.
    List<ComponentAncestor> Function(String componentId) ancestorsAt(DateTime eventUTC) =>
        (componentId) => eventUTC.millisecondsSinceEpoch == 0
            ? appRepository.componentHierarchy.currentAncestors(componentId)
            : appRepository.componentHierarchy.ancestorsAt(componentId, eventUTC);
    final ancestorsOf = ancestorsAt(_editableInstallation.dateTimeUTC);

    final isInitialInstallation = widget.editEntry != null
        ? widget.editEntry!.isInitial
        : widget.component.installations.isEmpty;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: widget.component.name,
              leadingIcon: Icon(widget.component.componentType.getIconData()),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _InstallationTransitionPreview(
                        origin: isInitialInstallation
                            ? null
                            : _parentPreview(
                                appRepository,
                                originParentType ?? InstallationParentType.none,
                                originParentId,
                                ancestorsOf,
                              ),
                        target: _parentPreview(appRepository, targetParentType, targetParentId, ancestorsOf),
                        end: _editableEnd == null
                            ? null
                            : _parentPreview(
                                appRepository,
                                _editableEnd!.parentType,
                                _editableEnd!.parent,
                                ancestorsAt(_editableEnd!.dateTimeUTC),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SetInstallationTimeline(
                      componentId: widget.component.id,
                      componentType: widget.component.componentType,
                      initialInstallations: _installations,
                      originalInstallations: widget.component.installations,
                      onChanged: (newInstallations) {
                        setState(() {
                          // Edits keep an entry's id, so ids track the editable entries.
                          _editableInstallation =
                              newInstallations.firstWhereOrNull((n) => n.id == _editableInstallation.id) ??
                                  _editableInstallation;
                          if (_editableEnd != null) {
                            _editableEnd =
                                newInstallations.firstWhereOrNull((n) => n.id == _editableEnd!.id) ?? _editableEnd;
                          }
                          _installations = List.from(newInstallations);
                        });
                      },
                      isEntryEditable: (installation) =>
                          installation.id == _editableInstallation.id || installation.id == _editableEnd?.id,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: FilledButton(
                onPressed: _hasChanges ? _onConfirm : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_ParentPreview _parentPreview(
  AppRepository appRepository,
  InstallationParentType parentType,
  String? parentId,
  List<ComponentAncestor> Function(String componentId) ancestorsOf,
) => switch (parentType) {
      InstallationParentType.bike => _ParentPreview(
        icon: Bike.iconData,
        label: appRepository.bikes[parentId]?.name ?? 'BIKE NOT FOUND',
        isError: !appRepository.bikes.containsKey(parentId),
      ),
      InstallationParentType.component => _ParentPreview(
        icon: appRepository.components[parentId]?.componentType.getIconData() ?? Component.iconData,
        label: appRepository.components[parentId]?.name ?? 'COMPONENT NOT FOUND',
        isError: !appRepository.components.containsKey(parentId),
        ancestors: parentId == null ? const [] : ancestorsOf(parentId),
        bikes: appRepository.bikes,
      ),
      InstallationParentType.none => const _ParentPreview(
        icon: Icons.shelves,
        label: 'Uninstalled',
      ),
      InstallationParentType.archived => const _ParentPreview(
        icon: Icons.inventory_2_outlined,
        label: 'Archive',
      ),
    };

/// Origin -> target (-> end) card at the top of the sheet.
class _InstallationTransitionPreview extends StatelessWidget {
  final _ParentPreview? origin;
  final _ParentPreview target;
  final _ParentPreview? end;

  const _InstallationTransitionPreview({
    this.origin,
    required this.target,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // Top-aligned so both icons and the arrow stay level when only one side has an ancestor tree.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (origin != null) Expanded(child: origin!),
          arrow,
          Expanded(child: target),
          if (end != null) ...[arrow, Expanded(child: end!)],
        ],
      ),
    );
  }
}

class _ParentPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isError;
  final List<ComponentAncestor> ancestors;
  final Map<String, Bike> bikes;

  const _ParentPreview({
    required this.icon,
    required this.label,
    this.isError = false,
    this.ancestors = const [],
    this.bikes = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (ancestors.isNotEmpty) ...[
          const SizedBox(height: 2),
          // Shrink-wraps the left-aligned rows so the tree stays centered under the label.
          IntrinsicWidth(
            child: ComponentAncestorsColumn(
              ancestors: ancestors,
              bikes: bikes,
              iconSize: 13,
              spacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
