import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../current_setup_badge.dart';
import '../sheets/sheet.dart';

class SetupComparisonHeader extends StatelessWidget {
  final Setup setupA;
  final Setup setupB;
  final int differenceCount;
  final bool differencesOnly;
  final ValueChanged<bool> onDifferencesOnlyChanged;

  const SetupComparisonHeader({
    super.key,
    required this.setupA,
    required this.setupB,
    required this.differenceCount,
    required this.differencesOnly,
    required this.onDifferencesOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: sheetTitle(context, 'Compare setups')),
                sheetCloseButton(context),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _SetupIdentity(
                    key: const Key('compare-identity-a'),
                    setup: setupA,
                    dateFormat: appSettings.dateFormat,
                    timeFormat: appSettings.timeFormat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SetupIdentity(
                    key: const Key('compare-identity-b'),
                    setup: setupB,
                    dateFormat: appSettings.dateFormat,
                    timeFormat: appSettings.timeFormat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final count = Text(
                  '$differenceCount ${differenceCount == 1 ? 'difference' : 'differences'}',
                  style: Theme.of(context).textTheme.labelLarge,
                );
                final filter = SegmentedButton<bool>(
                  key: const Key('compare-filter-control'),
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Differences')),
                    ButtonSegment(value: false, label: Text('All')),
                  ],
                  selected: {differencesOnly},
                  onSelectionChanged: (selection) => onDifferencesOnlyChanged(selection.single),
                );
                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      count,
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerRight, child: filter),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: count),
                    filter,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupIdentity extends StatelessWidget {
  final Setup setup;
  final String dateFormat;
  final String timeFormat;

  const _SetupIdentity({super.key, required this.setup, required this.dateFormat, required this.timeFormat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateTime =
        '${DateFormat(dateFormat).format(setup.datetimeLocal)} • ${DateFormat(timeFormat).format(setup.datetimeLocal)}';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  setup.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (setup.isCurrent) ...[
                const SizedBox(width: 4),
                const CurrentSetupBadge(),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            dateTime,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
