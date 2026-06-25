import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import 'sheet.dart';

final List<Adjustment> _adjustmentPresets = [
  StepAdjustment(name: "Grip", notes: "Rate grip on 1-10 scale", unit: null, category: AdjustmentCategory.rating, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
  NumericalAdjustment(name: "Bottom Outs", min: 0, unit: null, category: AdjustmentCategory.rating, notes: "How many times did the fork bottom out?"),
  BooleanAdjustment(name: "Bottom Out?", notes: "Did the fork bottom out? (Yes/No)", unit: null, category: AdjustmentCategory.rating),
  DurationAdjustment(name: "Laptime track xyz", notes: "Laptime of segment xyz", min: Duration.zero, max: null, unit: null, category: AdjustmentCategory.rating),
  CategoricalAdjustment(name: "Travel Usage", notes: "Is the O-ring 2–5mm from the end of the stanchion? Consistent bottoming out means too linear; never using full travel means too progressive or too stiff.", unit: null, category: AdjustmentCategory.rating, options: {"Not using enough", "Just right", "Bottoming out"}),
  CategoricalAdjustment(name: "Rebound Balance", notes: "When pushing down on the pedals, do the front and rear return at the same speed?", unit: null, category: AdjustmentCategory.rating, options: {"Front is faster", "Balanced", "Rear is faster"}),
  BooleanAdjustment(name: "Harshness", notes: "Does the bike feel spike-y or harsh on fast, repetitive bumps (roots/chatter)? Suggests high-speed compression is too closed.", unit: null, category: AdjustmentCategory.rating),
  BooleanAdjustment(name: "Wallowing", notes: "Does the bike feel like it dives or disappears under you in deep berms or G-outs? Suggests low-speed compression is too open.", unit: null, category: AdjustmentCategory.rating),
  BooleanAdjustment(name: "Bucking", notes: "Does the rear end feel like it's trying to overtake the front on jumps or drops? Suggests rebound is too fast.", unit: null, category: AdjustmentCategory.rating),
  BooleanAdjustment(name: "Arm Pump", notes: "Do your forearms pump up within one or two runs? Suggests bars are too stiff, grips too thin, or brake levers too far in/out.", unit: null, category: AdjustmentCategory.rating),
  CategoricalAdjustment(name: "Steering Speed", notes: "How does the steering feel? Twitchy suggests bars too narrow/stem too long. Lazy suggests bars too wide.", unit: null, category: AdjustmentCategory.rating, options: {"Twitchy", "Responsive", "Lazy"}),
  BooleanAdjustment(name: "Pinky Pain", notes: "Does the outside of your hand hurt? Suggests the bar sweep/roll is incorrect.", unit: null, category: AdjustmentCategory.rating),
  BooleanAdjustment(name: "Front End Grip", notes: "Do you have to consciously lean over the front to get the tire to bite? Suggests front end might be too high or bike is too long.", unit: null, category: AdjustmentCategory.rating),
  CategoricalAdjustment(name: "Center of Gravity", notes: "How does the bike feel in terms of position? Do you feel tucked into the bike or perched on top of it?", unit: null, category: AdjustmentCategory.rating, options: {"Perched on top", "Centered", "Tucked in"}),
  BooleanAdjustment(name: "Squirm", notes: "Does the tire feel like it's folding or rolling off the rim in hard corners? Suggests tire pressure is too low.", unit: null, category: AdjustmentCategory.rating),
  BooleanAdjustment(name: "Pinging", notes: "Does the bike feel like it's bouncing off rocks rather than absorbing them? Suggests tire pressure is too high.", unit: null, category: AdjustmentCategory.rating),
  BooleanAdjustment(name: "Vague Traction", notes: "Do you feel the front wheel tucking or sliding without warning?", unit: null, category: AdjustmentCategory.rating),
];

void showRatingAddAdjustmentBottomSheet({
  required BuildContext context,
  required Future<void> Function(Adjustment adjustment) addAdjustmentFromPreset,
  required Future<void> Function<T extends Adjustment>() addAdjustment,
}) async {
  await showModalBottomSheet(
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
              child: sheetTitle(context, "Add Metric"),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        onTap: () async {
                          Navigator.pop(context);
                          await addAdjustmentFromPreset(adjustmentPreset);
                        },
                      )),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          "Custom Metrics",
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
                      leading: Icon(NumericalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Numerical Metric"),
                      subtitle: const Text("How many times did the fork bottom out?", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<NumericalAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Step Metric"),
                      subtitle: const Text("Rate grip or confidence (on 1-10 scale)", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<StepAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Categorical Metric"),
                      subtitle: const Text("Rate based on categories (good/bad/acceptable)", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<CategoricalAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("On/Off Metric"),
                      subtitle: const Text("Did the fork bottom out? (Yes/No)", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<BooleanAdjustment>(); // Then execute logic
                      },
                    ),
                    if (context.read<AppSettings>().enableTextAdjustment)
                      ListTile(
                        leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                        title: const Text("Text Metric"),
                        subtitle: const Text("Flexible field for any other metric", style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                        onTap: () async {
                          Navigator.pop(context); // Close sheet first
                          await addAdjustment<TextAdjustment>(); // Then execute logic
                        },
                      ),
                    ListTile(
                      leading: Icon(DurationAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Duration Metric"),
                      subtitle: const Text("Perfect for recording laptimes", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<DurationAdjustment>(); // Then execute logic
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
  