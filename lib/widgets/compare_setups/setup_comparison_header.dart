import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/setup.dart';
import '../current_setup_badge.dart';
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
      title: sheetTitle(context, 'Setup comparison'),
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
  final Iterable<Setup>? setups;
  final bool showBikeNames;
  final Map<String, String> bikeNamesById;
  final ValueChanged<Setup>? onSetupAChanged;
  final ValueChanged<Setup>? onSetupBChanged;

  const SetupComparisonIdentities({
    super.key,
    required this.setupA,
    required this.setupB,
    this.setups,
    this.showBikeNames = false,
    this.bikeNamesById = const {},
    this.onSetupAChanged,
    this.onSetupBChanged,
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
                spacing: 8,
                children: [
                  Expanded(
                    child: _SetupIdentity(
                      surfaceKey: const Key('compare-identity-a'),
                      side: 'A',
                      setup: setupA,
                      dateFormat: appSettings.dateFormat,
                      timeFormat: appSettings.timeFormat,
                      setups: setups,
                      showBikeNames: showBikeNames,
                      bikeNamesById: bikeNamesById,
                      highlightedSetupId: setupB.id,
                      onSetupChanged: onSetupAChanged,
                    ),
                  ),
                  Expanded(
                    child: _SetupIdentity(
                      surfaceKey: const Key('compare-identity-b'),
                      side: 'B',
                      setup: setupB,
                      dateFormat: appSettings.dateFormat,
                      timeFormat: appSettings.timeFormat,
                      setups: setups,
                      showBikeNames: showBikeNames,
                      bikeNamesById: bikeNamesById,
                      highlightedSetupId: setupA.id,
                      onSetupChanged: onSetupBChanged,
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
  final Iterable<Setup>? setups;
  final bool showBikeNames;
  final Map<String, String> bikeNamesById;
  final String? highlightedSetupId;
  final ValueChanged<Setup>? onSetupChanged;

  const _SetupIdentity({
    required this.surfaceKey,
    required this.side,
    required this.setup,
    required this.dateFormat,
    required this.timeFormat,
    this.setups,
    this.showBikeNames = false,
    this.bikeNamesById = const {},
    this.highlightedSetupId,
    this.onSetupChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateTime =
        '${DateFormat(dateFormat).format(setup.datetimeLocal)} • ${DateFormat(timeFormat).format(setup.datetimeLocal)}';
    final radius = BorderRadius.circular(12);
    final content = Padding(
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
    );
    final animatedContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(setup.id),
        child: setup.isCurrent
            ? CurrentSetupHighlight(
                child: content,
              )
            : content,
      ),
    );
    Material surface(Widget child) => Material(
      key: surfaceKey,
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    if (onSetupChanged == null || setups == null) return surface(animatedContent);

    final availableSetups = setups!.toList()..sort((a, b) => b.datetime.compareTo(a.datetime));
    final menuWidth = MediaQuery.sizeOf(context).width - 32;
    return surface(
      PopupMenuButton<Setup>(
        tooltip: 'Choose setup $side',
        enableFeedback: true,
        constraints: BoxConstraints.tightFor(width: menuWidth),
        menuPadding: EdgeInsets.zero,
        initialValue: setup,
        itemBuilder: (context) => availableSetups
            .map(
              (candidate) => _setupMenuItem(
                context,
                candidate,
                showBikeName: showBikeNames,
                bikeName: bikeNamesById[candidate.bike],
                selectedSides: {
                  if (candidate.id == setup.id) side,
                  if (candidate.id == highlightedSetupId) side == 'A' ? 'B' : 'A',
                },
              ),
            )
            .toList(growable: false),
        onSelected: onSetupChanged!,
        child: animatedContent,
      ),
    );
  }

  PopupMenuEntry<Setup> _setupMenuItem(
    BuildContext context,
    Setup candidate, {
    required Set<String> selectedSides,
    required bool showBikeName,
    required String? bikeName,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dateTime =
        '${DateFormat(dateFormat).format(candidate.datetimeLocal)} • ${DateFormat(timeFormat).format(candidate.datetimeLocal)}';
    final place = [
      candidate.place?.locality,
      candidate.place?.isoCountryCode,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    final child = Container(
      key: Key('compare-setup-option-${candidate.id}'),
      width: double.infinity,
      color: selectedSides.isEmpty ? null : scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Setup.iconData, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(candidate.displayName, overflow: TextOverflow.ellipsis)),
                          if (candidate.isCurrent) ...[
                            const SizedBox(width: 4),
                            const CurrentSetupBadge(compact: true),
                          ],
                        ],
                      ),
                    ),
                    for (final selectedSide in selectedSides) _sideBadge(context, selectedSide),
                  ],
                ),
                _pickerMetadata(context, Icons.calendar_today_outlined, dateTime),
                if (showBikeName) _pickerMetadata(context, Bike.iconData, bikeName ?? 'Unknown bike'),
                if (place.isNotEmpty) _pickerMetadata(context, Icons.location_on_outlined, place),
              ],
            ),
          ),
        ],
      ),
    );
    return PopupMenuItem<Setup>(
      value: candidate,
      padding: EdgeInsets.zero,
      child: child,
    );
  }

  Widget _sideBadge(BuildContext context, String side) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
      child: Text(side, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer)),
    );
  }

  Widget _pickerMetadata(BuildContext context, IconData icon, String text) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      spacing: 2,
      children: [
        Icon(icon, size: 11, color: color),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }
}
