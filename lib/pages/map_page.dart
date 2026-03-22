import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../widgets/chips/map_filter_widget.dart';
import '../widgets/sheets/strava_activity.dart';
import '../widgets/sheets/setup_display.dart';
import '../models/strava/strava_activity.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final setups = appRepository.filteredSetups.values.where(
      (s) => s.position?.latitude != null && s.position?.longitude != null,
    );

    return FutureBuilder<List<StravaActivity>>(
      future: appRepository.getFilteredStravaActivitiesWithPosition(),
      builder: (context, snapshot) {
        final stravaActivities = snapshot.data ?? [];
        
        final List<Marker> markers = [
          if (appSettings.displayShowSetups) ...setups.map(
            (setup) => Marker(
              point: LatLng(setup.position!.latitude!, setup.position!.longitude!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () async {
                  await showSetupDisplaySheet(context: context, setup: setup);
                },
                child: Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                  shadows: const [
                    Shadow(
                      blurRadius: 12,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (appSettings.enableStrava && appSettings.displayShowActivities) ...stravaActivities.map(
            (activity) => Marker(
              point: LatLng(activity.startLat!, activity.startLon!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () async {
                  await showStravaActivitySheet(
                    context: context,
                    stravaActivity: activity,
                  );
                },
                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Color(0xFFFC5200), // Strava Orange
                  shadows: [
                    Shadow(
                      blurRadius: 12,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];

        return Scaffold(
          appBar: AppBar(title: const Text("Map View"), centerTitle: true),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialRotation: 0,
                  initialCenter: const LatLng(44.1687, 8.3444), // Finale Ligure
                  initialZoom: 13,
                  initialCameraFit: markers.isNotEmpty
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(
                            markers.map((m) => m.point).toList(),
                          ),
                          padding: const EdgeInsets.all(50),
                          maxZoom: 17,
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    minZoom: 3,
                    userAgentPackageName: 'com.jonaskeller14.bike_setup_tracker',
                    tileDisplay: const TileDisplay.fadeIn(),
                    tileBuilder: (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.6, 0.3, 0.1, 0, 0, // Muted Red
                          0.1, 0.8, 0.1, 0, 0, // Muted Green
                          0.1, 0.3, 0.6, 0, 0, // Muted Blue
                          0, 0, 0, 1, 0, // Alpha (no change)
                        ]),
                        child: tileWidget,
                      );
                    },
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 15,
                      markers: markers,
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    showFlutterMapAttribution: false,
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap | Cyclosm',
                        onTap: () => launchUrlString('https://openstreetmap.org/copyright'),
                      ),
                      if (stravaActivities.isNotEmpty)
                        const LogoSourceAttribution(
                          Image(
                            image: AssetImage('assets/strava/1.2-Strava-API-Logos/1.2-Strava-API-Logos/Powered by Strava/pwrdBy_strava_orange/api_logo_pwrdBy_strava_stack_orange.png'),
                            height: 24,
                          ),
                          tooltip: 'Powered by Strava',
                        ),
                    ],
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsetsGeometry.all(8),
                  child: MapFilterWidget(),
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              FloatingActionButton(
                heroTag: 'map_zoom_in',
                mini: true,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    (_mapController.camera.zoom + 1),
                  );
                },
                child: const Icon(Icons.add),
              ),
              FloatingActionButton(
                heroTag: 'map_zoom_out',
                mini: true,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    (_mapController.camera.zoom - 1),
                  );
                },
                child: const Icon(Icons.remove),
              ),
              if (markers.isNotEmpty) ...[
                FloatingActionButton(
                  heroTag: 'map_center_focus',
                  mini: true,
                  onPressed: () {
                    final points = markers.map((m) => m.point).toList();
                    final bounds = LatLngBounds.fromPoints(points);
                    _mapController.rotate(0);
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(50),
                        maxZoom: 17,
                      ),
                    );
                  },
                  child: const Icon(Icons.center_focus_strong),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
