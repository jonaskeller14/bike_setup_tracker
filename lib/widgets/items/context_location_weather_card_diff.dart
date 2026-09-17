import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../env/env.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_position.dart';
import '../../models/context/context_weather.dart';
import '../map_pins.dart';

class ContextLocationWeatherCardDiff extends StatelessWidget {
  final ContextPosition? positionA;
  final geo.Placemark? placeA;
  final ContextWeather? weatherA;
  final ContextPosition? positionB;
  final geo.Placemark? placeB;
  final ContextWeather? weatherB;

  const ContextLocationWeatherCardDiff({
    super.key,
    required this.positionA,
    required this.placeA,
    required this.weatherA,
    required this.positionB,
    required this.placeB,
    required this.weatherB,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = positionA != null || placeA != null || positionB != null || placeB != null;
    final hasWeather = (weatherA?.hasWeatherData ?? false) || (weatherB?.hasWeatherData ?? false);
    final hasCondition = weatherA?.condition != null || weatherB?.condition != null;
    if (!hasLocation && !hasWeather && !hasCondition) return const SizedBox.shrink();

    final sections = <Widget>[
      if (hasLocation) _locationSection(),
      if (hasWeather) _weatherSection(context),
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

  Widget _locationSection() {
    return ExpansionTile(
      key: const Key('compare-disclosure-location'),
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.location_city),
      title: _ComparisonTextRow(
        valueA: _address(placeA),
        valueB: _address(placeB),
      ),
      children: [
        ListTile(
          leading: const Icon(Icons.my_location),
          title: _ComparisonTextRow(
            valueA: _coordinates(positionA),
            valueB: _coordinates(positionB),
          ),
          dense: true,
        ),
        _AltitudeRow(positionA: positionA, positionB: positionB),
        _ComparisonMap(positionA: positionA, positionB: positionB),
      ],
    );
  }

  Widget _weatherSection(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final weatherCodeDiffer = weatherA?.getWeatherCodeLabel() != weatherB?.getWeatherCodeLabel();

    String temperature(ContextWeather? weather) {
      final value = ContextWeather.convertTemperatureFromCelsius(
        weather?.currentTemperature,
        settings.temperatureUnit,
      );
      return value == null ? '-' : '${value.round()} ${settings.temperatureUnit}';
    }

    String precipitation(ContextWeather? weather) {
      final value = ContextWeather.convertPrecipitationFromMm(
        weather?.dayAccumulatedPrecipitation,
        settings.precipitationUnit,
      );
      return value == null ? '-' : '${value.round()} ${settings.precipitationUnit}';
    }

    String humidity(ContextWeather? weather) =>
        weather?.currentHumidity == null ? '-' : '${weather!.currentHumidity!.round()} %';

    String wind(ContextWeather? weather) {
      final value = ContextWeather.convertWindSpeedFromKmh(weather?.currentWindSpeed, settings.windSpeedUnit);
      return value == null ? '-' : '${value.round()} ${settings.windSpeedUnit}';
    }

    String soilMoisture(ContextWeather? weather) => weather?.currentSoilMoisture0to7cm == null
        ? '-'
        : '${weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)} m³/m³';

    return ExpansionTile(
      key: const Key('compare-disclosure-conditions'),
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: _DifferenceLeading(
        iconA: weatherA?.getIconData() ?? Icons.question_mark_sharp,
        iconB: weatherB?.getIconData() ?? Icons.question_mark_sharp,
        different: weatherCodeDiffer,
      ),
      title: _ComparisonTextRow(
        valueA: weatherA?.getWeatherCodeLabel() ?? '-',
        valueB: weatherB?.getWeatherCodeLabel() ?? '-',
      ),
      children: [
        _WeatherRow(
          icon: ContextWeather.currentTemperatureIconData,
          valueA: temperature(weatherA),
          valueB: temperature(weatherB),
        ),
        _WeatherRow(
          icon: ContextWeather.dayAccumulatedPrecipitationIconData,
          valueA: precipitation(weatherA),
          valueB: precipitation(weatherB),
        ),
        _WeatherRow(
          icon: ContextWeather.currentHumidityIconData,
          valueA: humidity(weatherA),
          valueB: humidity(weatherB),
        ),
        _WeatherRow(
          icon: ContextWeather.currentWindSpeedIconData,
          valueA: wind(weatherA),
          valueB: wind(weatherB),
        ),
        _WeatherRow(
          icon: ContextWeather.currentSoilMoisture0to7cmIconData,
          valueA: soilMoisture(weatherA),
          valueB: soilMoisture(weatherB),
        ),
      ],
    );
  }

  Widget _conditionSection() {
    return ListTile(
      leading: _conditionDifferenceLeading(),
      title: _ComparisonTextRow(
        valueA: weatherA?.condition?.value ?? '-',
        valueB: weatherB?.condition?.value ?? '-',
      ),
      dense: true,
    );
  }

  Widget _conditionDifferenceLeading() {
    final conditionsDiffer = weatherA?.condition != weatherB?.condition;

    if (conditionsDiffer) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(weatherA?.condition?.iconData ?? Icons.question_mark_sharp, size: 18, color: weatherA?.condition?.color),
          Icon(weatherB?.condition?.iconData ?? Icons.question_mark_sharp, size: 18, color: weatherB?.condition?.color),
        ],
      );
    }

