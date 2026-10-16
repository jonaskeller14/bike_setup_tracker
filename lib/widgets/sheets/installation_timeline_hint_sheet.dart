import 'package:flutter/material.dart';

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

  static final _exampleBikes = {
    'trail-bike': Bike(id: 'trail-bike', name: 'Trail bike', person: null),
    'enduro-bike': Bike(id: 'enduro-bike', name: 'Enduro bike', person: null),
  };

  Component _exampleComponent() {
    final now = DateTime.now();

    Installation event(String? bikeId, int daysAgo, int hour, int minute) {
      final localDate = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
      return Installation(
        parent: bikeId,
        dateTimeUTC: localDate.toUtc(),
        dateTimeLocal: localDate,
      );
    }

    final base = component ?? Component(name: 'Fork', componentType: ComponentType.fork, installations: const []);
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
    final exampleComponent = _exampleComponent();
    final value = this.value;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(
            title: 'Installation history',
            leadingIcon: Icon(Icons.history),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track when you install, remove, move, or archive components. '
                    'Set the date for each change to keep an accurate history. '
                    'This lets your setups show only the components that were installed on the bike at that time.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Without installation history, the app only saves the bike where this component is installed now. '
                    'It does not save past installs or removals.'
                    '${value == null ? ' You can change this anytime in Settings.' : ''}',
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
                          'Example timeline',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        DisplayInstallationTimeline(
                          component: exampleComponent,
                          bikes: _exampleBikes,
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
                    label: const Text('Activate now'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continue without tracking'),
                  ),
                ],
              ),
            )
          else
            RadioGroup<bool>(
              groupValue: value,
              onChanged: (selected) => Navigator.pop(context, selected),
              child: const Column(
                children: [
                  RadioListTile(value: false, title: Text('Off')),
                  RadioListTile(value: true, title: Text('On')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
