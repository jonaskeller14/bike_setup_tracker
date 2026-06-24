import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';

class DataSelectBike extends StatelessWidget {
  final Bike bike;
  final Map<String, Person> persons;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectBike({
    super.key,
    required this.bike,
    required this.persons,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Bike.iconData),
        title: Text(
          bike.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: bike.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: appSettings.enablePerson
            ? Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Icon(
                    bike.person != null ? Person.iconData : Icons.person_off,
                    size: 13,
                    color:
                        bike.person == null || persons.containsKey(bike.person)
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
                  ),
                  if (bike.person != null)
                    Flexible(
                      child: Text(
                        persons[bike.person]?.name ?? "PERSON NOT FOUND",
                        style: TextStyle(
                          color:
                              bike.person == null ||
                                  persons.containsKey(bike.person)
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8)
                              : Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
