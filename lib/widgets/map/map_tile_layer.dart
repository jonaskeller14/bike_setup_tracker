import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../env/env.dart';

/// Base map tiles: Mapbox when enabled, otherwise CyclOSM re-tinted to
/// match the light or dark theme.
class MapTileLayer extends StatelessWidget {
  final bool useMapbox;

  const MapTileLayer({super.key, required this.useMapbox});

  static const String _userAgentPackageName = 'com.jonaskeller14.bike_setup_tracker';

  /// Inverted luminance, so the light CyclOSM tiles read as a dark map.
  static const ColorFilter _darkFilter = ColorFilter.matrix(<double>[
    -0.2126, -0.7152, -0.0722, 0, 255, //
    -0.2126, -0.7152, -0.0722, 0, 255, //
    -0.2126, -0.7152, -0.0722, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  static const ColorFilter _lightFilter = ColorFilter.matrix(<double>[
    0.6, 0.3, 0.1, 0, 0, // Muted Red
    0.1, 0.8, 0.1, 0, 0, // Muted Green
    0.1, 0.3, 0.6, 0, 0, // Muted Blue
    0, 0, 0, 1, 0, // Alpha (no change)
  ]);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (useMapbox) {
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/mapbox/{style_id}/tiles/256/{z}/{x}/{y}?access_token={access_token}',
        additionalOptions: {
          'access_token': Env.mapboxToken,
          'style_id': isDarkMode ? 'dark-v11' : 'outdoors-v12',
        },
        userAgentPackageName: _userAgentPackageName,
        tileDisplay: const TileDisplay.fadeIn(),
      );
    }
    return TileLayer(
      urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      minZoom: 3,
      maxZoom: 18,
      userAgentPackageName: _userAgentPackageName,
      tileDisplay: const TileDisplay.fadeIn(),
      tileBuilder: (context, tileWidget, tile) => ColorFiltered(
        colorFilter: Theme.of(context).brightness == Brightness.dark ? _darkFilter : _lightFilter,
        child: tileWidget,
      ),
    );
  }
}
