import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/filtered_data.dart';
import '../models/setup.dart';
import '../models/app_data.dart';
import 'setup_display_page.dart';
import 'strava_activitiy_page.dart';
import 'setup_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  Future<void> _editSetup(Setup setup) async {
    final data = context.read<AppData>();
    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.edit(setup: setup)),
    );
    if (editedSetup == null) return;
    data.editSetup(editedSetup);
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final setups = filteredData.setups.values.where((s) => s.position?.latitude != null && s.position?.longitude != null);
    final stravaActivities = filteredData.stravaActivities.values.where((a) => a.startLat != null && a.startLon != null);

    final List<Marker> markers = [
      ...setups.map((setup) => Marker(
            point: LatLng(setup.position!.latitude!, setup.position!.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetupDisplayPage(
                    setupIds: filteredData.setups.keys.toList(),
                    initialSetup: setup,
                    editSetup: _editSetup,
                  ),
                ),
              ),
              child: Icon(
                Icons.location_pin,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
                shadows: const [Shadow(blurRadius: 12, color: Colors.black26, offset: Offset(0, 2))],
              ),
            ),
          )),
      ...stravaActivities.map((activity) => Marker(
            point: LatLng(activity.startLat!, activity.startLon!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StravaActivityPage(stravaActivity: activity),
                ),
              ),
              child: const Icon(
                Icons.location_pin,
                size: 40,
                color: Color(0xFFFC5200), // Strava Orange
                shadows: [Shadow(blurRadius: 12, color: Colors.black26, offset: Offset(0, 2))],
              ),
            ),
          )),
    ];

    LatLng initialCenter = const LatLng(44.1687, 8.3444); // Finale Ligure
    double initialZoom = 13;

    if (markers.isNotEmpty) {
      double totalLat = 0;
      double totalLon = 0;
      for (var m in markers) {
        totalLat += m.point.latitude;
        totalLon += m.point.longitude;
      }
      initialCenter = LatLng(totalLat / markers.length, totalLon / markers.length);
      
      if (markers.length > 1) {
        initialZoom = 11;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map View"),
        centerTitle: true,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          initialCameraFit: markers.isNotEmpty 
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(markers.map((m) => m.point).toList()), 
                padding: const EdgeInsets.all(50),
              )
            : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.jonaskeller.bike_setup_tracker',
            tileDisplay: const TileDisplay.fadeIn(),
            tileBuilder: (context, tileWidget, tile) {
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.6, 0.3, 0.1, 0, 0,  // Muted Red
                  0.1, 0.8, 0.1, 0, 0,  // Muted Green
                  0.1, 0.3, 0.6, 0, 0,  // Muted Blue
                  0,   0,   0,   1, 0,  // Alpha (no change)
                ]),
                child: tileWidget,
              );
            },
          ),
          MarkerLayer(markers: markers),
          RichAttributionWidget(
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
      floatingActionButton: markers.isNotEmpty ? FloatingActionButton(
        mini: true,
        onPressed: () {
          if (markers.isEmpty) return;
          final points = markers.map((m) => m.point).toList();
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        },
        child: const Icon(Icons.center_focus_strong),
      ) : null,
    );
  }
}
