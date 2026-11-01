import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/entity_names.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../l10n/test_session_text.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../models/feedback/test_session.dart';
import '../../models/feedback/test_session_method.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/bike_adjustment_column_service.dart';
import '../../services/test_session_service.dart';
import '../../theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/empty_state_placeholder2.dart';
import '../../widgets/sheets/pick_adjustments.dart';
import '../../widgets/sheets/pick_setups.dart';
import '../../widgets/sheets/sheet.dart';
import '../../widgets/text/section_title.dart';

typedef _Differences = ({List<String> adjustmentIds, int count});

/// Which proposal strategy the rider picked; [Tournament] needs its candidates,
/// so the page holds the choice apart from the [TestSessionMethod].
enum _MethodChoice {
  fineTune(PatternSearch()),
  explore(OrthogonalArray()),
  compare(Tournament(candidateSetupIds: [])),
  free(null);

  final TestSessionMethod? method;
  const _MethodChoice(this.method);

  static _MethodChoice of(TestSessionMethod? method) => switch (method) {
    PatternSearch() => fineTune,
    OrthogonalArray() => explore,
    Tournament() => compare,
    null => free,
  };
}

/// Creates a [TestSession]: bike, method, adjustments, goal and name. Pops the
/// new session; the caller records its first run.
///
/// [TestSessionPage.edit] changes only the name and shows the rest locked,
/// because the runs already depend on it.
class TestSessionPage extends StatefulWidget {
  final Bike? initialBike;

  /// The session being edited.
  final TestSession? session;

  const TestSessionPage({super.key, this.initialBike}) : session = null;

  const TestSessionPage.edit({super.key, required TestSession this.session}) : initialBike = null;

  @override
  State<TestSessionPage> createState() => _TestSessionPageState();
}

