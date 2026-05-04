import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../env/env.dart';
import '../models/app_settings.dart';
import '../models/strava/strava_activity.dart';
import '../repositories/app_repository.dart';
import '../widgets/chips/map_filter_widget.dart';
import '../widgets/sheets/setup_display.dart';
import '../widgets/sheets/strava_activity.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  Future<void> _animatedMapMove(LatLng destLocation, double destZoom) async {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    await controller.forward();
  }

  Future<void> _locateMe() async {
    final location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationData = await location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
      _animatedMapMove(_userLocation!, 15);
    }
  }

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
        
        final Marker? userLocationMarker = _userLocation == null
            ? null
            : Marker(
                point: _userLocation!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black26,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );

        final List<Marker> clusterMarkers = [
          if (appSettings.displayShowSetups)
            ...setups.map(
              (setup) => Marker(
                point:
                    LatLng(setup.position!.latitude!, setup.position!.longitude!),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () async {
                    await showSetupDetailsSheet(context: context, setup: setup);
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
          if (appSettings.enableStrava && appSettings.displayShowActivities)
            ...stravaActivities.map(
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

        final List<Marker> markers = [
          ?userLocationMarker,
          ...clusterMarkers,
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
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
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
                  if (appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty)
                    TileLayer(
                      urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/{style_id}/tiles/256/{z}/{x}/{y}@2x?access_token={access_token}',
                      additionalOptions: {
                        'access_token': Env.mapboxToken,
                        'style_id': Theme.of(context).brightness == Brightness.dark ? 'dark-v11' : 'outdoors-v12',
                      },
                      userAgentPackageName: 'com.jonaskeller14.bike_setup_tracker',
                      tileDisplay: const TileDisplay.fadeIn(),
                    )
                  else
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      minZoom: 3,
                      maxZoom: 18,
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
                                  0.6, 0.3, 0.1, 0, 0,  // Muted Red
                                  0.1, 0.8, 0.1, 0, 0,  // Muted Green
                                  0.1, 0.3, 0.6, 0, 0,  // Muted Blue
                                  0,   0,   0,   1, 0,  // Alpha (no change)
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
                      markers: clusterMarkers,
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
                  if (userLocationMarker != null)
                    MarkerLayer(markers: [userLocationMarker]),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    showFlutterMapAttribution: false,
                    attributions: [
                      if (appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty) ...[
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
              const SafeArea(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(8),
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
                onPressed: () async {
                  final newZoom = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
                  await _animatedMapMove(_mapController.camera.center, newZoom);
                },
                child: const Icon(Icons.add),
              ),
              FloatingActionButton(
                heroTag: 'map_zoom_out',
                mini: true,
                onPressed: () async {
                  final newZoom = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
                  await _animatedMapMove(_mapController.camera.center, newZoom);
                },
                child: const Icon(Icons.remove),
              ),
              FloatingActionButton(
                heroTag: 'map_locate_me',
                mini: true,
                onPressed: _locateMe,
                child: const Icon(Icons.my_location),
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
