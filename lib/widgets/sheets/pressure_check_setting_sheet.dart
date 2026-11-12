import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
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
String pressureCheckComponentTypesSummary(Set<ComponentType> hidden, AppLocalizations l10n) {
  final total = ComponentType.values.length;
  if (hidden.isEmpty) return l10n.pressureCheckTypesAll;
  if (hidden.length > 3) return l10n.pressureCheckTypesCount(total - hidden.length, total);
  return l10n.pressureCheckTypesAllExcept(
    ComponentType.values.where(hidden.contains).map((type) => type.label(l10n)).join(', '),
  );
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
          SheetHeader(title: context.l10n.featuresPressureCheck, leadingIcon: const Icon(Icons.compress)),
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
                      context.l10n.pressureCheckSettingIntro,
                      style: muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(context.l10n.pressureCheckEnabled),
                    value: enabled,
                    onChanged: (v) => appSettings.enablePressureAssistant = v,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SheetSectionTitle(title: context.l10n.pressureCheckThresholdTitle),
                        Text(
                          context.l10n.pressureCheckThresholdHint,
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
                        SheetSectionTitle(title: context.l10n.pressureCheckTypesTitle),
                        Text(context.l10n.pressureCheckTypesHint, style: muted),
                      ],
                    ),
                  ),
                  ListTile(
                    enabled: enabled,
                    title: Text(pressureCheckComponentTypesSummary(appSettings.pressureCheckHiddenComponentTypes, context.l10n)),
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
