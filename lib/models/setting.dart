class Setting {
  final String name;
  final DateTime datetime;

  Setting({
    required this.name,
    required this.datetime,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'datetime': datetime.toIso8601String(),
      };

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      name: json['name'],
      datetime: DateTime.parse(json['datetime']),
    );
  }
}