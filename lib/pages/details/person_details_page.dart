import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../icons/simple_icons.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../models/weather.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/person_actions.dart';
import '../../utils/table_column.dart';
import '../../widgets/chips/bike_and_tags_filter.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/sheets/column_filter.dart';
import '../../widgets/text/section_title.dart';

class PersonDetailsPage extends StatefulWidget {
  final String personId;

  const PersonDetailsPage({super.key, required this.personId});

  @override
  State<PersonDetailsPage> createState() => _PersonDetailsPageState();
}

class _PersonDetailsPageState extends State<PersonDetailsPage> {
  bool _sortAscending = true;
  TableColumn? _sortColumn;

  static const bool _highlighting = true;

  final Set<TableColumn> _columns = {
    TableColumn(section: TableColumnSection.generalContext, label: "Name", active: true),
    TableColumn(section: TableColumnSection.generalContext, label: "Notes", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Tags", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Date", active: true),
    TableColumn(section: TableColumnSection.generalContext, label: "Time", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Place", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Altitude", active: false),
    TableColumn(section: TableColumnSection.generalContext, label: "Bike", active: false),
  };

  List<Setup> sortSetupsByColumn({
    required List<Setup> setups,
    required Iterable<Adjustment> componentAdjustments,
    required Iterable<Adjustment> personAdjustments,
    required Iterable<Adjustment> ratingAdjustments,
    required Map<String, Bike> bikes,
  }) {
    if (_sortColumn == null) return setups;

    switch (_sortColumn!.section) {
      case TableColumnSection.generalContext || TableColumnSection.weatherContext:
        switch (_sortColumn!.label) {
          case "Name": _sortAscending 
            ? setups.sort((a, b) => a.name.compareTo(b.name)) 
            : setups.sort((a, b) => b.name.compareTo(a.name));
          case "Notes": _sortAscending 
              ? setups.sort((a, b) => (a.notes ?? '').compareTo(b.notes ?? '')) 
              : setups.sort((a, b) => (b.notes ?? '').compareTo(a.notes ?? ''));
          case "Tags": _sortAscending 
              ? setups.sort((a, b) => a.tags.join('; ').compareTo(b.tags.join('; '))) 
              : setups.sort((a, b) => b.tags.join('; ').compareTo(a.tags.join('; ')));
          case "Date": _sortAscending 
              ? setups.sort((a, b) => a.datetime.compareTo(b.datetime)) 
              : setups.sort((a, b) => b.datetime.compareTo(a.datetime));
          case "Time": _sortAscending 
              ? setups.sort((a, b) => a.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(b.datetime.copyWith(year: 0, month: 0, day: 0))) 
              : setups.sort((a, b) => b.datetime.copyWith(year: 0, month: 0, day: 0).compareTo(a.datetime.copyWith(year: 0, month: 0, day: 0)));
          case "Place": _sortAscending 
              ? setups.sort((a, b) => (a.place?.locality ?? '').compareTo(b.place?.locality ?? '')) 
              : setups.sort((a, b) => (b.place?.locality ?? '').compareTo(a.place?.locality ?? ''));
          case "Altitude": _sortAscending 
              ? setups.sort((a, b) => (a.position?.altitude ?? double.negativeInfinity).compareTo(b.position?.altitude ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.position?.altitude ?? double.negativeInfinity).compareTo(a.position?.altitude ?? double.negativeInfinity));
          case "Bike": _sortAscending 
            ? setups.sort((a, b) => (bikes[a.bike]?.name ?? '').compareTo(bikes[b.bike]?.name ?? '')) 
            : setups.sort((a, b) => (bikes[b.bike]?.name ?? '').compareTo(bikes[a.bike]?.name ?? ''));
          case "Weather Code": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.getWeatherCodeLabel() ?? '').compareTo(b.weather?.getWeatherCodeLabel() ?? '')) 
              : setups.sort((a, b) => (b.weather?.getWeatherCodeLabel() ?? '').compareTo(a.weather?.getWeatherCodeLabel() ?? ''));
          case "Temperature": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Precipitation": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Humidity": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Windspeed": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Soil Moisture": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.currentTemperature ?? double.negativeInfinity).compareTo(b.weather?.currentTemperature ?? double.negativeInfinity)) 
              : setups.sort((a, b) => (b.weather?.currentTemperature ?? double.negativeInfinity).compareTo(a.weather?.currentTemperature ?? double.negativeInfinity));
          case "Condition": _sortAscending 
              ? setups.sort((a, b) => (a.weather?.condition?.value ?? '').compareTo(b.weather?.condition?.value ?? '')) 
              : setups.sort((a, b) => (b.weather?.condition?.value ?? '').compareTo(a.weather?.condition?.value ?? ''));
        }
      case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes || TableColumnSection.ratingMetrics:
        final column2value = switch (_sortColumn!.section) {
          TableColumnSection.componentAdjustments => (Setup s) => s.bikeAdjustmentValues[_sortColumn!.label],
          TableColumnSection.personAttributes => (Setup s) => s.personAdjustmentValues[_sortColumn!.label],
          TableColumnSection.ratingMetrics => (Setup s) => s.ratingAdjustmentValues[_sortColumn!.label],
          _ => null, 
        };
        if (column2value == null) return setups;

        final Adjustment? adjustment = switch (_sortColumn!.section) {
          TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == _sortColumn!.label),
          TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == _sortColumn!.label),
          TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == _sortColumn!.label),
          _ => null,
        };
        if (adjustment == null) return setups;

        switch (adjustment) {
          case BooleanAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? false) ? 1 : 0).compareTo((column2value(b) ?? false) ? 1 : 0)) 
              : setups.sort((a, b) => ((column2value(b) ?? false) ? 1 : 0).compareTo((column2value(a) ?? false) ? 1 : 0));
          case StepAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? 0) as int).compareTo((column2value(b) ?? 0) as int)) 
              : setups.sort((a, b) => ((column2value(b) ?? 0) as int).compareTo((column2value(a) ?? 0) as int));
          case NumericalAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? double.negativeInfinity) as double).compareTo((column2value(b) ?? double.negativeInfinity) as double)) 
              : setups.sort((a, b) => ((column2value(b) ?? double.negativeInfinity) as double).compareTo((column2value(a) ?? double.negativeInfinity) as double));
          case CategoricalAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? '') as String).compareTo((column2value(b) ?? '') as String)) 
              : setups.sort((a, b) => ((column2value(b) ?? '') as String).compareTo((column2value(a) ?? '') as String));
          case TextAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? '') as String).compareTo((column2value(b) ?? '') as String)) 
              : setups.sort((a, b) => ((column2value(b) ?? '') as String).compareTo((column2value(a) ?? '') as String));
          case DurationAdjustment(): _sortAscending 
              ? setups.sort((a, b) => ((column2value(a) ?? Duration.zero) as Duration).compareTo((column2value(b) ?? Duration.zero) as Duration)) 
              : setups.sort((a, b) => ((column2value(b) ?? Duration.zero) as Duration).compareTo((column2value(a) ?? Duration.zero) as Duration));
        }
    }
    return setups;
  }

  Widget _noColumnsPlaceholder() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Select a column to display the table',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _noSetupsPlaceholder({required bool hasAdjustments}) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          hasAdjustments
              ? 'No setups yet'
              : 'No attribute defined for this person',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();

    final bikes = appRepository.bikes;

    final person = appRepository.persons[widget.personId];
    if (person == null) return const SizedBox.shrink();
    final personAdjustments = person.adjustments;

    final stravaAthlete = appRepository.stravaAthletes[person.stravaAthlete];

    // Remove only invalid columns (to keep prior modifications to 'active')
    for (final column in _columns.toSet()) {
      switch (column.section) {
        case TableColumnSection.generalContext:
          if (column.label == "Tags" && !appSettings.enableSetupTags) _columns.remove(column);
        case TableColumnSection.componentAdjustments:
          _columns.remove(column);
        case TableColumnSection.personAttributes:
          if (!personAdjustments.any((pa) => pa.id == column.label)) {
            _columns.remove(column);
            continue;
          }          
        case TableColumnSection.ratingMetrics:
          _columns.remove(column);
        case TableColumnSection.weatherContext: continue; 
      }
    }

    // Add missing columns
    if (appSettings.enableSetupTags) {
      _columns.add(TableColumn(section: TableColumnSection.generalContext, label: "Tags", active: false));
    }
    _columns.addAll(personAdjustments.map((a) => TableColumn(section: TableColumnSection.personAttributes, label: a.id, active: true)));

    final sortedColumns = _columns.sorted((a, b) => a.section.index.compareTo(b.section.index));  // sort by enum index
    final activeColumns = sortedColumns.where((c) => c.active).toList();
    if (!activeColumns.contains(_sortColumn)) _sortColumn = null;

    final setupsUnsorted = appRepository.filteredSetups.values.where(
        (s) => person.adjustments.any((adj) => s.personAdjustmentValues.containsKey(adj.id))
    ).toList().reversed.toList();

    final setups = sortSetupsByColumn(
      setups: setupsUnsorted,
      componentAdjustments: [],
      personAdjustments: personAdjustments,
      ratingAdjustments: [],
      bikes: bikes,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Person.iconData),
            Expanded(
              child: Text(person.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => PersonActions.editPerson(context, person: person),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (person.notes != null)
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.top,
                  title: SelectableText(person.notes!),
                  dense: true,
                ),

              if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement)
                ListTile(
                  leading: Badge(
                    label: const Icon(SimpleIcons.strava, size: 11),
                    backgroundColor: Colors.transparent,
                    child: person.stravaAthlete != null
                        ? Icon(Icons.link, color: appRepository.stravaAthletes.containsKey(person.stravaAthlete) ? null : Theme.of(context).colorScheme.error)
                        : const Icon(Icons.link_off),
                  ),                
                  title: Text(
                    stravaAthlete != null
                        ? "${stravaAthlete.firstname} ${stravaAthlete.lastname}" 
                        : (person.stravaAthlete == null 
                            ? "No Strava Athlete linked to this person." 
                            : "STRAVA ATHLETE NOT FOUND"),
                    style: TextStyle(
                      color: person.stravaAthlete == null || stravaAthlete != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),

              if ((appSettings.enableStrava && subscriptionService.hasStravaEntitlement) || person.notes != null)
                const Divider(height: 1),

              const SectionTitle(title: "Attribute History"),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 6,
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.view_column_outlined),
                      showCheckmark: false,
                      label: const Text("Columns"),
                      selected: _columns.any((c) => c.active),
                      onSelected: (bool newValue) async {
                        await showColumnFilterSheet(
                          context: context, 
                          sortedColumns: sortedColumns, 
                          componentAdjustments: [],
                          ratingAdjustments: [],
                          personAdjustments: personAdjustments,
                          onColumnStatusChanged: () => setState(() {}), // TableColumn.active is changed
                        );
                      },
                    ),
                    BikeAndTagsFilterChip(enableSetupTagFilter: appSettings.enableSetupTags),
                  ],
                ),
              ),

              if (activeColumns.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DataTable(
                    sortAscending: _sortAscending,
                    sortColumnIndex: activeColumns.contains(_sortColumn) 
                        ? activeColumns.indexOf(_sortColumn!)
                        : null,
                    columnSpacing: 20,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                    dataRowMaxHeight: double.infinity,
                    columns: activeColumns.map((column) {
                      switch (column.section) {
                        case TableColumnSection.generalContext || TableColumnSection.weatherContext:
                          return DataColumn(
                            label: Text(column.label, overflow: TextOverflow.ellipsis),
                            onSort: (int _, bool ascending) {
                              setState(() {
                                _sortAscending = ascending;
                                _sortColumn = column;
                              });
                            },
                          );
                        case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes || TableColumnSection.ratingMetrics:
                          final Adjustment? adjustment = switch (column.section) {
                            TableColumnSection.componentAdjustments => null,
                            TableColumnSection.ratingMetrics => null,
                            TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label),
                            _ => null,
                          };
                          return DataColumn(
                            label: Text(
                              (adjustment?.name ?? "-") + (adjustment?.unit != null ? " [${adjustment!.unit}]" : ""),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onSort: (int _, bool ascending) {
                              setState(() {
                                _sortAscending = ascending;
                                _sortColumn = column;
                              });
                            },
                          );
                      }
                    }).toList(),
                    rows: setups.map((setup) {
                      return DataRow(
                        cells: activeColumns.map((column) {
                          switch (column.section) {
                            case TableColumnSection.generalContext:
                              return switch (column.label) {
                                "Name" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.name, overflow: TextOverflow.ellipsis)))),
                                "Notes" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.notes ?? '-', overflow: TextOverflow.ellipsis)))),
                                "Tags" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.tags.isEmpty ? '-' : setup.tags.join('; '), overflow: TextOverflow.ellipsis)))),
                                "Date" => DataCell(Text(DateFormat(appSettings.dateFormat).format(setup.datetimeLocal))),
                                "Time" => DataCell(Text(DateFormat(appSettings.timeFormat).format(setup.datetimeLocal))),
                                "Place" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(setup.place?.locality ?? '-', overflow: TextOverflow.ellipsis)))),
                                "Altitude" => DataCell(Center(child: Text(setup.position?.altitude == null ? '-' : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}"))),
                                "Bike" => DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(bikes[setup.bike]?.name ?? '-', overflow: TextOverflow.ellipsis)))),
                                _ => const DataCell(Text("ERROR")),
                              };
                            case TableColumnSection.weatherContext:
                              return switch (column.label) {
                                "Weather Code" => DataCell(Center(child: Text(setup.weather?.getWeatherCodeLabel() ?? "-"))),
                                "Temperature" => DataCell(Center(child: Text(setup.weather?.currentTemperature == null ? '-' : "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}"))),
                                "Precipitation" => DataCell(Center(child: Text(setup.weather?.dayAccumulatedPrecipitation == null ? '-' : "${Weather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}"))),
                                "Humidity" => DataCell(Center(child: Text(setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %"))),
                                "Windspeed" => DataCell(Center(child: Text(setup.weather?.currentWindSpeed == null ? '-' : "${Weather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}"))),
                                "Soil Moisture" => DataCell(Center(child: Text(setup.weather?.currentSoilMoisture0to7cm == null ? '-' : setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)))),
                                "Condition" => DataCell(Center(child: Text(setup.weather?.condition == null ? '-' : setup.weather!.condition!.value))),
                                _ => const DataCell(Text("ERROR")),
                              };
                            case TableColumnSection.componentAdjustments || TableColumnSection.personAttributes || TableColumnSection.ratingMetrics:
                              final value = switch (column.section) {
                                TableColumnSection.componentAdjustments => setup.bikeAdjustmentValues[column.label],
                                TableColumnSection.ratingMetrics => setup.ratingAdjustmentValues[column.label],
                                TableColumnSection.personAttributes => setup.personAdjustmentValues[column.label],
                                _ => null,
                              };
                              final initialValue = switch (column.section) {
                                TableColumnSection.componentAdjustments => setup.previousBikeAdjustmentValues[column.label],
                                TableColumnSection.ratingMetrics => setup.previousRatingAdjustmentValues[column.label],
                                TableColumnSection.personAttributes => setup.previousPersonAdjustmentValues[column.label],
                                _ => null,
                              };
             
                              Color? highlightColor;
                              if (_highlighting) {
                                final bool isChanged = value != null && initialValue != value;
                                final bool isInitial = initialValue == null;
                                highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
                              }
        
                              return DataCell(
                                Center(
                                  child: Text(
                                    Adjustment.formatValue(value), 
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: highlightColor, fontWeight: highlightColor != null ? FontWeight.bold : null),
                                  ),
                                ),
                              );
                          }
                        }).toList(),
                      );
                    }).toList(),
                  ),
                )
              else
                _noColumnsPlaceholder(),
              if (setups.isEmpty)
                _noSetupsPlaceholder(hasAdjustments: person.adjustments.isNotEmpty),
              if (activeColumns.isNotEmpty && setups.isNotEmpty)
                const InitialChangedValueLegend(),
            ],
          ),
        )
      ),
    );
  }
}
