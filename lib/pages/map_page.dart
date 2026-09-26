import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../env/env.dart';
import '../models/app_settings.dart';
import '../models/context/context_position.dart';
import '../models/strava/strava_activity.dart';
import '../repositories/app_repository.dart';
import '../services/location_service.dart';
import '../services/subscription_service.dart';
import '../utils/animated_map_camera.dart';
import '../utils/map_empty_state.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/chips/map_filter_widget.dart';
import '../widgets/map/map_attribution.dart';
import '../widgets/map/map_cluster_bubble.dart';
import '../widgets/map/map_compass_button.dart';
import '../widgets/map/map_control_button.dart';
import '../widgets/map/map_tile_layer.dart';
import '../widgets/map_empty_state_card.dart';
import '../widgets/map_pins.dart';
import '../widgets/sheets/rating_entry_details.dart';
import '../widgets/sheets/setup_details.dart';
import '../widgets/sheets/strava_activity.dart';

class MapPage extends StatefulWidget {
  final LocationService? locationService;
  final Stream<LocationMarkerHeading?>? headingStream;

  /// Activity to open the map on. Its pin is shown even when the map filters
  /// would hide it; ignored when it has no start position.
  final StravaActivity? focusActivity;

  const MapPage({super.key, this.locationService, this.headingStream, this.focusActivity});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimatedMapCamera _camera = AnimatedMapCamera(_mapController, this);
  late final LocationService _locationService;
  late final bool _ownsLocationService;
  LatLng? _userLocation;
  late final Stream<LocationMarkerPosition> _markerPositions;
  late final Stream<LocationMarkerHeading?> _headings;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  final ValueNotifier<double> _rotation = ValueNotifier<double>(0);
  AppRepository? _repository;
  List<StravaActivity> _stravaActivities = const [];
  bool _stravaHasAnyPosition = false;
  bool _stravaResolved = false;
  bool _stravaFailed = false;
  int _stravaRequestId = 0;
  MapPinState _pinState = MapPinState.loading;
  MapPinState? _collapsedFor;
  bool _cameraTouchedByUser = false;
  List<LatLng> _pinPoints = const [];

  /// Camera sources the page drives itself; anything else comes from the user.
  static const Set<MapEventSource> _programmaticCameraSources = {
    MapEventSource.mapController,
    MapEventSource.fitCamera,
    MapEventSource.custom,
    MapEventSource.interactiveFlagsChanged,
    MapEventSource.nonRotatedSizeChange,
  };

