import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../models/setup.dart';
import '../../models/bike.dart';
import '../../models/weather.dart';
import '../../models/app_settings.dart';
import '../lists/adjustment_compact_display_list.dart';
import '../../utils/setup_actions.dart';

class SetupListCard extends StatelessWidget {
  final String setupId;
  final void Function()? onTap;
  final bool displayOnlyChanges;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;

  const SetupListCard({
    super.key,
    required this.setupId,
    required this.onTap,
    required this.displayOnlyChanges,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    required this.displayRatingAdjustmentValues,
  });

  Widget _setupCardCurrentLabel(BuildContext context) {
    return Positioned(
      top: -1, 
      right: -1, 
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(12 / 2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          'Current',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  ListTile _setupListTile(BuildContext context, Setup setup) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      minTileHeight: 0,
      titleAlignment: ListTileTitleAlignment.top,
      title: Text(
        setup.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
                  Icon(Icons.calendar_month, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Text(
                    DateFormat(appSettings.dateFormat).format(setup.datetimeLocal),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.access_time, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      DateFormat(appSettings.timeFormat).format(setup.datetimeLocal),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(
                    Bike.iconData,
                    size: 13, 
                    color: bikes.containsKey(setup.bike) 
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
                  ),
                  Flexible(
                    child: Text(
                      bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
                      style: TextStyle(
                        color: bikes.containsKey(setup.bike)
                            ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                            : Theme.of(context).colorScheme.error, 
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (setup.place != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(Icons.location_pin, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (setup.weather?.currentTemperature != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(Weather.currentTemperatureIconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                  ],
                )
              ],
              if (setup.weather?.condition != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(setup.weather?.condition?.getIconData() ?? Icons.question_mark, size: 13, color: setup.weather?.condition?.getColor()),
                    Flexible(
                      child: Text(
                        setup.weather?.condition?.value ?? "-",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              if (appSettings.enableSetupTags) 
                ...setup.tags.map((tag) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Icon(Icons.tag, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      Flexible(
                        child: Text(
                          tag,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ),
                    ],
                  );
                })
            ],
          ),
          if (setup.notes != null && setup.notes!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(
                    Icons.notes,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    setup.notes!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: PopupMenuButton<_SetupListCardPopupMenuButtonOptions>(
        onSelected: (_SetupListCardPopupMenuButtonOptions value) {
          switch (value) {
            case _SetupListCardPopupMenuButtonOptions.edit: SetupActions.editSetup(context, setup: setup);
            case _SetupListCardPopupMenuButtonOptions.share: SetupActions.shareSetup(context, setup: setup);
            case _SetupListCardPopupMenuButtonOptions.restore: SetupActions.duplicateSetup(context, setup: setup);
            case _SetupListCardPopupMenuButtonOptions.remove: SetupActions.removeSetup(context, setup: setup);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_SetupListCardPopupMenuButtonOptions>>[
          const PopupMenuItem<_SetupListCardPopupMenuButtonOptions>(
            value: _SetupListCardPopupMenuButtonOptions.edit,
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 10),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem<_SetupListCardPopupMenuButtonOptions>(
            value: _SetupListCardPopupMenuButtonOptions.share,
            child: Row(
              children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 10),
                Text('Share'),
              ],
            ),
          ),
          const PopupMenuItem<_SetupListCardPopupMenuButtonOptions>(
            value: _SetupListCardPopupMenuButtonOptions.restore,
            child: Row(
              children: [
                Icon(Icons.restore, size: 20),
                SizedBox(width: 10),
                Text('Restore'),
              ],
            ),
          ),
          const PopupMenuItem<_SetupListCardPopupMenuButtonOptions>(
            value: _SetupListCardPopupMenuButtonOptions.remove,
            child: Row(
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 10),
                Text('Remove'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final setups = appRepository.setups;
    final components = appRepository.components;
    final persons = appRepository.persons;
    final ratings = appRepository.ratings;
    final setup = setups[setupId];
    if (setup == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: setup.isCurrent 
          ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ))
          : null,
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [ 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _setupListTile(context, setup),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: AdjustmentCompactDisplayList(
                    components: [for (var c in components.values) c, for (var p in persons.values) p, for (var r in ratings.values) r],
                    adjustmentValues: {for (var e in setup.personAdjustmentValues.entries) e.key: e.value, for (var e in setup.bikeAdjustmentValues.entries) e.key: e.value, for (var e in setup.ratingAdjustmentValues.entries) e.key: e.value},
                    previousAdjustmentValues: {
                      for (var e in setup.previousBikeAdjustmentValues.entries) e.key: e.value, 
                      for (var e in setup.previousPersonAdjustmentValues.entries) e.key: e.value,
                      for (var e in setup.previousRatingAdjustmentValues.entries) e.key: e.value,
                    },
                    showComponentIcons: true,
                    highlightInitialValues: true,
                    displayOnlyChanges: displayOnlyChanges,
                    displayBikeAdjustmentValues: displayBikeAdjustmentValues,
                    displayPersonAdjustmentValues: displayPersonAdjustmentValues,
                    displayRatingAdjustmentValues: displayRatingAdjustmentValues,
                  ),
                ),
              ],
            ),
            if (setup.isCurrent)
              _setupCardCurrentLabel(context),
          ],
        ),
      ),
    );
  }
}

enum _SetupListCardPopupMenuButtonOptions {
  edit,
  share,
  restore,
  remove,
}
