class Setting {
  final String name;
  final DateTime datetime;
  final String? notes;

  Setting({
    required this.name,
    required this.datetime,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'datetime': datetime.toIso8601String(),
        'notes': notes,
      };

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      name: json['name'],
      datetime: DateTime.parse(json['datetime']),
      notes: json['notes'] != null ? json['notes'] as String : null,
    );
  }
}