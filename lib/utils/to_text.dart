import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/enum_labels.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/feedback/feedback_summary.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/person.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/task/task_association.dart';
import '../models/task/task_entry.dart';
import '../repositories/app_repository.dart';

String toText({
  required BuildContext context,
  required SelectedData selectedData,
}) {
  final appSettings = context.read<AppSettings>();
  final l10n = context.l10n;
  return withLocaleOf(l10n, () => _toText(selectedData, appSettings, l10n));
}

String _toText(SelectedData selectedData, AppSettings appSettings, AppLocalizations l10n) {
  final buffer = StringBuffer();

  final persons = selectedData.persons.values;
  if (appSettings.enablePerson && persons.isNotEmpty) {
    buffer.writeln("${l10n.exportSectionRiders.toUpperCase()}:");
    for (final p in persons) {
      buffer.writeln("👤 ${p.name}${p.isDeleted ? ' ${l10n.exportDeleted}' : ''}");
    }
    buffer.writeln("\n-----------\n");
  }

  final bikes = selectedData.bikes.values;
  if (bikes.isNotEmpty) {
    buffer.writeln("${l10n.exportSectionBikes.toUpperCase()}:");
    for (final b in bikes) {
      if (appSettings.enablePerson) {
        buffer.writeln("🚲 ${b.name} (${selectedData.persons[b.person]?.name ?? '-'})${b.isDeleted ? ' ${l10n.exportDeleted}' : ''}");
      } else {
        buffer.writeln("🚲 ${b.name}${b.isDeleted ? ' ${l10n.exportDeleted}' : ''}");
      }
      if (b.notes != null && b.notes!.isNotEmpty) buffer.writeln(b.notes!);
    }
    buffer.writeln("\n-----------\n");
  }

  final setups = selectedData.setups.values.toList();
  setups.sort((a, b) => b.datetime.compareTo(a.datetime)); // Sort newest first

  if (setups.isNotEmpty) {
    buffer.writeln("${l10n.exportSectionSetups.toUpperCase()}:");
    for (int i = 0; i < setups.length; i++) {
      final setup = setups[i];
      _appendSetupText(buffer, setup, selectedData.bikes, selectedData.persons, selectedData.components, appSettings, l10n);
      if (i < setups.length - 1) {
        buffer.writeln("\n-----------\n");
      }
    }
  }

  final taskEntries = selectedData.taskEntries.values.where((e) => !e.isDeleted).toList();
  taskEntries.sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC)); // Sort newest first

  if (appSettings.enableTask && taskEntries.isNotEmpty) {
    if (buffer.isNotEmpty) buffer.writeln("\n-----------\n");
    buffer.writeln("${l10n.exportSectionTaskLog.toUpperCase()}:");
    for (int i = 0; i < taskEntries.length; i++) {
      _appendTaskEntryText(buffer, taskEntries[i], selectedData, appSettings, l10n);
      if (i < taskEntries.length - 1) {
        buffer.writeln();
      }
    }
  }

  final feedbacks = selectedData.feedbacks.values.where((f) => !f.isDeleted).toList();
  feedbacks.sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC)); // Sort newest first

  if (appSettings.enableRating && feedbacks.isNotEmpty) {
    if (buffer.isNotEmpty) buffer.writeln("\n-----------\n");
    buffer.writeln("${l10n.exportSectionFeedback.toUpperCase()}:");
    for (int i = 0; i < feedbacks.length; i++) {
      _appendFeedbackText(buffer, feedbacks[i], selectedData, appSettings);
      if (i < feedbacks.length - 1) {
        buffer.writeln();
      }
    }
  }

  return buffer.toString();
}

String setupToText({
  required BuildContext context,
  required Setup setup,
}) {
  final appSettings = context.read<AppSettings>();
  final appRepository = context.read<AppRepository>();
  final l10n = context.l10n;
  final buffer = StringBuffer();

  withLocaleOf(l10n, () => _appendSetupText(
    buffer, 
    setup, 
    appRepository.bikes, 
    appRepository.persons, 
    appRepository.components, 
    appSettings,
    l10n
  ));

  return buffer.toString();
}

