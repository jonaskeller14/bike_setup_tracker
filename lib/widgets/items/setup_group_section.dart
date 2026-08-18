import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import 'setup_group_header.dart';
import 'setup_list_tile.dart';
import 'tile_meta_row.dart';

class SetupGroupSection extends StatelessWidget {
  final List<String> setupIds;
  final void Function(Setup setup)? onTapSetup;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;

  const SetupGroupSection({
    super.key,
    required this.setupIds,
    required this.onTapSetup,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
  });

  Widget _member(BuildContext context, Setup setup, {required bool hidePlace}) {
    return SetupListTile(
      key: ValueKey(setup.id),
      setupId: setup.id,
      onTap: onTapSetup == null ? null : () => onTapSetup!(setup),
      displayBikeAdjustmentValues: displayBikeAdjustmentValues,
      displayPersonAdjustmentValues: displayPersonAdjustmentValues,
      showDate: false,
      embedded: true,
      hidePlace: hidePlace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final setups = setupIds
        .map((id) => appRepository.setups[id])
        .whereType<Setup>()
        .toList();

    if (setups.isEmpty) return const SizedBox.shrink();
    if (setups.length == 1) {
      return SetupListTile(
        setupId: setups.first.id,
        onTap: onTapSetup == null ? null : () => onTapSetup!(setups.first),
        displayBikeAdjustmentValues: displayBikeAdjustmentValues,
        displayPersonAdjustmentValues: displayPersonAdjustmentValues,
        showDate: !appSettings.enableTimelineDayHeaders,
      );
    }

    final bikes = appRepository.bikes;
    final bikeId = setups.first.bike;
    final bikeFound = bikes.containsKey(bikeId);

    // Place is shown once when all members that have one agree; divergent
    // places fall back to per-member rows rather than being hidden.
    String placeLabel(geo.Placemark place) =>
        "${place.locality}, ${place.isoCountryCode}";
    final placeLabels = setups
        .map((s) => s.place)
        .whereType<geo.Placemark>()
        .map(placeLabel)
        .toSet();
    final String? sharedPlace = placeLabels.length == 1
        ? placeLabels.first
        : null;

    // Weather is shared testing-session context — unlikely to change within
    // the group window, so the first member that has any represents it.
    final ContextWeather? weather = setups
        .map((s) => s.weather)
        .where((w) => w?.currentTemperature != null || w?.condition != null)
        .firstOrNull;

    final localTimes = setups.map((s) => s.datetimeLocal).toList();
    final earliest = localTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = localTimes.reduce((a, b) => a.isAfter(b) ? a : b);
    final timeFormat = DateFormat(appSettings.timeFormat);
    final startText = timeFormat.format(earliest);
    final endText = timeFormat.format(latest);
    final timeText = startText == endText ? startText : "$startText – $endText";
    // Members share a local day, so one date covers the group. The day header
    // states it when enabled.
    final dateTimeText = appSettings.enableTimelineDayHeaders
        ? timeText
        : "${DateFormat(appSettings.dateFormat).format(earliest)} • $timeText";

    final metadataRows = <Widget>[
      if (sharedPlace != null)
        TileMetaRow(icon: Icons.location_pin, text: sharedPlace, muted: true),
      if (weather?.currentTemperature != null)
        TileMetaRow(
          icon: ContextWeather.currentTemperatureIconData,
          text: "${ContextWeather.convertTemperatureFromCelsius(weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
          muted: true,
        ),
      if (weather?.condition != null)
        TileMetaRow(
          icon: weather?.condition?.iconData ?? Icons.question_mark,
          text: weather?.condition?.value ?? "-",
          iconColor: weather?.condition?.color,
          muted: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetupGroupHeader(
          setupCount: setups.length,
          dateTimeText: dateTimeText,
          bikeMetadata: TileMetaRow(
            icon: Bike.iconData,
            text: bikes[bikeId]?.name ?? "BIKE NOT FOUND",
            isError: !bikeFound,
          ),
          contextMetadata: metadataRows,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            // One outlined container binds the whole group; the members sit
            // inside it, separated by hairlines.
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < setups.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  _member(context, setups[i], hidePlace: sharedPlace != null),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
