import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import 'setup_list_card.dart';

class SetupGroupCard extends StatelessWidget {
  final List<String> setupIds;
  final void Function(Setup setup)? onTapSetup;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;

  const SetupGroupCard({
    super.key,
    required this.setupIds,
    required this.onTapSetup,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
  });

  Widget _metadataRow(
    BuildContext context,
    IconData icon,
    String text, {
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(
          icon,
          size: 13,
          color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color:
                  textColor ??
                  Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _member(BuildContext context, Setup setup, {required bool hidePlace}) {
    final card = SetupListCard(
      key: ValueKey(setup.id),
      setupId: setup.id,
      onTap: onTapSetup == null ? null : () => onTapSetup!(setup),
      displayBikeAdjustmentValues: displayBikeAdjustmentValues,
      displayPersonAdjustmentValues: displayPersonAdjustmentValues,
      showDate: false,
      embedded: true,
      hidePlace: hidePlace,
    );
    if (!setup.isCurrent) return card;

    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: primary, width: 4)),
      ),
      child: card,
    );
  }

  Widget _memberDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
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
      return SetupListCard(
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Icon(
                      Setup.iconData,
                      size: 18,
                      
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Text(
                        "${setups.length} Setups",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    _metadataRow(
                      context,
                      Bike.iconData,
                      bikes[bikeId]?.name ?? "BIKE NOT FOUND",
                      iconColor: bikeFound
                          ? null
                          : Theme.of(context).colorScheme.error,
                      textColor: bikeFound
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                    // Members share a local day, so one date covers the group.
                    // The day header states it when enabled.
                    if (!appSettings.enableTimelineDayHeaders)
                      _metadataRow(
                        context,
                        Icons.calendar_month,
                        DateFormat(appSettings.dateFormat).format(earliest),
                      ),
                    _metadataRow(context, Icons.access_time, timeText),
                    if (sharedPlace != null)
                      _metadataRow(context, Icons.location_pin, sharedPlace),
                    if (weather?.currentTemperature != null)
                      _metadataRow(
                        context,
                        ContextWeather.currentTemperatureIconData,
                        "${ContextWeather.convertTemperatureFromCelsius(weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
                      ),
                    if (weather?.condition != null)
                      _metadataRow(
                        context,
                        weather?.condition?.iconData ?? Icons.question_mark,
                        weather?.condition?.value ?? "-",
                        iconColor: weather?.condition?.color,
                      ),
                  ],
                ),
              ],
            ),
          ),
          _memberDivider(context),
          for (var i = 0; i < setups.length; i++) ...[
            if (i > 0) _memberDivider(context),
            _member(context, setups[i], hidePlace: sharedPlace != null),
          ],
        ],
      ),
    );
  }
}
