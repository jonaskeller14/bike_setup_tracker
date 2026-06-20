import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../env/env.dart';
import '../../icons/weather_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/context/context_position.dart';
import '../../models/context/context_weather.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../utils/setup_actions.dart';
import '../../widgets/display_adjustment/display_adjustment_list.dart';
import '../../widgets/display_adjustment/display_dangling_adjustment.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/items/rating_entry_list_tile.dart';
import '../../widgets/sheets/sheet.dart';
import '../../widgets/text/section_title.dart';

class SetupDetailsPage extends StatefulWidget {
  final List<String> setupIds;
  final Setup? initialSetup;

  const SetupDetailsPage({
    super.key, 
    required this.setupIds,
    this.initialSetup,
  });

  @override
  State<SetupDetailsPage> createState() => _SetupDetailsPageState();
}

class _SetupDetailsPageState extends State<SetupDetailsPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialSetup != null) _currentPageIndex = widget.setupIds.indexOf(widget.initialSetup!.id);
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  Row _navigationRow(int index) {
    final bool isSmallScreen = MediaQuery.sizeOf(context).width < 360;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (isSmallScreen)
          IconButton(
            onPressed: index > 0 
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_back),
            color: Theme.of(context).colorScheme.primary,
          )
        else
          TextButton.icon(
            onPressed: index > 0 
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Prev"),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),

        Text(
          "${index + 1} / ${widget.setupIds.length}",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),

        if (isSmallScreen)
          IconButton(
            onPressed: index < widget.setupIds.length - 1 
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_forward),
            color: Theme.of(context).colorScheme.primary,
          )
        else
          TextButton.icon(
            onPressed: index < widget.setupIds.length - 1 
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Next"),
            iconAlignment: IconAlignment.end,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final List<Setup?> setups = widget.setupIds.map((setupId) => appRepository.setups[setupId]).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _navigationRow(_currentPageIndex),
        actions: [
          IconButton(
            onPressed: () => SetupActions.editSetup(context, setup: setups[_currentPageIndex]!), 
            icon: const Icon(Icons.edit),
          )
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        itemCount: setups.length,
        itemBuilder: (context, index) {
          final Setup? setup = setups[index];
          if (setup == null) return const Expanded(child: Center(child: Text("Setup not found.")));

          return SetupDetailsPageContent(setup: setup);
        },
      )
    );
  }
}

class SetupDetailsPageContent extends StatelessWidget {
  final Setup setup;
  final bool showEditButton;
  final bool showCloseButton;

  const SetupDetailsPageContent({super.key, required this.setup, this.showEditButton = false, this.showCloseButton = false});

