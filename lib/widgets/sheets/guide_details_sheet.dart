import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/component/component_catalog.dart';
import '../../utils/component_preset_resolver.dart';
import '../catalog_axis_chips.dart';
import 'sheet_header.dart';

/// Asks for the catalog details of [componentName] that its setup guide
/// lacks: the values of [axisIds], option axes of [preset]'s product that are
/// still unset. Resolves to [preset] with the chosen values, or null when
/// dismissed. A detail left unset stays unset.
Future<ResolvedPreset?> showGuideDetailsSheet(
  BuildContext context, {
  required String componentName,
  required ResolvedPreset preset,
  required List<String> axisIds,
}) {
  return showModalBottomSheet<ResolvedPreset>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _GuideDetailsSheet(componentName: componentName, preset: preset, axisIds: axisIds),
  );
}

class _GuideDetailsSheet extends StatefulWidget {
  final String componentName;
  final ResolvedPreset preset;
  final List<String> axisIds;

  const _GuideDetailsSheet({required this.componentName, required this.preset, required this.axisIds});

  @override
  State<_GuideDetailsSheet> createState() => _GuideDetailsSheetState();
}

class _GuideDetailsSheetState extends State<_GuideDetailsSheet> {
  late ResolvedPreset _preset = widget.preset;

  late final List<OptionAxis> _axes = [
    for (final id in widget.axisIds) ?widget.preset.axes.firstWhereOrNull((axis) => axis.id == id),
  ];

  bool get _hasChoice => _axes.any((axis) => _preset.selections.containsKey(axis.id));

  void _toggle(OptionAxis axis, OptionValue value) {
    unawaited(HapticFeedback.selectionClick());
    final selected = _preset.selections[axis.id] == value;
    setState(() => _preset = _preset.select(axis, selected ? null : value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: context.l10n.guideDetailsTitle),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.guideDetailsIntro(widget.componentName),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  for (final axis in _axes)
                    CatalogAxisChips(
                      axis: axis,
                      selected: _preset.selections[axis.id],
                      onTap: (value) => _toggle(axis, value),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              onPressed: _hasChoice
                  ? () {
                      unawaited(HapticFeedback.mediumImpact());
                      Navigator.pop(context, _preset);
                    }
                  : null,
              label: Text(context.l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}
