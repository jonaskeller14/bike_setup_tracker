class ComponentStats {
  final double distance;
  final double elevationGain;
  final Duration movingTime;
  final Duration elapsedTime;
  final int activityCount;

  const ComponentStats({
    required this.distance,
    required this.elevationGain,
    required this.movingTime,
    required this.elapsedTime,
    required this.activityCount,
  });

  factory ComponentStats.zero() => const ComponentStats(
        distance: 0,
        elevationGain: 0,
        movingTime: Duration.zero,
        elapsedTime: Duration.zero,
        activityCount: 0,
      );

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'elevationGain': elevationGain,
        'movingTime': movingTime.inMicroseconds,
        'elapsedTime': elapsedTime.inMicroseconds,
        'activityCount': activityCount,
      };

  factory ComponentStats.fromJson(Map<String, dynamic> json) {
    return ComponentStats(
      distance: (json['distance'] as num).toDouble(),
      elevationGain: (json['elevationGain'] as num).toDouble(),
      movingTime: Duration(microseconds: json['movingTime'] as int),
      elapsedTime: Duration(microseconds: json['elapsedTime'] as int),
      activityCount: json['activityCount'] as int? ?? 0,
    );
  }

  ComponentStats operator +(ComponentStats other) {
    return ComponentStats(
      distance: distance + other.distance,
      elevationGain: elevationGain + other.elevationGain,
      movingTime: movingTime + other.movingTime,
      elapsedTime: elapsedTime + other.elapsedTime,
      activityCount: activityCount + other.activityCount,
    );
  }

  ComponentStats operator -(ComponentStats other) {
    return ComponentStats(
      distance: distance - other.distance,
      elevationGain: elevationGain - other.elevationGain,
      movingTime: movingTime - other.movingTime,
      elapsedTime: elapsedTime - other.elapsedTime,
      activityCount: activityCount - other.activityCount,
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
          elapsedTime == other.elapsedTime &&
          activityCount == other.activityCount;

  @override
  int get hashCode => Object.hash(distance, elevationGain, movingTime, elapsedTime, activityCount);
}
