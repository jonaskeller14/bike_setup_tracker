
enum FilterType {
  person,
  bike,
  component,
  componentType,
  global,
}

sealed class RatingAssociation {
  const RatingAssociation();

  String? get filter => null;
  FilterType get filterType;

  static RatingAssociation fromIds({
    String? componentId,
    String? bikeId,
    String? personId,
    String? componentTypeStr,
  }) {
    if (componentId != null) return ComponentRatingAssociation(componentId);
    if (componentTypeStr != null) return ComponentTypeRatingAssociation(componentTypeStr);
    if (bikeId != null) return BikeRatingAssociation(bikeId);
    if (personId != null) return PersonRatingAssociation(personId);
    return const GlobalRatingAssociation();
  }
}

class GlobalRatingAssociation extends RatingAssociation {
  const GlobalRatingAssociation();

  @override
  FilterType get filterType => FilterType.global;

  @override
  bool operator ==(Object other) => other is GlobalRatingAssociation;

  @override
  int get hashCode => runtimeType.hashCode;
}

class BikeRatingAssociation extends RatingAssociation {
  final String bikeId;

  const BikeRatingAssociation(this.bikeId);

  @override
  String? get filter => bikeId;

  @override
  FilterType get filterType => FilterType.bike;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BikeRatingAssociation && bikeId == other.bikeId;

  @override
  int get hashCode => Object.hash(runtimeType, bikeId);
}

class ComponentTypeRatingAssociation extends RatingAssociation {
  final String componentTypeStr;

  const ComponentTypeRatingAssociation(this.componentTypeStr);

  @override
  String? get filter => componentTypeStr;

  @override
  FilterType get filterType => FilterType.componentType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentTypeRatingAssociation && componentTypeStr == other.componentTypeStr;

  @override
  int get hashCode => Object.hash(runtimeType, componentTypeStr);
}

class ComponentRatingAssociation extends RatingAssociation {
  final String componentId;

  const ComponentRatingAssociation(this.componentId);

  @override
  String? get filter => componentId;

  @override
  FilterType get filterType => FilterType.component;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentRatingAssociation && componentId == other.componentId;

  @override
  int get hashCode => Object.hash(runtimeType, componentId);
}

class PersonRatingAssociation extends RatingAssociation {
  final String personId;

  const PersonRatingAssociation(this.personId);

  @override
  String? get filter => personId;

  @override
  FilterType get filterType => FilterType.person;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonRatingAssociation && personId == other.personId;

  @override
  int get hashCode => Object.hash(runtimeType, personId);
}
