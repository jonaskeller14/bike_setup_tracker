class Component {
  final String name;
  
  Component({required this.name});

  Map<String, dynamic> toJson() => {'name': name};

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(name: json['name']);
  }
}