import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';

class InstallationListTile extends StatelessWidget {
  final ComponentInstallation componentInstallation;
  final VoidCallback? onTap;

  const InstallationListTile({
    super.key,
    required this.componentInstallation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    final originBikeName = componentInstallation.originParent == null 
        ? "Archive" 
        : (bikes[componentInstallation.originParent]?.name ?? "BIKE NOT FOUND");
    final targetBikeName = componentInstallation.installation.parent == null 
        ? "Archive" 
        : (bikes[componentInstallation.installation.parent]?.name ?? "BIKE NOT FOUND");

    final isOriginError = componentInstallation.originParent != null && !bikes.containsKey(componentInstallation.originParent);
    final isTargetError = componentInstallation.installation.parent != null && !bikes.containsKey(componentInstallation.installation.parent);

    return ListTile(
      onTap: onTap,
      title: Text("${componentInstallation.isInitial ? 'Added' : (componentInstallation.installation.parent != null ? 'Installed' : 'Deinstalled')} '${componentInstallation.component.name}'"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
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
                    name: originBikeName,
                    isDeinstalled: componentInstallation.originParent == null,
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
                  name: targetBikeName,
                  isDeinstalled: componentInstallation.installation.parent == null,
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
  final String name;
  final bool isDeinstalled;
  final bool isError;

  const _CompactBikeLabel({
    required this.name,
    required this.isDeinstalled,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(
          isDeinstalled ? Icons.shelves : Bike.iconData,
          size: 12,
          color: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Flexible(
          child: Text(
            name,
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
