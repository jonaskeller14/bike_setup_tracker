import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/installation.dart';
import '../../repositories/app_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    final originParentType = componentInstallation.originParentType ?? InstallationParentType.none;
    final targetParentType = componentInstallation.installation.parentType;

    final originBikeName = bikes[componentInstallation.originParent]?.name ?? "BIKE NOT FOUND";
    final targetBikeName = bikes[componentInstallation.installation.parent]?.name ?? "BIKE NOT FOUND";

    final isOriginError = componentInstallation.originParent != null && !bikes.containsKey(componentInstallation.originParent);
    final isTargetError = componentInstallation.installation.parent != null && !bikes.containsKey(componentInstallation.installation.parent);

    return ListTile(
      onTap: onTap,
      title: Text(componentInstallation.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              if (showDate)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(Icons.calendar_month, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Text(
                      DateFormat(appSettings.dateFormat).format(componentInstallation.installation.dateTimeLocal),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      DateFormat(appSettings.timeFormat).format(componentInstallation.installation.dateTimeLocal),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (!componentInstallation.isInitial) ...[
                Flexible(
                  child: _CompactBikeLabel(
                    parentType: originParentType,
                    bikeName: originBikeName,
                    isError: isOriginError,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ] else ...[
                 Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.arrow_forward, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              Flexible(
                child: _CompactBikeLabel(
                  parentType: targetParentType,
                  bikeName: targetBikeName,
                  isError: isTargetError,
                ),
              ),
            ],
          ),
        ],
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CompactBikeLabel extends StatelessWidget {
  final InstallationParentType parentType;
  final String bikeName;
  final bool isError;

  const _CompactBikeLabel({
    required this.parentType,
    required this.bikeName,
    this.isError = false,
  });

  IconData get _icon => switch (parentType) {
        InstallationParentType.bike => Bike.iconData,
        InstallationParentType.none => Icons.shelves,
        InstallationParentType.archived => Icons.inventory_2_outlined,
      };

  String get _label => switch (parentType) {
        InstallationParentType.bike => bikeName,
        InstallationParentType.none => 'Uninstalled',
        InstallationParentType.archived => 'Archive',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(
          _icon,
          size: 12,
          color: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Flexible(
          child: Text(
            _label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isError 
                  ? Theme.of(context).colorScheme.error 
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
