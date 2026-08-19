import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../env/env.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_position.dart';

class ContextLocationCardDiff extends StatelessWidget {
  final LocationData? positionA;
  final geo.Placemark? placeA;
  final LocationData? positionB;
  final geo.Placemark? placeB;

  const ContextLocationCardDiff({
    super.key,
    required this.positionA,
    required this.placeA,
    required this.positionB,
    required this.placeB,
  });

  @override
  Widget build(BuildContext context) {
    if (positionA == null && placeA == null && positionB == null && placeB == null) {
      return const SizedBox.shrink();
    }

    final addressA = _address(placeA);
    final addressB = _address(placeB);
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('compare-disclosure-location'),
        dense: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.location_city),
        title: _ComparisonTextRow(
          valueA: addressA,
          valueB: addressB,
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
      ),
    );
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

  static String _coordinates(LocationData? position) {
    if (position?.latitude == null && position?.longitude == null) return '-';
    return '${position?.latitude?.toStringAsFixed(4) ?? '-'}°/'
        '${position?.longitude?.toStringAsFixed(4) ?? '-'}°';
  }
}

class _AltitudeRow extends StatelessWidget {
  final LocationData? positionA;
  final LocationData? positionB;

  const _AltitudeRow({required this.positionA, required this.positionB});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    String altitude(LocationData? position) {
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

class _ComparisonMap extends StatelessWidget {
  final LocationData? positionA;
  final LocationData? positionB;

  const _ComparisonMap({required this.positionA, required this.positionB});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final points = <({String label, LatLng point, Color color})>[
      if (positionA?.latitude != null && positionA?.longitude != null)
        (
          label: 'A',
          point: LatLng(positionA!.latitude!, positionA!.longitude!),
          color: Theme.of(context).colorScheme.primary,
        ),
      if (positionB?.latitude != null && positionB?.longitude != null)
        (
          label: 'B',
          point: LatLng(positionB!.latitude!, positionB!.longitude!),
          color: Theme.of(context).colorScheme.primary,
        ),
    ];
    if (points.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: FlutterMap(
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                        child: const Icon(Icons.location_pin, size: 46, color: Colors.black38),
                      ),
                      Icon(Icons.location_pin, size: 46, color: point.color),
                      Align(
                        alignment: const Alignment(0, -0.35),
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            point.label,
                            style: TextStyle(
                              color: point.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
