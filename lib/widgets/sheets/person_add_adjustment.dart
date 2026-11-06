import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../utils/adjustment_preset_consumption.dart';
import '../../utils/adjustment_presets.dart';
import '../sticky_section.dart';
import 'adjustment_preset_list.dart';
import 'sheet.dart';
import 'sheet_header.dart';

void showPersonAddAdjustmentBottomSheet({
  required BuildContext context,
  List<Adjustment> existingAdjustments = const [],
  required Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset,
  required Future<void> Function<T extends Adjustment>() addAdjustment,
}) async {
  await showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) {
      final presets = personAdjustmentPresetsFor(context.l10n);
      final consumedCount = presets.where((preset) => isAdjustmentPresetConsumed(preset, existingAdjustments)).length;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: context.l10n.riderFormAddAttribute, showClose: false),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (presets.isNotEmpty)
                      StickySection(
                        header: sheetSectionHeader(context,
                          consumedCount == 0
                              ? context.l10n.addAdjustmentTemplates
                              : context.l10n.riderAttributeTemplatesProgress(consumedCount, presets.length),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AdjustmentPresetList(
                              presets: presets,
                              existingAdjustments: existingAdjustments,
                              allAddedHint: context.l10n.riderAttributeAllAdded,
                              onSelected: addAdjustmentFromPreset,
                            ),
                            const Divider(height: 16),
                          ],
                        ),
                      ),
                    StickySection(
                      header: sheetSectionHeader(context, context.l10n.riderAttributeCustom),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(NumericalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(context.l10n.riderAttributeTypeNumerical),
                            subtitle: Text(context.l10n.riderAttributeTypeNumericalHint, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet first
                              await addAdjustment<NumericalAdjustment>(); // Then execute logic
                            },
                          ),
                          ListTile(
                            leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(context.l10n.riderAttributeTypeStep),
                            subtitle: Text(context.l10n.riderAttributeTypeStepHint, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet first
                              await addAdjustment<StepAdjustment>(); // Then execute logic
                            },
                          ),
                          ListTile(
                            leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(context.l10n.riderAttributeTypeCategorical),
                            subtitle: Text(context.l10n.riderAttributeTypeCategoricalHint, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet first
                              await addAdjustment<CategoricalAdjustment>(); // Then execute logic
                            },
                          ),
                          ListTile(
                            leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                            title: Text(context.l10n.riderAttributeTypeBoolean),
                            subtitle: Text(context.l10n.riderAttributeTypeBooleanHint, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet first
                              await addAdjustment<BooleanAdjustment>(); // Then execute logic
                            },
                          ),
                          if (context.read<AppSettings>().enableTextAdjustment)
                            ListTile(
                              leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                              title: Text(context.l10n.riderAttributeTypeText),
                              subtitle: Text(context.l10n.riderAttributeTypeTextHint, style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                              onTap: () async {
                                Navigator.pop(context); // Close sheet first
                                await addAdjustment<TextAdjustment>(); // Then execute logic
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
    },
  );
}
  
