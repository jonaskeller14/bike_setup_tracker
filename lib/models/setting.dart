class Setting {
  final String name;

  Setting({required this.name});

  Map<String, dynamic> toJson() => {'name': name};

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(name: json['name']);
  }
}