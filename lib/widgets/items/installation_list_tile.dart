import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';
import 'tile_meta_row.dart';

class InstallationListTile extends StatelessWidget {
  final ComponentInstallation componentInstallation;
  final VoidCallback? onTap;
  final bool showDate;

  const InstallationListTile({
    super.key,
    required this.componentInstallation,
    this.onTap,
    this.showDate = true,
  });

  static IconData _bikeIcon(InstallationParentType type) => switch (type) {
        InstallationParentType.bike => Bike.iconData,
        InstallationParentType.none => Icons.shelves,
        InstallationParentType.archived => Icons.inventory_2_outlined,
      };

  static String _bikeLabel(InstallationParentType type, String bikeName) => switch (type) {
        InstallationParentType.bike => bikeName,
        InstallationParentType.none => 'Uninstalled',
        InstallationParentType.archived => 'Archive',
      };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    final originParentType = componentInstallation.originParentType ?? InstallationParentType.none;
    final targetParentType = componentInstallation.installation.parentType;

    // Deinstallation/archival: the target ("Uninstalled"/"Archive") is already
    // implied by the title, so show where the component came from instead.
    final isDeinstallation = targetParentType != InstallationParentType.bike;
    final showBikeInfo = !isDeinstallation || !componentInstallation.isInitial;

    final displayParentType = isDeinstallation ? originParentType : targetParentType;
    final displayBikeId = isDeinstallation
        ? componentInstallation.originParent
        : componentInstallation.installation.parent;
    final displayBikeName = bikes[displayBikeId]?.name ?? "BIKE NOT FOUND";
    final isDisplayError = displayBikeId != null && !bikes.containsKey(displayBikeId);

    final timeText = DateFormat(appSettings.timeFormat).format(componentInstallation.installation.dateTimeLocal);
    final dateText = DateFormat(appSettings.dateFormat).format(componentInstallation.installation.dateTimeLocal);

    return ListTile(
      onTap: onTap,
      titleAlignment: ListTileTitleAlignment.top,
      minLeadingWidth: 0,
      horizontalTitleGap: 8,
      leading: Padding(
        padding: EdgeInsets.zero,
        child: Transform.scale(
          scaleX: targetParentType == InstallationParentType.bike ? 0.7 : -0.7,
          child: const Icon(Icons.arrow_right_alt, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        componentInstallation.label,
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
              if (showBikeInfo)
                TileMetaRow(
                  icon: _bikeIcon(displayParentType),
                  text: _bikeLabel(displayParentType, displayBikeName),
                  isError: isDisplayError,
                ),
            ],
          ),
        ],
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      minTileHeight: 0,
      minVerticalPadding: 0,
    );
  }
}
