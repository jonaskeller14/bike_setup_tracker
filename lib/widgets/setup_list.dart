import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../widgets/adjustment_display_list.dart';

class SetupList extends StatefulWidget {
  final List<Setup> setups;
  final List<Component> components;
  final void Function(Setup setup) editSetup;
  final void Function(Setup setup) restoreSetup;
  final void Function(Setup setup) removeSetup;

  const SetupList({
    super.key,
    required this.setups,
    required this.components,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
  });

  @override
  State<SetupList> createState() => _SetupListState();
}

class _SetupListState extends State<SetupList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded
        ? widget.setups.length
        : widget.setups.length.clamp(0, 3);

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: setup.isCurrent
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    // onTap: () => debugPrint("Setup clicked"),
                    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    title: Text(
                      setup.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(setup.datetime),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
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
                  if (setup.notes != null && setup.notes!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3), // tweak to match font size
                          child: Icon(
                            Icons.notes,
                            size: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            setup.notes!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.pedal_bike, size: 13, color: Colors.grey.shade800),
                            const SizedBox(width: 2),
                            Text(
                              setup.bike.name,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (setup.place != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.location_pin, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                        if (setup.position != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.position!.altitude!.round()} m",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                        if (setup.weather?.currentTemperature != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.thermostat, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.weather!.currentTemperature!.toStringAsFixed(1)} °C",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                        if (setup.weather?.currentHumidity != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.opacity, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.weather!.currentHumidity!.round()} %",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                        if (setup.weather?.dayAccumulatedPrecipitation != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.water_drop, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.weather!.dayAccumulatedPrecipitation!.round()} mm",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                        if (setup.weather?.currentWindSpeed != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.air, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.weather!.currentWindSpeed!.round()} km/h",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                        if (setup.weather?.currentSoilMoisture0to7cm != null) ... [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.spa, size: 13, color: Colors.grey.shade800),
                              const SizedBox(width: 2),
                              Text(
                                "${setup.weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)} m³/m³",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        if (widget.setups.length > 3)
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
