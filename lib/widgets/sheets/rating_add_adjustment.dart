import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/adjustment/adjustment.dart';
import '../../pages/adjustment/boolean_adjustment_page.dart';
import '../../pages/adjustment/categorical_adjustment_page.dart';
import '../../pages/adjustment/numerical_adjustment_page.dart';
import '../../pages/adjustment/step_adjustment_page.dart';
import '../../pages/adjustment/text_adjustment_page.dart';
import '../../pages/adjustment/duration_adjustment_page.dart';
import 'sheet.dart';

final List<Adjustment> _adjustmentPresets = [
  StepAdjustment(name: "Grip", notes: "Rate grip on 1-10 scale", unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
  NumericalAdjustment(name: "Bottom Outs", min: 0, unit: null, notes: "How many times did the fork bottom out?"),
  BooleanAdjustment(name: "Bottom Out?", notes: "Did the fork bottom out? (Yes/No)", unit: null),
  DurationAdjustment(name: "Laptime track xyz", notes: "Laptime of segment xyz", min: Duration.zero, max: null, unit: null),
  CategoricalAdjustment(name: "Travel Usage", notes: "Is the O-ring 2–5mm from the end of the stanchion? Consistent bottoming out means too linear; never using full travel means too progressive or too stiff.", unit: null, options: ["Not using enough", "Just right", "Bottoming out"]),
  CategoricalAdjustment(name: "Rebound Balance", notes: "When pushing down on the pedals, do the front and rear return at the same speed?", unit: null, options: ["Front is faster", "Balanced", "Rear is faster"]),
  BooleanAdjustment(name: "Harshness", notes: "Does the bike feel spike-y or harsh on fast, repetitive bumps (roots/chatter)? Suggests high-speed compression is too closed.", unit: null),
  BooleanAdjustment(name: "Wallowing", notes: "Does the bike feel like it dives or disappears under you in deep berms or G-outs? Suggests low-speed compression is too open.", unit: null),
  BooleanAdjustment(name: "Bucking", notes: "Does the rear end feel like it's trying to overtake the front on jumps or drops? Suggests rebound is too fast.", unit: null),
  BooleanAdjustment(name: "Arm Pump", notes: "Do your forearms pump up within one or two runs? Suggests bars are too stiff, grips too thin, or brake levers too far in/out.", unit: null),
  CategoricalAdjustment(name: "Steering Speed", notes: "How does the steering feel? Twitchy suggests bars too narrow/stem too long. Lazy suggests bars too wide.", unit: null, options: ["Twitchy", "Responsive", "Lazy"]),
  BooleanAdjustment(name: "Pinky Pain", notes: "Does the outside of your hand hurt? Suggests the bar sweep/roll is incorrect.", unit: null),
  BooleanAdjustment(name: "Front End Grip", notes: "Do you have to consciously lean over the front to get the tire to bite? Suggests front end might be too high or bike is too long.", unit: null),
  CategoricalAdjustment(name: "Center of Gravity", notes: "How does the bike feel in terms of position? Do you feel tucked into the bike or perched on top of it?", unit: null, options: ["Perched on top", "Centered", "Tucked in"]),
  BooleanAdjustment(name: "Squirm", notes: "Does the tire feel like it's folding or rolling off the rim in hard corners? Suggests tire pressure is too low.", unit: null),
  BooleanAdjustment(name: "Pinging", notes: "Does the bike feel like it's bouncing off rocks rather than absorbing them? Suggests tire pressure is too high.", unit: null),
  BooleanAdjustment(name: "Vague Traction", notes: "Do you feel the front wheel tucking or sliding without warning?", unit: null),
];

void showRatingAddAdjustmentBottomSheet({
  required BuildContext context,
  required Function addAdjustmentFromPreset,
  required Function addAdjustment,
}) {
  showModalBottomSheet(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: sheetTitle(context, "Add Attribute"),
              ),
              const SizedBox(height: 16),
              if (_adjustmentPresets.isNotEmpty) ... [
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
                ..._adjustmentPresets.map((adjustmentPreset) => ListTile(
                  leading: Icon(adjustmentPreset.getIconData()),
                  title: Text(adjustmentPreset.name),
                  subtitle: Text(adjustmentPreset.getProperties(), style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    Navigator.pop(context);
                    addAdjustmentFromPreset(adjustmentPreset);
                  },
                )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "Custom Attribute",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
              ListTile(
                leading: Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
                title: Text("Numerical Attribute"),
                subtitle: Text("Body Weight, Height, Age", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<NumericalAdjustment>(const NumericalAdjustmentPage()); // Then execute logic
                },
              ),
              ListTile(
                leading: Icon(Icons.stairs_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text("Step Attribute"),
                subtitle: Text("Increments", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<StepAdjustment>(const StepAdjustmentPage()); // Then execute logic
                },
              ),
              ListTile(
                leading: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                title: Text("Categorical Attribute"),
                subtitle: Text("Training status, Riding Gear, Riding style", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<CategoricalAdjustment>(const CategoricalAdjustmentPage()); // Then execute logic
                },
              ),
              ListTile(
                leading: Icon(Icons.toggle_on, color: Theme.of(context).colorScheme.primary),
                title: Text("On/Off Attribute"),
                subtitle: Text("Wearing a backpack?", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<BooleanAdjustment>(const BooleanAdjustmentPage()); // Then execute logic
                },
              ),
              if (context.read<AppSettings>().enableTextAdjustment)
                ListTile(
                  leading: Icon(Icons.text_snippet, color: Theme.of(context).colorScheme.primary),
                  title: Text("Text Attribute"),
                  subtitle: Text("Flexible field for any other attribute", style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    Navigator.pop(context); // Close sheet first
                    addAdjustment<TextAdjustment>(const TextAdjustmentPage()); // Then execute logic
                  },
                ),
              ListTile(
                leading: Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text("Duration Attribute"),
                subtitle: Text("Perfect for recording laptimes", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<DurationAdjustment>(const DurationAdjustmentPage()); // Then execute logic
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
  