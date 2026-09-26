import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/person.dart';
import '../models/rating/rating.dart';
import '../models/rating/rating_entry.dart';
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
import '../widgets/animated_app_bar_switcher.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_placeholder.dart';
import '../widgets/sticky_section.dart';
import '../widgets/timeline_day_header.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  Set<_TrashItem> _selectedItems = {};
  bool _isRestoring = false;

  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  List<_TrashItem> _deletedItems(AppRepository appRepository) {
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
    return deletedCombined;
  }

  void _clearSelection() {
    setState(() => _selectedItems = {});
  }

  void _toggleSelection(_TrashItem item) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_selectedItems.remove(item)) {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _restoreSelectedItems() async {
    if (_isRestoring || _selectedItems.isEmpty) return;

    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final selection = _TrashSelection(_selectedItems);
    final message = _selectedItems.length == 1
        ? "'${_selectedItems.first.name}' restored from trash."
        : '${_selectedItems.length} items restored from trash.';
    unawaited(HapticFeedback.lightImpact());
    setState(() => _isRestoring = true);

    try {
      await selection.restore(appRepository);

      if (!mounted) return;
      setState(() => _selectedItems = {});
      messenger.showSnackBar(
        AppSnackBar.info(
          context,
          message,
          duration: const Duration(seconds: 5),
          action: AppSnackBarAction(
            label: 'UNDO',
            onPressed: () async => selection.remove(appRepository),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Widget _trashItem({required BuildContext context, required _TrashItem deletedItem}) {
    final timeFormat = DateFormat(context.read<AppSettings>().timeFormat);
    final selected = _selectedItems.contains(deletedItem);

    return ListTile(
      leading: Icon(deletedItem.iconData),
      title: Text(deletedItem.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Deleted at: ${timeFormat.format(deletedItem.lastModified.toLocal())}'),
      onTap: _isSelectionMode ? () => _toggleSelection(deletedItem) : null,
      onLongPress: _isRestoring ? null : () => _toggleSelection(deletedItem),
      trailing: _isSelectionMode
          ? Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : IconButton(
              icon: const Icon(Icons.restore_from_trash),
              onPressed: () => deletedItem.restore(context),
            ),
    );
  }

  Widget _trashCard({required BuildContext context, required _TrashItem deletedItem}) {
    final defaultCardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceContainerLow;
    final selected = _selectedItems.contains(deletedItem);

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      tween: ColorTween(
        begin: defaultCardColor,
        end: selected ? Theme.of(context).colorScheme.primaryContainer : defaultCardColor,
      ),
      builder: (context, color, child) => Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias, // Borderradius for InkWell
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
      child: _trashItem(context: context, deletedItem: deletedItem),
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
              _trashCard(context: context, deletedItem: item),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keeps the freshest snapshot of each still-deleted item and drops the rest.
    final visibleItems = _deletedItems(context.read<AppRepository>()).toSet();
    _selectedItems = visibleItems.intersection(_selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final deletedCombined = _deletedItems(appRepository);
    final sections = <({DateTime day, List<_TrashItem> items})>[];
    for (final item in deletedCombined) {
      final local = item.lastModified.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (sections.isEmpty || sections.last.day != day) {
        sections.add((day: day, items: []));
      }
      sections.last.items.add(item);
    }

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: AnimatedAppBarSwitcher(
          child: _isSelectionMode
              ? AppBar(
                  key: const ValueKey('trash-selection-app-bar'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isRestoring ? null : _clearSelection,
                  ),
                  title: Text('${_selectedItems.length} selected'),
                  actions: [
                    IconButton(
                      onPressed: _isRestoring ? null : _restoreSelectedItems,
                      icon: const Icon(Icons.restore_from_trash),
                      tooltip: 'Restore selected',
                    ),
                  ],
                )
              : AppBar(
                  key: const ValueKey('trash-app-bar'),
                  title: const Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.delete),
                      Expanded(child: Text('Trash')),
                    ],
                  ),
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
      ),
    );
  }
}

sealed class _TrashItem {
  String get id;
  DateTime get lastModified;
  IconData get iconData;
  String get name;
  void restore(BuildContext context);
  const _TrashItem();

  @override
  bool operator ==(Object other) => other is _TrashItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _TrashSelection {
  final List<Person> persons = [];
  final List<Bike> bikes = [];
  final List<Component> components = [];
  final List<Setup> setups = [];
  final List<Rating> ratings = [];
  final List<RatingEntry> ratingEntries = [];
  final List<TaskRule> taskRules = [];
  final List<TaskEntry> taskEntries = [];

  _TrashSelection(Iterable<_TrashItem> items) {
    for (final item in items) {
      switch (item) {
        case _PersonTrashItem(:final person):
          persons.add(person);
        case _BikeTrashItem(:final bike):
          bikes.add(bike);
        case _ComponentTrashItem(:final component):
          components.add(component);
        case _SetupTrashItem(:final setup):
          setups.add(setup);
        case _RatingTrashItem(:final rating):
          ratings.add(rating);
        case _RatingEntryTrashItem(:final ratingEntry):
          ratingEntries.add(ratingEntry);
        case _TaskRuleTrashItem(:final taskRule):
          taskRules.add(taskRule);
        case _TaskEntryTrashItem(:final taskEntry):
          taskEntries.add(taskEntry);
      }
    }
  }

  Future<void> restore(AppRepository appRepository) async {
    await appRepository.restorePersons(persons);
    await appRepository.restoreBikes(bikes);
    await appRepository.restoreComponents(components);
    await appRepository.restoreSetups(setups);
    await appRepository.restoreRatings(ratings);
    await appRepository.restoreRatingEntries(ratingEntries);
    await appRepository.restoreTaskRules(taskRules);
    await appRepository.restoreTaskEntries(taskEntries);
  }

  Future<void> remove(AppRepository appRepository) async {
    await appRepository.removePersons(persons);
    await appRepository.removeBikes(bikes);
    await appRepository.removeComponents(components);
    await appRepository.removeSetups(setups);
    await appRepository.removeRatings(ratings);
    await appRepository.removeRatingEntries(ratingEntries);
    await appRepository.removeTaskRules(taskRules);
    await appRepository.removeTaskEntries(taskEntries);
  }
}

class _BikeTrashItem extends _TrashItem {
  final Bike bike;
  @override String get id => 'bike-${bike.id}';
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
  @override String get id => 'person-${person.id}';
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
  @override String get id => 'component-${component.id}';
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
  @override String get id => 'setup-${setup.id}';
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
  @override String get id => 'rating-${rating.id}';
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
  @override String get id => 'rating-entry-${ratingEntry.id}';
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
  @override String get id => 'task-rule-${taskRule.id}';
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
  @override String get id => 'task-entry-${taskEntry.id}';
  @override DateTime get lastModified => taskEntry.lastModified;
  @override IconData get iconData => Icons.check_box_outlined;
  @override String get name => taskEntry.name;
  @override
  void restore(BuildContext context) async {
    await TaskActions.restoreTaskEntry(context, taskEntry: taskEntry);
  }
  const _TaskEntryTrashItem(this.taskEntry);
}
