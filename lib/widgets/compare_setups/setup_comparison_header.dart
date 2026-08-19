import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../current_setup_highlight.dart';
import '../sheets/sheet.dart';

class SetupComparisonHeader extends StatelessWidget {
  const SetupComparisonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: false,
      automaticallyImplyLeading: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surface,
      title: sheetTitle(context, 'Compare setups'),
      actions: [
        const SizedBox(width: 8),
        sheetCloseButton(context),
        const SizedBox(width: 16),
      ],
    );
  }
}

class SetupComparisonIdentities extends StatelessWidget {
  final Setup setupA;
  final Setup setupB;
  final VoidCallback? onTapA;
  final VoidCallback? onTapB;

  const SetupComparisonIdentities({
    super.key,
    required this.setupA,
    required this.setupB,
    this.onTapA,
    this.onTapB,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return PinnedHeaderSliver(
      child: ColoredBox(
        key: const Key('compare-identity-band'),
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _SetupIdentity(
                      surfaceKey: const Key('compare-identity-a'),
                      side: 'A',
                      setup: setupA,
                      dateFormat: appSettings.dateFormat,
                      timeFormat: appSettings.timeFormat,
                      onTap: onTapA,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SetupIdentity(
                      surfaceKey: const Key('compare-identity-b'),
                      side: 'B',
                      setup: setupB,
                      dateFormat: appSettings.dateFormat,
                      timeFormat: appSettings.timeFormat,
                      onTap: onTapB,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupIdentity extends StatelessWidget {
  final Key surfaceKey;
  final String side;
  final Setup setup;
  final String dateFormat;
  final String timeFormat;
  final VoidCallback? onTap;

  const _SetupIdentity({
    required this.surfaceKey,
    required this.side,
    required this.setup,
    required this.dateFormat,
    required this.timeFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateTime =
        '${DateFormat(dateFormat).format(setup.datetimeLocal)} • ${DateFormat(timeFormat).format(setup.datetimeLocal)}';
    final radius = BorderRadius.circular(12);
    final content = InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                side,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setup.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
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
            ),
          ],
        ),
      ),
    );
    return Material(
      key: surfaceKey,
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: setup.isCurrent
          ? CurrentSetupHighlight(
              child: content,
            )
          : content,
    );
  }
}
