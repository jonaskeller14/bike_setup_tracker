class ComponentStats {
  final double distance;
  final double elevationGain;
  final Duration movingTime;
  final Duration elapsedTime;
  final int activityCount;
  final double kilojoules;

  const ComponentStats({
    this.distance = 0,
    this.elevationGain = 0,
    this.movingTime = Duration.zero,
    this.elapsedTime = Duration.zero,
    this.activityCount = 0,
    this.kilojoules = 0,
  });

  static const zero = ComponentStats();

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'elevationGain': elevationGain,
        'movingTime': movingTime.inMicroseconds,
        'elapsedTime': elapsedTime.inMicroseconds,
        'activityCount': activityCount,
        'kilojoules': kilojoules,
      };

  factory ComponentStats.fromJson(Map<String, dynamic> json) {
    return ComponentStats(
      distance: (json['distance'] as num).toDouble(),
      elevationGain: (json['elevationGain'] as num).toDouble(),
      movingTime: Duration(microseconds: json['movingTime'] as int),
      elapsedTime: Duration(microseconds: json['elapsedTime'] as int),
      activityCount: json['activityCount'] as int? ?? 0,
      kilojoules: (json['kilojoules'] as num?)?.toDouble() ?? 0,
    );
  }

  ComponentStats operator +(ComponentStats other) {
    return ComponentStats(
      distance: distance + other.distance,
      elevationGain: elevationGain + other.elevationGain,
      movingTime: movingTime + other.movingTime,
      elapsedTime: elapsedTime + other.elapsedTime,
      activityCount: activityCount + other.activityCount,
      kilojoules: kilojoules + other.kilojoules,
    );
  }

  ComponentStats operator -(ComponentStats other) {
    return ComponentStats(
      distance: distance - other.distance,
      elevationGain: elevationGain - other.elevationGain,
      movingTime: movingTime - other.movingTime,
      elapsedTime: elapsedTime - other.elapsedTime,
      activityCount: activityCount - other.activityCount,
      kilojoules: kilojoules - other.kilojoules,
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
          activityCount == other.activityCount &&
          kilojoules == other.kilojoules;

  @override
  int get hashCode => Object.hash(distance, elevationGain, movingTime, elapsedTime, activityCount, kilojoules);
}