void _appendSetupText(
  StringBuffer buffer, 
  Setup setup, 
  Map<String, Bike> bikes,
  Map<String, Person> persons,
  Map<String, Component> components,
  AppSettings settings,
  AppLocalizations l10n,
) {
  final dateString = DateFormat(settings.dateFormat).format(setup.datetimeLocal);
  final timeString = DateFormat(settings.timeFormat).format(setup.datetimeLocal);

  final bikeName = bikes[setup.bike]?.name ?? '-';
  final personName = persons[setup.person]?.name ?? '-';

  final bookmark = settings.enableSetupBookmark && setup.isBookmarked ? ' 🔖' : '';

  if (settings.enablePerson) {
    buffer.writeln("🎛️ $dateString $timeString - ${setup.displayName}$bookmark ($bikeName | $personName)${setup.isDeleted ? ' ${l10n.exportDeleted}' : ''}");
  } else {
    buffer.writeln("🎛️ $dateString $timeString - ${setup.displayName}$bookmark ($bikeName)${setup.isDeleted ? ' ${l10n.exportDeleted}' : ''}");
  }

  // Location & Weather Context compact oneliner
  final contextLine = _generateContextLine(setup, settings, l10n);
  if (contextLine.isNotEmpty) {
    buffer.writeln(contextLine);
  }

  if (setup.notes != null && setup.notes!.isNotEmpty) {
    buffer.writeln(setup.notes!);
  }

  if (setup.tags.isNotEmpty) {
    buffer.writeln("🏷️ ${setup.tags.join(', ')}");
  }

  // Person Attributes
  if (settings.enablePerson && setup.personAdjustmentValues.isNotEmpty) {
    final person = persons[setup.person];
    if (person != null) {
      buffer.writeln("\n👤 ${l10n.exportRiderAttributes(person.name)}");
      for (final adj in person.adjustments) {
        if (setup.personAdjustmentValues[adj.id] case final value?) {
          buffer.writeln("- ${adj.name}: ${value.display}${adj.unitSuffix()}");
        }
      }
    }
  }

  // Component Adjustments
  for (final component in components.values) {
    if (!component.adjustments.any((adj) => setup.bikeAdjustmentValues[adj.id] != null)) continue;

    buffer.writeln("\n- ${component.name}");
    for (final adjustment in component.adjustments) {
      if (setup.bikeAdjustmentValues[adjustment.id] case final value?) {
        buffer.writeln("\t- ${adjustment.name}: ${value.display}${adjustment.unitSuffix()}");
      }
    }
  }

}

void _appendFeedbackText(
  StringBuffer buffer,
  RideFeedback feedback,
  SelectedData data,
  AppSettings settings,
) {
  final dateString = DateFormat(settings.dateFormat).format(feedback.dateTimeLocal);
  final timeString = DateFormat(settings.timeFormat).format(feedback.dateTimeLocal);
  final setup = feedback.ratedSetupIn(data.setups) ?? data.setups[feedback.setupId];
  final context = [?setup?.displayName, ?data.bikes[feedback.bike]?.name].join(', ');

  buffer.writeln("💬 $dateString $timeString${context.isEmpty ? '' : ' ($context)'}");
  for (final line in [?feedback.verdict(data.setups), ?feedback.issuesSummary, ?feedback.notes]) {
    if (line.isNotEmpty) buffer.writeln(line);
  }
}

