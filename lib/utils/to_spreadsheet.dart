import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/weather.dart';

class SpreadsheetExport {
  static List<int>? toExcel(SelectedData appRepository, AppSettings settings) {
    final excel = Excel.createExcel();

    final bikes = appRepository.bikes.values.where((b) => !b.isDeleted).toList();
    if (bikes.isEmpty) {
      excel['No Data'].appendRow([TextCellValue('No bikes found or data is empty.')]);
    }

    for (final bike in bikes) {
      final sheet = excel[bike.name];
      final headerData = _generateHeader(appRepository, settings, bikeId: bike.id);
      
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

      final setups = appRepository.setups.values.where((s) => s.bike == bike.id && !s.isDeleted).toList();
      setups.sort((a, b) => b.datetime.compareTo(a.datetime));

      for (final setup in setups) {
        final row = _generateSetupCellValueRow(setup, headerData.columnMap, appRepository, settings);
        sheet.appendRow(row);
      }
    }

    if (bikes.isNotEmpty && excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel.encode();
  }

  static String toCsv(SelectedData appRepository, AppSettings settings) {
    final headerData = _generateHeader(appRepository, settings, includeBikeColumn: true);
    final row1 = headerData.row1;
    final row2 = headerData.row2;
    final columnMap = headerData.columnMap;

    final buffer = StringBuffer();
    buffer.writeln(row1.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    buffer.writeln(row2.map((e) => '"${e.replaceAll('"', '""')}"').join(','));

    final setups = appRepository.setups.values.where((s) => !s.isDeleted).toList();
    setups.sort((a, b) => b.datetime.compareTo(a.datetime));

    for (final setup in setups) {
      final row = _generateSetupStringRow(setup, columnMap, appRepository, settings, includeBikeColumn: true);
      buffer.writeln(row.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    }

    return buffer.toString();
  }

  static _HeaderData _generateHeader(SelectedData appRepository, AppSettings settings, {String? bikeId, bool includeBikeColumn = false}) {
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
    final bike = bikeId != null ? appRepository.bikes[bikeId] : null;
    final personId = bike?.person;
    final person = personId != null ? appRepository.persons[personId] : null;
    if (person != null) {
      final int personStart = colIndex;
      row1.add('Person: ${person.name}');
      row2.add('Name');
      columnMap['p_name'] = colIndex++;

      for (final adj in person.adjustments) {
        row1.add('');
        row2.add('${adj.name}${adj.unit != null ? ' [${adj.unit}]' : ''}');
        columnMap['p_adj_${adj.id}'] = colIndex++;
      }
      merges.add(_MergeInfo(personStart, colIndex - 1, 'Person'));
    }

    // Component Adjustments
    final components = appRepository.components.values
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
        row2.add('${adj.name}${adj.unit != null ? ' [${adj.unit}]' : ''}');
        columnMap['comp_${adj.id}'] = colIndex++;
      }
      
      merges.add(_MergeInfo(startCol, colIndex - 1, component.name));
    }

    // Add Ratings
    final Set<String> ratingAdjIds = {};
    final setups = appRepository.setups.values.where((s) => !s.isDeleted && (bikeId == null || s.bike == bikeId));
    for (final setup in setups) {
      ratingAdjIds.addAll(setup.ratingAdjustmentValues.keys);
    }

    if (ratingAdjIds.isNotEmpty) {
      final int startCol = colIndex;
      row1.add('Ratings');
      for (int i = 1; i < ratingAdjIds.length; i++) {
        row1.add('');
      }
      for (final adjId in ratingAdjIds) {
        String name = adjId;
        for (final rating in appRepository.ratings.values) {
          final adj = rating.adjustments.firstWhereOrNull((a) => a.id == adjId);
          if (adj != null) {
            name = '${adj.name}${adj.unit != null ? ' [${adj.unit}]' : ''}';
            break;
          }
        }
        row2.add(name);
        columnMap['rate_$adjId'] = colIndex++;
      }
      merges.add(_MergeInfo(startCol, colIndex - 1, 'Ratings'));
    }

    return _HeaderData(row1, row2, columnMap, merges);
  }

  static List<CellValue> _generateSetupCellValueRow(Setup setup, Map<String, int> columnMap, SelectedData appRepository, AppSettings settings) {
    final List<CellValue> row = List.filled(columnMap.length, TextCellValue(''));

    row[columnMap['name']!] = TextCellValue(setup.name);
    
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
      row[columnMap['altitude']!] = DoubleCellValue(Setup.convertAltitudeFromMeters(alt, settings.altitudeUnit) ?? alt);
    }

    // Weather
    final w = setup.weather;
    if (w != null) {
      row[columnMap['w_code']!] = TextCellValue(w.getWeatherCodeLabel() ?? '');
      if (w.currentTemperature != null) {
        row[columnMap['w_temp']!] = DoubleCellValue(Weather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit) ?? 0);
      }
      if (w.dayAccumulatedPrecipitation != null) {
        row[columnMap['w_precip']!] = DoubleCellValue(Weather.convertPrecipitationFromMm(w.dayAccumulatedPrecipitation, settings.precipitationUnit) ?? 0);
      }
      if (w.currentHumidity != null) {
        row[columnMap['w_humid']!] = DoubleCellValue(w.currentHumidity!);
      }
      if (w.currentWindSpeed != null) {
        row[columnMap['w_wind']!] = DoubleCellValue(Weather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit) ?? 0);
      }
      if (w.currentSoilMoisture0to7cm != null) {
        row[columnMap['w_soil']!] = DoubleCellValue(w.currentSoilMoisture0to7cm!);
      }
      row[columnMap['w_cond']!] = TextCellValue(w.condition?.value ?? '');
    }

    // Person
    final bike = appRepository.bikes[setup.bike];
    final person = bike != null ? appRepository.persons[bike.person] : null;
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

    for (final entry in setup.ratingAdjustmentValues.entries) {
      final key = 'rate_${entry.key}';
      if (columnMap.containsKey(key)) {
        row[columnMap[key]!] = TextCellValue(Adjustment.formatValue(entry.value));
      }
    }

    return row;
  }

