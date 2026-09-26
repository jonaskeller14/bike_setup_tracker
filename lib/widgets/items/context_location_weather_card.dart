import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../env/env.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_position.dart';
import '../../models/context/context_weather.dart';
import '../../utils/url.dart';

class ContextLocationWeatherCard extends StatelessWidget {
  final ContextPosition? position;
  final geo.Placemark? place;
  final String displayName;
  final Widget mapPin;
  final ContextWeather? weather;

  const ContextLocationWeatherCard({
    super.key,
    required this.position,
    required this.place,
    required this.displayName,
    required this.mapPin,
    required this.weather,
  });

  bool get _hasLocation => position != null || place != null;

  bool get _hasWeather => weather?.hasWeatherData ?? false;

  bool get _hasCondition => weather?.condition != null;

  @override
  Widget build(BuildContext context) {
    final hasLocation = _hasLocation;
    final hasWeather = _hasWeather;
    final hasCondition = _hasCondition;
    if (!hasLocation && !hasWeather && !hasCondition) return const SizedBox.shrink();

    final appSettings = context.watch<AppSettings>();

    final sections = <Widget>[
      if (hasLocation) _locationSection(context, appSettings, isLast: !hasWeather && !hasCondition),
      if (hasWeather) _weatherSection(appSettings),
      if (hasCondition) _conditionSection(),
    ];

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            sections[i],
          ],
        ],
      ),
    );
  }

  Widget _locationSection(BuildContext context, AppSettings appSettings, {required bool isLast}) {
    return ExpansionTile(
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.location_city),
      title: place == null
          ? const Text("No Address available")
          : SelectableText(
              "${place!.thoroughfare ?? ''} ${place!.subThoroughfare ?? ''}, "
              "${place!.locality ?? ''}, ${place!.isoCountryCode ?? ''}"
                  .replaceAll(RegExp(r' ,'), '')
                  .trim(),
            ),
      children: [
        ListTile(
          leading: const Icon(Icons.my_location),
          title: SelectableText(
            "Latitude/Longitude: ${position?.latitude?.toStringAsFixed(4) ?? '-'}°/${position?.longitude?.toStringAsFixed(4) ?? '-'}°",
          ),
          dense: true,
          enabled: position?.latitude != null || position?.longitude != null,
        ),
        ListTile(
          leading: const Icon(Icons.arrow_upward),
          title: SelectableText(
            "Altitude: ${ContextPosition.convertAltitudeFromMeters(position?.altitude, appSettings.altitudeUnit)?.round() ?? "-"} ${appSettings.altitudeUnit}",
          ),
          dense: true,
          enabled: position?.altitude != null,
        ),
        if (position?.latitude != null && position?.longitude != null)
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.zero,
              child: FlutterMap(
                options: MapOptions(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  initialCenter: LatLng(position!.latitude!, position!.longitude!),
                  initialZoom: 13,
                  minZoom: 3,
                  onTap: (_, _) => launchLocationOnMap(context, position!.latitude!, position!.longitude!, displayName),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  if (appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty)
                    TileLayer(
                      urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/{style_id}/tiles/256/{z}/{x}/{y}?access_token={access_token}',
                      additionalOptions: {
                        'access_token': Env.mapboxToken,
                        'style_id': Theme.of(context).brightness == Brightness.dark ? 'dark-v11' : 'outdoors-v12',
                      },
                      userAgentPackageName: 'com.jonaskeller14.bike_setup_tracker',
                      tileDisplay: const TileDisplay.fadeIn(),
                    )
                  else
                    TileLayer(
                      urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      minZoom: 3,
                      userAgentPackageName: 'com.jonaskeller14.bike_setup_tracker',
                      tileDisplay: const TileDisplay.fadeIn(),
                      tileBuilder: (context, tileWidget, tile) {
                        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        return ColorFiltered(
                          colorFilter: isDarkMode
                              ? const ColorFilter.matrix(<double>[
                                  -0.2126, -0.7152, -0.0722, 0, 255,
                                  -0.2126, -0.7152, -0.0722, 0, 255,
                                  -0.2126, -0.7152, -0.0722, 0, 255,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.matrix(<double>[
                                  0.6, 0.3, 0.1, 0, 0,
                                  0.1, 0.8, 0.1, 0, 0,
                                  0.1, 0.3, 0.6, 0, 0,
                                  0,   0,   0,   1, 0,
                                ]),
                          child: tileWidget,
                        );
                      },
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(position!.latitude!, position!.longitude!),
                        width: 40,
                        height: 40,
                        child: mapPin,
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: [
                      if (appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty) ...[
                        LogoSourceAttribution(
                          Image.asset('assets/mapbox/mapbox-logo.png', height: 24),
                        ),
                        TextSourceAttribution(
                          'Mapbox',
                          onTap: () => launchUrlString('https://www.mapbox.com/about/maps/'),
                        ),
                        TextSourceAttribution(
                          'OpenStreetMap',
                          onTap: () => launchUrlString('https://www.openstreetmap.org/copyright'),
                        ),
                        TextSourceAttribution(
                          prependCopyright: false,
                          'Improve this map',
                          onTap: () => launchUrlString('https://www.mapbox.com/map-feedback/'),
                        ),
                      ] else ...[
                        TextSourceAttribution(
                          'OpenStreetMap | Cyclosm',
                          onTap: () => launchUrlString('https://openstreetmap.org/copyright'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _weatherSection(AppSettings appSettings) {
    return ExpansionTile(
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(weather!.getIconData()),
      title: Text("Weather: ${weather!.getWeatherCodeLabel() ?? '-'}"),
      children: [
        ListTile(
          leading: const Icon(ContextWeather.currentTemperatureIconData),
          title: SelectableText(
            "Temperature: ${ContextWeather.convertTemperatureFromCelsius(weather!.currentTemperature, appSettings.temperatureUnit)?.round() ?? '-'} ${appSettings.temperatureUnit}",
          ),
          dense: true,
          enabled: weather!.currentTemperature != null,
        ),
        ListTile(
          leading: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
          title: SelectableText(
            "Precipitation: ${ContextWeather.convertPrecipitationFromMm(weather!.dayAccumulatedPrecipitation, appSettings.precipitationUnit)?.round() ?? '-'} ${appSettings.precipitationUnit}",
          ),
          dense: true,
          enabled: weather!.dayAccumulatedPrecipitation != null,
        ),
        ListTile(
          leading: const Icon(ContextWeather.currentHumidityIconData),
          title: SelectableText("Humidity: ${weather!.currentHumidity?.round() ?? '-'} %"),
          dense: true,
          enabled: weather!.currentHumidity != null,
        ),
        ListTile(
          leading: const Icon(ContextWeather.currentWindSpeedIconData),
          title: SelectableText(
            "Windspeed: ${ContextWeather.convertWindSpeedFromKmh(weather!.currentWindSpeed, appSettings.windSpeedUnit)?.round() ?? '-'} ${appSettings.windSpeedUnit}",
          ),
          dense: true,
          enabled: weather!.currentWindSpeed != null,
        ),
        ListTile(
          leading: const Icon(ContextWeather.currentSoilMoisture0to7cmIconData),
          title: SelectableText(
            "Soil Moisture: ${weather!.currentSoilMoisture0to7cm?.toStringAsFixed(2) ?? '-'} m³/m³",
          ),
          dense: true,
          enabled: weather!.currentSoilMoisture0to7cm != null,
        ),
      ],
    );
  }

  Widget _conditionSection() {
    return ListTile(
      leading: Icon(weather!.condition!.iconData, color: weather!.condition!.color),
      title: SelectableText('Condition: ${weather!.condition!.value}'),
      dense: true,
    );
  }
}