class _TestSessionPageState extends State<TestSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _knobFieldKey = GlobalKey<FormFieldState<List<String>>>();
  final _candidateFieldKey = GlobalKey<FormFieldState<List<String>>>();
  final _nameController = TextEditingController();
  late String _bike;
  _MethodChoice _choice = _MethodChoice.fineTune;
  final List<String> _knobIds = [];
  final List<String> _candidateIds = [];
  final List<FeedbackAspect> _goal = [];
  (Object, _Differences)? _differencesCache;

  bool get _isEdit => widget.session != null;

  @override
  void initState() {
    super.initState();
    final appRepository = context.read<AppRepository>();
    _bike =
        widget.session?.bike ??
        widget.initialBike?.id ??
        appRepository.view.bikes.keys.firstOrNull ??
        appRepository.bikes.keys.firstOrNull ??
        '';
    if (widget.session case final session?) {
      _nameController.text = session.name ?? '';
      _choice = _MethodChoice.of(session.method);
      if (session.method case Tournament(:final candidateSetupIds)) _candidateIds.addAll(candidateSetupIds);
      _knobIds.addAll(session.adjustmentIds);
      _goal.addAll(session.goal);
    }
    _nameController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// Re-validates a placeholder once its list changed, so a shown error clears.
  void _knobsChanged() => _knobFieldKey.currentState?.didChange(List.of(_knobIds));
  void _candidatesChanged() => _candidateFieldKey.currentState?.didChange(List.of(_candidateIds));

  bool get _hasChanges => _isEdit
      ? _nameController.text.trim() != (widget.session!.name ?? '')
      : _nameController.text.trim().isNotEmpty || _knobIds.isNotEmpty || _candidateIds.isNotEmpty || _goal.isNotEmpty;

  List<TestSessionKnob> _knobs() {
    final appRepository = context.read<AppRepository>();
    final now = DateTime.now().toUtc();
    return TestSessionService.knobsFor(
      bikeComponents: appRepository.components.values.where(
        (component) => appRepository.componentHierarchy.bikeAt(component.id, now) == _bike,
      ),
      rider: context.read<AppSettings>().enablePerson
          ? appRepository.persons[appRepository.bikes[_bike]?.person]
          : null,
    );
  }

  List<Setup> _bikeSetups() => context
      .read<AppRepository>()
      .setups
      .values
      .where((setup) => setup.bike == _bike && setup.testSessionId == null)
      .sorted((a, b) => b.datetime.compareTo(a.datetime));

  void _onBikeChanged(String? bike) {
    if (bike == null || bike == _bike) return;
    setState(() {
      _bike = bike;
      _knobIds.clear();
      _candidateIds.clear();
    });
    _knobsChanged();
    _candidatesChanged();
  }

  _Differences _differences() {
    final appRepository = context.read<AppRepository>();
    final source = (
      appRepository.setups,
      appRepository.components,
      appRepository.componentHierarchy,
      appRepository.setupHistory,
      _bike,
      _candidateIds.join(','),
    );
    if (_differencesCache case (final cachedSource, final differences) when cachedSource == source) return differences;

    final projection = BikeAdjustmentColumnService.build(
      bikeId: _bike,
      setups: appRepository.setups.values,
      components: appRepository.components.values,
      hierarchy: appRepository.componentHierarchy,
      history: appRepository.setupHistory,
    );
    final differences = TestSessionService.differencesBetween(
      _candidateIds.map((id) => appRepository.setups[id]).nonNulls,
      projection,
    );
    _differencesCache = (source, differences);
    return differences;
  }

  List<String> _sessionKnobIds() => _choice == _MethodChoice.compare ? _differences().adjustmentIds : _knobIds;

  /// Adjustments to test, or for Compare the columns the setups differ in.
  int get _knobCount => _choice == _MethodChoice.compare ? _differences().count : _knobIds.length;

  void _save() {
    if (widget.session case final session?) {
      final name = _nameController.text.trim();
      Navigator.pop(context, session.copyWith(name: name.isEmpty ? null : name));
      return;
    }
    // The empty adjustment and setup placeholders show their own error.
    if (!_formKey.currentState!.validate()) return;

    final appRepository = context.read<AppRepository>();
    String? error;
    final knobIds = _sessionKnobIds();
    if (appRepository.runningSessionFor(_bike) != null) {
      error = context.l10n.testSessionErrAlreadyRunning;
    } else if (_choice != _MethodChoice.compare &&
        appRepository.setups[appRepository.resolveSetupId(bikeId: _bike, atUtc: DateTime.now().toUtc())] == null) {
      error = context.l10n.testSessionErrRecordSetup;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, error));
      return;
    }

    final now = DateTime.now();
    final name = _nameController.text.trim();
    Navigator.pop(
      context,
      TestSession(
        bike: _bike,
        name: name.isEmpty ? null : name,
        method: _choice == _MethodChoice.compare
            ? Tournament(candidateSetupIds: List.of(_candidateIds))
            : _choice.method,
        adjustmentIds: knobIds,
        goal: List.of(_goal),
        startedAtUTC: now.toUtc(),
        startedAtLocal: now,
      ),
    );
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await showDiscardChangesDialog(context);
    if (!mounted || !discard) return;
    Navigator.of(context).pop();
  }

  /// Closing the sheet keeps the selection: the page follows every tick.
  Future<void> _pickKnobs() {
    // The rider's attributes can't be tuned between runs.
    final groups = groupBy(_knobs().where((knob) => !knob.isRider), (knob) => knob.ownerId).values.toList();
    final hierarchy = context.read<AppRepository>().componentHierarchy;
    final now = DateTime.now().toUtc();
    return showPickAdjustmentsSheet(
      context,
      title: context.l10n.testSessionPickAdjustmentsTitle,
      groups: [
        for (final group in groups)
          PickAdjustmentsGroup(
            title: group.first.ownerName,
            icon: group.first.ownerIcon,
            ancestors: hierarchy.ancestorsBelowBikeAt(group.first.ownerId, now),
            adjustments: [for (final knob in group) knob.adjustment],
          ),
      ],
      selectedIds: _knobIds,
      onChanged: (ids) {
        setState(
          () => _knobIds
            ..clear()
            ..addAll(ids),
        );
        _knobsChanged();
      },
      warningFor: _tooManyAdjustmentsMessage,
      emptyHint: context.l10n.testSessionNoAdjustments,
    );
  }

  /// Soft: more than a few adjustments still work, they just tell less.
  String? _tooManyAdjustmentsMessage(int count) => count > TestSessionService.recommendedMaxAdjustments
      ? context.l10n.testSessionTooManyAdjustments(TestSessionService.recommendedMaxAdjustments)
      : null;

  /// Soft, like the adjustments: more setups just take many more runs.
  String? _tooManySetupsMessage(int count) => count > TestSessionService.recommendedMaxCompareSetups
      ? context.l10n.testSessionTooManySetups(
          count,
          count * (count - 1) ~/ 2,
          TestSessionService.recommendedMaxCompareSetups,
        )
      : null;

  /// Closing the sheet keeps the selection.
  Future<void> _pickCandidates() async {
    final selected = await showPickSetupsSheet(
      context,
      title: context.l10n.testSessionPickSetupsTitle,
      options: _bikeSetups(),
      selectedIds: _candidateIds,
      warningFor: _tooManySetupsMessage,
      emptyTitle: context.l10n.testSessionNoSetups,
    );
    if (!mounted) return;
    setState(
      () => _candidateIds
        ..clear()
        ..addAll(selected),
    );
    _candidatesChanged();
  }

  /// An edited session keeps its bike: the runs already depend on it.
  Widget _lockedBike(Bike? bike) {
    // Dimmed like the locked type field of the component form.
    final disabled = Theme.of(context).disabledColor;
    return InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        labelText: context.l10n.setupFormBikeLabel,
        enabled: false,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.lock_outline),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(Bike.iconData, color: disabled),
          Expanded(
            child: Text(bike?.name ?? context.l10n.bikeNotFound, overflow: TextOverflow.ellipsis, style: TextStyle(color: disabled)),
          ),
        ],
      ),
    );
  }

  Widget _methodSection() {
    final theme = Theme.of(context);
    final expected = testSessionExpectedRuns(
      _choice == _MethodChoice.compare ? Tournament(candidateSetupIds: _candidateIds) : _choice.method,
      _knobCount,
      context.l10n,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final choice in _MethodChoice.values)
              ChoiceChip(
                label: Text(testSessionMethodLabel(choice.method, context.l10n)),
                selected: _choice == choice,
                onSelected: _isEdit ? null : (_) => setState(() => _choice = choice),
              ),
          ],
        ),
        Text(
          [
            testSessionMethodDescription(_choice.method, context.l10n),
            if (expected != null) context.l10n.testSessionExpect(expected),
          ].join(' '),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _addButton({required String label, required VoidCallback onPressed}) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.add), label: Text(label)),
  );

  /// Edit mode: the session's adjustments in their order, without reordering,
  /// removing or adding.
  Widget _lockedKnobs() {
    final knobs = {for (final knob in _knobs()) knob.adjustment.id: knob};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, id) in _knobIds.indexed)
          ListTile(
            enabled: false,
            contentPadding: EdgeInsets.zero,
            // A disabled tile greys its texts and icons, not an avatar.
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).disabledColor,
              child: Text('${index + 1}'),
            ),
            title: Text(
              knobs[id]?.adjustment.name ?? context.l10n.testSessionAdjustmentNotFound,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(knobs[id]?.ownerName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }

  Widget _lockedCandidates() {
    final setups = context.read<AppRepository>().setups;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in _candidateIds)
          ListTile(
            enabled: false,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Setup.iconData),
            title: Text(
              setups[id]?.label(context.l10n) ?? context.l10n.setupDetailsNotFoundTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Edit mode: only the chosen aspects, which may include a custom issue no
  /// feedback uses any more.
  Widget _lockedGoal() {
    final theme = Theme.of(context);
    if (_goal.isEmpty) {
      return Text(context.l10n.testSessionNoGoal, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    final labelOf = context.read<AppRepository>().customIssues.labelOf;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final aspect in _goal)
          FilterChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text(testSessionGoalLabel(aspect, labelOf, context.l10n), maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: true,
            onSelected: null,
          ),
      ],
    );
  }

  Widget _knobSection() {
    final knobs = {for (final knob in _knobs()) knob.adjustment.id: knob};
    return FormField<List<String>>(
      key: _knobFieldKey,
      initialValue: _knobIds,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => _knobIds.isEmpty ? context.l10n.testSessionPickAtLeastOne : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_knobIds.isEmpty)
            EmptyStatePlaceholder2(
              title: context.l10n.componentFormAdjustmentsEmptyTitle,
              errorTitle: field.errorText,
              subtitle: context.l10n.testSessionAdjustmentsEmptySubtitle,
              errorSubtitle: context.l10n.componentFormAdjustmentsEmptyError,
              onTap: _pickKnobs,
            )
          else ...[
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (oldIndex, newIndex) =>
                  setState(() => _knobIds.insert(newIndex, _knobIds.removeAt(oldIndex))),
              children: [
                for (final (index, id) in _knobIds.indexed)
                  ListTile(
                    key: ValueKey(id),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 14, child: Text('${index + 1}')),
                    title: Text(
                      knobs[id]?.adjustment.name ?? context.l10n.testSessionAdjustmentNotFound,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(knobs[id]?.ownerName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: context.l10n.testSessionRemoveAdjustment,
                      onPressed: () {
                        setState(() => _knobIds.remove(id));
                        _knobsChanged();
                      },
                    ),
                  ),
              ],
            ),
            if (_tooManyAdjustmentsMessage(_knobIds.length) case final message?) SheetWarning(message: message),
          ],
          const SizedBox(height: 8),
          _addButton(label: context.l10n.componentFormAddAdjustment, onPressed: _pickKnobs),
        ],
      ),
    );
  }

  Widget _candidateSection() {
    final setups = context.read<AppRepository>().setups;
    final theme = Theme.of(context);
    final differing = _knobCount;
    return FormField<List<String>>(
      key: _candidateFieldKey,
      initialValue: _candidateIds,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) {
        if (_candidateIds.length < TestSessionService.minCompareSetups) {
          return context.l10n.testSessionPickAtLeastSetups(TestSessionService.minCompareSetups);
        }
        return _knobCount == 0 ? context.l10n.testSessionSameValues : null;
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_candidateIds.isEmpty)
            EmptyStatePlaceholder2(
              iconData: Setup.iconData,
              title: context.l10n.noSetupsTitle,
              errorTitle: field.errorText,
              subtitle: context.l10n.testSessionSetupsEmptySubtitle(TestSessionService.minCompareSetups),
              errorSubtitle: context.l10n.testSessionSetupsEmptyError,
              onTap: _pickCandidates,
            )
          else ...[
            for (final id in _candidateIds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Setup.iconData),
                title: Text(
                  setups[id]?.label(context.l10n) ?? context.l10n.setupDetailsNotFoundTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.testSessionRemoveSetup,
                  onPressed: () {
                    setState(() => _candidateIds.remove(id));
                    _candidatesChanged();
                  },
                ),
              ),
            if (_tooManySetupsMessage(_candidateIds.length) case final message?) SheetWarning(message: message),
            if (field.hasError)
              Text(field.errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error))
            else if (_candidateIds.length >= TestSessionService.minCompareSetups)
              Text(
                context.l10n.testSessionDifferingCount(differing),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
          const SizedBox(height: 8),
          _addButton(
            label: _candidateIds.isEmpty ? context.l10n.testSessionAddSetups : context.l10n.testSessionChangeSetups,
            onPressed: _pickCandidates,
          ),
        ],
      ),
    );
  }

  /// Front, Rear and Other side by side from this width on, like the feedback form.
  static const double _sideBySideWidth = 560;

  Widget _goalChip(FeedbackAspect aspect, String label, {String? tooltip}) {
    final selected = _goal.contains(aspect);
    final full = _goal.length >= TestSession.maxGoalAspects;
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      tooltip: tooltip,
      selected: selected,
      onSelected: !selected && full
          ? null
          : (value) => setState(() {
              if (value) {
                _goal.add(aspect);
              } else {
                _goal.remove(aspect);
              }
            }),
    );
  }

  Widget _goalGroup(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 4, children: chips),
      ],
    );
  }

  Widget _goalSection() {
    final custom = context.read<AppRepository>().customIssues;
    final groups = [
      for (final end in FeedbackEnd.values)
        _goalGroup(end.label(context.l10n), [
          for (final attribute in FeedbackAttribute.values)
            _goalChip(
              EndAspect(end, attribute),
              attribute.qualityLabel(context.l10n),
              tooltip: attribute.hint(context.l10n),
            ),
        ]),
      if (custom.usages.isNotEmpty)
        _goalGroup(context.l10n.feedbackIssueOther, [
          for (final usage in custom.usages) _goalChip(usage.issue.aspect, usage.label),
        ]),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= _sideBySideWidth
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [for (final group in groups) Expanded(child: group)],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: groups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bikes = context.read<AppRepository>().bikes;
    const padding = EdgeInsets.symmetric(horizontal: 16);
    // The runs depend on everything but the name.
    final Widget? locked = _isEdit
        ? Icon(Icons.lock_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)
        : null;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? context.l10n.testSessionEditTitle : context.l10n.startTestSession),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: _isEdit ? context.l10n.save : context.l10n.testSessionStartTooltip,
              onPressed: _save,
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        if (_isEdit)
                          _lockedBike(bikes[_bike])
                        else
                          DropdownButtonFormField<String>(
                            initialValue: bikes.containsKey(_bike) ? _bike : null,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: context.l10n.setupFormBikeLabel, border: const OutlineInputBorder()),
                            items: [
                              for (final bike in bikes.values)
                                DropdownMenuItem(
                                  value: bike.id,
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      const Icon(Bike.iconData),
                                      Expanded(child: Text(bike.name, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: _onBikeChanged,
                          ),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: context.l10n.testSessionNameLabel,
                            hintText: context.l10n.testSessionUnnamed,
                            border: const OutlineInputBorder(),
                            fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                            filled: _isEdit && _hasChanges,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionTitle(
                    title: context.l10n.testSessionSectionMethod,
                    infoText: context.l10n.testSessionSectionMethodInfo,
                    trailing: locked,
                  ),
                  Padding(padding: padding, child: _methodSection()),
                  if (_choice == _MethodChoice.compare) ...[
                    SectionTitle(title: context.l10n.testSessionSectionSetups, trailing: locked),
                    Padding(padding: padding, child: _isEdit ? _lockedCandidates() : _candidateSection()),
                  ] else ...[
                    SectionTitle(
                      title: context.l10n.componentFormAdjustmentsTitle,
                      infoText: context.l10n.testSessionSectionAdjustmentsInfo,
                      trailing: locked,
                    ),
                    Padding(padding: padding, child: _isEdit ? _lockedKnobs() : _knobSection()),
                  ],
                  SectionTitle(
                    title: context.l10n.testSessionSectionGoal,
                    trailing:
                        locked ??
                        Text(
                          '${_goal.length} / ${TestSession.maxGoalAspects}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                  ),
                  Padding(
                    padding: padding,
                    child: Text(
                      context.l10n.testSessionGoalPrompt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(padding: padding, child: _isEdit ? _lockedGoal() : _goalSection()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
