sealed class TaskAssociation {
  const TaskAssociation();

  String? get componentId => null;
  String? get bikeId => null;

  Map<String, dynamic> toJson();

  static TaskAssociation fromIds({String? componentId, String? bikeId}) {
    if (componentId != null) return ComponentTaskAssociation(componentId);
    if (bikeId != null) return BikeTaskAssociation(bikeId);
    return const GeneralTaskAssociation();
  }

  factory TaskAssociation.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'general' => const GeneralTaskAssociation(),
      'bike' => BikeTaskAssociation(json['id'] as String),
      'component' => ComponentTaskAssociation(json['id'] as String),
      _ => throw ArgumentError('Unknown TaskAssociation type: $type'),
    };
  }
}

class GeneralTaskAssociation extends TaskAssociation {
  const GeneralTaskAssociation();

  @override
  Map<String, dynamic> toJson() => {'type': 'general'};

  @override
  bool operator ==(Object other) => other is GeneralTaskAssociation;

  @override
  int get hashCode => runtimeType.hashCode;
}

class BikeTaskAssociation extends TaskAssociation {
  final String id;

  const BikeTaskAssociation(this.id);

  @override
  String? get bikeId => id;

  @override
  Map<String, dynamic> toJson() => {'type': 'bike', 'id': id};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BikeTaskAssociation && id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

class ComponentTaskAssociation extends TaskAssociation {
  final String id;

  const ComponentTaskAssociation(this.id);

  @override
  String? get componentId => id;

  @override
  Map<String, dynamic> toJson() => {'type': 'component', 'id': id};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ComponentTaskAssociation && id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}
