import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/setup.dart';
import '../current_setup_badge.dart';
import '../current_setup_highlight.dart';
import '../sheets/sheet.dart';

/// Horizontal inset of the band's content, matching the comparison cards below it.
const double _bandInset = 16;

/// Gap between the two identities, matching the paired cards below them.
const double _bandGap = 8;

/// Gutters left by a setup menu on the side it edits and on the opposite side.
const double _menuNearGutter = 8;
const double _menuFarGutter = 32;

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
  final VoidCallback? onSwap;
  final bool animateSwap;

  const SetupComparisonIdentities({
    super.key,
    required this.setupA,
    required this.setupB,
    this.setups,
    this.showBikeNames = false,
    this.bikeNamesById = const {},
    this.onSetupAChanged,
    this.onSetupBChanged,
    this.onSwap,
    this.animateSwap = false,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;
    return PinnedHeaderSliver(
      child: ColoredBox(
        key: const Key('compare-identity-band'),
        color: scheme.surfaceContainerHighest,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _CurrentColumn(isCurrent: setupA.isCurrent)),
                      Expanded(child: _CurrentColumn(isCurrent: setupB.isCurrent, barAtEnd: true)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _bandInset, vertical: 8),
                  child: Row(
                    spacing: _bandGap,
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
                          animateSwap: animateSwap,
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
                          animateSwap: animateSwap,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  width: 1,
                  child: ColoredBox(color: scheme.outlineVariant),
                ),
                if (onSwap case final onSwap?) _SwapSidesButton(onPressed: onSwap),
              ],
            ),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

/// Marks the half of the band holding the current setup, bleeding to the screen
/// edge on its outer side and stopping at the seam on its inner side.
class _CurrentColumn extends StatelessWidget {
  final bool isCurrent;
  final bool barAtEnd;

  const _CurrentColumn({required this.isCurrent, this.barAtEnd = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isCurrent
          ? CurrentSetupHighlight(barAtEnd: barAtEnd, child: const SizedBox.expand())
          : const SizedBox.shrink(),
    );
  }
}

class _SwapSidesButton extends StatelessWidget {
  static const double size = 32;

  final VoidCallback onPressed;

  const _SwapSidesButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      key: const Key('compare-swap-sides'),
      tooltip: 'Swap A and B',
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: size, height: size),
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.swap_horiz),
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
  final bool animateSwap;

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
    this.animateSwap = false,
  });

  bool get _isLeading => side == 'A';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateTime =
        '${DateFormat(dateFormat).format(setup.datetimeLocal)} • ${DateFormat(timeFormat).format(setup.datetimeLocal)}';
    // The swap button straddles the seam, so each side keeps its inner edge clear.
    final content = Padding(
      padding: _isLeading ? const EdgeInsets.fromLTRB(8, 8, 16, 8) : const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
      duration: Duration(milliseconds: animateSwap ? 220 : 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: animateSwap
          ? (_isLeading ? _swapInFromEnd : _swapInFromStart)
          : _fadeInPlace,
      child: KeyedSubtree(
        key: ValueKey(setup.id),
        child: content,
      ),
    );
    Material surface(Widget child) => Material(
      key: surfaceKey,
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: child,
    );
    if (onSetupChanged == null || setups == null) return surface(animatedContent);

    final availableSetups = setups!.toList()..sort((a, b) => b.datetime.compareTo(a.datetime));
    return surface(
      // The band, not the screen, anchors the menu: a wide-screen sheet is narrower
      // than the window, and the menu has to lean towards the side it edits.
      LayoutBuilder(
        builder: (context, constraints) {
          final identityWidth = constraints.maxWidth;
          final bandWidth = 2 * identityWidth + _bandGap + 2 * _bandInset;
          return PopupMenuButton<Setup>(
            tooltip: 'Choose setup $side',
            enableFeedback: true,
            constraints: BoxConstraints.tightFor(width: bandWidth - _menuNearGutter - _menuFarGutter),
            offset: Offset(
              _isLeading
                  ? _menuNearGutter - _bandInset
                  : _menuFarGutter - _bandInset - _bandGap - identityWidth,
              0,
            ),
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
          );
        },
      ),
    );
  }

  // Static so AnimatedSwitcher only rebuilds its transitions when the mode changes.
  static Widget _fadeInPlace(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
        child: child,
      ),
    );
  }

  static Widget _swapInFromEnd(Widget child, Animation<double> animation) => _swap(child, animation, 1);

  static Widget _swapInFromStart(Widget child, Animation<double> animation) => _swap(child, animation, -1);

  static Widget _swap(Widget child, Animation<double> animation, double dx) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
        child: child,
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
