import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import '../models/app_data.dart';
import '../models/setup.dart';
import '../models/adjustment/adjustment.dart';

class SpreadsheetExport {
  static List<int>? toExcel(AppData appData) {
    final excel = Excel.createExcel();

    final bikes = appData.bikes.values.where((b) => !b.isDeleted).toList();
    

    for (final bike in bikes) {
      final sheet = excel[bike.name];
      final headerData = _generateHeader(appData, bikeId: bike.id);
      
      sheet.appendRow(headerData.row1.map((e) => TextCellValue(e)).toList());
      sheet.appendRow(headerData.row2.map((e) => TextCellValue(e)).toList());

      for (final merge in headerData.merges) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: merge.start, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: merge.end, rowIndex: 0),
          customValue: TextCellValue(merge.label),
        );
      }

      final setups = appData.setups.values.where((s) => s.bike == bike.id && !s.isDeleted).toList();
      setups.sort((a, b) => b.datetime.compareTo(a.datetime));

      for (final setup in setups) {
        final row = _generateSetupCellValueRow(setup, headerData.columnMap, appData);
        sheet.appendRow(row);
      }
    }

    if (bikes.isEmpty) {
      excel['No Data'].appendRow([TextCellValue('No bikes found or data is empty.')]);
    } else {
      excel.delete(excel.getDefaultSheet() ?? "Sheet1");
    }

    return excel.encode();
  }

  static String toCsv(AppData appData) {
    // CSV is a flat format, so we'll combine all bikes or just list everything.
    // For simplicity, we'll generate one big table with an extra "Bike" column.
    final headerData = _generateHeader(appData, includeBikeColumn: true);
    final row1 = headerData.row1;
    final row2 = headerData.row2;
    final columnMap = headerData.columnMap;

    final buffer = StringBuffer();
    buffer.writeln(row1.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    buffer.writeln(row2.map((e) => '"${e.replaceAll('"', '""')}"').join(','));

    final setups = appData.setups.values.where((s) => !s.isDeleted).toList();
    setups.sort((a, b) => b.datetime.compareTo(a.datetime));

    for (final setup in setups) {
      final row = _generateSetupStringRow(setup, columnMap, appData, includeBikeColumn: true);
      buffer.writeln(row.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    }

    return buffer.toString();
  }

  static _HeaderData _generateHeader(AppData appData, {String? bikeId, bool includeBikeColumn = false}) {
    final List<String> row1 = ['General', '', '', '', ''];
    final List<String> row2 = ['Name', 'DateTime', 'Tags', 'Notes', 'Place'];
    final Map<String, int> columnMap = {
      'name': 0,
      'datetime': 1,
      'tags': 2,
      'notes': 3,
      'place': 4,
    };

    if (includeBikeColumn) {
      row1.add('');
      row2.add('Bike');
      columnMap['bike'] = 5;
    }

    final List<_MergeInfo> merges = [
      _MergeInfo(0, includeBikeColumn ? 5 : 4, 'General'),
    ];

    int colIndex = includeBikeColumn ? 6 : 5;

    // Filter components by bike if specified
    final components = appData.components.values
        .where((c) => !c.isDeleted && (bikeId == null || c.bike == bikeId))
        .toList();

    // Add Component Adjustments
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

    // Add Ratings if any
    final Set<String> ratingAdjIds = {};
    final setups = appData.setups.values.where((s) => !s.isDeleted && (bikeId == null || s.bike == bikeId));
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
        for (final rating in appData.ratings.values) {
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

  static List<CellValue> _generateSetupCellValueRow(Setup setup, Map<String, int> columnMap, AppData appData) {
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
    row[columnMap['place']!] = TextCellValue(setup.place?.locality ?? '');

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

  static List<String> _generateSetupStringRow(Setup setup, Map<String, int> columnMap, AppData appData, {bool includeBikeColumn = false}) {
    final List<String> row = List.filled(columnMap.length, '');

    row[columnMap['name']!] = setup.name;
    row[columnMap['datetime']!] = DateFormat('yyyy-MM-dd HH:mm').format(setup.datetimeLocal);
    row[columnMap['tags']!] = setup.tags.join('; ');
    row[columnMap['notes']!] = setup.notes ?? '';
    row[columnMap['place']!] = setup.place?.locality ?? '';

    if (includeBikeColumn) {
      final bike = appData.bikes[setup.bike];
      row[columnMap['bike']!] = bike?.name ?? setup.bike;
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
