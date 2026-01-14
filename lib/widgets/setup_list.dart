import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/setup.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/weather.dart';
import '../models/app_settings.dart';
import '../pages/setup_display_page.dart';
import 'adjustment_compact_display_list.dart';

const defaultVisibleCount = 10;

class SetupList extends StatefulWidget {
  final Map<String, Person> persons;
  final Map<String, Rating> ratings;
  final Map<String, Bike> bikes;
  final List<Setup> setups;
  final List<Component> components;
  final void Function(Setup setup) editSetup;
  final void Function(Setup setup) restoreSetup;
  final void Function(Setup setup) removeSetup;
  final bool displayOnlyChanges;
  final Widget filterWidget;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;
  final Setup? Function({required DateTime datetime, String? bike, String? person}) getPreviousSetupbyDateTime;

  const SetupList({
    super.key,
    required this.persons,
    required this.ratings,
    required this.bikes,
    required this.setups,
    required this.components,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
    required this.displayOnlyChanges,
    required this.filterWidget,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    required this.displayRatingAdjustmentValues,
    required this.getPreviousSetupbyDateTime,
  });

  @override
  State<SetupList> createState() => _SetupListState();
}

class _SetupListState extends State<SetupList> {
  bool _expanded = false;

  Widget _setupCardCurrentLabel() {
    return Positioned(
      top: -1, 
      right: -1, 
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(12 / 2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          'Current',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  ListTile _setupListTile(Setup setup, {required String dateFormat, required String timeFormat, required String altitudeUnit, required String temperatureUnit}) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      minTileHeight: 0,
      title: Text(
        setup.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    DateFormat(dateFormat).format(setup.datetime),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    DateFormat(timeFormat).format(setup.datetime),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Bike.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    widget.bikes[setup.bike]?.name ?? "-",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (setup.place != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_pin, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
              if (setup.position?.altitude != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      "${Setup.convertAltitudeFromMeters(setup.position!.altitude!, altitudeUnit).round()} $altitudeUnit",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                )
              ],
              if (setup.weather?.currentTemperature != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.thermostat, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, temperatureUnit).round()} $temperatureUnit",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                )
              ],
              if (setup.weather?.condition != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    setup.weather!.getConditionsIcon(size: 13),
                    const SizedBox(width: 2),
                    Text(
                      setup.weather?.condition?.value ?? "-",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                )
              ],
            ],
          ),
          if (setup.notes != null && setup.notes!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(
                    Icons.notes,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    setup.notes!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            widget.editSetup(setup);
          } else if (value == 'restore') {
            widget.restoreSetup(setup);
          } else if (value == 'remove') {
            widget.removeSetup(setup);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 10),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'restore',
            child: Row(
              children: [
                Icon(Icons.restore, size: 20),
                SizedBox(width: 10),
                Text('Restore'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 10),
                Text('Remove'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Card _setupCard(Setup setup, {required String dateFormat, required String timeFormat, required String altitudeUnit, required String temperatureUnit}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: setup.isCurrent 
          ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ))
          : null,
      child: Stack(
        children: [ 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _setupListTile(
                setup,
                dateFormat: dateFormat,
                timeFormat: timeFormat,
                altitudeUnit: altitudeUnit,
                temperatureUnit: temperatureUnit, 
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: AdjustmentCompactDisplayList(
                  components: [for (var c in widget.components) c, for (var p in widget.persons.values.toList()) p, for (var r in widget.ratings.values.toList()) r],
                  adjustmentValues: {for (var e in setup.personAdjustmentValues.entries) e.key: e.value, for (var e in setup.bikeAdjustmentValues.entries) e.key: e.value, for (var e in setup.ratingAdjustmentValues.entries) e.key: e.value},
                  previousAdjustmentValues: {for (var e in (setup.previousBikeSetup?.bikeAdjustmentValues.entries ?? {}.entries)) e.key: e.value, for (var e in (setup.previousPersonSetup?.personAdjustmentValues.entries ?? {}.entries)) e.key: e.value},
                  showComponentIcons: true,
                  highlightInitialValues: true,
                  displayOnlyChanges: widget.displayOnlyChanges,
                  displayBikeAdjustmentValues: widget.displayBikeAdjustmentValues,
                  displayPersonAdjustmentValues: widget.displayPersonAdjustmentValues,
                  displayRatingAdjustmentValues: widget.displayRatingAdjustmentValues,
                ),
              ),
            ],
          ),
          if (setup.isCurrent)
            _setupCardCurrentLabel(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final visibleCount = _expanded
        ? widget.setups.length
        : widget.setups.length.clamp(0, defaultVisibleCount);

    return widget.setups.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.filterWidget,
                Expanded(
                  child: Center(
                    child: Text(
                      'No setups yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            children: [
              widget.filterWidget,
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCount,
                itemBuilder: (context, index) {
                  final setup = widget.setups[widget.setups.length - 1 - index];
                  return InkWell(
                    onTap: () async {
                      //FIXME: for getPreviousSetupbyDateTime we need all setups, not just the filtered ones (which are displayed in this SetupList)
                      Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                        setups: widget.setups,
                        initialSetup: setup,
                        bikes: widget.bikes,
                        persons: widget.persons,
                        components: widget.components,
                        getPreviousSetupbyDateTime: widget.getPreviousSetupbyDateTime,
                      )));
                    },
                    child: _setupCard(
                      setup,
                      dateFormat: appSettings.dateFormat,
                      timeFormat: appSettings.timeFormat,
                      altitudeUnit: appSettings.altitudeUnit,
                      temperatureUnit: appSettings.temperatureUnit, 
                    ),
                  ); 
                },
              ),
              if (widget.setups.length > defaultVisibleCount)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(_expanded ? "Show less" : "Show more"),
                  ),
                ),
            ]
          );
  }
}
