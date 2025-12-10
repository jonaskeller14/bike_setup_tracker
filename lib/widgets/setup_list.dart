import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/setup.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/weather.dart';
import '../models/app_settings.dart';
import '../widgets/adjustment_display_list.dart';

const defaultVisibleCount = 10;

class SetupList extends StatefulWidget {
  final Map<String, Bike> bikes;
  final List<Setup> setups;
  final List<Component> components;
  final void Function(Setup setup) editSetup;
  final void Function(Setup setup) restoreSetup;
  final void Function(Setup setup) removeSetup;
  final bool displayOnlyChanges;

  const SetupList({
    super.key,
    required this.bikes,
    required this.setups,
    required this.components,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
    this.displayOnlyChanges = false,
  });

  @override
  State<SetupList> createState() => _SetupListState();
}

class _SetupListState extends State<SetupList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final visibleCount = _expanded
        ? widget.setups.length
        : widget.setups.length.clamp(0, defaultVisibleCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCount,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, index) {
            final setup = widget.setups[widget.setups.length - 1 - index];

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
                      ListTile(
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
                                      DateFormat(appSettings.dateFormat).format(setup.datetime),
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
                                      DateFormat(appSettings.timeFormat).format(setup.datetime),
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
                                    Icon(Icons.pedal_bike, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                        "${Setup.convertAltitudeFromMeters(setup.position!.altitude!, appSettings.altitudeUnit).round()} ${appSettings.altitudeUnit}",
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
                                        "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit).round()} ${appSettings.temperatureUnit}",
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                      ),
                                    ],
                                  )
                                ],
                                if (setup.weather?.currentSoilMoisture0to7cm != null) ... [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      setup.weather!.getConditionsIcon(size: 13),
                                      const SizedBox(width: 2),
                                      Text(
                                        setup.weather?.getConditionsLabel() ?? "-",
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                        child: AdjustmentDisplayList(
                          components: widget.components,
                          adjustmentValues: setup.adjustmentValues,
                          previousAdjustmentValues: setup.previousSetup?.adjustmentValues,
                          showComponentIcons: true,
                          highlightInitialValues: true,
                          displayOnlyChanges: widget.displayOnlyChanges,
                        ),
                      ),
                    ],
                  ),
                  if (setup.isCurrent)
                    Positioned(
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
                    ),
                ],
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
      ],
    );
  }
}
