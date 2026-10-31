import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../utils/adjustment_preset_consumption.dart';
import '../sticky_section.dart';
import 'adjustment_preset_list.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// Used in app onboarding
final NumericalAdjustment ridingWeightPreset = NumericalAdjustment(name: 'Riding weight', unit: AdjustmentUnit.fromLegacy('kg'), min: 0.0, notes: "Weight including all gear (helmet, shoes, hydration pack).", presetKey: "person:riding_weight");

final List<Adjustment> _adjustmentPresets = [
  ridingWeightPreset,
  NumericalAdjustment(name: 'Height', unit: AdjustmentUnit.fromLegacy('cm'), min: 0.0, notes: "Body height", presetKey: "person:height"),
  NumericalAdjustment(name: 'Inseam', unit: AdjustmentUnit.fromLegacy('cm'), min: 0.0, notes: "Crotch to floor, barefoot. Helps with dropper post length and saddle height.", presetKey: "person:inseam"),
  NumericalAdjustment(name: 'FTP', unit: AdjustmentUnit.fromLegacy('W'), min: 0.0, notes: "Functional Threshold Power: the highest power you can sustain for about one hour.", presetKey: "person:ftp"),
  NumericalAdjustment(name: 'Max heart rate', unit: AdjustmentUnit.fromLegacy('bpm'), min: 0.0, notes: "Highest heart rate reached in an all-out effort. Basis for heart rate zones.", presetKey: "person:max_heart_rate"),
  NumericalAdjustment(name: 'Resting heart rate', unit: AdjustmentUnit.fromLegacy('bpm'), min: 0.0, notes: "Heart rate at rest, ideally measured right after waking up.", presetKey: "person:resting_heart_rate"),
  NumericalAdjustment(name: 'LTHR', unit: AdjustmentUnit.fromLegacy('bpm'), min: 0.0, notes: "Lactate Threshold Heart Rate: the average heart rate you can sustain for about one hour.", presetKey: "person:lthr"),
  CategoricalAdjustment(name: 'Riding style', unit: null, options: const {'Comfort', 'Balanced', 'Race'}, notes: "Race-oriented riders usually require higher support (more compression damping).", presetKey: "person:riding_style"),
];

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
      final consumedCount = _adjustmentPresets.where((preset) => isAdjustmentPresetConsumed(preset, existingAdjustments)).length;
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
                    if (_adjustmentPresets.isNotEmpty)
                      StickySection(
                        header: sheetSectionHeader(context,
                          consumedCount == 0
                              ? context.l10n.addAdjustmentTemplates
                              : context.l10n.riderAttributeTemplatesProgress(consumedCount, _adjustmentPresets.length),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AdjustmentPresetList(
                              presets: _adjustmentPresets,
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
  
