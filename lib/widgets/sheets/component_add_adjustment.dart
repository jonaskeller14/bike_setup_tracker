import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../../utils/adjustment_preset_consumption.dart';
import '../../utils/component_catalog_application.dart';
import '../sticky_section.dart';
import 'adjustment_preset_list.dart';
import 'component_type_picker.dart';
import 'sheet.dart';
import 'sheet_header.dart';

final Map<ComponentType, List<Adjustment>> _adjustmentPresets = {
  ComponentType.frame: [
    CategoricalAdjustment(name: "Flipchip", notes: "Controls geometry and bottom bracket height", unit: null, options: const {"Low", "Mid", "High"}, presetKey: "frame:flipchip"),
    CategoricalAdjustment(name: "Chainstay Length", notes: "Some bikes have an adjustable chainstay length", unit: null, options: const {"Short", "Mid", "Long"}, presetKey: "frame:chainstay_length"),
  ],
  ComponentType.fork: [
    BooleanAdjustment(name: "Lockout", unit: null, notes: "Is the lockout lever enabled?", presetKey: "fork:lockout"),
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("psi"), min: 0, notes: "Fork air pressure", presetKey: "fork:pressure"),
    SagAdjustment(name: "SAG", notes: kForkSagNotes, presetKey: "fork:sag"),
    StepAdjustment(name: "Rebound", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, dialColor: StepAdjustmentDialColor.red, notes: "Rebound clicks", presetKey: "fork:rebound"),
    StepAdjustment(name: "Compression", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Compression clicks", presetKey: "fork:compression"),
    StepAdjustment(name: "LSR", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, dialColor: StepAdjustmentDialColor.red, notes: "Low Speed Rebound clicks", presetKey: "fork:lsr"),
    StepAdjustment(name: "HSR", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, dialColor: StepAdjustmentDialColor.red, notes: "High Speed Rebound clicks", presetKey: "fork:hsr"),
    StepAdjustment(name: "LSC", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Low Speed Compression clicks", presetKey: "fork:lsc"),
    StepAdjustment(name: "HSC", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "High Speed Compression clicks", presetKey: "fork:hsc"),
    StepAdjustment(name: "Volume Spacers", unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton, notes: "Number of volume spacers installed in the air spring", presetKey: "fork:volume_spacers"),
  ],
  ComponentType.shock: [
    BooleanAdjustment(name: "Lockout", unit: null, notes: "Is the lockout lever enabled?", presetKey: "shock:lockout"),
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("psi"), min: 0, notes: "Shock air pressure", presetKey: "shock:pressure"),
    NumericalAdjustment(name: "Spring Rate", unit: AdjustmentUnit.fromLegacy("lbs/in"), min: 0, notes: "Coil spring rate", presetKey: "shock:spring_rate"),
    SagAdjustment(name: "SAG", notes: kShockSagNotes, presetKey: "shock:sag"),
    StepAdjustment(name: "Rebound", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, dialColor: StepAdjustmentDialColor.red, notes: "Rebound clicks", presetKey: "shock:rebound"),
    StepAdjustment(name: "Compression", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Compression clicks", presetKey: "shock:compression"),
    StepAdjustment(name: "LSR", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, dialColor: StepAdjustmentDialColor.red, notes: "Low Speed Rebound clicks", presetKey: "shock:lsr"),
    StepAdjustment(name: "HSR", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, dialColor: StepAdjustmentDialColor.red, notes: "High Speed Rebound clicks", presetKey: "shock:hsr"),
    StepAdjustment(name: "LSC", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Low Speed Compression clicks", presetKey: "shock:lsc"),
    StepAdjustment(name: "HSC", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "High Speed Compression clicks", presetKey: "shock:hsc"),
    StepAdjustment(name: "Volume Spacers", unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton, notes: "Number of volume spacers installed in the air spring", presetKey: "shock:volume_spacers"),
  ],
  ComponentType.cockpit: [
    NumericalAdjustment(name: "Bar Roll", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of handlebars in degrees", presetKey: "cockpit:bar_roll"),
    NumericalAdjustment(name: "Bar Width", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Total width of handlebars", presetKey: "cockpit:bar_width"),
    NumericalAdjustment(name: "Bar Rise", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "The vertical distance between the center of the clamp area and the center of the bar ends.", presetKey: "cockpit:bar_rise"),
  ],
  ComponentType.stem: [
    NumericalAdjustment(name: "Stem Length", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Measured center-to-center from the fork steerer tube to the handlebar clamp.", presetKey: "stem:stem_length"),
    NumericalAdjustment(name: "Stem Angle", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of the stem relative to the steering column", presetKey: "stem:stem_angle"),
    StepAdjustment(name: "Stack Spacers", unit: null, step: 5, min: 0, max: 100, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton, notes: "Height of spacers under the stem", presetKey: "stem:stack_spacers"),
  ],
  ComponentType.grip: [
    NumericalAdjustment(name: "Rotation", unit: AdjustmentUnit.fromLegacy("°"), notes: "Rotation angle for ergonomic or asymmetric grips", presetKey: "grip:rotation"),
  ],
  ComponentType.shifter: [
    NumericalAdjustment(name: "Lateral Position", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Distance from the grip to the shifter clamp", presetKey: "shifter:lateral_position"),
    NumericalAdjustment(name: "Angle", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of the shifter relative to the horizontal", presetKey: "shifter:angle"),
  ],
  ComponentType.derailleur: [
    BooleanAdjustment(name: "Clutch", notes: "Is the derailleur clutch/stabilizer enabled?", unit: null, presetKey: "derailleur:clutch"),
    CategoricalAdjustment(name: "Clutch Tension", options: const {"Soft", "Medium", "Hard"}, notes: "Adjustable clutch tension for some derailleurs", unit: null, presetKey: "derailleur:clutch_tension"),
  ],
  ComponentType.pedal: [
    StepAdjustment(name: "Clipless Spring Tension", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Release tension setting for clipless pedals", presetKey: "pedal:spring_tension"),
    CategoricalAdjustment(name: "Pin Arrangement", options: const {"Full", "Aggressive", "Balanced", "Minimum"}, notes: "Pattern and arrangement of pins on platform pedals", unit: null, presetKey: "pedal:pin_arrangement"),
    NumericalAdjustment(name: "Pin Height", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Height of the pins above the pedal platform", presetKey: "pedal:pin_height"),
  ],
  ComponentType.brakeLever: [
    NumericalAdjustment(name: "Lever Reach", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Distance from the handlebar to the lever blade", presetKey: "brake_lever:lever_reach"),
    NumericalAdjustment(name: "Lever Angle",  unit: AdjustmentUnit.fromLegacy("°"),  notes: "Angle of brake levers relative to horizontal (pointing down).", presetKey: "brake_lever:lever_angle"),
    NumericalAdjustment(name: "Lateral Position", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Distance from the grip to the lever clamp", presetKey: "brake_lever:lateral_position"),
    NumericalAdjustment(name: "Bite Point", unit: AdjustmentUnit.fromLegacy("mm"), notes: "The distance the lever moves before the pads engage", presetKey: "brake_lever:bite_point"),
  ],
  ComponentType.wheelFront: [
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("bar"), min: 0, notes: "Front tire pressure", presetKey: "wheel_front:pressure"),
    BooleanAdjustment(name: "Insert", unit: null, notes: "Tire insert installed?", presetKey: "wheel_front:insert"),
    CategoricalAdjustment(name: "Wear", options: const {"New", "Used", "Worn Out"}, unit: null, notes: "Current state of the tire tread", presetKey: "wheel_front:wear"),
  ],
  ComponentType.wheelRear: [
    NumericalAdjustment(name: "Tire Pressure", unit: AdjustmentUnit.fromLegacy("bar"), min: 0, notes: "Rear tire pressure", presetKey: "wheel_rear:tire_pressure"),
    BooleanAdjustment(name: "Insert", unit: null, notes: "Tire insert installed?", presetKey: "wheel_rear:insert"),
    CategoricalAdjustment(name: "Tire Wear", options: const {"New", "Used", "Worn Out"}, unit: null, notes: "Current state of the tire tread", presetKey: "wheel_rear:tire_wear"),
  ],
  ComponentType.tire: [
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("bar"), min: 0, notes: "Tire pressure", presetKey: "tire:pressure"),
    CategoricalAdjustment(name: "Wear", options: const {"New", "Used", "Worn Out"}, unit: null, notes: "Current state of the tire tread", presetKey: "tire:wear"),
  ],
  ComponentType.saddle: [
    NumericalAdjustment(name: "Saddle Tilt", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of the saddle relative to horizontal", presetKey: "saddle:saddle_tilt"),
    NumericalAdjustment(name: "Saddle Fore/Aft", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Position of the saddle on the rails", presetKey: "saddle:saddle_fore_aft"),
  ],
  ComponentType.seatpost: [
    NumericalAdjustment(name: "Saddle Height", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Distance from Bottom Bracket to top of saddle", presetKey: "seatpost:saddle_height"),
    NumericalAdjustment(name: "Dropper Pressure", unit: AdjustmentUnit.fromLegacy("psi"), min: 0, notes: "Air pressure for the dropper post return", presetKey: "seatpost:dropper_pressure"),
  ],
  ComponentType.motor: [
    NumericalAdjustment(name: "Max Power", unit: AdjustmentUnit.fromLegacy("W"), min: 0, notes: "Maximum motor power output", presetKey: "motor:max_power"),
    NumericalAdjustment(name: "Max Torque", unit: AdjustmentUnit.fromLegacy("Nm"), min: 0, notes: "Maximum motor torque", presetKey: "motor:max_torque"),
    CategoricalAdjustment(name: "Mode", notes: "Current assistance level", unit: null, options: const {"Eco", "Trail", "Turbo", "Boost", "Auto"}, presetKey: "motor:mode"),
  ],
  ComponentType.equipment: [
    BooleanAdjustment(name: "Backpack", notes: "Wearing a backpack? Yes/No", unit: null, presetKey: "equipment:backpack"),
    CategoricalAdjustment(name: "Upper clothing layer 1", notes: "First clothing layer from inside (e.g. thermal shirt, ...)", unit: null, options: const {"my Clothing Item A", "my Clothing Item B"}, presetKey: "equipment:upper_clothing_1"),
    CategoricalAdjustment(name: "Upper clothing layer 2", notes: "Second clothing layer from inside (e.g. wind jacket, ...)", unit: null, options: const {"my Clothing Item A", "my Clothing Item B"}, presetKey: "equipment:upper_clothing_2"),
    CategoricalAdjustment(name: "Cleat Position", notes: "Shoe cleat fore/aft or lateral position", unit: null, options: const {"Forward", "Neutral", "Rearward"}, presetKey: "equipment:cleat_position"),
  ],
  ComponentType.other: [
    NumericalAdjustment(name: "Stack Height", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Height of spacers under the stem", presetKey: "other:stack_height"),
  ],
};

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
    final presets = _adjustmentPresets[componentType] ?? const <Adjustment>[];
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
