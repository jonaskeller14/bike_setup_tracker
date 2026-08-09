import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/component.dart';
import '../../utils/component_preset_application.dart';
import '../items/adjustment_properties.dart';
import '../items/adjustment_type_icon.dart';
import 'component_type_picker.dart';
import 'sheet.dart';
import 'sheet_header.dart';

final Map<ComponentType, List<Adjustment>> _adjustmentPresets = {
  ComponentType.frame: [
    CategoricalAdjustment(name: "Flipchip", notes: "Controls geometry and bottom bracket height", unit: null, options: {"Low", "Mid", "High"}),
    CategoricalAdjustment(name: "Chainstay Length", notes: "Some bikes have a adjustable chainstay length", unit: null, options: {"Short", "Mid", "Long"}),
  ],
  ComponentType.fork: [
    BooleanAdjustment(name: "Lockout", unit: null, notes: "Is the lockout lever enabled?"),
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("psi"), min: 0, notes: "Fork air pressure"),
    SagAdjustment(name: "SAG", notes: kForkSagNotes),
    StepAdjustment(name: "Rebound", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Rebound clicks"),
    StepAdjustment(name: "Compression", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Compression clicks"),
    StepAdjustment(name: "Volume Spacers", unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton, notes: "Number of volume spacers installed in the air spring"),
  ],
  ComponentType.shock: [
    BooleanAdjustment(name: "Lockout", unit: null, notes: "Is the lockout lever enabled?"),
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("psi"), min: 0, notes: "Shock air pressure"),
    NumericalAdjustment(name: "Spring Rate", unit: AdjustmentUnit.fromLegacy("lbs/in"), min: 0, notes: "Coil spring rate"),
    SagAdjustment(name: "SAG", notes: kShockSagNotes),
    StepAdjustment(name: "Rebound", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Rebound clicks"),
    StepAdjustment(name: "Compression", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Compression clicks"),
    StepAdjustment(name: "Volume Spacers", unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton, notes: "Number of volume spacers installed in the air spring"),
  ],
  ComponentType.cockpit: [
    NumericalAdjustment(name: "Bar Roll", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of handlebars in degrees"),
    NumericalAdjustment(name: "Bar Width", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Total width of handlebars"),
    NumericalAdjustment(name: "Bar Rise", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "The vertical distance between the center of the clamp area and the center of the bar ends."),
  ],
  ComponentType.stem: [
    NumericalAdjustment(name: "Stem Length", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Measured center-to-center from the fork steerer tube to the handlebar clamp."),
    NumericalAdjustment(name: "Stem Angle", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of the stem relative to the steering column"),
    StepAdjustment(name: "Stack Spacers", unit: null, step: 5, min: 0, max: 100, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton, notes: "Height of spacers under the stem"),
  ],
  ComponentType.grip: [
    NumericalAdjustment(name: "Rotation", unit: AdjustmentUnit.fromLegacy("°"), notes: "Rotation angle for ergonomic or asymmetric grips"),
  ],
  ComponentType.shifter: [
    NumericalAdjustment(name: "Lateral Position", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Distance from the grip to the shifter clamp"),
    NumericalAdjustment(name: "Angle", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of the shifter relative to the horizontal"),
  ],
  ComponentType.derailleur: [
    BooleanAdjustment(name: "Clutch", notes: "Is the derailleur clutch/stabilizer enabled?", unit: null),
    CategoricalAdjustment(name: "Clutch Tension", options: {"Soft", "Medium", "Hard"}, notes: "Adjustable clutch tension for some derailleurs", unit: null),
  ],
  ComponentType.pedal: [
    StepAdjustment(name: "Clipless Spring Tension", unit: null, step: 1, min: 0, max: 20, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Release tension setting for clipless pedals"),
    CategoricalAdjustment(name: "Pin Arrangement", options: {"Full", "Aggressive", "Balanced", "Minimum"}, notes: "Pattern and arrangement of pins on platform pedals", unit: null),
    NumericalAdjustment(name: "Pin Height", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Height of the pins above the pedal platform"),
  ],
  ComponentType.brakeLever: [
    NumericalAdjustment(name: "Lever Reach", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Distance from the handlebar to the lever blade"),
    NumericalAdjustment(name: "Lever Angle",  unit: AdjustmentUnit.fromLegacy("°"),  notes: "Angle of brake levers relative to horizontal (pointing down)."),
    NumericalAdjustment(name: "Lateral Position", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Distance from the grip to the lever clamp"),
    NumericalAdjustment(name: "Bite Point", unit: AdjustmentUnit.fromLegacy("mm"), notes: "The distance the lever moves before the pads engage"),
  ],
  ComponentType.wheelFront: [
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("bar"), min: 0, notes: "Front tire pressure"),
    BooleanAdjustment(name: "Insert", unit: null, notes: "Tire insert installed?"),
    CategoricalAdjustment(name: "Wear", options: {"New", "Used", "Worn Out"}, unit: null, notes: "Current state of the tire tread"),
  ],
  ComponentType.wheelRear: [
    NumericalAdjustment(name: "Tire Pressure", unit: AdjustmentUnit.fromLegacy("bar"), min: 0, notes: "Rear tire pressure"),
    BooleanAdjustment(name: "Insert", unit: null, notes: "Tire insert installed?"),
    CategoricalAdjustment(name: "Tire Wear", options: {"New", "Used", "Worn Out"}, unit: null, notes: "Current state of the tire tread"),
  ],
  ComponentType.tire: [
    NumericalAdjustment(name: "Pressure", unit: AdjustmentUnit.fromLegacy("bar"), min: 0, notes: "Tire pressure"),
    CategoricalAdjustment(name: "Wear", options: {"New", "Used", "Worn Out"}, unit: null, notes: "Current state of the tire tread"),
  ],
  ComponentType.saddle: [
    NumericalAdjustment(name: "Saddle Tilt", unit: AdjustmentUnit.fromLegacy("°"), notes: "Angle of the saddle relative to horizontal"),
    NumericalAdjustment(name: "Saddle Fore/Aft", unit: AdjustmentUnit.fromLegacy("mm"), notes: "Position of the saddle on the rails"),
  ],
  ComponentType.seatpost: [
    NumericalAdjustment(name: "Saddle Height", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Distance from Bottom Bracket to top of saddle"),
    NumericalAdjustment(name: "Dropper Pressure", unit: AdjustmentUnit.fromLegacy("psi"), min: 0, notes: "Air pressure for the dropper post return"),
  ],
  ComponentType.motor: [
    NumericalAdjustment(name: "Max Power", unit: AdjustmentUnit.fromLegacy("W"), min: 0, notes: "Maximum motor power output"),
    NumericalAdjustment(name: "Max Torque", unit: AdjustmentUnit.fromLegacy("Nm"), min: 0, notes: "Maximum motor torque"),
    CategoricalAdjustment(name: "Mode", notes: "Current assistance level", unit: null, options: {"Eco", "Trail", "Turbo", "Boost", "Auto"}),
  ],
  ComponentType.equipment: [
    BooleanAdjustment(name: "Backpack", notes: "Wearing a backpack? Yes/No", unit: null),
    CategoricalAdjustment(name: "Upper clothing layer 1", notes: "First clothing layer from inside (e.g. thermal shirt, ...)", unit: null, options: {"my Clothing Item A", "my Clothing Item B"}),
    CategoricalAdjustment(name: "Upper clothing layer 2", notes: "Second clothing layer from inside (e.g. wind jacket, ...)", unit: null, options: {"my Clothing Item A", "my Clothing Item B"}),
    CategoricalAdjustment(name: "Cleat Position", notes: "Shoe cleat fore/aft or lateral position", unit: null, options: {"Forward", "Neutral", "Rearward"}),
  ],
  ComponentType.other: [
    NumericalAdjustment(name: "Stack Height", unit: AdjustmentUnit.fromLegacy("mm"), min: 0, notes: "Height of spacers under the stem"),
  ],
};

void showComponentAddAdjustmentBottomSheet({
  required BuildContext context,
  required ComponentType? componentType,
  bool enableDurationAdjustment = false,
  required Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset,
  required Future<void> Function<T extends Adjustment>() addAdjustment,
  Future<void> Function(ComponentType componentType)? onComponentTypeSelected,
}) async {
  await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _ComponentAddAdjustmentSheet(
      componentType: componentType,
      enableDurationAdjustment: enableDurationAdjustment,
      addAdjustmentFromPreset: addAdjustmentFromPreset,
      addAdjustment: addAdjustment,
      onComponentTypeSelected: onComponentTypeSelected,
    ),
  );
}

class _ComponentAddAdjustmentSheet extends StatefulWidget {
  final ComponentType? componentType;
  final bool enableDurationAdjustment;
  final Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset;
  final Future<void> Function<T extends Adjustment>() addAdjustment;
  final Future<void> Function(ComponentType componentType)? onComponentTypeSelected;

  const _ComponentAddAdjustmentSheet({
    required this.componentType,
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
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: "Add Adjustment", showClose: false),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      componentType != null ? "Suggested for ${componentType.label}" : "Pre-filled Templates",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (componentType == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SheetFilterEmptyHint(
                        icon: widget.onComponentTypeSelected != null ? Icons.category_outlined : Icons.info_outline,
                        title: widget.onComponentTypeSelected != null
                            ? "Select a component type"
                            : "No templates available",
                        hint: widget.onComponentTypeSelected != null
                            ? "Templates are suggested per component type."
                            : "Select a component type first.",
                        onTap: widget.onComponentTypeSelected == null ? null : _pickComponentType,
                      ),
                    )
                  else
                    if (_adjustmentPresets[componentType] != null && _adjustmentPresets[componentType]!.isNotEmpty)
                      ..._adjustmentPresets[componentType]!.map((adjustmentPreset) => ListTile(
                        leading: AdjustmentTypeIcon(adjustmentPreset),
                        title: Text(adjustmentPreset.name),
                        subtitle: AdjustmentProperties(adjustmentPreset, singleLine: true, compact: true),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                        onTap: () async {
                          Navigator.pop(context);
                          await widget.addAdjustmentFromPreset(adjustmentPreset);
                        },
                      ))
                    else
                      Text(
                        "No templates available.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  const Divider(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      "Custom Adjustment",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(NumericalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Numerical Adjustment"),
                    subtitle: const Text("Pressure (psi/bar), Length, Angle, Weight", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      Navigator.pop(context); // Close sheet first
                      await widget.addAdjustment<NumericalAdjustment>(); // Then execute logic
                    },
                  ),
                  ListTile(
                    leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Step Adjustment"),
                    subtitle: const Text("Rebound/Compression clicks, Spacers, Increments", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      Navigator.pop(context); // Close sheet first
                      await widget.addAdjustment<StepAdjustment>(); // Then execute logic
                    },
                  ),
                  ListTile(
                    leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Categorical Adjustment"),
                    subtitle: const Text("Tire Compound (soft/hard), Brand, Style, Mode", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      Navigator.pop(context); // Close sheet first
                      await widget.addAdjustment<CategoricalAdjustment>(); // Then execute logic
                    },
                  ),
                  ListTile(
                    leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                    title: const Text("On/Off Adjustment"),
                    subtitle: const Text("Lockout, Climb switch, Component installed? Yes/No", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      Navigator.pop(context); // Close sheet first
                      await widget.addAdjustment<BooleanAdjustment>(); // Then execute logic
                    },
                  ),
                  if (context.read<AppSettings>().enableTextAdjustment)
                    ListTile(
                      leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Text Adjustment"),
                      subtitle: const Text("Notes, advanced settings details", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await widget.addAdjustment<TextAdjustment>(); // Then execute logic
                      },
                    ),
                  if (widget.enableDurationAdjustment)
                    ListTile(
                      leading: Icon(DurationAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Duration Adjustment"),
                      subtitle: const Text("Time Span", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await widget.addAdjustment<DurationAdjustment>(); // Then execute logic
                      },
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
