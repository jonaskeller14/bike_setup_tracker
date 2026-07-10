import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../set_installation_timeline.dart';
import 'sheet_header.dart';

Future<void> showAddInstallationSheet(BuildContext context, {
  required Component component,
  required String? targetBikeId,
  bool isArchiving = false,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
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
  required ComponentInstallation editEntry,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
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
  final ComponentInstallation? editEntry;
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
    required ComponentInstallation editEntry,
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
      final now = DateTime.now();
      _editableInstallation = widget.isArchiving
          ? Archival(dateTimeUTC: now.toUtc(), dateTimeLocal: now)
          : Installation(parent: widget.targetBikeId, dateTimeUTC: now.toUtc(), dateTimeLocal: now);
      _installations.add(_editableInstallation);
    }
  }

  void _onConfirm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedComponent = widget.component.copyWith(
        installations: _installations,
      );
      await context.read<AppRepository>().editComponent(updatedComponent);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  bool get _hasChanges {
    if (_installations.length != widget.component.installations.length) return true;
    for (int i = 0; i < _installations.length; i++) {
      if (_installations[i] != widget.component.installations[i]) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final theme = Theme.of(context);
    
    // Origin is the state before this event. In edit mode that is the entry's
    // recorded origin; in add mode it is the component's latest installation.
    final originInstallation = widget.editEntry == null
        ? widget.component.latestInstallation
        : null;
    final originParentType = widget.editEntry != null
        ? widget.editEntry!.originParentType
        : originInstallation?.parentType;
    final originBikeId = widget.editEntry != null
        ? widget.editEntry!.originParent
        : originInstallation?.parent;

    // Target is derived from the actual installation subtype being edited, so
    // Uninstallation vs Archival are never confused.
    final targetParentType = _editableInstallation.parentType;
    final targetBikeId = _editableInstallation.parent;

    final originBikeNotFound = originBikeId != null && bikes[originBikeId] == null;
    final targetBikeNotFound = targetBikeId != null && bikes[targetBikeId] == null;
    final originBikeName = bikes[originBikeId]?.name ?? "BIKE NOT FOUND";
    final targetBikeName = bikes[targetBikeId]?.name ?? "BIKE NOT FOUND";
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
                          children: [
                            if (!isInitialInstallation)
                              Expanded(
                                child: _BikePreview(
                                  parentType: originParentType ?? InstallationParentType.none,
                                  bikeName: originBikeName,
                                  isError: originBikeNotFound,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                            ),
                            Expanded(
                              child: _BikePreview(
                                parentType: targetParentType,
                                bikeName: targetBikeName,
                                isError: targetBikeNotFound,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SetInstallationTimeline(
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

class _BikePreview extends StatelessWidget {
  final InstallationParentType parentType;
  final String bikeName;
  final bool isError;

  const _BikePreview({
    required this.parentType,
    required this.bikeName,
    this.isError = false,
  });

  IconData get _icon => switch (parentType) {
        InstallationParentType.bike => Bike.iconData,
        InstallationParentType.none => Icons.shelves,
        InstallationParentType.archived => Icons.inventory_2_outlined,
      };

  String get _label => switch (parentType) {
        InstallationParentType.bike => bikeName,
        InstallationParentType.none => 'Uninstalled',
        InstallationParentType.archived => 'Archive',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _icon,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          _label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
