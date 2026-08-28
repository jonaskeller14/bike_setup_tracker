import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';
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

class _InstallationTimelineHintSheet extends StatelessWidget {
  const _InstallationTimelineHintSheet({required this.component});

  final Component component;

  static final _exampleBikes = {
    'trail-bike': Bike(id: 'trail-bike', name: 'Trail bike', person: null),
    'enduro-bike': Bike(id: 'enduro-bike', name: 'Enduro bike', person: null),
  };

  Component _exampleComponent() {
    final now = DateTime.now();

    Installation event(String? bikeId, Duration ago) {
      final localDate = now.subtract(ago);
      return Installation(
        parent: bikeId,
        dateTimeUTC: localDate.toUtc(),
        dateTimeLocal: localDate,
      );
    }

    return component.copyWith(
      installations: [
        event('trail-bike', const Duration(days: 90)),
        event(null, const Duration(days: 45)),
        event('enduro-bike', const Duration(days: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exampleComponent = _exampleComponent();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(
            title: 'Track installation history?',
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
                    'Keep a dated history whenever you install, uninstall, move, or archive a component. '
                    'You can review past bike usage and correct the date before saving each change.',
                    style: theme.textTheme.bodyMedium,
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.history),
                  label: const Text('Activate installation timeline'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No thanks — don't ask again"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
