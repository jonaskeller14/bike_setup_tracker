import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import 'sheet.dart';

 final List<Adjustment> _adjustmentPresets = [
  NumericalAdjustment(name: 'Riding weight', unit: 'kg', min: 0.0, notes: "Weight including all gear (helmet, shoes, hydration pack)."), 
  NumericalAdjustment(name: 'Height', unit: 'cm', min: 0.0, notes: "Body height"),
  CategoricalAdjustment(name: 'Riding Style', unit: null, options: {'Plush/Comfort', 'Balanced', 'Aggressive/Race'}, notes: "Aggressive riders usually require higher support (more compression damping)."),
];

void showPersonAddAdjustmentBottomSheet({
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
              child: sheetTitle(context, "Add Attribute"),
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
                      leading: Icon(NumericalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Numerical Attribute"),
                      subtitle: const Text("Body Weight, Height, Age", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<NumericalAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Step Attribute"),
                      subtitle: const Text("Increments", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<StepAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Categorical Attribute"),
                      subtitle: const Text("Training status, Riding Gear, Riding style", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<CategoricalAdjustment>(); // Then execute logic
                      },
                    ),
                    ListTile(
                      leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                      title: const Text("On/Off Attribute"),
                      subtitle: const Text("Wearing a backpack?", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet first
                        await addAdjustment<BooleanAdjustment>(); // Then execute logic
                      },
                    ),
                    if (context.read<AppSettings>().enableTextAdjustment)
                      ListTile(
                        leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                        title: const Text("Text Attribute"),
                        subtitle: const Text("Flexible field for any other attribute", style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                        onTap: () async {
                          Navigator.pop(context); // Close sheet first
                          await addAdjustment<TextAdjustment>(); // Then execute logic
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
  