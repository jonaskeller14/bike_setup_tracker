
class StravaActivity {
  final int id;
  final String name;
  final double distance;
  final int movingTime;
  final double totalElevationGain;
  final String type;
  final DateTime startDate;
  final DateTime syncedAt;

  StravaActivity({
    required this.id,
    required this.name,
    required this.distance,
    required this.movingTime,
    required this.totalElevationGain,
    required this.type,
    required this.startDate,
    required this.syncedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'distance': distance,
    'moving_time': movingTime,
    'total_elevation_gain': totalElevationGain,
    'type': type,
    'start_date': startDate.toIso8601String(),
    'synced_at': syncedAt.toIso8601String(),
  };

  factory StravaActivity.fromJson(Map<String, dynamic> json) {
    return StravaActivity(
      id: json['id'] as int,
      name: json['name'] as String,
      distance: (json['distance'] as num).toDouble(),
      movingTime: json['moving_time'] as int,
      totalElevationGain: (json['total_elevation_gain'] as num).toDouble(),
      type: json['type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      syncedAt: (json['synced_at'] != null) 
          ? DateTime.parse(json['synced_at'] as String)
          : DateTime.now(),
    );
  }

  factory StravaActivity.fromFirestore(Map<String, dynamic> json) {
    // Firestore Timestamps need special handling if they are actual Timestamps
    // But our backend saves strings or uses serverTimestamp().
    return StravaActivity(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed Ride',
      distance: (json['distance'] as num? ?? 0).toDouble(),
      movingTime: json['moving_time'] as int? ?? 0,
      totalElevationGain: (json['total_elevation_gain'] as num? ?? 0).toDouble(),
      type: json['type'] as String? ?? 'Ride',
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String) 
          : DateTime.now(),
      syncedAt: DateTime.now(), // approximation
    );
  }
}
