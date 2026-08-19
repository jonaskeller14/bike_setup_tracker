import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';

class ContextBikePersonCardDiff extends StatelessWidget {
  final Setup setupA;
  final Setup setupB;
  final bool showBike;
  final bool showPerson;

  const ContextBikePersonCardDiff({
    super.key,
    required this.setupA,
    required this.setupB,
    required this.showBike,
    required this.showPerson,
  });

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikeA = appRepository.bikes[setupA.bike];
    final bikeB = appRepository.bikes[setupB.bike];
    final personA = setupA.person == null ? null : appRepository.persons[setupA.person];
    final personB = setupB.person == null ? null : appRepository.persons[setupB.person];

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBike)
            _OwnerRow(
              icon: Bike.iconData,
              valueA: bikeA?.name ?? 'BIKE NOT FOUND',
              valueB: bikeB?.name ?? 'BIKE NOT FOUND',
              errorA: bikeA == null,
              errorB: bikeB == null,
            ),
          if (showPerson)
            _OwnerRow(
              icon: setupA.person == null && setupB.person == null ? Icons.person_off : Person.iconData,
              valueA:
                  personA?.name ?? (setupA.person == null ? 'No person linked to this setup.' : 'PERSON NOT FOUND'),
              valueB:
                  personB?.name ?? (setupB.person == null ? 'No person linked to this setup.' : 'PERSON NOT FOUND'),
              errorA: setupA.person != null && personA == null,
              errorB: setupB.person != null && personB == null,
            ),
        ],
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  final IconData icon;
  final String? valueA;
  final String? valueB;
  final bool errorA;
  final bool errorB;

  const _OwnerRow({
    required this.icon,
    required this.valueA,
    required this.valueB,
    this.errorA = false,
    this.errorB = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(icon, color: errorA || errorB ? errorColor : null),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Expanded(
            child: SelectableText(valueA ?? '-', style: TextStyle(color: errorA ? errorColor : null)),
          ),
          Expanded(
            child: SelectableText(valueB ?? '-', style: TextStyle(color: errorB ? errorColor : null)),
          ),
        ],
      ),
      dense: true,
    );
  }
}
