import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../../models/component.dart';
import '../../../models/person.dart';
import '../../tooltips/component_tooltip.dart';
import '../../tooltips/person_tooltip.dart';
import '../../tooltips/tooltip_style.dart';

/// One owner (component or person) whose adjustment values are shown in a
/// compact adjustment row.
sealed class AdjustmentDisplayItem {
  final bool isError;
  AdjustmentDisplayItem({this.isError = false});

  List<Adjustment> get adjustments;
  String get name;
  String? get notes;
  String? get errorDescription;

  Widget buildIcon(BuildContext context);

  /// Wraps [child] in this owner's long-press tooltip (component or person).
  Widget wrapTooltip(BuildContext context, {required Widget child, TooltipStyle? style});
}

class ComponentDisplayItem extends AdjustmentDisplayItem {
  final Component _component;
  @override List<Adjustment> get adjustments => _component.adjustments;
  @override String get name => _component.name;
  @override String? get notes => _component.notes;
  @override String? get errorDescription => isError ? "Component was not installed at setup time" : null;
  @override
  Widget buildIcon(BuildContext context) {
    final icon = Icon(
      _component.componentType.getIconData(),
      color: isError ? Theme.of(context).colorScheme.error : null,
    );
    if (!isError) return icon;
    return Badge(
      label: _errorBadgeDot(context),
      backgroundColor: Colors.transparent,
      largeSize: 20,
      child: icon,
    );
  }
  @override
  Widget wrapTooltip(BuildContext context, {required Widget child, TooltipStyle? style}) =>
      ComponentTooltip(component: _component, isError: isError, style: style, child: child);
  ComponentDisplayItem(this._component, {super.isError});
}

class PersonDisplayItem extends AdjustmentDisplayItem {
  final Person _person;
  @override List<Adjustment> get adjustments => _person.adjustments;
  @override String get name => _person.name;
  @override String? get notes => _person.notes;
  @override String? get errorDescription => isError ? "Person is not linked to this setup" : null;
  @override
  Widget buildIcon(BuildContext context) {
    final icon = Icon(
      Person.iconData,
      color: isError ? Theme.of(context).colorScheme.error : null,
    );
    if (!isError) return icon;
    return Badge(
      label: _errorBadgeDot(context),
      backgroundColor: Colors.transparent,
      largeSize: 20,
      child: icon,
    );
  }
  @override
  Widget wrapTooltip(BuildContext context, {required Widget child, TooltipStyle? style}) =>
      PersonTooltip(person: _person, isError: isError, style: style, child: child);
  PersonDisplayItem(this._person, {super.isError});
}

Widget _errorBadgeDot(BuildContext context, {double size = 9}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      color: scheme.error,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.error, size: size, color: scheme.errorContainer),
  );
}
