import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../utils/person_actions.dart';
import '../items/person_list_card.dart';
import '../rider_name_form.dart';
import 'sheet_header.dart';

Future<void> showRiderSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (sheetContext) => RiderSheetContent(
      // Snackbars render behind a modal sheet, so the sheet closes first and
      // the removal reports through the page below to keep Undo visible.
      onRemove: (person) async {
        Navigator.pop(sheetContext);
        if (!context.mounted) return;
        await PersonActions.removePerson(context, person: person);
      },
    ),
  );
}

class RiderSheetContent extends StatelessWidget {
  const RiderSheetContent({super.key, required this.onRemove});

  final Future<void> Function(Person person) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final persons = context.select<AppRepository, Map<String, Person>>((repository) => repository.persons).values;

    return Padding(
      padding: EdgeInsets.only(bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Rider', leadingIcon: Icon(Person.iconData)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: persons.isEmpty
                    ? const RiderNameForm()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final person in persons)
                            PersonListCard(
                              key: ValueKey(person.id),
                              person: person,
                              onRemove: () => onRemove(person),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Riding weight and other rider values are recorded with each setup.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
