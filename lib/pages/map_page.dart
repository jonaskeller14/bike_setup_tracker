import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../env/env.dart';
import '../models/app_settings.dart';
import '../models/context/context_position.dart';
import '../models/strava/strava_activity.dart';
import '../repositories/app_repository.dart';
import '../services/location_service.dart';
import '../services/subscription_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/chips/map_filter_widget.dart';
import '../widgets/map_pins.dart';
import '../widgets/sheets/rating_entry_details.dart';
import '../widgets/sheets/setup_details.dart';
import '../widgets/sheets/strava_activity.dart';

class MapPage extends StatefulWidget {
  final LocationService? locationService;
  final Stream<LocationMarkerHeading?>? headingStream;

  const MapPage({super.key, this.locationService, this.headingStream});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final LocationService _locationService;
  late final bool _ownsLocationService;
  AnimationController? _mapMoveController;
  AnimationController? _mapRotateController;
  LatLng? _userLocation;
  late final Stream<LocationMarkerPosition> _markerPositions;
  late final Stream<LocationMarkerHeading?> _headings;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  final ValueNotifier<double> _rotation = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ownsLocationService = widget.locationService == null;
    _locationService = widget.locationService ?? LocationService();
    _locationService.addListener(_locationStatusChanged);
    // Built once: CurrentLocationLayer resubscribes whenever the stream
    // identity changes, and this page rebuilds on every repository change.
    _markerPositions = _locationService.positionStream
        .where((position) => ContextPosition.hasValidCoordinateChange(null, position))
        .map(
          (position) => LocationMarkerPosition(
            latitude: position.latitude!,
            longitude: position.longitude!,
            accuracy: position.accuracy ?? 0,
          ),
        );
    // flutter_rotation_sensor 0.2.0 starts Core Motion without a north
    // reference, so on iOS the azimuth is offset by an arbitrary constant and
    // the heading cone points the wrong way. Leave it off there. The fix needs
    // flutter_map_location_marker 10.3.0, which requires AGP 9.
    _headings =
        widget.headingStream ??
        (defaultTargetPlatform == TargetPlatform.iOS
            ? const Stream<LocationMarkerHeading?>.empty()
            : const LocationMarkerDataStreamFactory().fromRotationSensorHeadingStream());
    _mapEventSubscription = _mapController.mapEventStream.listen(
      (_) => _rotation.value = _mapController.camera.rotation,
    );
  }

  void _locationStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationService.removeListener(_locationStatusChanged);
    _locationService.stopPositionUpdates();
    if (_ownsLocationService) _locationService.dispose();
    unawaited(_mapEventSubscription?.cancel());
    _rotation.dispose();
    _mapMoveController?.dispose();
    _mapRotateController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  static double _rotationOffNorth(double rotation) {
    final normalized = rotation % 360;
    return normalized > 180 ? normalized - 360 : normalized;
  }

  Future<void> _animatedMapMove(LatLng destLocation, double destZoom) async {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    _mapMoveController?.dispose();
    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _mapMoveController = controller;
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        if (identical(_mapMoveController, controller)) _mapMoveController = null;
      }
    });

    try {
      await controller.forward().orCancel;
    } on TickerCanceled {
      // The page was disposed while the map was moving.
    }
  }

  Future<void> _animatedMapRotate(double destRotation) async {
    final rotationTween = Tween<double>(begin: _mapController.camera.rotation, end: destRotation);

    _mapRotateController?.dispose();
    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _mapRotateController = controller;
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() => _mapController.rotate(rotationTween.evaluate(animation)));

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        if (identical(_mapRotateController, controller)) _mapRotateController = null;
      }
    });

    try {
      await controller.forward().orCancel;
    } on TickerCanceled {
      // The page was disposed while the map was rotating.
    }
  }

  Future<void> _locateMe() async {
    if (_locationService.status == LocationStatus.searching) return;

    final position = await _locationService.fetchLocation();
    if (!mounted) return;

    if (ContextPosition.hasValidCoordinateChange(null, position)) {
      final userLocation = LatLng(position!.latitude!, position.longitude!);
      setState(() => _userLocation = userLocation);
      _locationService.startPositionUpdates();
      await _animatedMapMove(userLocation, 15);
      return;
    }

    final message = switch (_locationService.status) {
      LocationStatus.noService => 'Location services are disabled.',
      LocationStatus.noPermission => 'Location permission was not granted.',
      LocationStatus.permissionDeniedForever => 'Location permission is permanently denied.',
      LocationStatus.timeout => 'Location request timed out. Try again.',
      LocationStatus.error => 'Unable to determine your location.',
      _ => 'No valid location was returned.',
    };
    final AppSnackBarAction? action = switch (_locationService.status) {
      LocationStatus.noService => AppSnackBarAction(
        label: 'Settings',
        onPressed: _locationService.openLocationSettings,
      ),
      LocationStatus.permissionDeniedForever => AppSnackBarAction(
        label: 'Settings',
        onPressed: _locationService.openAppSettings,
      ),
      _ => null,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.error(context, message, action: action));
  }

  Widget _mapControlButton({Key? key, required Widget icon, required VoidCallback? onPressed}) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: key,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurfaceVariant,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(44, 44),
      ),
      onPressed: onPressed,
      icon: icon,
    );
  }

  static Widget _compassTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
        child: child,
      ),
    );
  }

  Widget _compassButton() {
    return ValueListenableBuilder<double>(
      valueListenable: _rotation,
      builder: (context, rotation, _) {
        final offNorth = _rotationOffNorth(rotation);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          reverseDuration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _compassTransition,
          child: offNorth.abs() <= 0.5
              ? const SizedBox.shrink()
              : _mapControlButton(
                  key: const Key('map-compass'),
                  icon: Transform.rotate(
                    angle: -_mapController.camera.rotationRad,
                    child: const Icon(Icons.navigation),
                  ),
                  onPressed: () {
                    unawaited(HapticFeedback.selectionClick());
                    unawaited(_animatedMapRotate(rotation - offNorth));
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final setups = appRepository.filteredSetups.values.where(
      (s) => (s.position?.latitude?.isFinite ?? false) && (s.position?.longitude?.isFinite ?? false),
    );

    return FutureBuilder<List<StravaActivity>>(
      future: appRepository.getFilteredStravaActivitiesWithPosition(),
      builder: (context, snapshot) {
        final stravaActivities = snapshot.data ?? [];
        final scheme = Theme.of(context).colorScheme;

        final List<Marker> clusterMarkers = [
          if (appSettings.displayShowSetups)
            ...setups.map(
              (setup) => Marker(
                point: LatLng(setup.position!.latitude!, setup.position!.longitude!),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () async {
                    await showSetupDetailsSheet(context: context, setupId: setup.id);
                  },
                  child: SetupMapPin.icon(
                    isCurrent: setup.isCurrent,
                    isBookmarked: appSettings.enableSetupBookmark && setup.isBookmarked,
                  ),
                ),
              ),
            ),
          if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement && appSettings.displayShowActivities)
            ...stravaActivities
                .where((a) => (a.startLat?.isFinite ?? false) && (a.startLon?.isFinite ?? false))
                .map(
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
                      child: StravaActivityMapPin(workoutType: activity.workout),
                    ),
                  ),
                ),
          if (appSettings.enableRating && appSettings.displayShowRatingEntries)
            ...appRepository.filteredRatingEntries.values
                .where(
                  (re) => (re.position?.latitude?.isFinite ?? false) && (re.position?.longitude?.isFinite ?? false),
                )
                .map(
                  (ratingEntry) => Marker(
                    point: LatLng(ratingEntry.position!.latitude!, ratingEntry.position!.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () async {
                        await showRatingEntryDetailsSheet(context: context, ratingEntry: ratingEntry);
                      },
                      child: const RatingEntryMapPin(),
                    ),
                  ),
                ),
        ];

        // Only used for camera fitting; the live marker draws itself.
        final List<LatLng> fitPoints = [
          ?_userLocation,
          ...clusterMarkers.map((marker) => marker.point),
        ];

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  initialRotation: 0,
                  initialCenter: const LatLng(44.1687, 8.3444), // Finale Ligure
                  initialZoom: 13,
                  minZoom: 3,
                  maxZoom: 18,
                  // Bound the camera to the world. Without this (default is
                  // CameraConstraint.unconstrained()), a fast pinch/fling
                  // zoom-out can momentarily drive the zoom scale to <= 0, so
                  // zoom(scale) = log(scale/256)/ln2 returns NaN/-Infinity. That
                  // produces a non-finite camera center which flutter_map 8.3.0
                  // now throws on during projection ("LatLng is not finite").
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-85.05112878, -180),
                      const LatLng(85.05112878, 180),
                    ),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                    enableMultiFingerGestureRace: true,
                  ),
                  initialCameraFit: fitPoints.isNotEmpty
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(fitPoints),
                          padding: const EdgeInsets.all(50),
                          maxZoom: 17,
                        )
                      : null,
                ),
                children: [
                  if (appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty)
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
                      minZoom: 3,
                      maxZoom: 18,
                      userAgentPackageName: 'com.jonaskeller14.bike_setup_tracker',
                      tileDisplay: const TileDisplay.fadeIn(),
                      tileBuilder: (context, tileWidget, tile) {
                        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        return ColorFiltered(
                          colorFilter: isDarkMode
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
                      showPolygon: false,
                      rotate: true,
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 18,
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
                  CurrentLocationLayer(
                    positionStream: _markerPositions,
                    headingStream: _headings,
                    style: LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        key: const Key('map-user-location-marker'),
                        color: scheme.primary,
                      ),
                      accuracyCircleColor: scheme.primary.withValues(alpha: 0.15),
                      headingSectorColor: scheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
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
                            image: AssetImage(
                              'assets/strava/1.2-Strava-API-Logos/1.2-Strava-API-Logos/Powered by Strava/pwrdBy_strava_orange/api_logo_pwrdBy_strava_stack_orange.png',
                            ),
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
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 12,
                    children: [
                      _mapControlButton(
                        icon: const BackButtonIcon(),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(child: MapFilterWidget()),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              _compassButton(),
              _mapControlButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final newZoom = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
                  await _animatedMapMove(_mapController.camera.center, newZoom);
                },
              ),
              _mapControlButton(
                icon: const Icon(Icons.remove),
                onPressed: () async {
                  final newZoom = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
                  await _animatedMapMove(_mapController.camera.center, newZoom);
                },
              ),
              _mapControlButton(
                key: const Key('map-locate-me'),
                icon: const Icon(Icons.my_location),
                onPressed: _locationService.status == LocationStatus.searching ? null : _locateMe,
              ),
              if (fitPoints.isNotEmpty)
                _mapControlButton(
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () {
                    _mapController.rotate(0);
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(fitPoints),
                        padding: const EdgeInsets.all(50),
                        maxZoom: 17,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
