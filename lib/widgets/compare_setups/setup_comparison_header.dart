import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../utils/automation_ids.dart';
import '../current_setup_highlight.dart';
import '../sheets/pick_setup.dart';
import '../sheets/sheet.dart';

/// Horizontal inset of the band's content, matching the comparison cards below it.
const double _bandInset = 16;

/// Gap between the two identities, matching the paired cards below them.
const double _bandGap = 8;

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
  final Set<String> currentSetupIds;
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
    this.currentSetupIds = const {},
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
                      Expanded(child: _CurrentColumn(isCurrent: currentSetupIds.contains(setupA.id))),
                      Expanded(child: _CurrentColumn(isCurrent: currentSetupIds.contains(setupB.id), barAtEnd: true)),
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

    return surface(
      Semantics(
        container: true,
        identifier: AutomationIds.compareSetupsSide(side),
        child: InkWell(
          onTap: () => _pickSetup(context),
          child: animatedContent,
        ),
      ),
    );
  }

  Future<void> _pickSetup(BuildContext context) async {
    final otherSide = _isLeading ? 'B' : 'A';
    final picked = await showPickSetupSheet(
      context,
      title: 'Choose setup $side',
      options: setups!.toList(),
      // Comparing a setup with itself shows nothing, so the other side's is taken.
      disabledIds: {?highlightedSetupId},
      sideLabels: {
        setup.id: side,
        ?highlightedSetupId: otherSide,
      },
      showBikeNames: showBikeNames,
      semanticsIdentifier: AutomationIds.compareSetupsOption,
    );
    if (picked != null && picked.id != setup.id) onSetupChanged!(picked);
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
}
