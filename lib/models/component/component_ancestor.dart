import 'component.dart';

sealed class ComponentAncestor {
  const ComponentAncestor();
}

class ParentComponentAncestor extends ComponentAncestor {
  final Component component;
  const ParentComponentAncestor(this.component);
}

class MissingParentAncestor extends ComponentAncestor {
  final String componentId;
  const MissingParentAncestor(this.componentId);
}

class BikeAncestor extends ComponentAncestor {
  final String bikeId;
  const BikeAncestor(this.bikeId);
}

class ArchivedAncestor extends ComponentAncestor {
  const ArchivedAncestor();
}

class UninstalledAncestor extends ComponentAncestor {
  const UninstalledAncestor();
}
