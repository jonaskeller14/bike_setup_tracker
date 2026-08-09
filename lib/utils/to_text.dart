import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/task/task_entry.dart';
import '../repositories/app_repository.dart';

String toText({
  required BuildContext context,
  required SelectedData selectedData,
}) {
  final appSettings = context.read<AppSettings>();
  final buffer = StringBuffer();

  final persons = selectedData.persons.values;
  if (appSettings.enablePerson && persons.isNotEmpty) {
    buffer.writeln("PROFILES:");
    for (final p in persons) {
      buffer.writeln("👤 ${p.name}${p.isDeleted ? ' [DELETED]' : ''}");
    }
    buffer.writeln("\n-----------\n");
  }

  final bikes = selectedData.bikes.values;
  if (bikes.isNotEmpty) {
    buffer.writeln("BIKES:");
    for (final b in bikes) {
      if (appSettings.enablePerson) {
        buffer.writeln("🚲 ${b.name} (${selectedData.persons[b.person]?.name ?? '-'})${b.isDeleted ? ' [DELETED]' : ''}");
      } else {
        buffer.writeln("🚲 ${b.name}${b.isDeleted ? ' [DELETED]' : ''}");
      }
      if (b.notes != null && b.notes!.isNotEmpty) buffer.writeln(b.notes!);
    }
    buffer.writeln("\n-----------\n");
  }

  final setups = selectedData.setups.values.toList();
  setups.sort((a, b) => b.datetime.compareTo(a.datetime)); // Sort newest first

  if (setups.isNotEmpty) {
    buffer.writeln("SETUPS:");
    for (int i = 0; i < setups.length; i++) {
      final setup = setups[i];
      _appendSetupText(buffer, setup, selectedData.bikes, selectedData.persons, selectedData.components, selectedData.ratings, appSettings);
      if (i < setups.length - 1) {
        buffer.writeln("\n-----------\n");
      }
    }
  }

  final taskEntries = selectedData.taskEntries.values.where((e) => !e.isDeleted).toList();
  taskEntries.sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC)); // Sort newest first

  if (appSettings.enableTask && taskEntries.isNotEmpty) {
    if (buffer.isNotEmpty) buffer.writeln("\n-----------\n");
    buffer.writeln("TASK LOG:");
    for (int i = 0; i < taskEntries.length; i++) {
      _appendTaskEntryText(buffer, taskEntries[i], selectedData, appSettings);
      if (i < taskEntries.length - 1) {
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
  final buffer = StringBuffer();

  _appendSetupText(
    buffer, 
    setup, 
    appRepository.bikes, 
    appRepository.persons, 
    appRepository.components, 
    appRepository.ratings, 
    appSettings
  );

  return buffer.toString();
}

void _appendSetupText(
  StringBuffer buffer, 
  Setup setup, 
  Map<String, Bike> bikes,
  Map<String, Person> persons,
  Map<String, Component> components,
  Map<String, Rating> ratings,
  AppSettings settings
) {
  final dateString = DateFormat(settings.dateFormat).format(setup.datetimeLocal);
  final timeString = DateFormat(settings.timeFormat).format(setup.datetimeLocal);

  final bikeName = bikes[setup.bike]?.name ?? '-';
  final personName = persons[setup.person]?.name ?? '-';

  if (settings.enablePerson) {
    buffer.writeln("🎛️ $dateString $timeString - ${setup.displayName} ($bikeName | $personName)${setup.isDeleted ? ' [DELETED]' : ''}");
  } else {
    buffer.writeln("🎛️ $dateString $timeString - ${setup.displayName} ($bikeName)${setup.isDeleted ? ' [DELETED]' : ''}");
  }

  // Location & Weather Context compact oneliner
  final contextLine = _generateContextLine(setup, settings);
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
      buffer.writeln("\n👤 ${person.name} Attributes:");
      for (final adj in person.adjustments) {
        if (setup.personAdjustmentValues.containsKey(adj.id)) {
          buffer.writeln("- ${adj.name}: ${Adjustment.formatValue(setup.personAdjustmentValues[adj.id])}${adj.unitSuffix()}");
        }
      }
    }
  }

  // Component Adjustments
  for (final component in components.values) {
    if (!component.adjustments.any((adj) => setup.bikeAdjustmentValues.containsKey(adj.id))) continue;

    buffer.writeln("\n- ${component.name}");
    for (final adjustment in component.adjustments) {
      if (setup.bikeAdjustmentValues.containsKey(adjustment.id)) {
        buffer.writeln("\t- ${adjustment.name}: ${Adjustment.formatValue(setup.bikeAdjustmentValues[adjustment.id])}${adjustment.unitSuffix()}");
      }
    }
  }

}

void _appendTaskEntryText(
  StringBuffer buffer,
  TaskEntry entry,
  SelectedData data,
  AppSettings settings,
) {
  final dateString = DateFormat(settings.dateFormat).format(entry.dateTimeLocal);
  final timeString = DateFormat(settings.timeFormat).format(entry.dateTimeLocal);

  final entryLink = _taskLinkLabel(entry.componentId, entry.bikeId, data);
  final contextString = entryLink != null ? ' ($entryLink)' : '';

  buffer.writeln("✅ $dateString $timeString - ${entry.name}$contextString${entry.isDeleted ? ' [DELETED]' : ''}");

  final rule = data.taskRules[entry.taskRule];
  if (rule != null) {
    final ruleLink = _taskLinkLabel(rule.componentId, rule.bikeId, data);
    buffer.writeln("📋 ${rule.name}${ruleLink != null ? ' ($ruleLink)' : ''}");

    final metaParts = [
      if (settings.enableTaskPriority) rule.priority.label,
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
      "${snapshot.activityCount} rides",
    );
  }
}

String? _taskLinkLabel(String? componentId, String? bikeId, SelectedData data) {
  if (componentId != null) {
    return 'Component: ${data.components[componentId]?.name ?? '?'}';
  }
  if (bikeId != null) {
    return 'Bike: ${data.bikes[bikeId]?.name ?? '?'}';
  }
  return null;
}

String _generateContextLine(Setup setup, AppSettings settings) {
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
    final label = w.getWeatherCodeLabel();
    if (label != null) weatherParts.add(label);
    
    if (w.currentTemperature != null) {
      final temp = ContextWeather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit)?.round() ?? w.currentTemperature!.round();
      weatherParts.add('$temp ${settings.temperatureUnit}');
    }

    if (w.currentHumidity != null) {
      weatherParts.add('${w.currentHumidity!.round()} % Humidity');
    }

    if (w.currentWindSpeed != null) {
      final speed = ContextWeather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit)?.round() ?? w.currentWindSpeed!.round();
      weatherParts.add('$speed ${settings.windSpeedUnit} Wind');
    }

    if (w.condition != null) {
      weatherParts.add(w.condition!.value);
    }

    if (weatherParts.isNotEmpty) {
      parts.add("☁️ ${weatherParts.join(', ')}");
    }
  }

  return parts.join(" | ");
}
