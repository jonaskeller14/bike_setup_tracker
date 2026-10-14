import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../text/sheet_section_title.dart';
import 'component_type_filter.dart';
import 'sheet_header.dart';

const List<int> _thresholdOptions = [1, 2, 3, 4, 5, 10];

/// The Pressure Check toggle, its threshold and the component types it covers.
Future<void> showPressureCheckSettingSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => const _PressureCheckSettingSheet(),
  );
}

/// "All", "All except Tire" or "28 of 30" for the component types not in [hidden].
String pressureCheckComponentTypesSummary(Set<ComponentType> hidden) {
  final total = ComponentType.values.length;
  if (hidden.isEmpty) return 'All';
  if (hidden.length > 3) return '${total - hidden.length} of $total';
  return 'All except ${ComponentType.values.where(hidden.contains).map((type) => type.label).join(', ')}';
}

class _PressureCheckSettingSheet extends StatelessWidget {
  const _PressureCheckSettingSheet();

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final enabled = appSettings.enablePressureAssistant;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Pressure Check', leadingIcon: Icon(Icons.compress)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'When adding a setup, checks whether your pump would still read the pressures you '
                      'last set. Colder or thinner air makes the same sealed chamber read differently.',
                      style: muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Enabled'),
                    value: enabled,
                    onChanged: (v) => appSettings.enablePressureAssistant = v,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SheetSectionTitle(title: 'Threshold'),
                        Text(
                          'Flag a pressure once the pump would read this much more or less than the value '
                          'you last set.',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      spacing: 6,
                      children: [
                        for (final percent in _thresholdOptions)
                          ChoiceChip(
                            label: Text('$percent %'),
                            selected: appSettings.pressureCheckThresholdPercent == percent,
                            onSelected: enabled ? (_) => appSettings.pressureCheckThresholdPercent = percent : null,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SheetSectionTitle(title: 'Component Types'),
                        Text('Skip types you check before every ride anyway, like tires.', style: muted),
                      ],
                    ),
                  ),
                  ListTile(
                    enabled: enabled,
                    leading: const Icon(Icons.category_outlined),
                    title: Text(pressureCheckComponentTypesSummary(appSettings.pressureCheckHiddenComponentTypes)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      final hidden = Set.of(appSettings.pressureCheckHiddenComponentTypes);
                      await showComponentTypeFilterSheet(
                        context: context,
                        availableComponentTypes: ComponentType.values,
                        hiddenComponentTypes: hidden,
                        onChanged: () => appSettings.pressureCheckHiddenComponentTypes = hidden,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
