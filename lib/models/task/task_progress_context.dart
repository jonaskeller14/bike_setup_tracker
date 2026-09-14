import '../component_stats.dart';

class TaskProgressContext {
  final ComponentStats currentStats;
  final ComponentStats baselineStats;
  final DateTime now;
  final DateTime baselineDate;

  const TaskProgressContext({
    required this.currentStats,
    required this.baselineStats,
    required this.now,
    required this.baselineDate,
  });

  ComponentStats get delta => currentStats - baselineStats;
  Duration get elapsed => now.difference(baselineDate);
}