  SliverAppBar _setupTitle(BuildContext context, {required Setup setup}) {
    final appSettings = context.read<AppSettings>();
    
    return SliverAppBar(
      pinned: true,
      expandedHeight: null, 
      toolbarHeight: 70, 
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      centerTitle: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  setup.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
                Text(
                  "${DateFormat(appSettings.dateFormat).format(setup.datetimeLocal)} • ${DateFormat(appSettings.timeFormat).format(setup.datetimeLocal)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (showEditButton || showCloseButton)
            const SizedBox(width: 12),
          if (showEditButton)
            sheetEditButton(context, onPressed: () => SetupActions.editSetup(context, setup: setup)),
          if (showCloseButton)
            sheetCloseButton(context),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1),
      ),
    );
  }

  PinnedHeaderSliver _sectionTitle(BuildContext context, {required String title}) {
    return PinnedHeaderSliver(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SectionTitle(title: title),
      ),
    );
  }

  SliverToBoxAdapter _contextSection(BuildContext context, {required Setup setup, required Bike? bike, required Person? person}) {
    final appSettings = context.watch<AppSettings>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (setup.notes != null || (setup.tags.isNotEmpty && appSettings.enableSetupTags))
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (setup.notes != null)
                      ListTile(
                        leading: const Icon(Icons.notes),
                        titleAlignment: ListTileTitleAlignment.titleHeight,
                        title: SelectableText(setup.notes!),
                        dense: true,
                      ),
                    ...setup.tags.map((tag) {
                      return ListTile(
                        leading: const Icon(Icons.tag),
                        title: Text(tag),
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
            if (setup.position != null || setup.place != null)
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: SelectableText("Latitude/Longitude: ${setup.position?.latitude?.toStringAsFixed(4) ?? '-'}°/${setup.position?.longitude?.toStringAsFixed(4) ?? '-'}°"),
                      dense: true,
                      enabled: setup.position?.latitude != null || setup.position?.longitude != null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: SelectableText("Altitude: ${ContextPosition.convertAltitudeFromMeters(setup.position?.altitude, appSettings.altitudeUnit)?.round() ?? "-"} ${appSettings.altitudeUnit}"),
                      dense: true,
                      enabled: setup.position?.altitude != null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_city),
                      title: setup.place == null 
                          ? const Text("No Address available")
                          : SelectableText(
                              "${setup.place!.thoroughfare ?? ''} ${setup.place!.subThoroughfare ?? ''}, "
                              "${setup.place!.locality ?? ''}, ${setup.place!.isoCountryCode ?? ''}"
                                .replaceAll(RegExp(r' ,'), '')
                                .trim(),
                            ),
                      dense: true,
                      enabled: setup.place != null,
                    ),
                    if (setup.position?.latitude != null && setup.position?.longitude != null)
                      SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: FlutterMap(
                            options: MapOptions(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              initialCenter: LatLng(setup.position!.latitude!, setup.position!.longitude!),
                              initialZoom: 13,
                              minZoom: 3,
                              onTap: (_, _) async {
                                final String scheme = Theme.of(context).platform == TargetPlatform.iOS ? 'maps' : 'geo';
                                await launchUrlString('$scheme:${setup.position!.latitude},${setup.position!.longitude}?q=${setup.position!.latitude},${setup.position!.longitude}(${Uri.encodeComponent(setup.displayName)})');
                              },
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
                                  subdomains: const ['a', 'b', 'c'], // Cyclosm uses subdomains for faster loading
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
                                              0.6, 0.3, 0.1, 0, 0,  // Muted Red
                                              0.1, 0.8, 0.1, 0, 0,  // Muted Green
                                              0.1, 0.3, 0.6, 0, 0,  // Muted Blue
                                              0,   0,   0,   1, 0,  // Alpha (no change)
                                            ]),
                                      child: tileWidget,
                                    );
                                  },
                                ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(setup.position!.latitude!, setup.position!.longitude!),
                                    width: 40,
                                    height: 40,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ImageFiltered(
                                          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                          child: const Icon(Icons.location_pin, size: 40, color: Colors.black38),
                                        ),
                                        Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              RichAttributionWidget(
                                showFlutterMapAttribution: false,
                                attributions: [
                                  if (appSettings.useMapBoxTiles && Env.mapboxToken.isNotEmpty) ...[
                                    LogoSourceAttribution(
                                      Image.asset(
                                        'assets/mapbox/mapbox-logo.png',
                                        height: 24,
                                      ),
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
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            if (setup.weather != null)
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(setup.weather?.getIconData() ?? WeatherIcons.na),
                      title: Text("Weather: ${setup.weather?.getWeatherCodeLabel() ?? '-'}"),
                      dense: true,
                      enabled: setup.weather?.currentWeatherCode != null,
                    ),
                    ListTile(
                      leading: const Icon(ContextWeather.currentTemperatureIconData),
                      title: SelectableText("Temperature: ${ContextWeather.convertTemperatureFromCelsius(setup.weather?.currentTemperature, appSettings.temperatureUnit)?.round() ?? '-'} ${appSettings.temperatureUnit}"),
                      dense: true,
                      enabled: setup.weather?.currentTemperature != null,
                    ),
                    ListTile(
                      leading: const Icon(ContextWeather.currentHumidityIconData),
                      title: SelectableText("Humidity: ${setup.weather?.currentHumidity?.round() ?? '-'} %"),
                      dense: true,
                      enabled: setup.weather?.currentHumidity != null,
                    ),
                    ListTile(
                      leading: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
                      title:  SelectableText("Precipitation: ${ContextWeather.convertPrecipitationFromMm(setup.weather?.dayAccumulatedPrecipitation, appSettings.precipitationUnit)?.round() ?? '-'} ${appSettings.precipitationUnit}"),
                      dense: true,
                      enabled: setup.weather?.dayAccumulatedPrecipitation != null,
                    ),
                    ListTile(
                      leading: const Icon(ContextWeather.currentWindSpeedIconData),
                      title:  SelectableText("Windspeed: ${ContextWeather.convertWindSpeedFromKmh(setup.weather?.currentWindSpeed, appSettings.windSpeedUnit)?.round() ?? '-'} ${appSettings.windSpeedUnit}"),
                      dense: true,
                      enabled: setup.weather?.currentWindSpeed != null,
                    ),
                    ListTile(
                      leading: const Icon(ContextWeather.currentSoilMoisture0to7cmIconData),
                      title:  SelectableText("Soil Moisture: ${setup.weather?.currentSoilMoisture0to7cm?.toStringAsFixed(2) ?? '-'} m³/m³"),
                      dense: true,
                      enabled: setup.weather?.currentSoilMoisture0to7cm != null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(setup.weather?.condition?.iconData ?? Icons.question_mark_sharp, color: setup.weather?.condition?.color),
                      title: SelectableText('Condition: ${setup.weather?.condition?.value ?? "-"}'),
                      dense: true,
                      enabled: setup.weather?.condition != null,
                    ),
                  ],
                ),
              ),
            Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Bike.iconData,
                        color: bike == null
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      title: Text(
                        bike?.name ?? "BIKE NOT FOUND", 
                        style: bike == null
                            ? TextStyle(color: Theme.of(context).colorScheme.error)
                            : null,
                      ),
                      dense: true,
                    ),
                    if (appSettings.enablePerson)
                      ListTile(
                        leading: setup.person != null ? const Icon(Person.iconData): const Icon(Icons.person_off),
                        title: Text(person?.name ?? (setup.person == null ? "No person linked to this setup." : "Person not found.")),
                        dense: true,
                      ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _legend(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: InitialChangedValueLegend(),
      ),
    );
  }

  SliverToBoxAdapter _valueSection(BuildContext context, {
    required Setup setup,
    required Iterable<Component> bikeComponents,
    required Person? person,
    required Map<String, dynamic> danglingBikeAdjustmentValues,
    required Map<String, dynamic> danglingPersonAdjustmentValues,
  }) {
    final appSettings = context.read<AppSettings>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bikeComponents.isEmpty)
              SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'No components available.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
              )
            else
              ...bikeComponents.map((bikeComponent) {
                return Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: SelectableText(bikeComponent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(Intl.plural(
                          bikeComponent.adjustments.length,
                          zero: "No adjustments yet.",
                          one: "1 adjustment",
                          other: '${bikeComponent.adjustments.length} adjustments',
                        )),
                        leading: Icon(bikeComponent.componentType.getIconData()),
                        enabled: bikeComponent.adjustments.isNotEmpty,
                        tileColor: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      AdjustmentDisplayList(
                        adjustments: bikeComponent.adjustments,
                        initialAdjustmentValues: setup.previousBikeAdjustmentValues,
                        adjustmentValues: setup.bikeAdjustmentValues,
                      ),
                    ],
                  ),
                );
              }),
            if (danglingBikeAdjustmentValues.isNotEmpty)
              Opacity(
                opacity: 0.4,
                child: Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("Dangling Adjustment Values", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(Intl.plural(
                          danglingBikeAdjustmentValues.length, 
                          one: "1 adjustment value found that is not associated with this bike.",
                          other: "${danglingBikeAdjustmentValues.length} adjustment values found that are not associated with this bike.",
                        )),
                        leading: const Icon(Icons.question_mark),
                        tileColor: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      ...danglingBikeAdjustmentValues.entries.map((danglingAdjustmentValue) {
                        return DisplayDanglingAdjustmentWidget(
                          name: danglingAdjustmentValue.key, 
                          initialValue: setup.previousBikeAdjustmentValues[danglingAdjustmentValue.key], 
                          value: danglingAdjustmentValue.value
                        );
                      }),
                    ],
                  ),
                ),
              ),
            if (appSettings.enablePerson) ...[
              if (person != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: SelectableText(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(Intl.plural(
                          person.adjustments.length,
                          zero: "No attributes yet.",
                          one: "1 attribute",
                          other: '${person.adjustments.length} attributes',
                        )),
                        leading: const Icon(Person.iconData),
                        enabled: person.adjustments.isNotEmpty,
                        tileColor: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      AdjustmentDisplayList(
                        adjustments: person.adjustments,
                        initialAdjustmentValues: setup.previousPersonAdjustmentValues,
                        adjustmentValues: setup.personAdjustmentValues,
                      ),
                    ],
                  ),
                ),
              if (danglingPersonAdjustmentValues.isNotEmpty)
                Opacity(
                  opacity: 0.4,
                  child: Card.outlined(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("Dangling Attribute Values", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(Intl.plural(
                            danglingPersonAdjustmentValues.length, 
                            one: "1 attribute value found that is not associated with this person.",
                            other: "${danglingPersonAdjustmentValues.length} attribute values found that are not associated with this person.",
                          )),
                          leading: const Icon(Icons.question_mark),
                          tileColor: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        ...danglingPersonAdjustmentValues.entries.map((danglingAdjustmentValue) {
                          return DisplayDanglingAdjustmentWidget(
                            name: danglingAdjustmentValue.key, 
                            initialValue: setup.previousPersonAdjustmentValues[danglingAdjustmentValue.key], 
                            value: danglingAdjustmentValue.value,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        )
      ),
    );
  }

  SliverToBoxAdapter _ratingEntriesSection(BuildContext context, {required Setup setup}) {
    final appRepository = context.watch<AppRepository>();
    final scheme = Theme.of(context).colorScheme;

    final entries = appRepository.ratingEntriesForSetup(setup.id)
      ..sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC));
    final score = appRepository.scoreForSetup(setup.id);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              titleAlignment: ListTileTitleAlignment.titleHeight,
              leading: CircleAvatar(
                backgroundColor: score == null ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                child: Text(
                  score == null ? "–" : score.toStringAsFixed(1),
                  style: TextStyle(
                    color: score == null ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: const Text("Setup score", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(score == null ? "No ratings yet" : "${score.toStringAsFixed(1)} / 10 across ${entries.length} rating${entries.length == 1 ? '' : 's'}"),
            ),
            ...entries.map((entry) => RatingEntryListTile(ratingEntry: entry)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => SetupActions.addRatingEntryForSetup(context, setup: setup),
                icon: const Icon(Icons.add),
                label: const Text("Add rating"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final persons = appRepository.persons;
    final components = appRepository.components;

    final Bike? bike = bikes[setup.bike];
    final Iterable<Component> bikeComponents = components.values.where((c) => c.bikeAt(setup.datetimeLocal.toUtc()) == setup.bike);
    final Person? person = persons[setup.person];

    final Map<String, dynamic> danglingBikeAdjustmentValues = Map.from(setup.bikeAdjustmentValues);
    for (final bikeComponent in bikeComponents) {
      for (final bikeComponentAdj in bikeComponent.adjustments) {
        danglingBikeAdjustmentValues.remove(bikeComponentAdj.id);
      }
    }

    final Map<String, dynamic> danglingPersonAdjustmentValues = Map.from(setup.personAdjustmentValues);
    for (final personAdj in (person?.adjustments ?? [])) {
      danglingPersonAdjustmentValues.remove(personAdj.id);
    }

    return CustomScrollView(
      slivers: [
        _setupTitle(context, setup: setup),
        SliverSafeArea(
          top: false,
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverMainAxisGroup(
                slivers: [
                  _sectionTitle(context, title: "Context"),
                  _contextSection(context, setup: setup, bike: bike, person: person),
                ],
              ),
              SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(child: Divider(height: 8)),
                  _sectionTitle(context, title: "Values"),
                  _valueSection(
                    context,
                    setup: setup,
                    person: person,
                    bikeComponents: bikeComponents,
                    danglingBikeAdjustmentValues: danglingBikeAdjustmentValues,
                    danglingPersonAdjustmentValues: danglingPersonAdjustmentValues,
                  ),
                  _legend(context),
                ]
              ),
              if (appSettings.enableRating)
                SliverMainAxisGroup(
                  slivers: [
                    const SliverToBoxAdapter(child: Divider(height: 8)),
                    _sectionTitle(context, title: "Ratings"),
                    _ratingEntriesSection(context, setup: setup),
                  ],
                ),
              
            ],
          ),
        ),
      ],
    );
  }
}
