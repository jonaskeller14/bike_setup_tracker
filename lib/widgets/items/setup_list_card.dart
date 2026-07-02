import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_weather.dart';
import '../../models/rating_entry.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../utils/setup_actions.dart';
import '../lists/adjustment_compact_display_list.dart';

class SetupListCard extends StatefulWidget {
  final String setupId;
  final void Function()? onTap;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;

  const SetupListCard({
    super.key,
    required this.setupId,
    required this.onTap,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
  });

  @override
  State<SetupListCard> createState() => _SetupListCardState();
}

class _SetupListCardState extends State<SetupListCard> {
  bool _displayOnlyChanges = true;  //TODO: should be false for Setup.isCurrent == true

  Widget _setupCardCurrentLabel(BuildContext context) {
    return Positioned(
      top: -1, 
      right: -1, 
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
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

  Widget _scoreBadge(BuildContext context, double score) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(RatingEntry.iconData, size: 13, color: colorScheme.onPrimaryContainer),
          Text(
            "${score.toStringAsFixed(1)} / 10",
            style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _setupListTile(BuildContext context, Setup setup) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final double? score = appSettings.enableRating
        ? appRepository.scoreForSetup(setup.id)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          setup.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                      if (score != null)
                        _scoreBadge(context, score),
                    ],
                  ),
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
                            DateFormat(appSettings.dateFormat).format(setup.datetimeLocal),
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
                              DateFormat(appSettings.timeFormat).format(setup.datetimeLocal),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Icon(
                        Bike.iconData,
                        size: 13,
                        color: bikes.containsKey(setup.bike)
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.error,
                      ),
                      Flexible(
                        child: Text(
                          bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
                          style: TextStyle(
                            color: bikes.containsKey(setup.bike)
                                ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                : Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
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
                            Icon(ContextWeather.currentTemperatureIconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            Flexible(
                              child: Text(
                                "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      ],
                      if (setup.weather?.condition != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 2,
                          children: [
                            Icon(setup.weather?.condition?.iconData ?? Icons.question_mark, size: 13, color: setup.weather?.condition?.color),
                            Flexible(
                              child: Text(
                                setup.weather?.condition?.value ?? "-",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      if (appSettings.enableSetupTags)
                        ...setup.tags.map((tag) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 2,
                            children: [
                              Icon(Icons.tag, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              Flexible(
                                child: Text(
                                  tag,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }),
                      if (appSettings.enableSetupImages && setup.images.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 2,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            Text('${setup.images.length}',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontSize: 13)),
                          ],
                        ),
                    ],
                  ),
                  if (setup.notes != null && setup.notes!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PopupMenuButton<_SetupOptions>(
                  onSelected: (_SetupOptions value) async {
                    switch (value) {
                      case _SetupOptions.edit:
                        await SetupActions.editSetup(context, setup: setup);
                      case _SetupOptions.share:
                        await SetupActions.shareSetup(context, setup: setup);
                      case _SetupOptions.restore:
                        await SetupActions.duplicateSetup(context, setup: setup);
                      case _SetupOptions.addRating:
                        await SetupActions.addRatingEntryForSetup(context, setup: setup);
                      case _SetupOptions.remove:
                        await SetupActions.removeSetup(context, setup: setup);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return _SetupOptions.values.where((option) {
                      if (!appSettings.enableRating && (option == _SetupOptions.addRating)) return false;
                      return true;
                    }).map((option) {
                      return PopupMenuItem<_SetupOptions>(
                        value: option,
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(option.iconData, size: 20),
                            Text(option.label),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
                ExpandIcon(  
                  //FIXME: only show this if setup has (valid) values,
                  //FIXME: only enable button of difference between displayONlyChanges and displayAll
                  isExpanded: !_displayOnlyChanges,
                  color: PopupMenuTheme.of(context).iconColor ?? IconTheme.of(context).color,
                  expandedColor: Theme.of(context).colorScheme.primary,
                  onPressed: (bool expanded) {
                    setState(() {
                      _displayOnlyChanges = expanded;
                    });
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final setups = appRepository.setups;
    final components = appRepository.components;
    final persons = appRepository.persons;
    final setup = setups[widget.setupId];
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
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _setupListTile(context, setup),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: AdjustmentCompactDisplayList(
                      components: components.values,
                      persons: persons.values,
                      adjustmentValues: {for (var e in setup.personAdjustmentValues.entries) e.key: e.value, for (var e in setup.bikeAdjustmentValues.entries) e.key: e.value},
                      previousAdjustmentValues: {
                        for (var e in setup.previousBikeAdjustmentValues.entries) e.key: e.value,
                        for (var e in setup.previousPersonAdjustmentValues.entries) e.key: e.value,
                      },
                      showRowIcons: true,
                      highlightInitialValues: true,
                      displayOnlyChanges: _displayOnlyChanges,
                      displayBikeAdjustmentValues: widget.displayBikeAdjustmentValues,
                      displayPersonAdjustmentValues: widget.displayPersonAdjustmentValues && appSettings.enablePerson,
                    ),
                  ),
                ),
              ],
            ),
            if (setup.isCurrent)
              _setupCardCurrentLabel(context),
          ],
        ),
      ),
    );
  }
}

enum _SetupOptions {
  edit("Edit", Icons.edit),
  share("Share", Icons.share),
  restore("Restore", Icons.restore),
  addRating("Add Rating", RatingEntry.iconData),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _SetupOptions(this.label, this.iconData);
}
