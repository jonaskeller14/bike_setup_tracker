import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('packCellRows', () {
    List<List<int>> pack(List<double> widths, {double rowWidth = 100, double spacing = 0}) =>
        packCellRows(widths: widths, rowWidth: rowWidth, spacing: spacing);

    test('no cells -> no rows', () {
      expect(pack([]), isEmpty);
    });

    test('everything that fits stays in one row', () {
      expect(pack([30, 30, 40]), [
        [0, 1, 2],
      ]);
    });

    test('spacing counts towards the row width', () {
      expect(pack([50, 50], spacing: 4), [
        [0],
        [1],
      ]);
    });

    test('balances rows instead of a full row followed by a lonely cell', () {
      // Greedy wrap: [25, 25, 25, 25] + [25].
      expect(pack([25, 25, 25, 25, 25]), [
        [0, 1, 2],
        [3, 4],
      ]);
    });

    test('keeps the fewest rows even when an extra row would be more even', () {
      expect(pack([20, 20, 20, 20, 20, 60]), hasLength(2));
    });

    test('preserves cell order', () {
      final rows = pack([60, 10, 50, 30, 40, 20]);
      expect(rows.expand((row) => row), [0, 1, 2, 3, 4, 5]);
    });

    test('breaks ties towards fuller earlier rows', () {
      expect(pack([40, 40, 40]), [
        [0, 1],
        [2],
      ]);
    });

    test('a cell wider than the row gets a row of its own', () {
      expect(pack([30, 150, 30]), [
        [0],
        [1],
        [2],
      ]);
    });

    test('capped cells always pair up', () {
      const rowWidth = 100.0;
      const spacing = 4.0;
      final cap = cellWidthCap(rowWidth: rowWidth, spacing: spacing);
      expect(pack([cap, cap, cap, cap], rowWidth: rowWidth, spacing: spacing), [
        [0, 1],
        [2, 3],
      ]);
    });
  });

  group('AdjustmentCell.resolve', () {
    final pressure = NumericalAdjustment(id: 'p', name: 'Pressure', notes: null, unit: null, min: 0, max: 200);
    final mode = TextAdjustment(id: 'm', name: 'Mode', notes: null, unit: null);

    AdjustmentCell resolve(dynamic value, dynamic previous, {bool isError = false, Adjustment? adjustment}) =>
        AdjustmentCell.resolve(
          adjustment: adjustment ?? pressure,
          value: value,
          previousValue: previous,
          isError: isError,
        );

    test('classifies by previous value', () {
      expect(resolve(80, null), isA<InitialCell>());
      expect(resolve(80, 80), isA<ConstantCell>());
      expect(resolve(80, 85), isA<ChangedCell>().having((c) => c.previousValue, 'previousValue', 85));
      expect(resolve(80, 85, isError: true), isA<ErrorCell>());
    });

    test('only initial and changed cells count as changes', () {
      expect(resolve(80, null).isChange, isTrue);
      expect(resolve(80, 85).isChange, isTrue);
      expect(resolve(80, 80).isChange, isFalse);
      expect(resolve(80, null, isError: true).isChange, isFalse);
    });

    test('numeric change shows a signed delta', () {
      expect(resolve(80, 85).displayText.change, '-5');
      expect(resolve(90, 85).displayText.change, '+5');
      expect(resolve(90, 85).displayText.changeDecoration, TextDecoration.none);
    });

    test('non-numeric change strikes through the previous value', () {
      final display = resolve('Open', 'Closed', adjustment: mode).displayText;
      expect(display.value, 'Open');
      expect(display.change, 'Closed');
      expect(display.changeDecoration, TextDecoration.lineThrough);
    });

    test('unchanged and error cells show no change', () {
      expect(resolve(80, 80).displayText.hasChange, isFalse);
      expect(resolve(80, 85, isError: true).displayText.hasChange, isFalse);
    });
  });
}
