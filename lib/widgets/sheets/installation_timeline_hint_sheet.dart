import 'package:flutter/material.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/installation.dart';
import '../display_installation_timeline.dart';
import 'sheet_header.dart';

Future<bool> showInstallationTimelineHintSheet(
  BuildContext context, {
  required Component component,
}) async {
  return await showModalBottomSheet<bool>(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        builder: (context) => _InstallationTimelineHintSheet(component: component),
      ) ??
      false;
}

/// Settings variant with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showInstallationTimelineSettingSheet(
  BuildContext context, {
  required bool value,
}) {
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _InstallationTimelineHintSheet(value: value),
  );
}

class _InstallationTimelineHintSheet extends StatelessWidget {
  const _InstallationTimelineHintSheet({this.component, this.value});

  final Component? component;
  final bool? value;

  static Map<String, Bike> _exampleBikes(AppLocalizations l10n) => {
    'trail-bike': Bike(id: 'trail-bike', name: l10n.installationHintExampleTrailBike, person: null),
    'enduro-bike': Bike(id: 'enduro-bike', name: l10n.installationHintExampleEnduroBike, person: null),
  };

  Component _exampleComponent(AppLocalizations l10n) {
    final now = DateTime.now();

    Installation event(String? bikeId, int daysAgo, int hour, int minute) {
      final localDate = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
      return Installation(
        parent: bikeId,
        dateTimeUTC: localDate.toUtc(),
        dateTimeLocal: localDate,
      );
    }

    final base = component ??
        Component(
          name: ComponentType.fork.label(l10n),
          componentType: ComponentType.fork,
          installations: const [],
        );
    return base.copyWith(
      installations: [
        event('trail-bike', 88, 9, 30),
        event(null, 43, 14, 15),
        event('enduro-bike', 11, 18, 45),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final exampleComponent = _exampleComponent(l10n);
    final value = this.value;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: l10n.installationHintTitle,
            leadingIcon: const Icon(Icons.history),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.installationHintBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    [
                      l10n.installationHintWithout,
                      if (value == null) l10n.installationHintChangeAnytime,
                    ].join(' '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.installationHintExample,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        DisplayInstallationTimeline(
                          component: exampleComponent,
                          bikes: _exampleBikes(l10n),
                          components: const {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (value == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(l10n.installationHintActivate),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.installationHintDecline),
                  ),
                ],
              ),
            )
          else
            RadioGroup<bool>(
              groupValue: value,
              onChanged: (selected) => Navigator.pop(context, selected),
              child: Column(
                children: [
                  RadioListTile(value: false, title: Text(l10n.valueOff)),
                  RadioListTile(value: true, title: Text(l10n.valueOn)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
