import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../current_setup_badge.dart';
import '../items/setup_tile_header.dart';
import '../sticky_section.dart';
import '../timeline_day_header.dart';
import 'sheet_header.dart';

/// Lists [options] newest first, grouped by day; the [suggestedId] one is highlighted.
Future<Setup?> showPickSetupSheet(
  BuildContext context, {
  required String title,
  required List<Setup> options,
  String? suggestedId,
}) {
  final sorted = [...options]..sort((a, b) => b.datetimeLocal.compareTo(a.datetimeLocal));
  final sections = <({DateTime day, List<Setup> setups})>[];
  for (final setup in sorted) {
    final local = setup.datetimeLocal;
    final day = DateTime(local.year, local.month, local.day);
    if (sections.isEmpty || sections.last.day != day) {
      sections.add((day: day, setups: []));
    }
    sections.last.setups.add(setup);
  }

  return showModalBottomSheet<Setup>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: title),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final section in sections)
                  StickySection(
                    header: TimelineDayHeader(day: section.day, margin: EdgeInsets.zero),
                    content: Column(
                      children: [
                        for (var index = 0; index < section.setups.length; index++) ...[
                          _PickSetupTile(
                            setup: section.setups[index],
                            suggested: section.setups[index].id == suggestedId,
                            onTap: () => Navigator.pop(context, section.setups[index]),
                          ),
                          if (index + 1 < section.setups.length) const Divider(height: 1),
                        ],
                      ],
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

class _PickSetupTile extends StatelessWidget {
  final Setup setup;
  final bool suggested;
  final VoidCallback onTap;

  const _PickSetupTile({required this.setup, required this.suggested, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final timeText = DateFormat(appSettings.timeFormat).format(setup.datetimeLocal);
    final isCurrent = appRepository.setupHistory.isCurrent(setup.id);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SetupTileHeader(
                setup: setup,
                dateTimeText: timeText,
                metadata: SetupTileHeader.metadataOf(setup, appSettings),
                badge: suggested || isCurrent
                    ? Wrap(
                        spacing: 4,
                        children: [
                          if (suggested) const _SuggestedBadge(),
                          if (isCurrent) const CurrentSetupBadge(),
                        ],
                      )
                    : null,
                showSetupIcon: true,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16.0),
          ],
        ),
      ),
    );
  }
}

class _SuggestedBadge extends StatelessWidget {
  const _SuggestedBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        'Suggested',
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
