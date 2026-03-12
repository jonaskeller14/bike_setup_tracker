import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/component.dart';
import 'sheet.dart';

final Map<ComponentType, List<Adjustment>> _adjustmentPresets = {
  ComponentType.frame: [
    CategoricalAdjustment(name: "Flipchip", notes: "Controls geometry and bottom bracket height", unit: null, category: AdjustmentCategory.component, options: {"Low", "Mid", "High"}),
    CategoricalAdjustment(name: "Chainstay Length", notes: "Some bikes have a adjustable chainstay length", unit: null, category: AdjustmentCategory.component, options: {"Short", "Mid", "Long"}),
  ],
  ComponentType.fork: [
    BooleanAdjustment(name: "Lockout", unit: null, category: AdjustmentCategory.component, notes: "Is the lockout lever enabled?"),
    NumericalAdjustment(name: "Pressure", unit: "psi", min: 0, category: AdjustmentCategory.component, notes: "Fork air pressure"),
    NumericalAdjustment(name: "SAG", unit: "%", min: 0, max: 100, category: AdjustmentCategory.component, notes: "Sag is how much your fork compresses under your body weight (including riding gear) in a static riding position. SAG is a good metric for initial setup. Recommended ranges by discipline: XC: 15%, Trail: 15-20%, Enduro: 20%, Downhill: 20-25%."),
    StepAdjustment(name: "Rebound", unit: null, step: 1, min: 0, max: 20, category: AdjustmentCategory.component, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Rebound clicks (0-20)"),
    StepAdjustment(name: "Compression", unit: null, step: 1, min: 0, max: 20, category: AdjustmentCategory.component, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Compression clicks (0-20)"),
  ],
  ComponentType.shock: [
    BooleanAdjustment(name: "Lockout", unit: null, category: AdjustmentCategory.component, notes: "Is the lockout lever enabled?"),
    NumericalAdjustment(name: "Pressure", unit: "psi", min: 0, category: AdjustmentCategory.component, notes: "Shock air pressure"),
    NumericalAdjustment(name: "Spring Rate", unit: "lbs", min: 0, category: AdjustmentCategory.component, notes: "Coil spring rate"),
    NumericalAdjustment(name: "SAG", unit: "%", min: 0, max: 100, category: AdjustmentCategory.component, notes: "Sag is how much your shock compresses under your body weight (including riding gear) in a static riding position. SAG is a good metric for initial setup. Recommended ranges by discipline: XC: 20-25%, Trail: 25-30%, Enduro: 30%, Downhill: 30-35%."),
    StepAdjustment(name: "Rebound", unit: null, step: 1, min: 0, max: 20, category: AdjustmentCategory.component, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Rebound clicks (0-20)"),
    StepAdjustment(name: "Compression", unit: null, step: 1, min: 0, max: 20, category: AdjustmentCategory.component, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Compression clicks (0-20)"),
  ],
  ComponentType.wheelFront: [
    NumericalAdjustment(name: "Pressure", unit: "bar", min: 0, category: AdjustmentCategory.component, notes: "Front tire pressure"),
    BooleanAdjustment(name: "Insert", unit: null, category: AdjustmentCategory.component, notes: "Tire insert installed?"),
    CategoricalAdjustment(name: "Wear", options: {"New", "Used", "Worn Out"}, unit: null, category: AdjustmentCategory.component, notes: "Current state of the tire tread"),
  ],
  ComponentType.wheelRear: [
    NumericalAdjustment(name: "Pressure", unit: "bar", min: 0, category: AdjustmentCategory.component, notes: "Rear tire pressure"),
    BooleanAdjustment(name: "Insert", unit: null, category: AdjustmentCategory.component, notes: "Tire insert installed?"),
    CategoricalAdjustment(name: "Wear", options: {"New", "Used", "Worn Out"}, unit: null, category: AdjustmentCategory.component, notes: "Current state of the tire tread"),
  ],
  ComponentType.cockpit: [
    NumericalAdjustment(name: "Bar Roll", unit: "°", category: AdjustmentCategory.component, notes: "Angle of handlebars in degrees"),
    NumericalAdjustment(name: "Bar Width", unit: "mm", min: 0, category: AdjustmentCategory.component, notes: "Total width of handlebars"),
    NumericalAdjustment(name: "Bar Rise", unit: "mm", min: 0, category: AdjustmentCategory.component, notes: "The vertical distance between the center of the clamp area and the center of the bar ends."),
    NumericalAdjustment(name: "Lever Angle",  unit: "°",  category: AdjustmentCategory.component, notes: "Angle of brake levers relative to horizontal."),
    NumericalAdjustment(name: "Stem Length", unit: "mm", min: 0, category: AdjustmentCategory.component, notes: "Measured center-to-center from the fork steerer tube to the handlebar clamp."),
  ],
  ComponentType.saddle: [
    NumericalAdjustment(name: "Saddle Tilt", unit: "°", category: AdjustmentCategory.component, notes: "Angle of the saddle relative to horizontal"),
    NumericalAdjustment(name: "Saddle Fore/Aft", unit: "mm", category: AdjustmentCategory.component, notes: "Position of the saddle on the rails"),
  ],
  ComponentType.seatpost: [
    NumericalAdjustment(name: "Saddle Height", unit: "mm", min: 0, category: AdjustmentCategory.component, notes: "Distance from Bottom Bracket to top of saddle"),
    NumericalAdjustment(name: "Dropper Pressure", unit: "psi", min: 0, category: AdjustmentCategory.component, notes: "Air pressure for the dropper post return"),
  ],
  ComponentType.pedal: [
    StepAdjustment(name: "Clipless Spring Tension", unit: null, step: 1, min: 0, max: 20, category: AdjustmentCategory.component, visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial, notes: "Release tension setting for clipless pedals"),
  ],
  ComponentType.motor: [
    NumericalAdjustment(name: "Max Power", unit: "W", min: 0, category: AdjustmentCategory.component, notes: "Maximum motor power output"),
    NumericalAdjustment(name: "Max Torque", unit: "Nm", min: 0, category: AdjustmentCategory.component, notes: "Maximum motor torque"),
    CategoricalAdjustment(name: "Mode", notes: "Current assistance level", unit: null, category: AdjustmentCategory.component, options: {"Eco", "Trail", "Turbo", "Boost", "Auto"}),
  ],
  ComponentType.equipment: [
    BooleanAdjustment(name: "Backpack", notes: "Wearing a backpack? Yes/No", unit: null, category: AdjustmentCategory.equipment),
    CategoricalAdjustment(name: "Upper clothing layer 1", notes: "First clothing layer from inside (e.g. thermal shirt, ...)", unit: null, category: AdjustmentCategory.equipment, options: {"my Clothing Item A", "my Clothing Item B"}),
    CategoricalAdjustment(name: "Upper clothing layer 2", notes: "Second clothing layer from inside (e.g. wind jacket, ...)", unit: null, category: AdjustmentCategory.equipment, options: {"my Clothing Item A", "my Clothing Item B"}),
    CategoricalAdjustment(name: "Cleat Position", notes: "Shoe cleat fore/aft or lateral position", unit: null, category: AdjustmentCategory.equipment, options: {"Forward", "Neutral", "Rearward"}),
  ],
  ComponentType.other: [
    NumericalAdjustment(name: "Stack Height", unit: "mm", min: 0, category: AdjustmentCategory.component, notes: "Height of spacers under the stem"),
  ],
};

void showComponentAddAdjustmentBottomSheet({
  required BuildContext context,
  required ComponentType? componentType,
  bool enableDurationAdjustment = false,
  required Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset,
  required Future<void> Function<T extends Adjustment>() addAdjustment,
}) {
  showModalBottomSheet(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: sheetTitle(context, "Add Adjustment"),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        "Pre-filled Templates",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (componentType == null) 
                      Text(
                        "No templates available. Select a component type first.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      if (_adjustmentPresets[componentType] != null && _adjustmentPresets[componentType]!.isNotEmpty)
                        ..._adjustmentPresets[componentType]!.map((adjustmentPreset) => ListTile(
                          leading: Icon(adjustmentPreset.getIconData()),
                          title: Text(adjustmentPreset.name),
                          subtitle: Text(adjustmentPreset.getProperties(), style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                          onTap: () {
                            Navigator.pop(context);
                            addAdjustmentFromPreset(adjustmentPreset);
                          },
                        ))
                      else 
                        Text(
                          "No templates available.",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
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
                      title: Text("Numerical Adjustment"),
                      subtitle: Text("Pressure (psi), Length, Weight", style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () {
                        Navigator.pop(context); // Close sheet first
                        addAdjustment<NumericalAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: Text("Step Adjustment"),
                      subtitle: Text("Rebound clicks, Spacers, Increments", style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () {
                        Navigator.pop(context); // Close sheet first
                        addAdjustment<StepAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: Text("Categorical Adjustment"),
                      subtitle: Text("Compound, Brand, Style, Mode", style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () {
                        Navigator.pop(context); // Close sheet first
                        addAdjustment<CategoricalAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: Text("On/Off Adjustment"),
                      subtitle: Text("Lockout, Climb switch, Component installed? Yes/No", style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () {
                        Navigator.pop(context); // Close sheet first
                        addAdjustment<BooleanAdjustment>(); // Then execute logic
                      },
                    ),
                    if (context.read<AppSettings>().enableTextAdjustment)
                      ListTile(
                        leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                        title: Text("Text Adjustment"),
                        subtitle: Text("Notes, advanced settings details", style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                        onTap: () {
                          Navigator.pop(context); // Close sheet first
                          addAdjustment<TextAdjustment>(); // Then execute logic
                        },
                      ),
                    if (enableDurationAdjustment)
                      ListTile(
                        leading: Icon(DurationAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                        title: Text("Duration Adjustment"),
                        subtitle: Text("", style: const TextStyle(fontSize: 12)),  //TODO
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                        onTap: () {
                          Navigator.pop(context); // Close sheet first
                          addAdjustment<DurationAdjustment>(); // Then execute logic
                        },
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
  