import '../models/component/component.dart';

/// Returns the index of the assigned [right] item for every [left] item.
/// The Hungarian assignment keeps matching deterministic and order-independent.
List<int> maximumScoreAssignment<T>(
  List<T> left,
  List<T> right,
  double Function(T left, T right) score,
) {
  assert(left.length <= right.length);
  final rowCount = left.length;
  final columnCount = right.length;
  final rowPotential = List<double>.filled(rowCount + 1, 0);
  final columnPotential = List<double>.filled(columnCount + 1, 0);
  final rowForColumn = List<int>.filled(columnCount + 1, 0);
  final previousColumn = List<int>.filled(columnCount + 1, 0);

  for (var row = 1; row <= rowCount; row++) {
    rowForColumn[0] = row;
    var column = 0;
    final minimum = List<double>.filled(columnCount + 1, double.infinity);
    final used = List<bool>.filled(columnCount + 1, false);
    do {
      used[column] = true;
      final currentRow = rowForColumn[column];
      var delta = double.infinity;
      var nextColumn = 0;
      for (var candidateColumn = 1; candidateColumn <= columnCount; candidateColumn++) {
        if (used[candidateColumn]) continue;
        final cost =
            -score(left[currentRow - 1], right[candidateColumn - 1]) -
            rowPotential[currentRow] -
            columnPotential[candidateColumn];
        if (cost < minimum[candidateColumn]) {
          minimum[candidateColumn] = cost;
          previousColumn[candidateColumn] = column;
        }
        if (minimum[candidateColumn] < delta) {
          delta = minimum[candidateColumn];
          nextColumn = candidateColumn;
        }
      }
      for (var candidateColumn = 0; candidateColumn <= columnCount; candidateColumn++) {
        if (used[candidateColumn]) {
          rowPotential[rowForColumn[candidateColumn]] += delta;
          columnPotential[candidateColumn] -= delta;
        } else {
          minimum[candidateColumn] -= delta;
        }
      }
      column = nextColumn;
    } while (rowForColumn[column] != 0);

    do {
      final nextColumn = previousColumn[column];
      rowForColumn[column] = rowForColumn[nextColumn];
      column = nextColumn;
    } while (column != 0);
  }

  final result = List<int>.filled(rowCount, 0);
  for (var column = 1; column <= columnCount; column++) {
    final row = rowForColumn[column];
    if (row != 0) result[row - 1] = column - 1;
  }
  return result;
}

double componentSimilarity(Component a, Component b) {
  final nameScore = nameSimilarity(a.name, b.name);
  final adjustmentSimilarity = setOverlap(
    a.adjustments.map((adjustment) => normalize(adjustment.name)).toSet(),
    b.adjustments.map((adjustment) => normalize(adjustment.name)).toSet(),
  );
  return nameScore * 0.7 + adjustmentSimilarity * 0.3;
}

double nameSimilarity(String a, String b) {
  final normalizedA = normalize(a);
  final normalizedB = normalize(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) return 0;
  final tokenSimilarity = setOverlap(
    normalizedA.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet(),
    normalizedB.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet(),
  );
  final bigramSimilarity = setOverlap(
    bigrams(normalizedA.replaceAll(' ', '')),
    bigrams(normalizedB.replaceAll(' ', '')),
  );
  return tokenSimilarity * 0.6 + bigramSimilarity * 0.4;
}

Set<String> bigrams(String value) {
  if (value.isEmpty) return const {};
  if (value.length == 1) return {value};
  return {
    for (var index = 0; index < value.length - 1; index++) value.substring(index, index + 2),
  };
}

double setOverlap(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  return 2 * a.intersection(b).length / (a.length + b.length);
}

String normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
