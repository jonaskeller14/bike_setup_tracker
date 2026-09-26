import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Tile source attribution, plus the "Powered by Strava" logo whenever
/// Strava activities are on the map.
class MapAttribution extends StatelessWidget {
  final bool useMapbox;
  final bool showStrava;

  const MapAttribution({super.key, required this.useMapbox, required this.showStrava});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        if (useMapbox) ...[
          LogoSourceAttribution(
            Image.asset(
              'assets/mapbox/mapbox-logo.png',
              height: 24,
            ),
            tooltip: 'Mapbox',
            onTap: () => launchUrlString('https://www.mapbox.com/about/maps/'),
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
        if (showStrava)
          const LogoSourceAttribution(
            Image(
              image: AssetImage(
                'assets/strava/1.2-Strava-API-Logos/1.2-Strava-API-Logos/Powered by Strava/pwrdBy_strava_orange/api_logo_pwrdBy_strava_stack_orange.png',
              ),
              height: 24,
            ),
            tooltip: 'Powered by Strava',
          ),
      ],
    );
  }
}
