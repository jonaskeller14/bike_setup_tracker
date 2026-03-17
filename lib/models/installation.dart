class Installation {
  final String? parent;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;

  Installation({
    required this.parent,
    required DateTime dateTimeUTC,
    required this.dateTimeLocal,
  }) : dateTimeUTC = dateTimeUTC.toUtc();

  Installation.sinceBeginning({required this.parent})
      : dateTimeUTC = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        dateTimeLocal = DateTime.fromMillisecondsSinceEpoch(0, isUtc: false);

  Installation copyWith({
    Object? parent = const _Sentinel(),
    Object? dateTimeUTC = const _Sentinel(),
    Object? dateTimeLocal = const _Sentinel(),
  }) {
    return Installation(
      parent: parent is _Sentinel 
          ? this.parent 
          : (parent as String?),
      dateTimeUTC: dateTimeUTC is _Sentinel 
          ? this.dateTimeUTC 
          : (dateTimeUTC as DateTime),
      dateTimeLocal: dateTimeLocal is _Sentinel 
          ? this.dateTimeLocal 
          : (dateTimeLocal as DateTime),
    );
  }

  Map<String, dynamic> toJson() => {
    'parent': parent,
    'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
    'dateTimeLocal': dateTimeLocal.toIso8601String(),
  };

  factory Installation.fromJson(Map<String, dynamic> json) {
    return Installation(
      parent: json['parent'] as String?,
      dateTimeUTC: DateTime.parse(json['dateTimeUTC'] as String).toUtc(),
      dateTimeLocal: DateTime.parse(json['dateTimeLocal'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Installation &&
        runtimeType == other.runtimeType &&
        parent == other.parent &&
        dateTimeUTC == other.dateTimeUTC &&
        dateTimeLocal == other.dateTimeLocal;
  }

  @override
  int get hashCode {
    return Object.hash(
      parent, 
      dateTimeUTC, 
      dateTimeLocal
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
