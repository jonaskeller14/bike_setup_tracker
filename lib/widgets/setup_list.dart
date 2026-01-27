import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/filtered_data.dart';
import '../models/setup.dart';
import '../models/bike.dart';
import '../models/weather.dart';
import '../models/app_settings.dart';
import '../pages/setup_display_page.dart';
import 'adjustment_compact_display_list.dart';
import 'initial_changed_value_legend.dart';

class SetupList extends StatefulWidget {
  final Map<String, Setup> setups;
  final void Function(Setup setup) editSetup;
  final void Function(Setup setup) restoreSetup;
  final void Function(Setup setup) removeSetup;
  final bool displayOnlyChanges;
  final Widget filterWidget;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;
  final bool accending;

  const SetupList({
    super.key,
    required this.setups,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
    required this.displayOnlyChanges,
    required this.filterWidget,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    required this.displayRatingAdjustmentValues,
    required this.accending,
  });

  @override
  State<SetupList> createState() => _SetupListState();
}

class _SetupListState extends State<SetupList> {
  int _maxItemCount = 10;
  static const int _itemCountIncrement = 10;

  @override
  Widget build(BuildContext context) {
    final visibleItemCount = widget.setups.length.clamp(0, _maxItemCount);
    
    final setups = widget.setups.values.toList();

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
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
            children: [
              widget.filterWidget,
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItemCount,
                itemBuilder: (context, index) {
                  final setup = widget.accending 
                      ? setups[index] 
                      : setups[widget.setups.length - 1 - index];
                  return InkWell(
                    onTap: () async {
                      Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                        setupIds: setups.map((s) => s.id).toList(),
                        initialSetup: setup,
                        editSetup: widget.editSetup,
                      )));
                    },
                    child: SetupCard(
                      setupId: setup.id,
                      editSetup: widget.editSetup,
                      restoreSetup: widget.restoreSetup,
                      removeSetup: widget.removeSetup,
                      displayOnlyChanges: widget.displayOnlyChanges,
                      displayBikeAdjustmentValues: widget.displayBikeAdjustmentValues,
                      displayPersonAdjustmentValues: widget.displayPersonAdjustmentValues,
                      displayRatingAdjustmentValues: widget.displayRatingAdjustmentValues,  
                    ),
                  ); 
                },
              ),
              if (widget.setups.length > visibleItemCount)
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _maxItemCount += _itemCountIncrement),
                    icon: const Icon(Icons.expand_more),
                    label: const Text("Show more"),
                  ),
                ),
              const SizedBox(height: 60),
              const InitialChangedValueLegend(),
            ]
          );
  }
}

class SetupCard extends StatelessWidget {
  final String setupId;
  final void Function(Setup setup) editSetup;
  final void Function(Setup setup) restoreSetup;
  final void Function(Setup setup) removeSetup;
  final bool displayOnlyChanges;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;

  const SetupCard({
    super.key,
    required this.setupId,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
    required this.displayOnlyChanges,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    required this.displayRatingAdjustmentValues,
  });

  Widget _setupCardCurrentLabel(BuildContext context) {
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

  ListTile _setupListTile(BuildContext context, Setup setup) {
    final appSettings = context.watch<AppSettings>();
    final filteredData = context.watch<FilteredData>();
    final bikes = filteredData.bikes;
    
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      minTileHeight: 0,
      titleAlignment: ListTileTitleAlignment.top,
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
                spacing: 2,
                children: [
                  Icon(Icons.calendar_month, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                spacing: 2,
                children: [
                  Icon(Icons.access_time, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      DateFormat(appSettings.timeFormat).format(setup.datetime),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Bike.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      bikes[setup.bike]?.name ?? "-",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (setup.place != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(Icons.location_pin, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (setup.weather?.currentTemperature != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(Weather.currentTemperatureIconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        "${Weather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                  ],
                )
              ],
              if (setup.weather?.condition != null) ... [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(setup.weather?.condition?.getIconData() ?? Icons.question_mark, size: 13, color: setup.weather?.condition?.getColor()),
                    Flexible(
                      child: Text(
                        setup.weather?.condition?.value ?? "-",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      ),
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
            editSetup(setup);
          } else if (value == 'restore') {
            restoreSetup(setup);
          } else if (value == 'remove') {
            removeSetup(setup);
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

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final setups = filteredData.setups;
    final components = filteredData.components;
    final persons = filteredData.persons;
    final ratings = filteredData.ratings;
    final setup = setups[setupId];
    if (setup == null) return const SizedBox.shrink();

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
              _setupListTile(context, setup),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: AdjustmentCompactDisplayList(
                  components: [for (var c in components.values) c, for (var p in persons.values) p, for (var r in ratings.values) r],
                  adjustmentValues: {for (var e in setup.personAdjustmentValues.entries) e.key: e.value, for (var e in setup.bikeAdjustmentValues.entries) e.key: e.value, for (var e in setup.ratingAdjustmentValues.entries) e.key: e.value},
                  previousAdjustmentValues: {for (var e in (setup.previousBikeSetup?.bikeAdjustmentValues.entries ?? {}.entries)) e.key: e.value, for (var e in (setup.previousPersonSetup?.personAdjustmentValues.entries ?? {}.entries)) e.key: e.value},
                  showComponentIcons: true,
                  highlightInitialValues: true,
                  displayOnlyChanges: displayOnlyChanges,
                  displayBikeAdjustmentValues: displayBikeAdjustmentValues,
                  displayPersonAdjustmentValues: displayPersonAdjustmentValues,
                  displayRatingAdjustmentValues: displayRatingAdjustmentValues,
                ),
              ),
            ],
          ),
          if (setup.isCurrent)
            _setupCardCurrentLabel(context),
        ],
      ),
    );
  }
}
