import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../models/task_entry.dart';
import '../models/task_rule.dart';
import '../repositories/app_repository.dart';
import '../utils/bike_actions.dart';
import '../utils/component_actions.dart';
import '../utils/person_actions.dart';
import '../utils/rating_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';

class TrashPage extends StatelessWidget{
  const TrashPage({super.key});

  ListTile _trashItem({required BuildContext context, required _TrashItem deletedItem}) {
    final appSettings = context.read<AppSettings>();
    final dateFormat = DateFormat(appSettings.dateFormat);
    final timeFormat = DateFormat(appSettings.timeFormat);

    return ListTile(
      leading: Icon(deletedItem.iconData),
      title: Text(deletedItem.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Deleted at: ${dateFormat.format(deletedItem.lastModified.toLocal())} ${timeFormat.format(deletedItem.lastModified.toLocal())}"),
      trailing: IconButton(
        icon: Icon(Icons.restore_from_trash),
        onPressed: () => deletedItem.restore(context),
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
      ...appRepository.deletedTaskRules.map((tr) => _TaskRuleTrashItem(tr)),
      ...appRepository.deletedTaskEntries.map((te) => _TaskEntryTrashItem(te)),
    ];

    deletedCombined.sort((a, b) => b.lastModified.compareTo(a.lastModified));

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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Items in the Trash are permanently deleted after 30 days. The Trash is emptied automatically.'),
              dense: true,
            ),
            Expanded(
              child: deletedCombined.isEmpty
                  ? Center(
                      child: Text(
                        "Empty Trash",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: deletedCombined.length,
                      itemBuilder: (context, index) {
                        final deletedItem = deletedCombined[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: _trashItem(context: context, deletedItem: deletedItem),
                        );
                      },
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
  @override String get name => setup.name;
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
