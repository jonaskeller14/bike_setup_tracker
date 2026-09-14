import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/strava/strava_gear.dart';
import '../../theme.dart';
import '../../utils/strava_gear_actions.dart';
import '../flash_highlight.dart';

class StravaGearLinkTile extends StatelessWidget {
  static const Duration _transitionDuration = Duration(milliseconds: 300);

  final StravaGear gear;
  final List<Bike> linkedBikes;
  final List<Bike> unlinkedBikes;
  final bool highlighted;
  final VoidCallback? onLinked;

  const StravaGearLinkTile({
    super.key,
    required this.gear,
    required this.linkedBikes,
    required this.unlinkedBikes,
    this.highlighted = false,
    this.onLinked,
  });

  bool get _isLinked => linkedBikes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FlashHighlight(
      highlighted: highlighted,
      color: Theme.of(context).extension<SnackBarColors>()!.success,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: AnimatedSwitcher(
          duration: _transitionDuration,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            _isLinked ? Icons.link : Icons.link_off,
            key: ValueKey<bool>(_isLinked),
            color: _isLinked ? null : colorScheme.error,
          ),
        ),
        title: Text(
          gear.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(
              Bike.iconData,
              size: 13,
              color: _isLinked ? colorScheme.onSurfaceVariant : colorScheme.error,
            ),
            Flexible(
              child: Text(
                _isLinked ? linkedBikes.map((b) => b.name).join(', ') : "Not linked to a bike",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: _isLinked ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8) : colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        trailing: AnimatedSwitcher(
          duration: _transitionDuration,
          child: KeyedSubtree(
            key: ValueKey<bool>(_isLinked),
            child: _isLinked ? _optionsButton(context) : _linkButton(context),
          ),
        ),
      ),
    );
  }

  Widget _optionsButton(BuildContext context) {
    return _menuButton(
      context,
      tooltip: "Options for '${gear.name}'",
      icon: const Icon(Icons.more_vert),
    );
  }

  Widget _linkButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.secondaryContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: _menuButton(
        context,
        tooltip: "Link '${gear.name}' to a bike",
        borderRadius: const BorderRadius.all(Radius.circular(100)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(Icons.add_link, size: 16, color: colorScheme.onSecondaryContainer),
              Text(
                "Link",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required String tooltip,
    Widget? child,
    Widget? icon,
    BorderRadius? borderRadius,
  }) {
    return PopupMenuButton<_StravaGearMenuOption>(
      tooltip: tooltip,
      borderRadius: borderRadius,
      icon: icon,
      onSelected: (_StravaGearMenuOption option) async {
        switch (option) {
          case _LinkToBike():
            await StravaGearActions.linkBike(context, gear: gear, bike: option.bike);
            onLinked?.call();
          case _AddNewBike():
            await StravaGearActions.addAsNewBike(context, gear: gear);
            onLinked?.call();
          case _UnlinkBike():
            await StravaGearActions.unlinkBike(context, gear: gear, bike: option.bike);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          if (_isLinked) ...[
            ...linkedBikes.map((Bike linkedBike) {
              return PopupMenuItem<_StravaGearMenuOption>(
                value: _UnlinkBike(linkedBike),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.link_off),
                    Expanded(child: Text("Unlink Bike '${linkedBike.name}'", overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
          ] else ...[
            if (unlinkedBikes.isNotEmpty) ...[
              ...unlinkedBikes.map((Bike bike) {
                return PopupMenuItem<_StravaGearMenuOption>(
                  value: _LinkToBike(bike),
                  child: Row(
                    spacing: 8,
                    children: [
                      const Icon(Icons.link),
                      Expanded(child: Text("Link to '${bike.name}'", overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem<_StravaGearMenuOption>(
              value: _AddNewBike(),
              child: Row(
                spacing: 8,
                children: [
                  Icon(Icons.add),
                  Text("Add as new Bike"),
                ],
              ),
            ),
          ],
        ];
      },
      child: child,
    );
  }
}

sealed class _StravaGearMenuOption {
  const _StravaGearMenuOption();
}

class _LinkToBike extends _StravaGearMenuOption {
  final Bike bike;
  const _LinkToBike(this.bike);
}

class _AddNewBike extends _StravaGearMenuOption {
  const _AddNewBike();
}

class _UnlinkBike extends _StravaGearMenuOption {
  final Bike bike;
  const _UnlinkBike(this.bike);
}
