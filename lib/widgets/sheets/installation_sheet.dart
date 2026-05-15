import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../set_installation_timeline.dart';
import 'sheet.dart';

Future<void> showAddInstallationSheet(BuildContext context, {
  required Component component, 
  required String? targetBikeId
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

  const InstallationSheet._({
    super.key,
    required this.component,
    this.targetBikeId,
    this.editEntry,
  });

  factory InstallationSheet.add({
    Key? key,
    required Component component,
    required String? targetBikeId,
  }) => InstallationSheet._(key: key, component: component, targetBikeId: targetBikeId);

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
      // Add the new installation entry
      final now = DateTime.now();
      _editableInstallation = Installation(
        parent: widget.targetBikeId,
        dateTimeUTC: now.toUtc(),
        dateTimeLocal: now,
      );
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
    
    final originBikeId = widget.editEntry != null 
        ? widget.editEntry!.originParent 
        : widget.component.bike;
        
    final targetBikeId = widget.editEntry != null
        ? widget.editEntry!.installation.parent
        : widget.targetBikeId;
        
    final originBikeNotFound = originBikeId != null && bikes[originBikeId] == null;
    final targetBikeNotFound = targetBikeId != null && bikes[targetBikeId] == null;
    final originBikeName = originBikeId == null ? "Archive" : (bikes[originBikeId]?.name ?? "BIKE NOT FOUND");
    final targetBikeName = targetBikeId == null ? "Archive" : (bikes[targetBikeId]?.name ?? "BIKE NOT FOUND");
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    spacing: 6,
                    children: [
                      Icon(widget.component.componentType.getIconData()),
                      sheetTitle(context, widget.component.name),
                    ],
                  ),
                  sheetCloseButton(context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Origin -> Arrow -> Target Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isInitialInstallation)
                            Expanded(
                              child: _BikePreview(
                                name: originBikeName,
                                isDeinstalled: originBikeId == null,
                                isError: originBikeNotFound,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                          ),
                          Expanded(
                            child: _BikePreview(
                              name: targetBikeName,
                              isDeinstalled: targetBikeId == null,
                              isError: targetBikeNotFound,
                            ),
                          ),
                        ],
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
  final String name;
  final bool isDeinstalled;
  final bool isError;

  const _BikePreview({
    required this.name,
    required this.isDeinstalled,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDeinstalled ? Icons.shelves : Bike.iconData,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          name,
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
