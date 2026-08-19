import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../current_setup_badge.dart';
import '../sheets/sheet.dart';

class SetupComparisonHeader extends StatelessWidget {
  final VoidCallback? onRestoreB;

  const SetupComparisonHeader({super.key, this.onRestoreB});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surface,
      title: sheetTitle(context, 'Compare setups'),
      actions: [
        if (onRestoreB != null)
          Tooltip(
            message: 'Restore setup B as current',
            child: Semantics(
              button: true,
              label: 'Restore setup B as current',
              child: FilledButton.tonalIcon(
                onPressed: onRestoreB,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Restore B'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
        const SizedBox(width: 8),
        sheetCloseButton(context),
        const SizedBox(width: 16),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }
}

class SetupComparisonSummary extends StatelessWidget {
  final Setup setupA;
  final Setup setupB;

  const SetupComparisonSummary({
    super.key,
    required this.setupA,
    required this.setupB,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
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
