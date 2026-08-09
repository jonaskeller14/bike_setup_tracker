import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';

class SpreadsheetExport {
  static List<int>? toExcel(SelectedData data, AppSettings settings) {
    final excel = Excel.createExcel();

    final bikes = data.bikes.values.where((b) => !b.isDeleted).toList();
    if (bikes.isEmpty) {
      excel['No Data'].appendRow([TextCellValue('No bikes found or data is empty.')]);
    }

    for (final bike in bikes) {
      final sheet = excel[bike.name];
      final headerData = _generateHeader(data, settings, bikeId: bike.id);
      
      // Row 1: Merged Group Headers
      sheet.appendRow(headerData.row1.map((e) => TextCellValue(e)).toList());
      // Row 2: Detailed Headers (Sub-groups and Adjustment Names)
      sheet.appendRow(headerData.row2.map((e) => TextCellValue(e)).toList());

      // Apply Merges for Row 1
      for (final merge in headerData.merges) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: merge.start, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: merge.end, rowIndex: 0),
          customValue: TextCellValue(merge.label),
        );
      }

      final setups = data.setups.values.where((s) => s.bike == bike.id && !s.isDeleted).toList();
      setups.sort((a, b) => b.datetime.compareTo(a.datetime));

      for (final setup in setups) {
        final row = _generateSetupCellValueRow(setup, headerData.columnMap, data, settings);
        sheet.appendRow(row);
      }
    }

    _appendTaskLogSheet(excel, data, settings);

    // Drop the default empty sheet once any real sheet has been added.
    if (excel.sheets.length > 1 && excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel.encode();
  }

  static String toCsv(SelectedData data, AppSettings settings) {
    final headerData = _generateHeader(data, settings, includeBikeColumn: true);
    final row1 = headerData.row1;
    final row2 = headerData.row2;
    final columnMap = headerData.columnMap;

    final buffer = StringBuffer();
    buffer.writeln(row1.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    buffer.writeln(row2.map((e) => '"${e.replaceAll('"', '""')}"').join(','));

    final setups = data.setups.values.where((s) => !s.isDeleted).toList();
    setups.sort((a, b) => b.datetime.compareTo(a.datetime));

    for (final setup in setups) {
      final row = _generateSetupStringRow(setup, columnMap, data, settings, includeBikeColumn: true);
      buffer.writeln(row.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    }

    _appendTaskLogCsv(buffer, data, settings);

    return buffer.toString();
  }

  static String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  static void _appendTaskLogCsv(StringBuffer buffer, SelectedData data, AppSettings settings) {
    if (!settings.enableTask) return;

    final entries = _sortedTaskEntries(data);
    if (entries.isEmpty) return;

    buffer.writeln();
    buffer.writeln(_csvCell('Task Log'));
    buffer.writeln(_taskLogHeaders(settings).map(_csvCell).join(','));

    for (final entry in entries) {
      final row = _generateTaskEntryStringRow(entry, data, settings);
      buffer.writeln(row.map(_csvCell).join(','));
    }
  }

  static _HeaderData _generateHeader(SelectedData data, AppSettings settings, {String? bikeId, bool includeBikeColumn = false}) {
    final List<String> row1 = ['General', '', '', '', '', ''];
    final List<String> row2 = ['Name', 'DateTime', 'Tags', 'Notes', 'Place', 'Altitude [${settings.altitudeUnit}]'];
    final Map<String, int> columnMap = {
      'name': 0,
      'datetime': 1,
      'tags': 2,
      'notes': 3,
      'place': 4,
      'altitude': 5,
    };

    if (includeBikeColumn) {
      row1.add('');
      row2.add('Bike');
      columnMap['bike'] = 6;
    }

    int colIndex = includeBikeColumn ? 7 : 6;
    final List<_MergeInfo> merges = [
      _MergeInfo(0, colIndex - 1, 'General'),
    ];

    // Weather Section
    final int weatherStart = colIndex;
    row1.addAll(['Weather', '', '', '', '', '', '']);
    row2.addAll([
      'Weather Code',
      'Temperature [${settings.temperatureUnit}]',
      'Precipitation [${settings.precipitationUnit}]',
      'Humidity [%]',
      'Windspeed [${settings.windSpeedUnit}]',
      'Soil Moisture',
      'Condition'
    ]);
    columnMap['w_code'] = colIndex++;
    columnMap['w_temp'] = colIndex++;
    columnMap['w_precip'] = colIndex++;
    columnMap['w_humid'] = colIndex++;
    columnMap['w_wind'] = colIndex++;
    columnMap['w_soil'] = colIndex++;
    columnMap['w_cond'] = colIndex++;
    merges.add(_MergeInfo(weatherStart, colIndex - 1, 'Weather'));

    // Person Section
    final bike = bikeId != null ? data.bikes[bikeId] : null;
    final personId = bike?.person;
    final person = personId != null ? data.persons[personId] : null;
    if (person != null) {
      final int personStart = colIndex;
      row1.add('Person: ${person.name}');
      row2.add('Name');
      columnMap['p_name'] = colIndex++;

      for (final adj in person.adjustments) {
        row1.add('');
        row2.add('${adj.name}${adj.unit != null ? ' [${adj.unit!.label}]' : ''}');
        columnMap['p_adj_${adj.id}'] = colIndex++;
      }
      merges.add(_MergeInfo(personStart, colIndex - 1, 'Person'));
    }

    // Component Adjustments
    final components = data.components.values
        .where((c) => !c.isDeleted && (bikeId == null || c.bike == bikeId))
        .toList();

    for (final component in components) {
      if (component.adjustments.isEmpty) continue;
      
      final int startCol = colIndex;
      row1.add(component.name);
      for (int i = 1; i < component.adjustments.length; i++) {
        row1.add('');
      }

      for (final adj in component.adjustments) {
        row2.add('${adj.name}${adj.unit != null ? ' [${adj.unit!.label}]' : ''}');
        columnMap['comp_${adj.id}'] = colIndex++;
      }
      
      merges.add(_MergeInfo(startCol, colIndex - 1, component.name));
    }

    return _HeaderData(row1, row2, columnMap, merges);
  }

  static List<CellValue> _generateSetupCellValueRow(Setup setup, Map<String, int> columnMap, SelectedData data, AppSettings settings) {
    final List<CellValue> row = List.filled(columnMap.length, TextCellValue(''));

    row[columnMap['name']!] = TextCellValue(setup.displayName);
    
    final localDt = setup.datetimeLocal;
    row[columnMap['datetime']!] = DateTimeCellValue(
      year: localDt.year,
      month: localDt.month,
      day: localDt.day,
      hour: localDt.hour,
      minute: localDt.minute,
    );
    
    row[columnMap['tags']!] = TextCellValue(setup.tags.join('; '));
    row[columnMap['notes']!] = TextCellValue(setup.notes ?? '');
    
    final city = setup.place?.locality ?? '';
    final country = setup.place?.isoCountryCode ?? '';
    row[columnMap['place']!] = TextCellValue(city.isNotEmpty && country.isNotEmpty ? '$city, $country' : city);

    final alt = setup.position?.altitude;
    if (alt != null) {
      row[columnMap['altitude']!] = DoubleCellValue(ContextPosition.convertAltitudeFromMeters(alt, settings.altitudeUnit) ?? alt);
    }

    // Weather
    final w = setup.weather;
    if (w != null) {
      row[columnMap['w_code']!] = TextCellValue(w.getWeatherCodeLabel() ?? '');
      if (w.currentTemperature != null) {
        row[columnMap['w_temp']!] = DoubleCellValue(ContextWeather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit) ?? 0);
      }
      if (w.dayAccumulatedPrecipitation != null) {
        row[columnMap['w_precip']!] = DoubleCellValue(ContextWeather.convertPrecipitationFromMm(w.dayAccumulatedPrecipitation, settings.precipitationUnit) ?? 0);
      }
      if (w.currentHumidity != null) {
        row[columnMap['w_humid']!] = DoubleCellValue(w.currentHumidity!);
      }
      if (w.currentWindSpeed != null) {
        row[columnMap['w_wind']!] = DoubleCellValue(ContextWeather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit) ?? 0);
      }
      if (w.currentSoilMoisture0to7cm != null) {
        row[columnMap['w_soil']!] = DoubleCellValue(w.currentSoilMoisture0to7cm!);
      }
      row[columnMap['w_cond']!] = TextCellValue(w.condition?.value ?? '');
    }

    // Person
    final bike = data.bikes[setup.bike];
    final person = bike != null ? data.persons[bike.person] : null;
    if (person != null && columnMap.containsKey('p_name')) {
      row[columnMap['p_name']!] = TextCellValue(person.name);
      for (final entry in setup.personAdjustmentValues.entries) {
        final key = 'p_adj_${entry.key}';
        if (columnMap.containsKey(key)) {
          row[columnMap[key]!] = TextCellValue(Adjustment.formatValue(entry.value));
        }
      }
    }

    for (final entry in setup.bikeAdjustmentValues.entries) {
      final key = 'comp_${entry.key}';
      if (columnMap.containsKey(key)) {
        row[columnMap[key]!]= TextCellValue(Adjustment.formatValue(entry.value));
      }
    }

    return row;
  }

  static List<String> _generateSetupStringRow(Setup setup, Map<String, int> columnMap, SelectedData data, AppSettings settings, {bool includeBikeColumn = false}) {
    final List<String> row = List.filled(columnMap.length, '');

    row[columnMap['name']!] = setup.displayName;
    row[columnMap['datetime']!] = DateFormat('yyyy-MM-dd HH:mm').format(setup.datetimeLocal);
    row[columnMap['tags']!] = setup.tags.join('; ');
    row[columnMap['notes']!] = setup.notes ?? '';
    
    final city = setup.place?.locality ?? '';
    final country = setup.place?.isoCountryCode ?? '';
    row[columnMap['place']!] = city.isNotEmpty && country.isNotEmpty ? '$city, $country' : city;

    final alt = setup.position?.altitude;
    if (alt != null) {
      row[columnMap['altitude']!] = (ContextPosition.convertAltitudeFromMeters(alt, settings.altitudeUnit) ?? alt).round().toString();
    }

    if (includeBikeColumn) {
      final bike = data.bikes[setup.bike];
      row[columnMap['bike']!] = bike?.name ?? setup.bike;
    }

    // Weather
    final w = setup.weather;
    if (w != null) {
      row[columnMap['w_code']!] = w.getWeatherCodeLabel() ?? '';
      row[columnMap['w_temp']!] = ContextWeather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit)?.round().toString() ?? '';
      row[columnMap['w_precip']!] = ContextWeather.convertPrecipitationFromMm(w.dayAccumulatedPrecipitation, settings.precipitationUnit)?.round().toString() ?? '';
      row[columnMap['w_humid']!] = w.currentHumidity?.round().toString() ?? '';
      row[columnMap['w_wind']!] = ContextWeather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit)?.round().toString() ?? '';
      row[columnMap['w_soil']!] = w.currentSoilMoisture0to7cm?.toStringAsFixed(2) ?? '';
      row[columnMap['w_cond']!] = w.condition?.value ?? '';
    }

    // Person
    final bike = data.bikes[setup.bike];
    final person = bike != null ? data.persons[bike.person] : null;
    if (person != null && columnMap.containsKey('p_name')) {
      row[columnMap['p_name']!] = person.name;
      for (final entry in setup.personAdjustmentValues.entries) {
        final key = 'p_adj_${entry.key}';
        if (columnMap.containsKey(key)) {
          row[columnMap[key]!] = Adjustment.formatValue(entry.value);
        }
      }
    }

    for (final entry in setup.bikeAdjustmentValues.entries) {
      final key = 'comp_${entry.key}';
      if (columnMap.containsKey(key)) {
        row[columnMap[key]!] = Adjustment.formatValue(entry.value);
      }
    }

    return row;
  }

  static List<TaskEntry> _sortedTaskEntries(SelectedData data) {
    final entries = data.taskEntries.values.where((e) => !e.isDeleted).toList();
    entries.sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC));
    return entries;
  }

  static List<String> _taskLogHeaders(AppSettings settings) {
    final headers = <String>[
      'Name',
      'Notes',
      'DateTime',
      'Link',
      'Task Rule',
      'Task Rule Notes',
      'Task Rule Link',
    ];
    if (settings.enableTaskPriority) headers.add('Priority');
    if (settings.enableTaskTags) headers.add('Tags');
    headers.add('Interval');
    // Snapshot stats only carry meaning when Strava tracking is enabled.
    if (settings.enableStrava) {
      headers.addAll([
        'Distance [${settings.distanceUnit}]',
        'Elevation [${settings.altitudeUnit}]',
        'Moving Time [h]',
        'Activities',
      ]);
    }
    return headers;
  }

  /// Describes what a component/bike pair points at: a component, a bike, or
  /// neither ("General"). Shared by task entries and their rules, which each
  /// link to at most one of a component or a bike.
  static String _linkLabel(String? componentId, String? bikeId, SelectedData data) {
    if (componentId != null) {
      return 'Component: ${data.components[componentId]?.name ?? '?'}';
    }
    if (bikeId != null) {
      return 'Bike: ${data.bikes[bikeId]?.name ?? '?'}';
    }
    return 'General';
  }

  static String _intervalDisplay(TaskRule? taskRule, AppSettings appSettings) {
    return taskRule?.interval?.toDisplayValue(
          distanceUnit: appSettings.distanceUnit,
          altitudeUnit: appSettings.altitudeUnit,
          dateFormat: appSettings.dateFormat,
        ) ??
        '';
  }

  static void _appendTaskLogSheet(Excel excel, SelectedData data, AppSettings settings) {
    if (!settings.enableTask) return;

    final entries = _sortedTaskEntries(data);
    if (entries.isEmpty) return;

    final sheet = excel['Task Log'];
    sheet.appendRow(_taskLogHeaders(settings).map((e) => TextCellValue(e)).toList());
    for (final entry in entries) {
      sheet.appendRow(_generateTaskEntryCellValueRow(entry, data, settings));
    }
  }

  static List<CellValue> _generateTaskEntryCellValueRow(TaskEntry entry, SelectedData data, AppSettings settings) {
    final rule = data.taskRules[entry.taskRule];
    final dt = entry.dateTimeLocal;

    final row = <CellValue>[
      TextCellValue(entry.name),
      TextCellValue(entry.notes ?? ''),
      DateTimeCellValue(year: dt.year, month: dt.month, day: dt.day, hour: dt.hour, minute: dt.minute),
      TextCellValue(_linkLabel(entry.componentId, entry.bikeId, data)),
      TextCellValue(rule?.name ?? ''),
      TextCellValue(rule?.notes ?? ''),
      TextCellValue(rule != null ? _linkLabel(rule.componentId, rule.bikeId, data) : ''),
    ];

    if (settings.enableTaskPriority) row.add(TextCellValue(rule?.priority.label ?? ''));
    if (settings.enableTaskTags) row.add(TextCellValue(rule?.tags.join('; ') ?? ''));
    row.add(TextCellValue(_intervalDisplay(rule, settings)));

    if (settings.enableStrava) {
      final snapshot = entry.snapshot;
      if (snapshot != null) {
        row.addAll([
          DoubleCellValue(AppSettings.convertDistanceFromMeters(snapshot.distance, settings.distanceUnit) ?? snapshot.distance),
          DoubleCellValue(AppSettings.convertElevationFromMeters(snapshot.elevationGain, settings.altitudeUnit) ?? snapshot.elevationGain),
          DoubleCellValue(snapshot.movingTime.inMinutes / 60),
          IntCellValue(snapshot.activityCount),
        ]);
      } else {
        row.addAll(List.filled(4, TextCellValue('')));
      }
    }

    return row;
  }

  static List<String> _generateTaskEntryStringRow(TaskEntry taskEntry, SelectedData data, AppSettings appSettings) {
    final taskRule = data.taskRules[taskEntry.taskRule];

    final row = <String>[
      taskEntry.name,
      taskEntry.notes ?? '',
      DateFormat('yyyy-MM-dd HH:mm').format(taskEntry.dateTimeLocal),
      _linkLabel(taskEntry.componentId, taskEntry.bikeId, data),
      taskRule?.name ?? '',
      taskRule?.notes ?? '',
      taskRule != null ? _linkLabel(taskRule.componentId, taskRule.bikeId, data) : '',
    ];

    if (appSettings.enableTaskPriority) row.add(taskRule?.priority.label ?? '');
    if (appSettings.enableTaskTags) row.add(taskRule?.tags.join('; ') ?? '');
    row.add(_intervalDisplay(taskRule, appSettings));

    if (appSettings.enableStrava) {
      final snapshot = taskEntry.snapshot;
      if (snapshot != null) {
        row.addAll([
          (AppSettings.convertDistanceFromMeters(snapshot.distance, appSettings.distanceUnit) ?? snapshot.distance).toStringAsFixed(1),
          (AppSettings.convertElevationFromMeters(snapshot.elevationGain, appSettings.altitudeUnit) ?? snapshot.elevationGain).round().toString(),
          (snapshot.movingTime.inMinutes / 60).toStringAsFixed(1),
          snapshot.activityCount.toString(),
        ]);
      } else {
        row.addAll(List.filled(4, ''));
      }
    }

    return row;
  }
}

class _MergeInfo {
  final int start;
  final int end;
  final String label;
  _MergeInfo(this.start, this.end, this.label);
}

class _HeaderData {
  final List<String> row1;
  final List<String> row2;
  final Map<String, int> columnMap;
  final List<_MergeInfo> merges;
  _HeaderData(this.row1, this.row2, this.columnMap, this.merges);
}