  static List<String> _generateSetupStringRow(Setup setup, Map<String, int> columnMap, SelectedData appRepository, AppSettings settings, {bool includeBikeColumn = false}) {
    final List<String> row = List.filled(columnMap.length, '');

    row[columnMap['name']!] = setup.name;
    row[columnMap['datetime']!] = DateFormat('yyyy-MM-dd HH:mm').format(setup.datetimeLocal);
    row[columnMap['tags']!] = setup.tags.join('; ');
    row[columnMap['notes']!] = setup.notes ?? '';
    
    final city = setup.place?.locality ?? '';
    final country = setup.place?.isoCountryCode ?? '';
    row[columnMap['place']!] = city.isNotEmpty && country.isNotEmpty ? '$city, $country' : city;

    final alt = setup.position?.altitude;
    if (alt != null) {
      row[columnMap['altitude']!] = (Setup.convertAltitudeFromMeters(alt, settings.altitudeUnit) ?? alt).round().toString();
    }

    if (includeBikeColumn) {
      final bike = appRepository.bikes[setup.bike];
      row[columnMap['bike']!] = bike?.name ?? setup.bike;
    }

    // Weather
    final w = setup.weather;
    if (w != null) {
      row[columnMap['w_code']!] = w.getWeatherCodeLabel() ?? '';
      row[columnMap['w_temp']!] = Weather.convertTemperatureFromCelsius(w.currentTemperature, settings.temperatureUnit)?.round().toString() ?? '';
      row[columnMap['w_precip']!] = Weather.convertPrecipitationFromMm(w.dayAccumulatedPrecipitation, settings.precipitationUnit)?.round().toString() ?? '';
      row[columnMap['w_humid']!] = w.currentHumidity?.round().toString() ?? '';
      row[columnMap['w_wind']!] = Weather.convertWindSpeedFromKmh(w.currentWindSpeed, settings.windSpeedUnit)?.round().toString() ?? '';
      row[columnMap['w_soil']!] = w.currentSoilMoisture0to7cm?.toStringAsFixed(2) ?? '';
      row[columnMap['w_cond']!] = w.condition?.value ?? '';
    }

    // Person
    final bike = appRepository.bikes[setup.bike];
    final person = bike != null ? appRepository.persons[bike.person] : null;
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

    for (final entry in setup.ratingAdjustmentValues.entries) {
      final key = 'rate_${entry.key}';
      if (columnMap.containsKey(key)) {
        row[columnMap[key]!] = Adjustment.formatValue(entry.value);
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
