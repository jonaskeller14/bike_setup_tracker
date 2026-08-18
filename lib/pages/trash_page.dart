import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/rating_entry.dart';
import '../models/setup.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../repositories/app_repository.dart';
import '../utils/bike_actions.dart';
import '../utils/component_actions.dart';
import '../utils/person_actions.dart';
import '../utils/rating_actions.dart';
import '../utils/rating_entry_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';
import '../widgets/empty_state_placeholder.dart';
import '../widgets/sticky_section.dart';
import '../widgets/timeline_day_header.dart';

class TrashPage extends StatelessWidget{
  const TrashPage({super.key});

  ListTile _trashItem({required BuildContext context, required _TrashItem deletedItem}) {
    final timeFormat = DateFormat(context.read<AppSettings>().timeFormat);

    return ListTile(
      leading: Icon(deletedItem.iconData),
      title: Text(deletedItem.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Deleted at: ${timeFormat.format(deletedItem.lastModified.toLocal())}'),
      trailing: IconButton(
        icon: const Icon(Icons.restore_from_trash),
        onPressed: () => deletedItem.restore(context),
      ),
    );
  }

  Widget _daySection(
    BuildContext context, {
    required DateTime day,
    required List<_TrashItem> items,
  }) {
    return StickySection(
      header: TimelineDayHeader(day: day, margin: EdgeInsets.zero),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            for (final item in items)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _trashItem(context: context, deletedItem: item),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final deletedCombined = <_TrashItem>[
      ...appRepository.deletedPersons.map((p) => _PersonTrashItem(p)),
      ...appRepository.deletedBikes.map((b) => _BikeTrashItem(b)),
      ...appRepository.deletedComponents.map((c) => _ComponentTrashItem(c)),
      ...appRepository.deletedSetups.map((s) => _SetupTrashItem(s)),
      ...appRepository.deletedRatings.map((r) => _RatingTrashItem(r)),
      ...appRepository.deletedRatingEntries.map((re) => _RatingEntryTrashItem(re)),
      ...appRepository.deletedTaskRules.map((tr) => _TaskRuleTrashItem(tr)),
      ...appRepository.deletedTaskEntries.map((te) => _TaskEntryTrashItem(te)),
    ];

    deletedCombined.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    final sections = <({DateTime day, List<_TrashItem> items})>[];
    for (final item in deletedCombined) {
      final local = item.lastModified.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (sections.isEmpty || sections.last.day != day) {
        sections.add((day: day, items: []));
      }
      sections.last.items.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          spacing: 8,
          children: [
            Icon(Icons.delete),
            Expanded(child: Text('Trash')),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Items in the Trash are permanently deleted after 30 days. The Trash is emptied automatically.'),
              dense: true,
            ),
            Expanded(
              child: deletedCombined.isEmpty
                  ? const CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: EmptyStatePlaceholder(
                              icon: Icons.delete_outline,
                              title: 'Trash is empty',
                              subtitle: 'Deleted items will appear here.',
                            ),
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverList.builder(
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            final section = sections[index];
                            return _daySection(
                              context,
                              day: section.day,
                              items: section.items,
                            );
                          },
                        ),
                      ],
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom)
          ],
        ),
      ),
    );
  }
}

sealed class _TrashItem {
  DateTime get lastModified;
  IconData get iconData;
  String get name;
  void restore(BuildContext context);
  const _TrashItem();
}

class _BikeTrashItem extends _TrashItem {
  final Bike bike;
  @override DateTime get lastModified => bike.lastModified;
  @override IconData get iconData => Bike.iconData;
  @override String get name => bike.name;
  @override
  void restore(BuildContext context) async {
    await BikeActions.restoreBike(context, bike: bike);
  }
  const _BikeTrashItem(this.bike);
}

class _PersonTrashItem extends _TrashItem {
  final Person person;
  @override DateTime get lastModified => person.lastModified;
  @override IconData get iconData => Person.iconData;
  @override String get name => person.name;
  @override
  void restore(BuildContext context) async {
    await PersonActions.restorePerson(context, person: person);
  }
  const _PersonTrashItem(this.person);
}

class _ComponentTrashItem extends _TrashItem {
  final Component component;
  @override DateTime get lastModified => component.lastModified;
  @override IconData get iconData => component.componentType.getIconData();
  @override String get name => component.name;
  @override
  void restore(BuildContext context) async {
    await ComponentActions.restoreComponent(context, component: component);
  }
  const _ComponentTrashItem(this.component);
}

class _SetupTrashItem extends _TrashItem {
  final Setup setup;
  @override DateTime get lastModified => setup.lastModified;
  @override IconData get iconData => Setup.iconData;
  @override String get name => setup.displayName;
  @override
  void restore(BuildContext context) async {
    await SetupActions.restoreSetup(context, setup: setup);
  }
  const _SetupTrashItem(this.setup);
}

class _RatingTrashItem extends _TrashItem {
  final Rating rating;
  @override DateTime get lastModified => rating.lastModified;
  @override IconData get iconData => Rating.iconData;
  @override String get name => rating.name;
  @override
  void restore(BuildContext context) async {
    await RatingActions.restoreRating(context, rating: rating);
  }
  const _RatingTrashItem(this.rating);
}

class _RatingEntryTrashItem extends _TrashItem {
  final RatingEntry ratingEntry;
  @override DateTime get lastModified => ratingEntry.lastModified;
  @override IconData get iconData => RatingEntry.iconData;
  @override String get name => ratingEntry.displayName;
  @override
  void restore(BuildContext context) async {
    await RatingEntryActions.restoreRatingEntry(context, ratingEntry: ratingEntry);
  }
  const _RatingEntryTrashItem(this.ratingEntry);
}

class _TaskRuleTrashItem extends _TrashItem {
  final TaskRule taskRule;
  @override DateTime get lastModified => taskRule.lastModified;
  @override IconData get iconData => Icons.check_box_outline_blank;
  @override String get name => taskRule.name;
  @override
  void restore(BuildContext context) async {
    await TaskActions.restoreTaskRule(context, taskRule: taskRule);
  }
  const _TaskRuleTrashItem(this.taskRule);
}

class _TaskEntryTrashItem extends _TrashItem {
  final TaskEntry taskEntry;
  @override DateTime get lastModified => taskEntry.lastModified;
  @override IconData get iconData => Icons.check_box_outlined;
  @override String get name => taskEntry.name;
  @override
  void restore(BuildContext context) async {
    await TaskActions.restoreTaskEntry(context, taskEntry: taskEntry);
  }
  const _TaskEntryTrashItem(this.taskEntry);
}
