import 'package:flutter/material.dart';

import '../../models/component/component.dart';
import '../../pages/details/component_details_page.dart';
import '../../utils/installation_issue.dart';
import 'garage_component_icon_card.dart';

class GarageComponentCell extends StatelessWidget {
  final Component component;
  final String? componentToShowDetails;
  final double? width;
  final InstallationIssue? issue;
  final bool merged;
  final void Function(Component)? onPressed;

  const GarageComponentCell({
    super.key,
    required this.component,
    required this.componentToShowDetails,
    this.width,
    this.issue,
    this.merged = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final card = GarageComponentIconCard(
      component: component,
      componentToShowDetails: componentToShowDetails,
      width: width,
      issue: issue,
      merged: merged,
    );

    if (onPressed == null) return card;

    return GestureDetector(
      onTap: () => onPressed!(component),
      onDoubleTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => ComponentDetailsPage(componentId: component.id),
          ),
        );
      },
      child: card,
    );
  }
}
