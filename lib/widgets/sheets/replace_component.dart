import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../../models/component/component_ancestor.dart';
import '../../models/component/installation.dart';
import '../../repositories/app_repository.dart';
import '../../services/app_hint_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/installation_timeline_validation.dart';
import '../component_tree_preview.dart';
import '../hints/installation_timeline_hint.dart';
import 'radio_option_card.dart';
import 'sheet.dart';
import 'sheet_header.dart';

sealed class ReplaceComponentResult {
  final DateTime replacementDate;
  /// Direct subcomponents to move onto the replacement; the others get uninstalled.
  final List<Component> movedSubcomponents;
  final List<Component> uninstalledSubcomponents;
  const ReplaceComponentResult({
    required this.replacementDate,
    required this.movedSubcomponents,
    required this.uninstalledSubcomponents,
  });
}

class ReplaceComponentNewResult extends ReplaceComponentResult {
  const ReplaceComponentNewResult({
    required super.replacementDate,
    required super.movedSubcomponents,
    required super.uninstalledSubcomponents,
  });
}

class ReplaceComponentExistingResult extends ReplaceComponentResult {
  final Component existingComponent;
  const ReplaceComponentExistingResult({
    required super.replacementDate,
    required super.movedSubcomponents,
    required super.uninstalledSubcomponents,
    required this.existingComponent,
  });
}

enum _ReplaceMode { existing, create }

Future<ReplaceComponentResult?> showReplaceComponentSheet(BuildContext context, {
  required Component component,
}) async {
  return showModalBottomSheet<ReplaceComponentResult?>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return _ReplaceComponentSheet(component: component);
    }
  );
}

class _ReplaceComponentSheet extends StatefulWidget {
  final Component component;

  const _ReplaceComponentSheet({required this.component});

  @override
  State<StatefulWidget> createState() => _ReplaceComponentSheetState();
}