void _appendTaskEntryText(
  StringBuffer buffer,
  TaskEntry entry,
  SelectedData data,
  AppSettings settings,
  AppLocalizations l10n,
) {
  final dateString = DateFormat(settings.dateFormat).format(entry.dateTimeLocal);
  final timeString = DateFormat(settings.timeFormat).format(entry.dateTimeLocal);

  final entryLink = _taskLinkLabel(entry.association, data, l10n);
  final contextString = entryLink != null ? ' ($entryLink)' : '';

  buffer.writeln("✅ $dateString $timeString - ${entry.name}$contextString${entry.isDeleted ? ' ${l10n.exportDeleted}' : ''}");

  final rule = data.taskRules[entry.taskRule];
  if (rule != null) {
    final ruleLink = _taskLinkLabel(rule.association, data, l10n);
    buffer.writeln("📋 ${rule.name}${ruleLink != null ? ' ($ruleLink)' : ''}");

    final metaParts = [
      if (settings.enableTaskPriority) rule.priority.label(l10n),
      if (settings.enableTaskTags && rule.tags.isNotEmpty) '🏷️ ${rule.tags.join(', ')}',
    ];
    if (metaParts.isNotEmpty) {
      buffer.writeln(metaParts.join(' · '));
    }

    if (rule.notes != null && rule.notes!.isNotEmpty) {
      buffer.writeln(rule.notes!);
    }
  }

  if (entry.notes != null && entry.notes!.isNotEmpty) {
    buffer.writeln(entry.notes!);
  }

  final snapshot = entry.snapshot;
  if (settings.enableStrava && snapshot != null) {
    final distance = AppSettings.convertDistanceFromMeters(snapshot.distance, settings.distanceUnit)?.round() ?? snapshot.distance.round();
    final elevation = AppSettings.convertElevationFromMeters(snapshot.elevationGain, settings.altitudeUnit)?.round() ?? snapshot.elevationGain.round();
    buffer.writeln(
      "📈 $distance ${settings.distanceUnit}, "
      "$elevation ${settings.altitudeUnit}, "
      "${snapshot.movingTime.inHours}h ${snapshot.movingTime.inMinutes.remainder(60)}m, "
      "${snapshot.activityCount} ${l10n.taskUnitRides(snapshot.activityCount)}",
    );
  }
}

String? _taskLinkLabel(TaskAssociation association, SelectedData data, AppLocalizations l10n) {
  return switch (association) {
    ComponentTaskAssociation(:final id) => l10n.exportLinkComponent(data.components[id]?.name ?? '?'),
    BikeTaskAssociation(:final id) => l10n.exportLinkBike(data.bikes[id]?.name ?? '?'),
    GeneralTaskAssociation() => null,
  };
}

String _generateContextLine(Setup setup, AppSettings settings, AppLocalizations l10n) {
  final parts = <String>[];

  // Location
  final city = setup.place?.locality ?? '';
  final country = setup.place?.isoCountryCode ?? '';
  final altitude = setup.position?.altitude;
  
  String locationStr = '';
  if (city.isNotEmpty || country.isNotEmpty) {
    locationStr = city.isNotEmpty && country.isNotEmpty ? '$city, $country' : city;
  }
  
  if (altitude != null) {
    final altVal = ContextPosition.convertAltitudeFromMeters(altitude, settings.altitudeUnit)?.round() ?? altitude.round();
    locationStr += locationStr.isNotEmpty ? ' ($altVal ${settings.altitudeUnit})' : '$altVal ${settings.altitudeUnit}';
  }

  if (locationStr.isNotEmpty) {
    parts.add("📍 $locationStr");
  }

  // Weather
  final w = setup.weather;
  if (w != null) {
    final weatherParts = <String>[];
    final label = w.getWeatherCodeLabel(l10n);
    if (label != null) weatherParts.add(label);
    
    if (w.currentTemperature != null) {
      final temp = ContextWeather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit)?.round() ?? w.currentTemperature!.round();
      weatherParts.add('$temp ${settings.temperatureUnit}');
    }

    if (w.currentHumidity != null) {
      weatherParts.add(l10n.exportWeatherHumidity(w.currentHumidity!.round()));
    }

    if (w.currentWindSpeed != null) {
      final speed = ContextWeather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit)?.round() ?? w.currentWindSpeed!.round();
      weatherParts.add(l10n.exportWeatherWind(speed, settings.windSpeedUnit));
    }

    if (w.condition != null) {
      weatherParts.add(w.condition!.label(l10n));
    }

    if (weatherParts.isNotEmpty) {
      parts.add("☁️ ${weatherParts.join(', ')}");
    }
  }

  return parts.join(" | ");
}
