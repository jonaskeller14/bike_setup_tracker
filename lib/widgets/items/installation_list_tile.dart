import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/installation.dart';
import '../../models/component/resolved_installation.dart';
import '../../repositories/app_repository.dart';
import 'tile_meta_row.dart';

class InstallationListTile extends StatelessWidget {
  final ResolvedInstallation componentInstallation;
  final VoidCallback? onTap;
  final bool showDate;

  const InstallationListTile({
    super.key,
    required this.componentInstallation,
    this.onTap,
    this.showDate = true,
  });

  static IconData _parentIcon(
    InstallationParentType type,
    String? parentId,
    AppRepository appRepository,
  ) => switch (type) {
        InstallationParentType.bike => Bike.iconData,
        InstallationParentType.component =>
          appRepository.components[parentId]?.componentType.getIconData() ?? Component.iconData,
        InstallationParentType.none => Icons.shelves,
        InstallationParentType.archived => Icons.inventory_2_outlined,
      };

  static String _parentLabel(
    InstallationParentType type,
    String? parentId,
    AppRepository appRepository,
    AppLocalizations l10n,
  ) => switch (type) {
        InstallationParentType.bike => appRepository.bikes[parentId]?.name ?? l10n.bikeNotFound,
        InstallationParentType.component => appRepository.components[parentId]?.name ?? l10n.componentNotFound,
        InstallationParentType.none => l10n.timelineUninstalled,
        InstallationParentType.archived => l10n.timelineArchive,
      };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final l10n = context.l10n;
    final originParentType = componentInstallation.originParentType ?? InstallationParentType.none;
    final targetParentType = componentInstallation.installation.parentType;

    // Deinstallation/archival: the target ("Uninstalled"/"Archive") is already
    // implied by the title, so show where the component came from instead.
    final isDeinstallation = targetParentType != InstallationParentType.bike &&
        targetParentType != InstallationParentType.component;
    final showBikeInfo = !isDeinstallation || !componentInstallation.isInitial;

    final displayParentType = isDeinstallation ? originParentType : targetParentType;
    final displayParentId = isDeinstallation
        ? componentInstallation.originParent
        : componentInstallation.installation.parent;
    final isDisplayError = displayParentId != null && switch (displayParentType) {
      InstallationParentType.bike => !appRepository.bikes.containsKey(displayParentId),
      InstallationParentType.component => !appRepository.components.containsKey(displayParentId),
      InstallationParentType.none || InstallationParentType.archived => false,
    };

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
          scaleX: isDeinstallation ? -0.7 : 0.7,
          child: const Icon(Icons.arrow_right_alt, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        componentInstallation.label(l10n),
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
                  icon: _parentIcon(displayParentType, displayParentId, appRepository),
                  text: _parentLabel(displayParentType, displayParentId, appRepository, l10n),
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
