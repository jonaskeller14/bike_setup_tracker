import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/feedback/test_session.dart';
import '../../models/person.dart';
import '../running_badge.dart';

class ContextBikePersonCard extends StatelessWidget {
  final Bike? bike;
  final Person? person;
  final bool personLinked;
  final bool showPerson;
  final String? testSessionId;
  final TestSession? testSession;
  final VoidCallback? onTestSessionTap;

  const ContextBikePersonCard({
    super.key,
    required this.bike,
    required this.person,
    required this.personLinked,
    required this.showPerson,
    this.testSessionId,
    this.testSession,
    this.onTestSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Bike.iconData, color: bike == null ? errorColor : null),
            title: Text(
              bike?.name ?? context.l10n.bikeNotFound,
              style: TextStyle(color: bike == null ? errorColor : null),
            ),
            dense: true,
          ),
          if (showPerson)
            ListTile(
              leading: Icon(personLinked ? Person.iconData : Icons.person_off),
              title: Text(
                person?.name ?? (personLinked ? context.l10n.riderNotFound : context.l10n.contextNoRiderLinked),
              ),
              dense: true,
            ),
          if (testSessionId != null)
            ListTile(
              leading: Icon(TestSession.iconData, color: testSession == null ? errorColor : null),
              title: Row(
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(
                      testSession?.displayName ?? context.l10n.testSessionNotFound,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: testSession == null ? errorColor : null),
                    ),
                  ),
                  if (testSession?.isRunning ?? false) const RunningBadge(),
                ],
              ),
              trailing: testSession == null ? null : const Icon(Icons.chevron_right),
              onTap: testSession == null ? null : onTestSessionTap,
              dense: true,
            ),
        ],
      ),
    );
  }
}
