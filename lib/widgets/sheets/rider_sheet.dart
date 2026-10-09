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
                        spacing: 24,
                        children: [
                          Text(
                            'Suspension, sag and tire pressure depend on your weight. Recording rider '
                            'values with each setup keeps your setups comparable when your weight changes.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          for (final person in persons)
                            _RiderSection(
                              key: ValueKey(person.id),
                              person: person,
                              onRemove: () => onRemove(person),
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

class _RiderSection extends StatelessWidget {
  const _RiderSection({super.key, required this.person, required this.onRemove});

  final Person person;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final hasLinkedBike = context.select<AppRepository, bool>(
      (repository) => repository.bikes.values.any((bike) => bike.person == person.id),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        PersonListCard(person: person, onRemove: onRemove),
        hasLinkedBike ? _RecordRiderValuesButton(person: person) : _LinkBikeButton(person: person),
      ],
    );
  }
}

class _LinkBikeButton extends StatelessWidget {
  const _LinkBikeButton({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBikes = context.select<AppRepository, bool>((repository) => repository.bikes.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        FilledButton.icon(
          onPressed: hasBikes ? () => PersonActions.editBikeLinks(context, person: person) : null,
          icon: const Icon(Icons.add_link),
          label: const Text('Link bike'),
        ),
        Text(
          hasBikes ? 'Link a bike to record rider values with its setups.' : 'Add a bike to link it to this rider.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RecordRiderValuesButton extends StatelessWidget {
  const _RecordRiderValuesButton({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mirrors the component guard of SetupActions.addSetup, whose error
    // snackbar would render behind this sheet.
    final hasComponents = context.select<AppRepository, bool>((repository) => repository.components.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        FilledButton.tonalIcon(
          onPressed: hasComponents ? () => PersonActions.recordRiderValues(context, person: person) : null,
          icon: const Icon(Icons.add),
          label: const Text('Record rider values'),
        ),
        Text(
          hasComponents ? 'Rider values are saved with a new setup.' : 'Add a component to record setups.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
