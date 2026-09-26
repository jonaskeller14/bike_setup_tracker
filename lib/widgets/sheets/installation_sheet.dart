import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/component_ancestor.dart';
import '../../models/component/installation.dart';
import '../../models/component/resolved_installation.dart';
import '../../repositories/app_repository.dart';
import '../../utils/installation_timeline_validation.dart';
import '../component_ancestors_column.dart';
import '../dialogs/component_descendant_warning.dart';
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
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return InstallationSheet.edit(
        component: component,
        editEntry: editEntry,
      );
    },
  );
}

class InstallationSheet extends StatefulWidget {
  final Component component;
  final String? targetBikeId;
  final ResolvedInstallation? editEntry;
  final bool isArchiving;

  const InstallationSheet._({
    super.key,
    required this.component,
    this.targetBikeId,
    this.editEntry,
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
  }) => InstallationSheet._(key: key, component: component, editEntry: editEntry);

  @override
  State<InstallationSheet> createState() => _InstallationSheetState();
}

class _InstallationSheetState extends State<InstallationSheet> {
  late List<Installation> _installations;
  late Installation _editableInstallation;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Start with current installations
    _installations = List.from(widget.component.installations);
    
    if (widget.editEntry != null) {
      _editableInstallation = widget.editEntry!.installation;
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
    if (!widget.component.isArchived && updatedComponent.isArchived) {
      final confirmed = await confirmComponentDescendantImpact(
        context,
        component: widget.component,
        descendants: appRepository.affectedDescendants(widget.component.id),
        action: 'Archive',
      );
      if (!confirmed || !mounted) return;
    }
    await appRepository.editComponent(updatedComponent);
    if (!mounted) return;
    Navigator.pop(context);
  }

  bool get _hasChanges =>
      !listEquals(_installations, widget.component.installations);

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final theme = Theme.of(context);
    
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
    final eventUTC = _editableInstallation.dateTimeUTC;
    List<ComponentAncestor> ancestorsOf(String componentId) =>
        eventUTC.millisecondsSinceEpoch == 0
            ? appRepository.componentHierarchy.currentAncestors(componentId)
            : appRepository.componentHierarchy.ancestorsAt(componentId, eventUTC);

    final originPreview = _parentPreview(
      appRepository,
      originParentType ?? InstallationParentType.none,
      originParentId,
      ancestorsOf,
    );
    final targetPreview = _parentPreview(
      appRepository,
      targetParentType,
      targetParentId,
      ancestorsOf,
    );
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
                    // Origin -> Arrow -> Target Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
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
                            if (!isInitialInstallation)
                              Expanded(
                                child: _ParentPreview(
                                  icon: originPreview.icon,
                                  label: originPreview.label,
                                  isError: originPreview.isError,
                                  ancestors: originPreview.ancestors,
                                  bikes: appRepository.bikes,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                            ),
                            Expanded(
                              child: _ParentPreview(
                                icon: targetPreview.icon,
                                label: targetPreview.label,
                                isError: targetPreview.isError,
                                ancestors: targetPreview.ancestors,
                                bikes: appRepository.bikes,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SetInstallationTimeline(
                      componentId: widget.component.id,
                      initialInstallations: _installations,
                      originalInstallations: widget.component.installations,
                      onChanged: (newInstallations) {
                        setState(() {
                          final addedItems = newInstallations.where((n) => !_installations.contains(n)).toList();
                          if (addedItems.isNotEmpty) {
                            _editableInstallation = addedItems.first;
                          }
                          _installations = List.from(newInstallations);
                        });
                      },
                      isEntryEditable: (installation) => installation == _editableInstallation,
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

({IconData icon, String label, bool isError, List<ComponentAncestor> ancestors}) _parentPreview(
  AppRepository appRepository,
  InstallationParentType parentType,
  String? parentId,
  List<ComponentAncestor> Function(String componentId) ancestorsOf,
) => switch (parentType) {
      InstallationParentType.bike => (
        icon: Bike.iconData,
        label: appRepository.bikes[parentId]?.name ?? 'BIKE NOT FOUND',
        isError: !appRepository.bikes.containsKey(parentId),
        ancestors: const [],
      ),
      InstallationParentType.component => (
        icon: appRepository.components[parentId]?.componentType.getIconData() ?? Component.iconData,
        label: appRepository.components[parentId]?.name ?? 'COMPONENT NOT FOUND',
        isError: !appRepository.components.containsKey(parentId),
        ancestors: parentId == null ? const [] : ancestorsOf(parentId),
      ),
      InstallationParentType.none => (
        icon: Icons.shelves,
        label: 'Uninstalled',
        isError: false,
        ancestors: const [],
      ),
      InstallationParentType.archived => (
        icon: Icons.inventory_2_outlined,
        label: 'Archive',
        isError: false,
        ancestors: const [],
      ),
    };

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
