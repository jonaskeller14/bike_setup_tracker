import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../chips/task_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../items/task_rule_list_card.dart';
import '../sticky_section.dart';
import '../task_caught_up_placeholder.dart';
import 'list_scroll_controller.dart';

class TaskList extends StatefulWidget {
  final ListScrollController? controller;
  final Set<String> selectedTaskRules;
  final ValueChanged<String>? onTaskRuleSelectionChanged;
  final VoidCallback? onSelectedTaskRulesCompleted;

  const TaskList({
    super.key,
    this.controller,
    this.selectedTaskRules = const {},
    this.onTaskRuleSelectionChanged,
    this.onSelectedTaskRulesCompleted,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  static const double _filterHeight = 64;
  static const double _sectionHeaderHeight = 40;

  late ListScrollController _controller;
  late bool _ownsController;
  final GlobalKey _dueSectionKey = GlobalKey();
  final GlobalKey _upcomingSectionKey = GlobalKey();
  final GlobalKey _completedSectionKey = GlobalKey();
  bool _showAllUpcoming = false;
  bool _showAllCompleted = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ListScrollController();
  }

  @override
  void didUpdateWidget(covariant TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) return;
    if (_ownsController) _controller.dispose();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ListScrollController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Widget _taskRuleCard(String taskRuleId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TaskRuleListCard(
        key: ValueKey('task-rule-$taskRuleId'),
        taskRuleId: taskRuleId,
        selectionMode: widget.selectedTaskRules.isNotEmpty,
        selected: widget.selectedTaskRules.contains(taskRuleId),
        onSelectionChanged: widget.onTaskRuleSelectionChanged == null
            ? null
            : () => widget.onTaskRuleSelectionChanged!(taskRuleId),
        onSelectedTaskRulesCompleted: widget.onSelectedTaskRulesCompleted,
      ),
    );
  }

  Widget _emptyDueSection(AppRepository repository) {
    if (!repository.hasTaskRulesInCurrentScope) {
      return EmptyStatePlaceholder(
        key: const ValueKey('task-empty-none'),
        icon: Icons.checklist,
        title: 'No tasks yet',
        subtitle: 'Add a task to track service intervals or other bike related todos.',
        actionLabel: 'Add a task',
        onAction: () => TaskActions.addTaskRule(context),
      );
    }

    if (repository.hasActiveTaskRuleNarrowing && repository.hasScopeActionableTaskRules) {
      return EmptyStatePlaceholder(
        key: const ValueKey('task-empty-filtered'),
        icon: Icons.filter_alt_off,
        title: 'Nothing due in this view',
        subtitle: 'Priority or tag filters are hiding tasks that need attention.',
        actionLabel: 'Clear filters',
        onAction: () {
          repository.selectAllTaskPriorities();
          repository.deselectAllTaskRuleTags();
        },
      );
    }

    final selectedBike = repository.selectedBike == null ? null : repository.bikes[repository.selectedBike!];
    return TaskCaughtUpPlaceholder(
      key: const ValueKey('task-empty-caught-up'),
      bikeName: selectedBike?.name,
    );
  }

  Widget _sectionToggle({
    required bool expanded,
    required int count,
    required VoidCallback onPressed,
    required String section,
  }) {
    return Center(
      child: TextButton.icon(
        key: ValueKey('task-$section-toggle'),
        onPressed: onPressed,
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
        label: Text(expanded ? 'Show less' : 'Show all ($count)'),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = '$title ($count)';
    return Semantics(
      button: true,
      header: true,
      label: '$label. Scroll to section',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        shape: Border.symmetric(
          horizontal: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _sectionHeaderHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    await Scrollable.ensureVisible(
      sectionContext,
      alignment: 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _section({
    required GlobalKey key,
    required String title,
    required int count,
    required Widget content,
  }) {
    return KeyedSubtree(
      key: key,
      child: StickySection(
        header: _sectionHeader(
          title: title,
          count: count,
          onTap: () => _scrollToSection(key),
        ),
        content: content,
      ),
    );
  }

  Widget _taskCards(Iterable<String> taskRuleIds) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final id in taskRuleIds) _taskRuleCard(id)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AppRepository>();
    final due = repository.actionableTaskRules;
    final upcoming = repository.upcomingTaskRules;
    final completed = repository.completedTaskRules;
    final visibleUpcoming = _showAllUpcoming ? upcoming : upcoming.take(3);
    final visibleCompleted = _showAllCompleted ? completed : completed.take(3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactDueHeight = (constraints.maxHeight - _filterHeight - 2 * _sectionHeaderHeight)
            .clamp(0, double.infinity)
            .toDouble();
        return CustomScrollView(
          key: const PageStorageKey('task-list-scroll'),
          controller: _controller.scrollController,
          slivers: [
            SliverPersistentHeader(
              floating: true,
              delegate: _TaskFilterHeaderDelegate(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            SliverList.list(
              children: [
                _section(
                  key: _dueSectionKey,
                  title: 'Due now',
                  count: due.length,
                  content: due.isEmpty
                      ? SizedBox(
                          height: compactDueHeight,
                          child: _emptyDueSection(repository),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: compactDueHeight,
                          ),
                          child: _taskCards(
                            due.map((task) => task.rule.id),
                          ),
                        ),
                ),
                _section(
                  key: _upcomingSectionKey,
                  title: 'Upcoming',
                  count: upcoming.length,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (upcoming.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Text('No upcoming tasks.'),
                        )
                      else
                        _taskCards(
                          visibleUpcoming.map((task) => task.rule.id),
                        ),
                      if (upcoming.length > 3)
                        _sectionToggle(
                          expanded: _showAllUpcoming,
                          count: upcoming.length,
                          section: 'upcoming',
                          onPressed: () => setState(
                            () => _showAllUpcoming = !_showAllUpcoming,
                          ),
                        ),
                    ],
                  ),
                ),
                _section(
                  key: _completedSectionKey,
                  title: 'Completed',
                  count: completed.length,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (completed.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Text('No completed tasks.'),
                        )
                      else
                        _taskCards(
                          visibleCompleted.map((task) => task.rule.id),
                        ),
                      if (completed.length > 3)
                        _sectionToggle(
                          expanded: _showAllCompleted,
                          count: completed.length,
                          section: 'completed',
                          onPressed: () => setState(
                            () => _showAllCompleted = !_showAllCompleted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 116),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TaskFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color backgroundColor;

  const _TaskFilterHeaderDelegate({required this.backgroundColor});

  @override
  double get minExtent => _TaskListState._filterHeight;

  @override
  double get maxExtent => _TaskListState._filterHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TaskListFilterWidget(),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TaskFilterHeaderDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}
