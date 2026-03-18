class ComponentStats {
  final double distance;
  final double elevationGain;
  final Duration movingTime;
  final Duration elapsedTime;

  const ComponentStats({
    required this.distance,
    required this.elevationGain,
    required this.movingTime,
    required this.elapsedTime,
  });

  factory ComponentStats.zero() => const ComponentStats(
        distance: 0,
        elevationGain: 0,
        movingTime: Duration.zero,
        elapsedTime: Duration.zero,
      );

  ComponentStats operator +(ComponentStats other) {
    return ComponentStats(
      distance: distance + other.distance,
      elevationGain: elevationGain + other.elevationGain,
      movingTime: movingTime + other.movingTime,
      elapsedTime: elapsedTime + other.elapsedTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentStats &&
          runtimeType == other.runtimeType &&
          distance == other.distance &&
          elevationGain == other.elevationGain &&
          movingTime == other.movingTime &&
          elapsedTime == other.elapsedTime;

  @override
  int get hashCode => Object.hash(distance, elevationGain, movingTime, elapsedTime);
}
