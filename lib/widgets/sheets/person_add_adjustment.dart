import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/adjustment/adjustment.dart';
import '../../pages/adjustment/boolean_adjustment_page.dart';
import '../../pages/adjustment/categorical_adjustment_page.dart';
import '../../pages/adjustment/numerical_adjustment_page.dart';
import '../../pages/adjustment/step_adjustment_page.dart';
import '../../pages/adjustment/text_adjustment_page.dart';
import 'sheet.dart';

 final List<Adjustment> _adjustmentPresets = [
  NumericalAdjustment(name: 'Riding weight', unit: 'kg', min: 0.0, notes: "Weight including all gear (helmet, shoes, hydration pack)."), 
  NumericalAdjustment(name: 'Height', unit: 'cm', min: 0.0, notes: "Body height"),
  CategoricalAdjustment(name: 'Riding Style', unit: null, options: {'Plush/Comfort', 'Balanced', 'Aggressive/Race'}, notes: "Aggressive riders usually require higher support (more compression damping)."),
];

void showPersonAddAdjustmentBottomSheet({
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
                leading: Icon(NumericalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                title: Text("Numerical Attribute"),
                subtitle: Text("Body Weight, Height, Age", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<NumericalAdjustment>(const NumericalAdjustmentPage()); // Then execute logic
                },
              ),
              ListTile(
                leading: Icon(StepAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                title: Text("Step Attribute"),
                subtitle: Text("Increments", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<StepAdjustment>(const StepAdjustmentPage()); // Then execute logic
                },
              ),
              ListTile(
                leading: Icon(CategoricalAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                title: Text("Categorical Attribute"),
                subtitle: Text("Training status, Riding Gear, Riding style", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  Navigator.pop(context); // Close sheet first
                  addAdjustment<CategoricalAdjustment>(const CategoricalAdjustmentPage()); // Then execute logic
                },
              ),
              ListTile(
                leading: Icon(BooleanAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
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
                  leading: Icon(TextAdjustment.iconData, color: Theme.of(context).colorScheme.primary),
                  title: Text("Text Attribute"),
                  subtitle: Text("Flexible field for any other attribute", style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () {
                    Navigator.pop(context); // Close sheet first
                    addAdjustment<TextAdjustment>(const TextAdjustmentPage()); // Then execute logic
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
  