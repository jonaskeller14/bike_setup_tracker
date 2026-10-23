import 'package:flutter/foundation.dart';

@immutable
sealed class TestSessionMethod {
  const TestSessionMethod();

  String get type;

  Map<String, dynamic> toJson() => {'type': type};

  factory TestSessionMethod.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      PatternSearch._type => const PatternSearch(),
      OrthogonalArray._type => const OrthogonalArray(),
      Tournament._type => Tournament(
        candidateSetupIds: (json['candidateSetupIds'] as List).map((e) => e as String).toList(),
      ),
      _ => throw Exception('Unknown test session method: $type'),
    };
  }

  @override
  bool operator ==(Object other) => other is TestSessionMethod && other.type == type;

  @override
  int get hashCode => type.hashCode;
}

/// Local optimization ("Fine-tune"): poll one knob ± one step around the best
/// run, move further after a success, halve the step when nothing helps.
/// With one knob this is bracketing.
final class PatternSearch extends TestSessionMethod {
  static const String _type = 'patternSearch';

  const PatternSearch();

  @override
  String get type => _type;
}

/// Broad optimization ("Explore"): every run changes all knobs in a two-level
/// orthogonal pattern (Hadamard / Plackett–Burman), so each knob's effect can
/// be estimated from about one run per knob.
final class OrthogonalArray extends TestSessionMethod {
  static const String _type = 'orthogonalArray';

  const OrthogonalArray();

  @override
  String get type => _type;
}

/// "Compare": rides existing setups against each other to find the best one.
final class Tournament extends TestSessionMethod {
  static const String _type = 'tournament';

  final List<String> candidateSetupIds;

  const Tournament({required this.candidateSetupIds});

  @override
  String get type => _type;

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'candidateSetupIds': candidateSetupIds};

  @override
  bool operator ==(Object other) => other is Tournament && listEquals(candidateSetupIds, other.candidateSetupIds);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(candidateSetupIds));
}
