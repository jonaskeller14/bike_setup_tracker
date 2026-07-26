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

  Widget _subtitleRow(BuildContext context, IconData icon, String text, {bool isError = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(icon, size: 12, color: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

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
        emphasized ? scheme.onSurface : scheme.onSurfaceVariant.withValues(alpha: 0.6);
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
    final dateText = DateFormat(appSettings.dateFormat).format(row.anchorDateLocal);

    final componentType = row.removed.component.componentType;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            titleAlignment: ListTileTitleAlignment.top,
            minLeadingWidth: 0,
            horizontalTitleGap: 8,
            leading: const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.swap_horiz,
              ),
            ),
            title: Text(
              "Replaced ${componentType.label}",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      showDate ? "$dateText • $timeText" : timeText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    _subtitleRow(
                      context,
                      Bike.iconData,
                      bikeName,
                      isError: isBikeError,
                    ),
                  ],
                ),
              ],
            ),
            dense: true,
            visualDensity: VisualDensity.compact,
            minTileHeight: 0,
            minVerticalPadding: 0,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
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
      ),
    );
  }
}
