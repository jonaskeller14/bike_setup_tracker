import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/person.dart';

class ContextBikePersonCard extends StatelessWidget {
  final Bike? bike;
  final Person? person;
  final bool personLinked;
  final bool showPerson;

  const ContextBikePersonCard({
    super.key,
    required this.bike,
    required this.person,
    required this.personLinked,
    required this.showPerson,
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
              bike?.name ?? 'BIKE NOT FOUND',
              style: TextStyle(color: bike == null ? errorColor : null),
            ),
            dense: true,
          ),
          if (showPerson)
            ListTile(
              leading: Icon(personLinked ? Person.iconData : Icons.person_off),
              title: Text(
                person?.name ?? (personLinked ? 'PERSON NOT FOUND' : 'No person linked to this setup.'),
              ),
              dense: true,
            ),
        ],
      ),
    );
  }
}