class _ReplaceComponentSheetState extends State<_ReplaceComponentSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _replaceDate;
  _ReplaceMode _mode = _ReplaceMode.create;
  String? _selectedComponentId;
  bool _moveSubcomponents = true;

  @override
  void initState() {
    super.initState();
    _replaceDate = DateTime.now();
  }

  List<Component> _subcomponents(AppRepository appRepository) {
    final componentHierarchy = appRepository.componentHierarchy;
    return appRepository.components.values
        .where((c) => switch (componentHierarchy.currentInstallation(c.id)) {
              ComponentInstallation(:final parentComponentId) => parentComponentId == widget.component.id,
              _ => false,
            })
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  ComponentOutcome? _outcomeFor({required int depth, required Component? replacement}) {
    final l10n = context.l10n;
    if (depth == 0) return ComponentOutcome(icon: Icons.shelves, label: l10n.timelineUninstalled);
    // Deeper levels stay on their own parent and follow it.
    if (depth > 1) return null;
    if (!_moveSubcomponents) return ComponentOutcome(icon: Icons.shelves, label: l10n.timelineUninstalled);
    final label = _mode == _ReplaceMode.existing
        ? replacement?.name ?? l10n.replaceOutcomeReplacement
        : l10n.replaceOutcomeNewComponent;
    return ComponentOutcome(icon: widget.component.componentType.getIconData(), label: label);
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final appRepository = context.read<AppRepository>();
    final subcomponents = _subcomponents(appRepository);
    final moved = _moveSubcomponents ? subcomponents : const <Component>[];
    final uninstalled = _moveSubcomponents ? const <Component>[] : subcomponents;
    final ReplaceComponentResult result = switch (_mode) {
      _ReplaceMode.existing => ReplaceComponentExistingResult(
        replacementDate: _replaceDate,
        movedSubcomponents: moved,
        uninstalledSubcomponents: uninstalled,
        existingComponent: appRepository.components[_selectedComponentId]!,
      ),
      _ReplaceMode.create => ReplaceComponentNewResult(
        replacementDate: _replaceDate,
        movedSubcomponents: moved,
        uninstalledSubcomponents: uninstalled,
      ),
    };

    Navigator.pop(context, result);
  }

  Future<DateTime?> _showDateTimePicker(DateTime initialDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      if (!mounted) return null;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  Widget _componentSelectedDisplay(Component component) {
    return Row(
      spacing: 8,
      children: [
        Icon(component.componentType.getIconData(), size: 20),
        Expanded(child: Text(component.name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  DropdownMenuItem<String> _componentDropdownItem(Component component, {required bool showStrava, required AppSettings appSettings}) {
    final cs = Theme.of(context).colorScheme;
    final stats = context.read<AppRepository>().componentStatsOf(component.id);

    return DropdownMenuItem<String>(
      value: component.id,
      child: Row(
        spacing: 8,
        children: [
          Icon(component.componentType.getIconData(), size: 20),
          Expanded(child: Text(component.name, overflow: TextOverflow.ellipsis)),
          if (showStrava)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  spacing: 2,
                  children: [
                    Icon(Icons.route, size: 11, color: cs.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        '${NumberFormat.decimalPattern(context.l10n.localeName).format(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit)!.round())} ${appSettings.distanceUnit}',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 2,
                  children: [
                    Icon(Icons.timer_outlined, size: 11, color: cs.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        '${stats.movingTime.inHours}h ${stats.movingTime.inMinutes.remainder(60)}m',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final hintService = context.watch<AppHintService>();
    final l10n = context.l10n;
    final showStrava = appSettings.enableStrava && subscriptionService.hasStravaEntitlement;
    // Without the timeline the swap happens now and nothing is dated.
    final tracksDates = appSettings.enableInstallationTimeline ||
        isComplexInstallationTimeline(widget.component.installations);
    final offerTimeline = !tracksDates && hintService.shouldOfferInstallationTimeline(widget.component.installations);

    final componentHierarchy = appRepository.componentHierarchy;
    // Ancestors are excluded: installing one on its own descendant would form a loop.
    final ancestorIds = componentHierarchy.currentAncestors(widget.component.id)
        .whereType<ParentComponentAncestor>()
        .map((a) => a.component.id)
        .toSet();
    final uninstalledComponents = appRepository.components.values
        .where((c) => c.id != widget.component.id &&
            c.componentType == widget.component.componentType &&
            !ancestorIds.contains(c.id) &&
            switch (componentHierarchy.currentInstallation(c.id)) {
              null || Uninstallation() => true,
              _ => false,
            } &&
            !componentHierarchy.isEffectivelyArchived(c.id))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Keep the selected component in the list even if it stops being
    // "uninstalled" (e.g. while the sheet animates away after the swap installed
    // it), so the dropdown always has exactly one item matching its value.
    final menuComponents = [...uninstalledComponents];
    final selected = appRepository.components[_selectedComponentId];
    if (selected != null && !menuComponents.any((c) => c.id == selected.id)) {
      menuComponents.add(selected);
    }
    final subcomponents = _subcomponents(appRepository);
    final noExistingAvailable = _mode == _ReplaceMode.existing && menuComponents.isEmpty;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: l10n.replaceTitle(widget.component.name)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_ReplaceMode>(
                        segments: [
                          ButtonSegment(
                            value: _ReplaceMode.existing,
                            label: Text(l10n.replaceModeExisting),
                            icon: const Icon(Icons.shelves),
                          ),
                          ButtonSegment(
                            value: _ReplaceMode.create,
                            label: Text(l10n.replaceModeNew),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() => _mode = selection.first);
                          _formKey.currentState?.validate();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      switch ((_mode, tracksDates)) {
                        (_ReplaceMode.existing, true) => l10n.replaceDescriptionExistingDated,
                        (_ReplaceMode.create, true) => l10n.replaceDescriptionNewDated,
                        (_ReplaceMode.existing, false) => l10n.replaceDescriptionExistingUndated,
                        (_ReplaceMode.create, false) => l10n.replaceDescriptionNewUndated,
                      },
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (offerTimeline) ...[
                      const SizedBox(height: 16),
                      InstallationTimelineHint(
                        message: l10n.replaceTimelineHint,
                        onDismiss: () => unawaited(hintService.dismiss(AppHint.installationTimelineV1)),
                        onActivate: () async {
                          // Reveals the date field in place.
                          context.read<AppSettings>().enableInstallationTimeline = true;
                          await hintService.complete(AppHint.installationTimelineV1);
                        },
                      ),
                    ],
                    if (noExistingAvailable) ...[
                      const SizedBox(height: 16),
                      SheetFilterEmptyHint(
                        icon: Icons.shelves,
                        title: l10n.replaceNoUninstalledTitle(widget.component.componentType.label(l10n)),
                        hint: l10n.replaceNoUninstalledHint,
                        onTap: () {
                          setState(() => _mode = _ReplaceMode.create);
                          _formKey.currentState?.validate();
                        },
                      ),
                    ] else if (_mode == _ReplaceMode.existing) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedComponentId,
                        isExpanded: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: l10n.replaceComponentLabel,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        hint: Text(l10n.replaceComponentHint),
                        selectedItemBuilder: (_) => menuComponents.map(_componentSelectedDisplay).toList(),
                        items: menuComponents
                            .map((c) => _componentDropdownItem(c, showStrava: showStrava, appSettings: appSettings))
                            .toList(),
                        onChanged: (id) => setState(() => _selectedComponentId = id),
                        validator: (id) {
                          if (_mode == _ReplaceMode.existing && id == null) {
                            return l10n.replaceComponentRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                    if (!noExistingAvailable && tracksDates) const SizedBox(height: 16),
                    if (!noExistingAvailable && tracksDates) FormField<DateTime>(
                      initialValue: _replaceDate,
                      validator: (value) {
                        if (value == null) return null;
                        // Subcomponents get moved or uninstalled at the replacement date too.
                        DateTime? lastInstall = [widget.component, ...subcomponents]
                            .expand((c) => c.installations)
                            .map((i) => i.dateTimeUTC)
                            .maxOrNull;
                        if (_mode == _ReplaceMode.existing && _selectedComponentId != null) {
                          // The chosen component must not be reinstalled before its own
                          // last (de)installation, or the timeline would be out of order.
                          final existingLast = appRepository.components[_selectedComponentId]
                              ?.installations.map((i) => i.dateTimeUTC).maxOrNull;
                          if (existingLast != null && (lastInstall == null || existingLast.isAfter(lastInstall))) {
                            lastInstall = existingLast;
                          }
                        }
                        if (lastInstall != null && !value.toUtc().isAfter(lastInstall)) {
                          final formatted = DateFormat("${appSettings.dateFormat} ${appSettings.timeFormat}", context.l10n.localeName)
                              .format(lastInstall.toLocal());
                          return l10n.replaceDateAfterLast(formatted);
                        }
                        return null;
                      },
                      builder: (state) {
                        return InkWell(
                          onTap: () async {
                            final picked = await _showDateTimePicker(state.value ?? DateTime.now());
                            if (picked != null) {
                              state.didChange(picked);
                              setState(() => _replaceDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.replaceDateLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText: state.errorText,
                              suffixIcon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(appSettings.dateFormat, context.l10n.localeName).format(state.value ?? _replaceDate),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat(appSettings.timeFormat, context.l10n.localeName).format(state.value ?? _replaceDate),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (subcomponents.isNotEmpty && !noExistingAvailable) ...[
                      const SizedBox(height: 16),
                      ComponentTreePreview(
                        root: widget.component,
                        components: appRepository.components,
                        childrenOf: componentHierarchy.childrenOf,
                        outcomeForDepth: (depth) => _outcomeFor(depth: depth, replacement: selected),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        spacing: 8,
                        children: [
                          RadioOptionCard(
                            selected: _moveSubcomponents,
                            onTap: () => setState(() => _moveSubcomponents = true),
                            title: l10n.replaceMoveSubcomponents,
                            subtitle: l10n.replaceMoveSubcomponentsHint,
                          ),
                          RadioOptionCard(
                            selected: !_moveSubcomponents,
                            onTap: () => setState(() => _moveSubcomponents = false),
                            title: l10n.uninstallSubcomponents,
                            subtitle: l10n.uninstallSubcomponentsHint,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              )
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                onPressed: noExistingAvailable ? null : _onContinue,
                label: Text(l10n.continueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
