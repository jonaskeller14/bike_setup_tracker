import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import '../../utils/timeline_grouping.dart';

class ReplacementListTile extends StatelessWidget {
  final ReplacementRow row;
  final VoidCallback? onTap;
  final bool showDate;

  const ReplacementListTile({
    super.key,
    required this.row,
    this.onTap,
    this.showDate = true,
  });

  Widget _subtitleRow(BuildContext context, IconData icon, String text, {Color? color}) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(icon, size: 12, color: effectiveColor),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Where the component ended up after this event, used as the trailing
  /// destination glyph (matches the vocabulary in [InstallationListTile]).
  static IconData _destinationIcon(InstallationParentType type) => switch (type) {
        InstallationParentType.bike => Bike.iconData,
        InstallationParentType.none => Icons.shelves,
        InstallationParentType.archived => Icons.inventory_2_outlined,
      };

  /// One half of the swap: `<type icon> <name> ──→ <destination icon>`.
  ///
  /// The destination glyph is the installed-vs-removed signal (bike = the new
  /// part that went on; shelf/archive = the old part that came off), so no verb
  /// label is needed. [emphasized] keeps the freshly installed line at full
  /// tone while the removed line is muted — a secondary reinforcement of a
  /// direction that order + arrow + destination already carry. The cue is
  /// colour only (weight stays regular) so no subtitle line out-weighs the
  /// tile title. The name is [Expanded]; parented in an [IntrinsicWidth] this
  /// aligns both arrows to the end of the longer name rather than the far edge.
  Widget _componentRow(
    BuildContext context,
    ComponentInstallation ci, {
    required bool emphasized,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final nameColor =
        emphasized ? scheme.onSurface : scheme.onSurfaceVariant.withValues(alpha: 0.7);
    final glyphColor =
        emphasized ? scheme.onSurfaceVariant : scheme.onSurfaceVariant.withValues(alpha: 0.6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(ci.component.componentType.getIconData(), size: 12, color: glyphColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            ci.component.name,
            style: TextStyle(color: nameColor, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_right_alt, size: 14, color: glyphColor),
        const SizedBox(width: 3),
        Icon(_destinationIcon(ci.installation.parentType), size: 13, color: glyphColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    final bikeId = row.installed.installation.parent;
    final bikeName = bikes[bikeId]?.name ?? "BIKE NOT FOUND";
    final isBikeError = bikeId != null && !bikes.containsKey(bikeId);

    final timeFormat = DateFormat(appSettings.timeFormat);
    final removedTime = timeFormat.format(row.removed.installation.dateTimeLocal);
    final installedTime = timeFormat.format(row.installed.installation.dateTimeLocal);
    final earlierTime = row.anchorInstallation == row.removed.installation
        ? removedTime
        : installedTime;
    final laterTime = earlierTime == removedTime ? installedTime : removedTime;
    final timeText = earlierTime == laterTime ? earlierTime : "$earlierTime – $laterTime";

    final componentType = row.removed.component.componentType;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: onTap,
          titleAlignment: ListTileTitleAlignment.top,
          // contentPadding: const EdgeInsets.symmetric(horizontal: 16),//TODO
          // minVerticalPadding: 4, //TODO
          minLeadingWidth: 0,
          horizontalTitleGap: 8,
          leading: const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.swap_horiz,
              // size: 20,
              // color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // title: Text(
          //   "Replaced ${componentType.label}",
          //   overflow: TextOverflow.ellipsis,
          //   maxLines: 1,
          //   style: const TextStyle(fontWeight: FontWeight.bold),
          // ),
          title: Row(
            spacing: 6,
            children: [
              // Icon(Icons.swap_horiz, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              Flexible(
                child: Text(
                  "Replaced ${componentType.label}",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  // style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  if (showDate)
                    _subtitleRow(
                      context,
                      Icons.calendar_month,
                      DateFormat(appSettings.dateFormat).format(row.anchorDateLocal),
                    ),
                  // Time carries no icon: an HH:mm reads as a time unaided, and
                  // dropping the clock glyph thins the subtitle and lets the wider
                  // Wrap spacing separate it cleanly from the bike beside it.
                  Text(
                    timeText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  if (!showDate)
                    _subtitleRow(
                      context,
                      Bike.iconData,
                      bikeName,
                      color: isBikeError ? Theme.of(context).colorScheme.error : null,
                    ),
                ],
              ),
              if (showDate)
                _subtitleRow(
                  context,
                  Bike.iconData,
                  bikeName,
                  color: isBikeError ? Theme.of(context).colorScheme.error : null,
                ),
              const SizedBox(height: 1),
              // Sized to the longer of the two component names so the arrows and
              // destination glyphs align in one column that sits just after the
              // name — never shoved to the far edge on wide / tablet layouts.
            ],
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
          minTileHeight: 0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _componentRow(context, row.installed, emphasized: false),
                      _componentRow(context, row.removed, emphasized: false),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