    final condition = weatherA?.condition ?? weatherB?.condition;
    return Icon(condition?.iconData ?? Icons.question_mark_sharp, color: condition?.color);
  }

  static String _address(geo.Placemark? place) {
    if (place == null) return '-';
    final address =
        '${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}, '
                '${place.locality ?? ''}, ${place.isoCountryCode ?? ''}'
            .replaceAll(RegExp(r' ,'), '')
            .trim();
    return address.isEmpty ? '-' : address;
  }

  static String _coordinates(ContextPosition? position) {
    if (position?.latitude == null && position?.longitude == null) return '-';
    return '${position?.latitude?.toStringAsFixed(4) ?? '-'}°/'
        '${position?.longitude?.toStringAsFixed(4) ?? '-'}°';
  }
}

class _AltitudeRow extends StatelessWidget {
  final ContextPosition? positionA;
  final ContextPosition? positionB;

  const _AltitudeRow({required this.positionA, required this.positionB});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    String altitude(ContextPosition? position) {
      final value = ContextPosition.convertAltitudeFromMeters(position?.altitude, settings.altitudeUnit);
      return value == null ? '-' : '${value.round()} ${settings.altitudeUnit}';
    }

    return ListTile(
      leading: const Icon(Icons.arrow_upward),
      title: _ComparisonTextRow(
        valueA: altitude(positionA),
        valueB: altitude(positionB),
      ),
      dense: true,
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final IconData icon;
  final String valueA;
  final String valueB;

  const _WeatherRow({
    required this.icon,
    required this.valueA,
    required this.valueB,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: _ComparisonTextRow(valueA: valueA, valueB: valueB),
      dense: true,
    );
  }
}

class _DifferenceLeading extends StatelessWidget {
  final IconData iconA;
  final IconData? iconB;
  final bool different;

  const _DifferenceLeading({
    required this.iconA,
    this.iconB,
    required this.different,
  });

  @override
  Widget build(BuildContext context) {
    if (different && iconB != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(iconA, size: 18),
          Icon(iconB, size: 18),
        ],
      );
    }
    return Icon(iconA);
  }
}

class _ComparisonTextRow extends StatelessWidget {
  final String valueA;
  final String valueB;

  const _ComparisonTextRow({required this.valueA, required this.valueB});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(
          child: SelectableText(valueA),
        ),
        Expanded(
          child: SelectableText(valueB),
        ),
      ],
    );
  }
}

class _ComparisonMap extends StatefulWidget {
  final ContextPosition? positionA;
  final ContextPosition? positionB;

  const _ComparisonMap({required this.positionA, required this.positionB});

  @override
  State<_ComparisonMap> createState() => _ComparisonMapState();
}

class _ComparisonMapState extends State<_ComparisonMap> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant _ComparisonMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasChanged(oldWidget.positionA, widget.positionA) || _hasChanged(oldWidget.positionB, widget.positionB)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitCamera();
      });
    }
  }

  bool _hasChanged(ContextPosition? previous, ContextPosition? current) =>
      previous?.latitude != current?.latitude || previous?.longitude != current?.longitude;

  List<({String label, LatLng point})> get _points => [
    if (widget.positionA?.latitude != null && widget.positionA?.longitude != null)
      (
        label: 'A',
        point: LatLng(widget.positionA!.latitude!, widget.positionA!.longitude!),
      ),
    if (widget.positionB?.latitude != null && widget.positionB?.longitude != null)
      (
        label: 'B',
        point: LatLng(widget.positionB!.latitude!, widget.positionB!.longitude!),
      ),
  ];

  void _fitCamera() {
    final points = _points;
    if (points.length == 1) {
      _mapController.move(points.single.point, 13);
    } else if (points.length > 1) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points.map((point) => point.point).toList()),
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final points = _points;
    if (points.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          initialCenter: points.first.point,
          initialZoom: 13,
          minZoom: 0,
          initialCameraFit: points.length > 1
              ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points.map((point) => point.point).toList()),
                  padding: const EdgeInsets.all(48),
                  maxZoom: 16,
                )
              : null,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          if (settings.useMapBoxTiles && Env.mapboxToken.isNotEmpty)
            TileLayer(
              urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/{style_id}/tiles/256/{z}/{x}/{y}?access_token={access_token}',
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
              minZoom: 0,
              userAgentPackageName: 'com.jonaskeller14.bike_setup_tracker',
              tileDisplay: const TileDisplay.fadeIn(),
              tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                colorFilter: Theme.of(context).brightness == Brightness.dark
                    ? const ColorFilter.matrix(<double>[
                        -0.2126,
                        -0.7152,
                        -0.0722,
                        0,
                        255,
                        -0.2126,
                        -0.7152,
                        -0.0722,
                        0,
                        255,
                        -0.2126,
                        -0.7152,
                        -0.0722,
                        0,
                        255,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ])
                    : const ColorFilter.matrix(<double>[
                        0.6,
                        0.3,
                        0.1,
                        0,
                        0,
                        0.1,
                        0.8,
                        0.1,
                        0,
                        0,
                        0.1,
                        0.3,
                        0.6,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                child: tileWidget,
              ),
            ),
          MarkerLayer(
            markers: [
              for (final point in points)
                Marker(
                  point: point.point,
                  width: 48,
                  height: 48,
                  child: SetupMapPin.label(label: point.label),
                ),
            ],
          ),
          RichAttributionWidget(
            showFlutterMapAttribution: false,
            attributions: [
              TextSourceAttribution(
                settings.useMapBoxTiles && Env.mapboxToken.isNotEmpty ? 'Mapbox' : 'OpenStreetMap | Cyclosm',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
