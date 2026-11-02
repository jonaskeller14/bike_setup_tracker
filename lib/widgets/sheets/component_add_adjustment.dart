import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../../utils/adjustment_preset_consumption.dart';
import '../../utils/adjustment_presets.dart';
import '../sticky_section.dart';
import 'adjustment_preset_list.dart';
import 'component_type_picker.dart';
import 'sheet.dart';
import 'sheet_header.dart';

void showComponentAddAdjustmentBottomSheet({
  required BuildContext context,
  required ComponentType? componentType,
  List<Adjustment> existingAdjustments = const [],
  bool enableDurationAdjustment = false,
  required Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset,
  required Future<void> Function<T extends Adjustment>() addAdjustment,
  Future<void> Function(ComponentType componentType)? onComponentTypeSelected,
}) async {
  await showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _ComponentAddAdjustmentSheet(
      componentType: componentType,
      existingAdjustments: existingAdjustments,
      enableDurationAdjustment: enableDurationAdjustment,
      addAdjustmentFromPreset: addAdjustmentFromPreset,
      addAdjustment: addAdjustment,
      onComponentTypeSelected: onComponentTypeSelected,
    ),
  );
}

class _ComponentAddAdjustmentSheet extends StatefulWidget {
  final ComponentType? componentType;
  final List<Adjustment> existingAdjustments;
  final bool enableDurationAdjustment;
  final Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset;
  final Future<void> Function<T extends Adjustment>() addAdjustment;
  final Future<void> Function(ComponentType componentType)? onComponentTypeSelected;

  const _ComponentAddAdjustmentSheet({
    required this.componentType,
    required this.existingAdjustments,
    required this.enableDurationAdjustment,
    required this.addAdjustmentFromPreset,
    required this.addAdjustment,
    required this.onComponentTypeSelected,
  });

  @override
  State<_ComponentAddAdjustmentSheet> createState() => _ComponentAddAdjustmentSheetState();
}

class _ComponentAddAdjustmentSheetState extends State<_ComponentAddAdjustmentSheet> {
  late ComponentType? _selectedType = widget.componentType;

  Future<void> _pickComponentType() async {
    final onComponentTypeSelected = widget.onComponentTypeSelected;
    if (onComponentTypeSelected == null) return;
    final pickedType = await showComponentTypePickerSheet(context: context);
    if (pickedType == null) return;
    setState(() => _selectedType = pickedType);
    await onComponentTypeSelected(pickedType);
  }

  @override
  Widget build(BuildContext context) {
    final componentType = _selectedType;
    final presets = componentAdjustmentPresetsFor(context.l10n)[componentType] ?? const <Adjustment>[];
    final consumedCount = presets.where((preset) => isAdjustmentPresetConsumed(preset, widget.existingAdjustments)).length;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.addAdjustmentTitle, showClose: false),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StickySection(
                    header: sheetSectionHeader(context,
                      componentType == null
                          ? context.l10n.addAdjustmentTemplates
                          : consumedCount == 0
                              ? context.l10n.addAdjustmentSuggested(componentType.label(context.l10n))
                              : context.l10n.addAdjustmentSuggestedProgress(componentType.label(context.l10n), consumedCount, presets.length),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (componentType == null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: SheetFilterEmptyHint(
                              icon: widget.onComponentTypeSelected != null ? Icons.category_outlined : Icons.info_outline,
                              title: widget.onComponentTypeSelected != null
                                  ? context.l10n.addAdjustmentSelectTypeTitle
                                  : context.l10n.addAdjustmentNoTemplatesTitle,
                              hint: widget.onComponentTypeSelected != null
                                  ? context.l10n.addAdjustmentTemplatesPerType
                                  : context.l10n.addAdjustmentSelectTypeFirst,
                              onTap: widget.onComponentTypeSelected == null ? null : _pickComponentType,
                            ),
                          )
                        else
                          if (presets.isNotEmpty)
                            AdjustmentPresetList(
                              presets: presets,
                              existingAdjustments: widget.existingAdjustments,
                              allAddedHint: context.l10n.addAdjustmentAllAdded,
                              onSelected: widget.addAdjustmentFromPreset,
                            )
                          else
                            Text(
                              context.l10n.addAdjustmentNoTemplates,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        const Divider(height: 16),
                      ],
                    ),
                  ),
                  StickySection(
                    header: sheetSectionHeader(context, context.l10n.addAdjustmentCustom),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(NumericalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                          title: Text(context.l10n.adjustmentTypeNumerical),
                          subtitle: Text(context.l10n.adjustmentTypeNumericalHint, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                          onTap: () async {
                            Navigator.pop(context); // Close sheet first
                            await widget.addAdjustment<NumericalAdjustment>(); // Then execute logic
                          },
                        ),
                        ListTile(
                          leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                          title: Text(context.l10n.adjustmentTypeStep),
                          subtitle: Text(context.l10n.adjustmentTypeStepHint, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                          onTap: () async {
                            Navigator.pop(context); // Close sheet first
                            await widget.addAdjustment<StepAdjustment>(); // Then execute logic
                          },
                        ),
                        ListTile(
                          leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                          title: Text(context.l10n.adjustmentTypeCategorical),
                          subtitle: Text(context.l10n.adjustmentTypeCategoricalHint, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                          onTap: () async {
                            Navigator.pop(context); // Close sheet first
                            await widget.addAdjustment<CategoricalAdjustment>(); // Then execute logic
                          },
                        ),
                        ListTile(
                          leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                          title: Text(context.l10n.adjustmentTypeBoolean),
                          subtitle: Text(context.l10n.adjustmentTypeBooleanHint, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                          onTap: () async {
                            Navigator.pop(context); // Close sheet first
                            await widget.addAdjustment<BooleanAdjustment>(); // Then execute logic
                          },
                        ),
                        if (context.read<AppSettings>().enableTextAdjustment)
                          ListTile(
                            leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(context.l10n.adjustmentTypeText),
                            subtitle: Text(context.l10n.adjustmentTypeTextHint, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet first
                              await widget.addAdjustment<TextAdjustment>(); // Then execute logic
                            },
                          ),
                        if (widget.enableDurationAdjustment)
                          ListTile(
                            leading: Icon(DurationAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(context.l10n.adjustmentTypeDuration),
                            subtitle: Text(context.l10n.adjustmentTypeDurationHint, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet first
                              await widget.addAdjustment<DurationAdjustment>(); // Then execute logic
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
