import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/weather.dart';
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
  Map<String, dynamic> bikes, 
  Map<String, dynamic> persons, 
  Map<String, dynamic> components, 
  Map<String, dynamic> ratings,
  AppSettings settings
) {
  final dateString = DateFormat(settings.dateFormat).format(setup.datetimeLocal);
  final timeString = DateFormat(settings.timeFormat).format(setup.datetimeLocal);

  final bikeName = bikes[setup.bike]?.name ?? '-';
  final personName = persons[setup.person]?.name ?? '-';

  if (settings.enablePerson) {
    buffer.writeln("🎛️ $dateString $timeString - ${setup.name} ($bikeName | $personName)${setup.isDeleted ? ' [DELETED]' : ''}");
  } else {
    buffer.writeln("🎛️ $dateString $timeString - ${setup.name} ($bikeName)${setup.isDeleted ? ' [DELETED]' : ''}");
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

  // Rating Metrics
  if (settings.enableRating && setup.ratingAdjustmentValues.isNotEmpty) {
    buffer.writeln("\n📊 Ratings:");
    for (final rating in ratings.values) {
      for (final adj in rating.adjustments) {
        if (setup.ratingAdjustmentValues.containsKey(adj.id)) {
          buffer.writeln("- ${adj.name}: ${Adjustment.formatValue(setup.ratingAdjustmentValues[adj.id])}${adj.unitSuffix()}");
        }
      }
    }
  }
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
    final altVal = Setup.convertAltitudeFromMeters(altitude, settings.altitudeUnit)?.round() ?? altitude.round();
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
      final temp = Weather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit)?.round() ?? w.currentTemperature!.round();
      weatherParts.add('$temp ${settings.temperatureUnit}');
    }

    if (w.currentHumidity != null) {
      weatherParts.add('${w.currentHumidity!.round()} % Humidity');
    }

    if (w.currentWindSpeed != null) {
      final speed = Weather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit)?.round() ?? w.currentWindSpeed!.round();
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
