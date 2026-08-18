import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/component_installation.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../../theme.dart';
import '../../utils/timeline_grouping.dart';
import '../set_installation_timeline.dart';
import 'sheet_header.dart';

Future<void> showReplacementSheet(
  BuildContext context, {
  required ComponentInstallation removed,
  required ComponentInstallation installed,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return ReplacementSheet(removed: removed, installed: installed);
    },
  );
}

class ReplacementSheet extends StatefulWidget {
  final ComponentInstallation removed;
  final ComponentInstallation installed;

  const ReplacementSheet({
    super.key,
    required this.removed,
    required this.installed,
  });

  @override
  State<ReplacementSheet> createState() => _ReplacementSheetState();
}

class _ReplacementSheetState extends State<ReplacementSheet> {
  late List<Installation> _removedInstallations;
  late List<Installation> _installedInstallations;
  late Installation _editableRemoved;
  late Installation _editableInstalled;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _removedInstallations = List.from(widget.removed.component.installations);
    _installedInstallations = List.from(
      widget.installed.component.installations,
    );
    _editableRemoved = widget.removed.installation;
    _editableInstalled = widget.installed.installation;
  }

  bool get _hasChanges =>
      !listEquals(_removedInstallations, widget.removed.component.installations) ||
      !listEquals(_installedInstallations, widget.installed.component.installations);

  void _onConfirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final appRepository = context.read<AppRepository>();
    if (!listEquals(_removedInstallations, widget.removed.component.installations)) {
      await appRepository.editComponent(
        widget.removed.component.copyWith(
          installations: _removedInstallations,
        ),
      );
    }
    if (!listEquals(_installedInstallations, widget.installed.component.installations)) {
      await appRepository.editComponent(
        widget.installed.component.copyWith(
          installations: _installedInstallations,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Mirrors InstallationSheet's editable-entry tracking: an edited entry is
  /// value-unequal to every previous entry, so it shows up as "added".
  void _trackEditable(
    List<Installation> previous,
    List<Installation> next,
    void Function(Installation) assign,
  ) {
    final addedItems = next.where((n) => !previous.contains(n)).toList();
    if (addedItems.isNotEmpty) assign(addedItems.first);
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final theme = Theme.of(context);
    final bikes = appRepository.bikes;

    final bikeId =
        _editableInstalled.parent ?? widget.installed.installation.parent;
    final bikeName = bikes[bikeId]?.name ?? "BIKE NOT FOUND";
    final isBikeError = bikeId != null && !bikes.containsKey(bikeId);
    final bikeColor = isBikeError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    final removedColor = theme.colorScheme.error;
    final installedColor = theme.extension<ValueHighlightColors>()!.initial;

    final String removedVerb = switch (widget.removed.installation.parentType) {
      InstallationParentType.archived => 'Archived',
      _ => 'Uninstalled',
    };

    final bool sameName =
        widget.removed.component.name == widget.installed.component.name;
    final String removedTitle = sameName
        ? "${widget.removed.component.name} ($removedVerb)"
        : widget.removed.component.name;
    final String installedTitle = sameName
        ? "${widget.installed.component.name} (Installed)"
        : widget.installed.component.name;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: "Replaced ${widget.removed.component.componentType.label}",
              leadingIcon: const Icon(Icons.swap_horiz),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'A replacement is simply two installations within '
                        '${kReplacementWindow.inMinutes} minutes: one component '
                        'removed and another installed on the same bike.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // Old -> Swap -> New Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(Bike.iconData, size: 15, color: bikeColor),
                                Flexible(
                                  child: Text(
                                    bikeName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: bikeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _ComponentPreview(
                                    component: widget.removed.component,
                                    caption: removedVerb,
                                    color: removedColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.swap_horiz,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: _ComponentPreview(
                                    component: widget.installed.component,
                                    caption: 'Installed',
                                    color: installedColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SetInstallationTimeline(
                      title: removedTitle,
                      initialInstallations: _removedInstallations,
                      originalInstallations: widget.removed.component.installations,
                      onChanged: (newInstallations) {
                        setState(() {
                          _trackEditable(
                            _removedInstallations,
                            newInstallations,
                            (installation) => _editableRemoved = installation,
                          );
                          _removedInstallations = List.from(newInstallations);
                        });
                      },
                      isEntryEditable: (installation) => installation == _editableRemoved,
                    ),
                    const SizedBox(height: 8),
                    SetInstallationTimeline(
                      title: installedTitle,
                      initialInstallations: _installedInstallations,
                      originalInstallations: widget.installed.component.installations,
                      onChanged: (newInstallations) {
                        setState(() {
                          _trackEditable(
                            _installedInstallations,
                            newInstallations,
                            (installation) => _editableInstalled = installation,
                          );
                          _installedInstallations = List.from(newInstallations);
                        });
                      },
                      isEntryEditable: (installation) => installation == _editableInstalled,
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

class _ComponentPreview extends StatelessWidget {
  final Component component;
  final String caption;
  final Color color;

  const _ComponentPreview({
    required this.component,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(component.componentType.getIconData(), color: color),
        const SizedBox(height: 4),
        Text(
          component.name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
