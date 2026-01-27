import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather_icons/weather_icons.dart';
import '../models/app_settings.dart';
import '../models/filtered_data.dart';
import '../models/setup.dart';
import '../models/person.dart';
import '../models/component.dart';
import '../models/rating.dart';
import '../models/bike.dart';
import '../models/weather.dart';
import '../widgets/display_adjustment/display_adjustment_list.dart';
import '../widgets/display_adjustment/display_dangling_adjustment.dart';
import '../widgets/initial_changed_value_legend.dart';

class SetupDisplayPage extends StatefulWidget {
  final List<String> setupIds;
  final Setup? initialSetup;
  final Function editSetup;

  const SetupDisplayPage({
    super.key, 
    required this.setupIds,
    this.initialSetup,
    required this.editSetup,
  });

  @override
  State<SetupDisplayPage> createState() => _SetupDisplayPageState();
}

class _SetupDisplayPageState extends State<SetupDisplayPage> {
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
    final appSettings = context.read<AppSettings>();
    final filteredData = context.watch<FilteredData>();
    final bikes = filteredData.bikes;
    final persons = filteredData.persons;
    final ratings = filteredData.ratings;
    final components = filteredData.components;

    final List<Setup?> setups = widget.setupIds.map((setupId) => filteredData.setups[setupId]).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _navigationRow(_currentPageIndex),
        actions: [
          IconButton(
            onPressed: () => widget.editSetup(setups[_currentPageIndex]), 
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
          if (setup == null) return Expanded(child: Center(child: const Text("Setup not found.")));
          
          final Bike? bike = bikes[setup.bike];
          Iterable<Component> bikeComponents = components.values.where((c) => c.bike == setup.bike);
          final Person? person = persons[setup.person];

          final danglingBikeAdjustmentValues = Map.from(setup.bikeAdjustmentValues);
          for (final bikeComponent in bikeComponents) {
            for (final bikeComponentAdj in bikeComponent.adjustments) {
              danglingBikeAdjustmentValues.remove(bikeComponentAdj.id);
            }
          }

          final danglingPersonAdjustmentValues = Map.from(setup.personAdjustmentValues);
          for (final personAdj in (person?.adjustments ?? [])) {
            danglingPersonAdjustmentValues.remove(personAdj.id);
          }

          final filteredRatings = <String, Rating>{};
          for (final rating in ratings.values) {
            switch (rating.filterType) {
              case FilterType.global:
                filteredRatings[rating.id] = rating;
              case FilterType.bike:
                if (rating.filter == setup.bike) filteredRatings[rating.id] = rating;
              case FilterType.componentType:
                if (bikeComponents.any((c) => c.componentType.toString() == rating.filter)) filteredRatings[rating.id] = rating;
              case FilterType.component:
                if (bikeComponents.any((c) => c.id == rating.filter)) filteredRatings[rating.id] = rating;
              case FilterType.person:
                if (rating.filter == setup.person) filteredRatings[rating.id] = rating;
            }
          }

          final Map<String, dynamic> danglingRatingAdjustmentValues = Map.fromEntries(setup.ratingAdjustmentValues.entries);
          danglingRatingAdjustmentValues.removeWhere((adjId, _) => filteredRatings.values.any((r) => r.adjustments.map((a) => a.id).contains(adjId)));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(setup.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      "${DateFormat(appSettings.dateFormat).format(setup.datetime)} • ${DateFormat(appSettings.timeFormat).format(setup.datetime)}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),),
                    ),
                  ],
                )
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CONTEXT", style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.2, 
                              color: Theme.of(context).colorScheme.primary
                            )),
                            
                          ],
                        )
                      ),
                      const SizedBox(height: 12),
                      if (setup.notes != null)
                        Card.outlined(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: ListTile(
                            leading: const Icon(Icons.notes),
                            titleAlignment: ListTileTitleAlignment.top,
                            title: SelectableText(setup.notes!),
                            dense: true,
                          ),
                        ),
                      if (setup.position != null || setup.place != null)
                        Card.outlined(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
                                title: SelectableText("Altitude: ${Setup.convertAltitudeFromMeters(setup.position?.altitude, appSettings.altitudeUnit)?.round() ?? "-"} ${appSettings.altitudeUnit}"),
                                dense: true,
                                enabled: setup.position?.altitude != null,
                              ),
                              ListTile(
                                leading: const Icon(Icons.location_city),
                                title: SelectableText("${setup.place?.thoroughfare ?? ''} ${setup.place?.subThoroughfare ?? ''}, ${setup.place?.locality ?? ''}, ${setup.place?.isoCountryCode ?? ''}"),
                                dense: true,
                                enabled: setup.place != null,
                              ),
                            ],
                          ),
                        ),
                      if (setup.weather != null)
                        Card.outlined(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
                                leading: const Icon(Weather.currentTemperatureIconData),
                                title: SelectableText("Temperature: ${Weather.convertTemperatureFromCelsius(setup.weather?.currentTemperature, appSettings.temperatureUnit)?.round() ?? '-'} ${appSettings.temperatureUnit}"),
                                dense: true,
                                enabled: setup.weather?.currentTemperature != null,
                              ),
                              ListTile(
                                leading: const Icon(Weather.currentHumidityIconData),
                                title: SelectableText("Humidity: ${setup.weather?.currentHumidity?.round() ?? '-'} %"),
                                dense: true,
                                enabled: setup.weather?.currentHumidity != null,
                              ),
                              ListTile(
                                leading: const Icon(Weather.dayAccumulatedPrecipitationIconData),
                                title:  SelectableText("Precipitation: ${Weather.convertPrecipitationFromMm(setup.weather?.dayAccumulatedPrecipitation, appSettings.precipitationUnit)?.round() ?? '-'} ${appSettings.precipitationUnit}"),
                                dense: true,
                                enabled: setup.weather?.dayAccumulatedPrecipitation != null,
                              ),
                              ListTile(
                                leading: const Icon(Weather.currentWindSpeedIconData),
                                title:  SelectableText("Windspeed: ${Weather.convertWindSpeedFromKmh(setup.weather?.currentWindSpeed, appSettings.windSpeedUnit)?.round() ?? '-'} ${appSettings.windSpeedUnit}"),
                                dense: true,
                                enabled: setup.weather?.currentWindSpeed != null,
                              ),
                              ListTile(
                                leading: const Icon(Weather.currentSoilMoisture0to7cmIconData),
                                title:  SelectableText("Soil Moisture: ${setup.weather?.currentSoilMoisture0to7cm?.toStringAsFixed(2) ?? '-'} m³/m³"),
                                dense: true,
                                enabled: setup.weather?.currentSoilMoisture0to7cm != null,
                              ),
                              Divider(height: 1),
                              ListTile(
                                leading: Icon(setup.weather?.condition?.getIconData() ?? Icons.question_mark_sharp, color: setup.weather?.condition?.getColor()),
                                title: SelectableText('Condition: ${setup.weather?.condition?.value ?? "-"}'),
                                dense: true,
                                enabled: setup.weather?.condition != null,
                              ),
                            ],
                          ),
                        ),
                      Card.outlined(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Bike.iconData),
                                title: Text(bike?.name ?? "Bike not found."),
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
                      const SizedBox(height: 16),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("VALUES", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Theme.of(context).colorScheme.primary)),
                            const SizedBox(height: 12),
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: SelectableText(bikeComponent.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(Intl.plural(
                                          bikeComponent.adjustments.length,
                                          zero: "No adjustments yet.",
                                          one: "1 adjustment",
                                          other: '${bikeComponent.adjustments.length} adjustments',
                                        )),
                                        leading: Icon(bikeComponent.componentType.getIconData()),
                                      ),
                                      AdjustmentDisplayList(
                                        adjustments: bikeComponent.adjustments,
                                        initialAdjustmentValues: setup.previousBikeSetup?.bikeAdjustmentValues ?? {},
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
                                        leading: Icon(Icons.question_mark),
                                      ),
                                      ...danglingBikeAdjustmentValues.entries.map((danglingAdjustmentValue) {
                                        return DisplayDanglingAdjustmentWidget(
                                          name: danglingAdjustmentValue.key, 
                                          initialValue: setup.previousBikeSetup?.bikeAdjustmentValues[danglingAdjustmentValue.key], 
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: SelectableText(person.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(Intl.plural(
                                          person.adjustments.length,
                                          zero: "No attributes yet.",
                                          one: "1 attribute",
                                          other: '${person.adjustments.length} attributes',
                                        )),
                                        leading: const Icon(Person.iconData),
                                      ),
                                      AdjustmentDisplayList(
                                        adjustments: person.adjustments,
                                        initialAdjustmentValues: setup.previousPersonSetup?.personAdjustmentValues ?? {},
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
                                          leading: Icon(Icons.question_mark),
                                        ),
                                        ...danglingPersonAdjustmentValues.entries.map((danglingAdjustmentValue) {
                                          return DisplayDanglingAdjustmentWidget(
                                            name: danglingAdjustmentValue.key, 
                                            initialValue: setup.previousPersonSetup?.personAdjustmentValues[danglingAdjustmentValue.key], 
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
                      if (appSettings.enableRating) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("RATING", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Theme.of(context).colorScheme.primary)),
                              const SizedBox(height: 12),
                              if (filteredRatings.isEmpty)
                                SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: Text(
                                      'No ratings available.',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                )
                              else
                                ...filteredRatings.values.map((rating) {
                                  return Card.outlined(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: SelectableText(rating.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(Intl.plural(
                                                rating.adjustments.length,
                                                zero: "No adjustments yet.",
                                                one: "1 adjustment",
                                                other: '${rating.adjustments.length} adjustments',
                                              )),
                                              Spacer(),
                                              switch (rating.filterType) {
                                                FilterType.bike => const Icon(Bike.iconData),
                                                FilterType.person => const Icon(Person.iconData),
                                                FilterType.component => Icon((components[rating.filter]?.componentType ?? ComponentType.other).getIconData()),
                                                FilterType.componentType => Icon((ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter) ?? ComponentType.other).getIconData()),
                                                FilterType.global => const SizedBox.shrink(),
                                              },
                                              const SizedBox(width: 2),
                                              switch (rating.filterType) {
                                                FilterType.bike => Text(bikes[rating.filter]?.name ?? "-", overflow: TextOverflow.ellipsis),
                                                FilterType.person => Text(persons[rating.filter]?.name ?? "-", overflow: TextOverflow.ellipsis),
                                                FilterType.componentType => Text(
                                                  ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.value ?? "-",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                FilterType.component => Text(
                                                  components[rating.filter]?.name ?? "-",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                FilterType.global => const SizedBox.shrink(),
                                              },
                                            ],
                                          ),
                                          leading: const Icon(Rating.iconData),
                                        ),
                                        AdjustmentDisplayList(
                                          adjustments: rating.adjustments,
                                          initialAdjustmentValues: {},
                                          adjustmentValues: setup.ratingAdjustmentValues,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              if (danglingRatingAdjustmentValues.isNotEmpty)
                                Opacity(
                                  opacity: 0.4,
                                  child: Card.outlined(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: const Text("Dangling Rating Values", style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(Intl.plural(
                                            danglingRatingAdjustmentValues.length, 
                                            one: "1 rating value found that is not associated with this bike/person/components.",
                                            other: "${danglingRatingAdjustmentValues.length} rating values found that are not associated with this bike/person/components.",
                                          )),
                                          leading: Icon(Icons.question_mark),
                                        ),
                                        ...danglingRatingAdjustmentValues.entries.map((danglingAdjustmentValue) {
                                          return DisplayDanglingAdjustmentWidget(
                                            name: danglingAdjustmentValue.key, 
                                            initialValue: null,
                                            value: danglingAdjustmentValue.value,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const InitialChangedValueLegend(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      )
    );
  }
}
