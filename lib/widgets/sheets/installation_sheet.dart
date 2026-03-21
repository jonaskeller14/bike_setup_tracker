import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/component.dart';
import '../../models/bike.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../set_installation_timeline.dart';
import 'sheet.dart';

Future<void> showInstallationSheet(BuildContext context, {
  required Component component, 
  required String? targetBikeId
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return InstallationSheet(
        component: component,
        targetBikeId: targetBikeId,
      );
    },
  );
}

class InstallationSheet extends StatefulWidget {
  final Component component;
  final String? targetBikeId;

  const InstallationSheet({
    super.key,
    required this.component,
    required this.targetBikeId,
  });

  @override
  State<InstallationSheet> createState() => _InstallationSheetState();
}

class _InstallationSheetState extends State<InstallationSheet> {
  late List<Installation> _installations;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Start with current installations + a new one for the target
    _installations = List.from(widget.component.installations);
    
    // Add the new installation entry
    final now = DateTime.now();
    _installations.add(Installation(
      parent: widget.targetBikeId,
      dateTimeUTC: now.toUtc(),
      dateTimeLocal: now,
    ));
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedComponent = widget.component.copyWith(
        installations: _installations,
      );
      context.read<AppRepository>().editComponent(updatedComponent);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final theme = Theme.of(context);
    
    final originBikeId = widget.component.bike;
    final originBikeName = originBikeId == null ? "Archive" : (bikes[originBikeId]?.name ?? "Unknown Bike");
    final targetBikeName = widget.targetBikeId == null ? "Archive" : (bikes[widget.targetBikeId]?.name ?? "Unknown Bike");

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
                  sheetTitle(context, widget.component.name),
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
                          Expanded(
                            child: _BikePreview(
                              name: originBikeName,
                              isDeinstalled: originBikeId == null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                          ),
                          Expanded(
                            child: _BikePreview(
                              name: targetBikeName,
                              isDeinstalled: widget.targetBikeId == null,
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
                          _installations = newInstallations;
                        });
                      },
                      isEntryEditable: (index) => index == _installations.length - 1,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: FilledButton(
                onPressed: _onConfirm,
                child: const Text('Confirm'),
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

  const _BikePreview({
    required this.name,
    required this.isDeinstalled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDeinstalled ? Icons.shelves : Bike.iconData,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
