import 'component.dart';
import 'installation.dart';


class ResolvedInstallation {
  // Runtime only helper model (resolved Installation entries)
  final Component component;
  final Installation installation;
  final String? originParent;
  final InstallationParentType? originParentType;
  final bool isInitial;

  ResolvedInstallation({
    required this.component,
    required this.installation,
    this.originParent,
    this.originParentType,
    this.isInitial = false,
  });

  String get shortLabel {
    final symbol = isInitial
        ? '+'
        : switch (installation.parentType) {
            InstallationParentType.bike => '>',
            InstallationParentType.component => '>',
            InstallationParentType.none => '<',
            InstallationParentType.archived => 'x',
          };
    return "$symbol ${component.name}";
  }
}