  @visibleForTesting
  MapPinState get pinState => _pinState;

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
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      _rotation.value = _mapController.camera.rotation;
      if (!_programmaticCameraSources.contains(event.source)) _cameraTouchedByUser = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_autoLocate()));
  }

  void _locationStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<AppRepository>();
    if (identical(repository, _repository)) return;
    _repository?.removeListener(_reloadStravaActivities);
    _repository = repository..addListener(_reloadStravaActivities);
    _reloadStravaActivities();
  }

  /// Requeries only when the repository changes, so unrelated rebuilds (layer
  /// toggles, location updates, rotation) no longer hit the database.
  void _reloadStravaActivities() => unawaited(_loadStravaActivities());

  Future<void> _loadStravaActivities() async {
    final repository = _repository;
    if (repository == null) return;
    final requestId = ++_stravaRequestId;
    try {
      final activities = await repository.getFilteredStravaActivitiesWithPosition();
      // The unscoped check only matters once the filtered query came back empty.
      final hasAnyPosition = activities.isNotEmpty || await repository.hasStravaActivitiesWithPosition();
      if (!mounted || requestId != _stravaRequestId) return;
      setState(() {
        _stravaActivities = activities;
        _stravaHasAnyPosition = hasAnyPosition;
        _stravaResolved = true;
        _stravaFailed = false;
      });
    } catch (_) {
      if (!mounted || requestId != _stravaRequestId) return;
      // Keep the last known activities: setups and rating entries stay pinned.
      setState(() {
        _stravaResolved = true;
        _stravaFailed = true;
      });
    }
  }

  /// Drops the failed result and queries again, which the card offers as Retry.
  void _retryStravaActivities() {
    setState(() {
      _stravaResolved = false;
      _stravaFailed = false;
    });
    _reloadStravaActivities();
  }

  MapPinState _pinStateFor({
    required int visiblePinCount,
    required AppRepository appRepository,
    required AppSettings appSettings,
    required bool stravaActive,
  }) {
    if (stravaActive && !_stravaResolved) return MapPinState.loading;
    if (stravaActive && _stravaFailed) return MapPinState.error;

    return mapPinState(
      visiblePinCount,
      hasAnyPositionedMapData(
        hasSetups: appRepository.hasSetupsWithPosition,
        hasRatingEntries: appRepository.hasRatingEntriesWithPosition,
        hasStravaActivities: _stravaHasAnyPosition,
        ratingEnabled: appSettings.enableRating,
        stravaActive: stravaActive,
      ),
    );
  }

  @override
  void dispose() {
    _repository?.removeListener(_reloadStravaActivities);
    _locationService.removeListener(_locationStatusChanged);
    _locationService.stopPositionUpdates();
    if (_ownsLocationService) _locationService.dispose();
    unawaited(_mapEventSubscription?.cancel());
    _rotation.dispose();
    _camera.dispose();
    _mapController.dispose();
    super.dispose();
  }

  static CameraFit _pinOverviewFit(List<LatLng> points) => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(points),
    padding: const EdgeInsets.all(50),
    maxZoom: 17,
  );

  /// The silent counterpart to [_locateMe], run once when the page opens. It may
  /// surface the OS permission prompt, but never a SnackBar.
  Future<void> _autoLocate() async {
    if (!mounted || _locationService.status == LocationStatus.permissionDeniedForever) return;

    final position = await _locationService.fetchLocation();
    if (!mounted || !ContextPosition.hasValidCoordinateChange(null, position)) return;

    final userLocation = LatLng(position!.latitude!, position.longitude!);
    setState(() => _userLocation = userLocation);
    _locationService.startPositionUpdates();

    // GPS can take seconds: never yank a camera the user has already moved,
    // nor one that opened on a specific activity.
    if (_cameraTouchedByUser || _focusPoint != null) return;
    if (_pinPoints.isEmpty) {
      await _camera.move(userLocation, 15);
      return;
    }
    final fit = _pinOverviewFit([userLocation, ..._pinPoints]).fit(_mapController.camera);
    await _camera.move(fit.center, fit.zoom);
  }

  Future<void> _locateMe() async {
    if (_locationService.status == LocationStatus.searching) return;

    final position = await _locationService.fetchLocation();
    if (!mounted) return;

    if (ContextPosition.hasValidCoordinateChange(null, position)) {
      final userLocation = LatLng(position!.latitude!, position.longitude!);
      setState(() => _userLocation = userLocation);
      _locationService.startPositionUpdates();
      await _camera.move(userLocation, 15);
      return;
    }

    final status = _locationService.status;
    final AppSnackBarAction? action = switch (status) {
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
      ..showSnackBar(AppSnackBar.error(context, status.errorMessage, action: action));
  }

  Future<void> _zoomBy(double delta) =>
      _camera.move(_mapController.camera.center, (_mapController.camera.zoom + delta).clamp(3.0, 18.0));

  static Marker _pinMarker({required LatLng point, required VoidCallback onTap, required Widget pin}) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: GestureDetector(onTap: onTap, child: pin),
    );
  }

  Iterable<Marker> _setupMarkers(AppRepository appRepository, AppSettings appSettings) {
    return appRepository.filteredSetups.values
        .where((s) => (s.position?.latitude?.isFinite ?? false) && (s.position?.longitude?.isFinite ?? false))
        .map(
          (setup) => _pinMarker(
            point: LatLng(setup.position!.latitude!, setup.position!.longitude!),
            onTap: () => showSetupDetailsSheet(context: context, setupId: setup.id),
            pin: SetupMapPin.icon(
              isCurrent: setup.isCurrent,
              isBookmarked: appSettings.enableSetupBookmark && setup.isBookmarked,
            ),
          ),
        );
  }

  LatLng? get _focusPoint {
    final activity = widget.focusActivity;
    if (activity == null || !activity.hasStartPosition) return null;
    return LatLng(activity.startLat!, activity.startLon!);
  }

  Iterable<Marker> _activityMarkers() {
    return _stravaActivities
        .where((a) => a.hasStartPosition && a.id != widget.focusActivity?.id)
        .map(
          (activity) => _pinMarker(
            point: LatLng(activity.startLat!, activity.startLon!),
            onTap: () => showStravaActivitySheet(context: context, stravaActivity: activity, showViewOnMap: false),
            pin: StravaActivityMapPin(workoutType: activity.workout),
          ),
        );
  }

  Iterable<Marker> _ratingEntryMarkers(AppRepository appRepository) {
    return appRepository.filteredRatingEntries.values
        .where((re) => (re.position?.latitude?.isFinite ?? false) && (re.position?.longitude?.isFinite ?? false))
        .map(
          (ratingEntry) => _pinMarker(
            point: LatLng(ratingEntry.position!.latitude!, ratingEntry.position!.longitude!),
            onTap: () => showRatingEntryDetailsSheet(context: context, ratingEntry: ratingEntry),
            pin: const RatingEntryMapPin(),
          ),
        );
  }

  /// Kept out of the cluster layer so the focused activity is never folded
  /// into a cluster bubble.
  Marker _focusMarker(StravaActivity activity, LatLng point) {
    return Marker(
      key: const Key('map-focus-activity'),
      point: point,
      width: 52,
      height: 52,
      child: GestureDetector(
        onTap: () => showStravaActivitySheet(context: context, stravaActivity: activity, showViewOnMap: false),
        child: Transform.scale(scale: 1.3, child: StravaActivityMapPin(workoutType: activity.workout)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final stravaActive = appSettings.enableStrava && subscriptionService.hasStravaEntitlement;
    final useMapbox = appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty;

    final colorScheme = Theme.of(context).colorScheme;

    final List<Marker> clusterMarkers = [
      if (appSettings.displayShowSetups) ..._setupMarkers(appRepository, appSettings),
      if (stravaActive && appSettings.displayShowActivities) ..._activityMarkers(),
      if (appSettings.enableRating && appSettings.displayShowRatingEntries) ..._ratingEntryMarkers(appRepository),
    ];

    final focusActivity = widget.focusActivity;
    final focusPoint = _focusPoint;
    _pinPoints = [?focusPoint, ...clusterMarkers.map((marker) => marker.point)];
    final List<LatLng> fitPoints = [?_userLocation, ..._pinPoints];

    final pinState = _pinStateFor(
      visiblePinCount: _pinPoints.length,
      appRepository: appRepository,
      appSettings: appSettings,
      stravaActive: stravaActive,
    );
    _pinState = pinState;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              backgroundColor: colorScheme.surfaceContainerHighest,
              initialRotation: 0,
              initialCenter: focusPoint ?? const LatLng(44.1687, 8.3444), // Finale Ligure
              initialZoom: focusPoint != null ? 15 : 13,
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
              initialCameraFit: focusPoint == null && fitPoints.isNotEmpty ? _pinOverviewFit(fitPoints) : null,
            ),
            children: [
              MapTileLayer(useMapbox: useMapbox),
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
                  builder: (context, markers) => MapClusterBubble(count: markers.length),
                ),
              ),
              if (focusActivity != null && focusPoint != null)
                MarkerLayer(markers: [_focusMarker(focusActivity, focusPoint)]),
              CurrentLocationLayer(
                positionStream: _markerPositions,
                headingStream: _headings,
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    key: const Key('map-user-location-marker'),
                    color: colorScheme.primary,
                  ),
                  accuracyCircleColor: colorScheme.primary.withValues(alpha: 0.15),
                  headingSectorColor: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
              MapAttribution(useMapbox: useMapbox, showStrava: _stravaActivities.isNotEmpty || focusPoint != null),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 12,
                    children: [
                      MapControlButton(
                        icon: const BackButtonIcon(),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(child: MapFilterWidget()),
                    ],
                  ),
                  if (pinState != MapPinState.loading && pinState != MapPinState.success)
                    Padding(
                      padding: const EdgeInsets.only(left: 2), // to align horizontally with BackButtonIcon
                      child: MapEmptyStateCard(
                        state: pinState,
                        collapsed: _collapsedFor == pinState,
                        onToggleCollapsed: () => setState(
                          () => _collapsedFor = _collapsedFor == pinState ? null : pinState,
                        ),
                        onRetry: _retryStravaActivities,
                      ),
                    ),
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
          MapCompassButton(
            rotation: _rotation,
            onResetNorth: (target) => unawaited(_camera.rotate(target)),
          ),
          MapControlButton(
            icon: const Icon(Icons.add),
            onPressed: () => _zoomBy(1),
          ),
          MapControlButton(
            icon: const Icon(Icons.remove),
            onPressed: () => _zoomBy(-1),
          ),
          MapControlButton(
            key: const Key('map-locate-me'),
            icon: const Icon(Icons.my_location),
            onPressed: _locationService.status == LocationStatus.searching ? null : _locateMe,
          ),
          if (fitPoints.isNotEmpty)
            MapControlButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: () {
                _mapController.rotate(0);
                _mapController.fitCamera(_pinOverviewFit(fitPoints));
              },
            ),
        ],
      ),
    );
  }
}
