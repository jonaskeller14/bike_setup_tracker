import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import '../icons/simple_icons.dart';
import '../models/app_settings.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/rating_entry.dart';
import '../models/setup.dart';
import '../models/timeline_entry.dart';
import '../models/timeline_row.dart';
import '../repositories/app_repository.dart';
import '../services/subscription_service.dart';
import '../utils/installation_timeline_validation.dart';
import '../utils/setup_actions.dart';
import '../utils/timeline_grouping.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/calendar_add_setup_appointment.dart';
import '../widgets/calendar_entry_appointment.dart';
import '../widgets/chips/filter_sheet_chip.dart';
import '../widgets/sheets/installation_sheet.dart';
import '../widgets/sheets/rating_entry_details.dart';
import '../widgets/sheets/replacement_sheet.dart';
import '../widgets/sheets/setup_details.dart';
import '../widgets/sheets/strava_activity.dart';
import '../widgets/sheets/task_rule_sheet.dart';

const Duration kCalendarZeroDuration = Duration(minutes: 30);
const double kCalendarTimeSlotHeight = 30;
const Color kCalendarStravaColor = Color(0xFFFC4C02); // Strava brand orange
const Color kCalendarRatingColor = Color(0xFFF9A825);
const Duration kCalendarScrollLeadIn = Duration(minutes: 30);
const int kCalendarFallbackHour = 6;
const Duration kCalendarFutureWindow = Duration(days: 365);
const double kCalendarGhostAlpha = 0.4;
const IconData kCalendarPredictedTaskIcon = Icons.insights;

const double kCalendarHeaderHeight = 48;
/// Approximate height of the weekday-label row above the month grid.
const double kCalendarViewHeaderHeight = 30;
const int kCalendarMonthWeekRows = 6;
const double kCalendarMonthCellMinHeight = 95;

DateTime calendarSlotStart(DateTime date) => date.copyWith(
      minute: (date.minute ~/ kCalendarZeroDuration.inMinutes) *
          kCalendarZeroDuration.inMinutes,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );

/// A task rule's predicted due date, drawn as a read-only ghost. Calendar-only
/// by design: nothing about it is recorded, so it is not a [TimelineEntry].
class CalendarPredictedTask {
  const CalendarPredictedTask({
    required this.taskRuleId,
    required this.name,
    required this.date,
  });

  final String taskRuleId;
  final String name;

  /// Local time the rule is expected to come due.
  final DateTime date;
}

DateTime calendarDisplayDateForDay(DateTime day, List<TimelineEntry> entries) {
  final target = DateUtils.dateOnly(day);
  DateTime? earliest;
  for (final entry in entries) {
    final local = entry.dateUTC.toLocal();
    if (!DateUtils.isSameDay(local, target)) continue;
    if (earliest == null || local.isBefore(earliest)) earliest = local;
  }
  if (earliest == null) return target.copyWith(hour: kCalendarFallbackHour);
  return earliest.subtract(kCalendarScrollLeadIn);
}

List<EntryRow> buildCalendarRows(List<TimelineEntry> entries, AppSettings settings) {
  final sortedEntries = [...entries]..sort((a, b) => a.dateUTC.compareTo(b.dateUTC));
  final rows = <EntryRow>[];
  for (final row in collapseIntoRows(sortedEntries, appSettings: settings)) {
    if (row is SetupGroupRow) {
      rows.addAll(row.setups.map(SingleEntryRow.new));
    } else {
      rows.add(row);
    }
  }
  return rows;
}

IconData setupCalendarIcon(Setup setup, {required bool showSetupBookmark}) {
  if (setup.isCurrent) return Icons.flag;
  if (showSetupBookmark && setup.isBookmarked) return Icons.bookmark;
  return Setup.iconData;
}

IconData calendarIconFor(TimelineEntry entry, {bool showSetupBookmark = false}) => switch (entry) {
      SetupEntry() => setupCalendarIcon(entry.setup, showSetupBookmark: showSetupBookmark),
      StravaEntry() => entry.activity.workout.isNotable
          ? entry.activity.workout.icon
          : SimpleIcons.strava,
      TaskTimeLineEntry() => Icons.check_box_outlined,
      InstallationEntry() => entry.componentInstallation.component.componentType.getIconData(),
      RatingEntryTimelineEntry() => RatingEntry.iconData,
    };

Color calendarColorFor(TimelineEntry entry, ColorScheme cs) => switch (entry) {
      SetupEntry() => cs.primary,
      StravaEntry() => kCalendarStravaColor,
      TaskTimeLineEntry() => cs.tertiary,
      InstallationEntry() => cs.secondary,
      RatingEntryTimelineEntry() => kCalendarRatingColor,
    };

Color calendarOnColorFor(TimelineEntry entry, ColorScheme cs) => switch (entry) {
      SetupEntry() => cs.onPrimary,
      StravaEntry() => Colors.white,
      TaskTimeLineEntry() => cs.onTertiary,
      InstallationEntry() => cs.onSecondary,
      RatingEntryTimelineEntry() => Colors.white,
    };

String calendarSubjectFor(TimelineEntry entry) => switch (entry) {
      SetupEntry() => entry.setup.displayName,
      StravaEntry() => entry.activity.name,
      TaskTimeLineEntry() => entry.taskEntry.name,
      InstallationEntry() => entry.componentInstallation.shortLabel,
      RatingEntryTimelineEntry() => entry.ratingEntry.displayName,
    };

IconData calendarIconForRow(EntryRow row, {bool showSetupBookmark = false}) => switch (row) {
      SingleEntryRow(:final entry) => calendarIconFor(entry, showSetupBookmark: showSetupBookmark),
      ReplacementRow() => Icons.swap_horiz,
      SetupGroupRow() => Setup.iconData,
    };

Color calendarColorForRow(EntryRow row, ColorScheme cs) => switch (row) {
      SingleEntryRow(:final entry) => calendarColorFor(entry, cs),
      ReplacementRow() => cs.secondary,
      SetupGroupRow() => cs.primary,
    };

Color calendarOnColorForRow(EntryRow row, ColorScheme cs) => switch (row) {
      SingleEntryRow(:final entry) => calendarOnColorFor(entry, cs),
      ReplacementRow() => cs.onSecondary,
      SetupGroupRow() => cs.onPrimary,
    };

String calendarSubjectForRow(EntryRow row) => switch (row) {
      SingleEntryRow(:final entry) => calendarSubjectFor(entry),
      ReplacementRow() => 'Replaced ${row.removed.component.componentType.label}',
      SetupGroupRow() => '${row.setups.length} setups',
    };

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = CalendarController();

  /// Guards the incremental Strava paging triggered by calendar navigation so
  /// only one coverage-load runs at a time.
  bool _loadingCoverage = false;

  static const _defaultView = _CalendarView.month;
  _CalendarView _selectedView = _defaultView;
  _CalendarView? _returnView;
  DateTime? _pendingSetupDate;
  bool _addingSetup = false;

  /// Dates currently visible, fed from [SfCalendar.onViewChanged]; used to tell
  /// whether "today" is already on screen (to disable the Today button).
  List<DateTime> _visibleDates = const [];

  /// Whether today already falls within the visible date range, so the Today
  /// button can be disabled. (Schedule scrolls freely, so keep it enabled.)
  bool get _todayShown {
    if (_visibleDates.isEmpty || _selectedView.view == CalendarView.schedule) {
      return false;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final first = DateUtils.dateOnly(_visibleDates.first);
    final last = DateUtils.dateOnly(_visibleDates.last);
    return !today.isBefore(first) && !today.isAfter(last);
  }

  void _selectView(_CalendarView option) {
    setState(() {
      _selectedView = option;
      _controller.view = option.view;
      _returnView = null;
      _pendingSetupDate = null;
    });
  }

  MenuItemButton _viewMenuItem(_CalendarView option, ColorScheme cs) {
    final selected = option == _selectedView;
    return MenuItemButton(
      onPressed: () => _selectView(option),
      leadingIcon: Icon(option.icon, size: 20),
      style: MenuItemButton.styleFrom(
        foregroundColor: selected ? cs.primary : cs.onSurface,
        backgroundColor: selected ? cs.primary.withValues(alpha: 0.10) : null,
      ),
      child: Text(
        option.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  bool _selectReturnView() {
    final returnView = _returnView;
    if (returnView == null) return false;
    setState(() {
      _selectedView = returnView;
      _controller.view = returnView.view;
      _returnView = null;
      _pendingSetupDate = null;
    });
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _showingStrava(AppSettings settings, SubscriptionService sub) =>
      settings.displayShowActivities && settings.enableStrava && sub.hasStravaEntitlement;

  List<TimelineEntry> _buildEntries(
    AppRepository repo,
    AppSettings settings,
    SubscriptionService sub,
  ) {
    return [
      if (settings.displayShowSetups)
        ...repo.filteredSetups.values.map((s) => SetupEntry(s)),
      if (_showingStrava(settings, sub))
        ...repo.filteredStravaActivities.values.map((a) => StravaEntry(a)),
      if (settings.displayShowTasks)
        ...repo.filteredTaskEntries.values.map((t) => TaskTimeLineEntry(t)),
      if (settings.displayShowInstallations)
        ...repo.filteredInstallations.map((ci) => InstallationEntry(ci)),
      if (settings.enableRating && settings.displayShowRatingEntries)
        ...repo.filteredRatingEntries.values.map((re) => RatingEntryTimelineEntry(re)),
    ];
  }

  /// Future due dates for the open, not-yet-due rules currently in scope.
  ///
  /// A forecast carrying a rate sample was extrapolated from riding, so it
  /// needs the Strava entitlement behind it. One without a sample is a date or
  /// duration trigger — a date the user set — and shows regardless.
  List<CalendarPredictedTask> _buildPredictedTasks(
    AppRepository repo,
    AppSettings settings,
    SubscriptionService sub,
  ) {
    if (!settings.enableTaskDuePrediction || !settings.displayShowTasks) return const [];
    final now = DateTime.now();
    final predicted = <CalendarPredictedTask>[];
    for (final open in repo.openTaskRules) {
      if (open.status.isDue) continue;
      final forecast = repo.getTaskRuleForecast(open.rule);
      if (forecast == null) continue;
      if (forecast.sample != null && !sub.hasStravaEntitlement) continue;
      final due = forecast.dueDate.toLocal();
      if (!due.isAfter(now)) continue;
      predicted.add(
        CalendarPredictedTask(taskRuleId: open.rule.id, name: open.rule.name, date: due),
      );
    }
    return predicted;
  }

  /// Collapses the built entries into display rows shared with the timeline
  /// list. Setup grouping stays off for the calendar in v1: rather than
  /// threading an override through the shared core, any [SetupGroupRow] it
  /// produced is expanded back into its per-setup rows.
  /// When the user navigates earlier than the currently loaded Strava window,
  /// page in older activities until the visible range is covered (or there is
  /// nothing more to load). Strava is paginated per active filter, so the loaded
  /// window already reflects the selected bike; paging it advances coverage
  /// without dead-ending on a global pagination boundary.
  void _ensureStravaCoverage(List<DateTime> visibleDates) {
    if (visibleDates.isEmpty || _loadingCoverage) return;
    final repo = context.read<AppRepository>();
    final settings = context.read<AppSettings>();
    final sub = context.read<SubscriptionService>();
    if (!_showingStrava(settings, sub)) return;
    if (!repo.hasMoreStrava) return;

    final visibleStart = visibleDates.first;
    // Paging walks *older*, so a visible range reaching into the future can
    // never be covered by it: clamp it to now, or navigating forward would
    // page the whole history looking for activities that cannot exist.
    final now = DateTime.now();
    final visibleEnd = visibleDates.last.isAfter(now) ? now : visibleDates.last;

    bool needsMore() {
      if (!repo.hasMoreStrava) return false;
      final dates = repo.stravaActivities.values.map((a) => a.startDate.toLocal());
      if (dates.isEmpty) return true; // nothing loaded yet
      final minLoaded = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      final maxLoaded = dates.reduce((a, b) => a.isAfter(b) ? a : b);
      return visibleStart.isBefore(minLoaded) || visibleEnd.isAfter(maxLoaded);
    }

    if (!needsMore()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _loadingCoverage || !needsMore()) return;
      _loadingCoverage = true;
      try {
        int safety = 0;
        while (mounted && needsMore() && !repo.isLoadingMoreStrava && safety < 500) {
          await repo.loadMoreStravaActivities();
          safety++;
        }
      } finally {
        _loadingCoverage = false;
      }
    });
  }

  Future<void> _onTap(CalendarTapDetails details, List<TimelineEntry> entries) async {
    switch (details.targetElement) {
      case CalendarElement.viewHeader:
        _clearPendingSetup();
        final date = details.date;
        if (date == null) return;
        if (_selectedView == _CalendarView.threeDay) {
          setState(() => _controller.displayDate = calendarDisplayDateForDay(date, entries));
        } else if (_selectedView != _CalendarView.day) {
          setState(() {
            _returnView = _selectedView;
            _selectedView = _CalendarView.day;
            _controller.view = CalendarView.day;
            _controller.displayDate = calendarDisplayDateForDay(date, entries);
          });
        }
      case CalendarElement.calendarCell:
        final date = details.date;
        if (date == null) return;
        if (_selectedView == _CalendarView.month) {
          setState(() {
            _returnView = _selectedView;
            _selectedView = _CalendarView.day;
            _controller.view = CalendarView.day;
            _controller.displayDate = calendarDisplayDateForDay(date, entries);
            _pendingSetupDate = null;
          });
          return;
        }
        if (_selectedView != _CalendarView.day &&
            _selectedView != _CalendarView.threeDay &&
            _selectedView != _CalendarView.week) {
          return;
        }
        final slotStart = calendarSlotStart(date);
        // The calendar reaches into the future so predictions have somewhere to
        // render, but nothing may be written there.
        if (slotStart.isAfter(DateTime.now())) {
          _clearPendingSetup();
          return;
        }
        if (_pendingSetupDate == slotStart) {
          await _addSetupAtPendingDate();
          return;
        }
        await HapticFeedback.selectionClick();
        if (!mounted) return;
        setState(() => _pendingSetupDate = slotStart);
      case CalendarElement.appointment:
        _clearPendingSetup();
        final appointments = details.appointments;
        if (appointments == null || appointments.isEmpty) return;
        final row = appointments.first;
        if (row is CalendarAddSetupSlot) {
          await _addSetupAtDate(row.date);
          return;
        }
        if (row is CalendarPredictedTask) {
          await showTaskRuleSheet(context, taskRuleId: row.taskRuleId);
          return;
        }
        if (row is! EntryRow) return;

        switch (row) {
          case SingleEntryRow(:final entry):
            await _openEntry(entry);
          case ReplacementRow():
            await showReplacementSheet(
              context,
              removed: row.removed,
              installed: row.installed,
            );
          // Setup groups get their own sheet in a later phase.
          case SetupGroupRow():
            return;
        }
      default:
        _clearPendingSetup();
        return;
    }
  }

  void _clearPendingSetup() {
    if (_pendingSetupDate == null || !mounted) return;
    setState(() => _pendingSetupDate = null);
  }

  Future<void> _addSetupAtPendingDate() async {
    final date = _pendingSetupDate;
    if (date == null) return;
    await _addSetupAtDate(date);
  }

  Future<void> _addSetupAtDate(DateTime date) async {
    if (_addingSetup) return;
    _addingSetup = true;
    await HapticFeedback.selectionClick();
    if (!mounted) {
      _addingSetup = false;
      return;
    }
    setState(() => _pendingSetupDate = null);
    try {
      await SetupActions.addSetup(context, initialDateTimeLocal: date);
    } finally {
      _addingSetup = false;
    }
  }

  Future<void> _openEntry(TimelineEntry entry) async {
    switch (entry) {
      case SetupEntry():
        await showSetupDetailsSheet(context: context, setup: entry.setup);
      case StravaEntry():
        await showStravaActivitySheet(context: context, stravaActivity: entry.activity);
      case TaskTimeLineEntry():
        await showTaskRuleSheet(
          context,
          taskRuleId: entry.taskEntry.taskRule,
          highlightTaskEntryId: entry.taskEntry.id,
        );
      case InstallationEntry():
        await showEditInstallationSheet(
          context,
          component: entry.componentInstallation.component,
          editEntry: entry.componentInstallation,
        );
      case RatingEntryTimelineEntry():
        await showRatingEntryDetailsSheet(context: context, ratingEntry: entry.ratingEntry);
    }
  }

  Future<void> _onDragEnd(AppointmentDragEndDetails details) async {
    final row = details.appointment;
    final newLocal = details.droppingTime;
    if (newLocal == null) return;
    if (row is CalendarPredictedTask) {
      // A prediction is derived, not stored: there is nothing to move. Rebuild
      // so it snaps back to its forecast date.
      setState(() {});
      return;
    }
    // `maxDate` used to make the future unreachable, which implicitly kept
    // drops out of it. Now that it is navigable, the guard has to be explicit.
    if (newLocal.isAfter(DateTime.now())) {
      _rejectMove(row is CalendarAddSetupSlot
          ? "Can't add a setup in the future."
          : "Can't move this into the future.");
      return;
    }
    if (row is CalendarAddSetupSlot) {
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() => _pendingSetupDate = newLocal);
      return;
    }
    if (row is! EntryRow) return;

    switch (row) {
      case SingleEntryRow(:final entry):
        await HapticFeedback.lightImpact();
        await _moveEntry(entry, newLocal);
      case ReplacementRow():
        await HapticFeedback.lightImpact();
        await _moveReplacement(row, newLocal);
      // Moving a setup group lands in a later phase.
      case SetupGroupRow():
        return;
    }
  }

  List<Installation> _reDated(
    Component component,
    Installation moved,
    DateTime newUtc,
    DateTime newLocal,
  ) {
    final updated = moved.copyWith(dateTimeUTC: newUtc, dateTimeLocal: newLocal);
    return component.installations.map((i) => i == moved ? updated : i).toList();
  }

  /// Moves both halves of a replacement onto the same new date/time. The halves
  /// always sit on different components, so this is two writes — both timelines
  /// are validated up front so a rejected move never persists half of it.
  Future<void> _moveReplacement(ReplacementRow row, DateTime newLocal) async {
    final newUtc = newLocal.toUtc();
    final oldLocal = row.anchorDateLocal;
    final appRepository = context.read<AppRepository>();

    final removedComponent = row.removed.component;
    final installedComponent = row.installed.component;
    final updatedRemoved =
        _reDated(removedComponent, row.removed.installation, newUtc, newLocal);
    final updatedInstalled =
        _reDated(installedComponent, row.installed.installation, newUtc, newLocal);

    if (!isValidInstallationTimeline(updatedRemoved) ||
        !isValidInstallationTimeline(updatedInstalled)) {
      _rejectMove("Can't move this replacement there.");
      return;
    }

    await appRepository.editComponent(removedComponent.copyWith(installations: updatedRemoved));
    await appRepository.editComponent(installedComponent.copyWith(installations: updatedInstalled));
    _showMoveUndoSnackBar(
      calendarSubjectForRow(row),
      oldLocal,
      newLocal,
      () async {
        await appRepository.editComponent(removedComponent);
        await appRepository.editComponent(installedComponent);
      },
    );
  }

  Future<void> _moveEntry(TimelineEntry entry, DateTime newLocal) async {
    final newUtc = newLocal.toUtc();
    final oldLocal = entry.dateUTC.toLocal();
    final appRepository = context.read<AppRepository>();

    switch (entry) {
      case SetupEntry():
        final original = entry.setup;
        await appRepository.editSetup(original.copyWith(datetime: newUtc, datetimeLocal: newLocal));
        _showMoveUndoSnackBar(
          calendarSubjectFor(entry),
          oldLocal,
          newLocal,
          () => appRepository.editSetup(original),
        );
      case TaskTimeLineEntry():
        final original = entry.taskEntry;
        await appRepository.editTaskEntry(
          [original.copyWith(dateTimeUTC: newUtc, dateTimeLocal: newLocal)],
        );
        _showMoveUndoSnackBar(
          calendarSubjectFor(entry),
          oldLocal,
          newLocal,
          () => appRepository.editTaskEntry([original]),
        );
      case InstallationEntry():
        final ci = entry.componentInstallation;
        final originalComponent = ci.component;
        final updatedInstallations =
            _reDated(originalComponent, ci.installation, newUtc, newLocal);
        if (!isValidInstallationTimeline(updatedInstallations)) {
          _rejectMove("Can't move this installation there.");
          return;
        }
        await appRepository.editComponent(originalComponent.copyWith(installations: updatedInstallations));
        _showMoveUndoSnackBar(
          calendarSubjectFor(entry),
          oldLocal,
          newLocal,
          () => appRepository.editComponent(originalComponent),
        );
      case RatingEntryTimelineEntry():
        final original = entry.ratingEntry;
        await appRepository.editRatingEntry(original.copyWith(dateTimeUTC: newUtc, dateTimeLocal: newLocal));
        _showMoveUndoSnackBar(
          calendarSubjectFor(entry),
          oldLocal,
          newLocal,
          () => appRepository.editRatingEntry(original),
        );
      case StravaEntry():
        // Strava activities are synced and read-only.
        _rejectMove("Strava activities can't be edited.");
    }
  }

  /// Refuses a drag: explains why and rebuilds so the appointment snaps back to
  /// its original slot.
  void _rejectMove(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.error(context, message, duration: const Duration(seconds: 2)),
    );
    setState(() {});
  }

  void _showMoveUndoSnackBar(
    String subject,
    DateTime from,
    DateTime to,
    Future<void> Function() restore,
  ) {
    if (!mounted) return;
    final appSettings = context.read<AppSettings>();
    final format = DateFormat('${appSettings.dateFormat} ${appSettings.timeFormat}');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.info(
        context,
        "'$subject' moved\n${format.format(from)}  →  ${format.format(to)}",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => restore(),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();
    final entries = _buildEntries(appRepository, appSettings, subscriptionService);
    final rows = buildCalendarRows(entries, appSettings);
    final calendarItems = <Object>[
      ...rows,
      ..._buildPredictedTasks(appRepository, appSettings, subscriptionService),
      if (_pendingSetupDate case final date?) CalendarAddSetupSlot(date),
    ];
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _returnView == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _selectReturnView();
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        title: Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterSheetChip.calendar,
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.today, size: 18),
              label: const Text('Today'),
              onPressed: _todayShown
                  ? null
                  : () => _controller.displayDate = DateTime.now(),
            ),
            const SizedBox(width: 6),
            MenuAnchor(
              alignmentOffset: const Offset(0, 4),
              style: MenuStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              menuChildren: _CalendarView.values.map((cv) => _viewMenuItem(cv, cs)).toList(),
              builder: (context, controller, child) => ActionChip(
                avatar: Icon(_selectedView.icon, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedView.label),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final cellHeight = (constraints.maxHeight - kCalendarHeaderHeight - kCalendarViewHeaderHeight) / kCalendarMonthWeekRows;
                return SfCalendarTheme(
                  data: SfCalendarThemeData(
                    backgroundColor: cs.surface,
                    todayHighlightColor: cs.primary,
                    cellBorderColor: cs.outlineVariant,
                    activeDatesTextStyle: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    leadingDatesTextStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                  child: SfCalendar(
                    controller: _controller,
                    view: _defaultView.view,
                    firstDayOfWeek: appSettings.firstDayOfWeek,
                    maxDate: DateTime.now().add(kCalendarFutureWindow),
                    cellEndPadding: 0,
                    dataSource: CalendarTimelineDataSource(calendarItems, cs),
                    allowDragAndDrop: true,
                    dragAndDropSettings: DragAndDropSettings(
                      indicatorTimeFormat: appSettings.timeFormat,
                    ),
                    showDatePickerButton: true,
                    backgroundColor: cs.surface,
                    cellBorderColor: cs.outlineVariant,
                    todayHighlightColor: cs.primary,
                    headerHeight: kCalendarHeaderHeight,
                    headerDateFormat: 'MMMM yyyy',
                    headerStyle: CalendarHeaderStyle(
                      textAlign: TextAlign.left,
                      backgroundColor: Colors.transparent,
                      textStyle: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    viewHeaderStyle: ViewHeaderStyle(
                      backgroundColor: cs.surface,
                      dayTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      dateTextStyle: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: (details) => _onTap(details, entries),
                    onDragStart: (_) => unawaited(HapticFeedback.lightImpact()),
                    onDragEnd: _onDragEnd,
                    onViewChanged: (ViewChangedDetails details) {
                      _ensureStravaCoverage(details.visibleDates);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _visibleDates = details.visibleDates);
                      });
                    },
                    appointmentBuilder: _appointmentBuilder,
                    timeSlotViewSettings: TimeSlotViewSettings(
                      numberOfDaysInView: _selectedView.days,
                      timeInterval: kCalendarZeroDuration,
                      timeIntervalHeight: kCalendarTimeSlotHeight,
                      timeFormat: appSettings.timeFormat,
                      timeTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                      dayFormat: 'EEE',
                    ),
                    scheduleViewSettings: ScheduleViewSettings(
                      hideEmptyScheduleWeek: true,
                      appointmentItemHeight: 56,
                      monthHeaderSettings: MonthHeaderSettings(
                        height: 56,
                        monthFormat: 'MMMM yyyy',
                        backgroundColor: cs.surfaceContainerHighest,
                        monthTextStyle: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      weekHeaderSettings: WeekHeaderSettings(
                        backgroundColor: cs.surface,
                        weekTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                      dayHeaderSettings: DayHeaderSettings(
                        dayTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        dateTextStyle: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      appointmentTextStyle: TextStyle(color: cs.onSurface, fontSize: 13),
                    ),
                    monthViewSettings: MonthViewSettings(
                      appointmentDisplayMode: cellHeight >= kCalendarMonthCellMinHeight
                          ? MonthAppointmentDisplayMode.appointment
                          : MonthAppointmentDisplayMode.indicator,
                      appointmentDisplayCount: 4,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _appointmentBuilder(BuildContext context, CalendarAppointmentDetails details) {
    if (details.isMoreAppointmentRegion) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          '+${details.appointments.length} more',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final row = details.appointments.first;
    if (row is CalendarAddSetupSlot) {
      return CalendarAddSetupAppointment(details: details, slot: row, addSetupAtDate: _addSetupAtDate);
    }
    final cs = Theme.of(context).colorScheme;
    if (row is CalendarPredictedTask) {
      return CalendarEntryAppointment(
        details: details,
        icon: kCalendarPredictedTaskIcon,
        subject: row.name,
        color: cs.tertiary,
        contentColor: cs.tertiary,
        ghost: true,
      );
    }
    if (row is! EntryRow) return const SizedBox.shrink();
    final showSetupBookmark = context.read<AppSettings>().enableSetupBookmark;
    return CalendarEntryAppointment(
      details: details,
      icon: calendarIconForRow(row, showSetupBookmark: showSetupBookmark),
      subject: calendarSubjectForRow(row),
      color: calendarColorForRow(row, cs),
      contentColor: calendarOnColorForRow(row, cs),
    );
  }
}

class CalendarTimelineDataSource extends CalendarDataSource<Object> {
  CalendarTimelineDataSource(List<Object> source, this._cs) {
    appointments = source;
  }

  final ColorScheme _cs;

  Object _item(int index) => appointments![index] as Object;

  @override
  DateTime getStartTime(int index) => switch (_item(index)) {
        EntryRow(:final anchorDateLocal) => anchorDateLocal,
        CalendarAddSetupSlot(:final date) => date,
        CalendarPredictedTask(:final date) => date,
        _ => throw StateError('Unsupported calendar item'),
      };

  @override
  DateTime getEndTime(int index) {
    final item = _item(index);
    if (item case CalendarAddSetupSlot(:final date)) {
      return date.add(kCalendarZeroDuration);
    }
    if (item case CalendarPredictedTask(:final date)) {
      return date.add(kCalendarZeroDuration);
    }
    final row = item as EntryRow;
    return switch (row) {
      // Anchored to the row's start (not `startDate.toLocal()`) so the span
      // stays positive for activities recorded in another timezone.
      SingleEntryRow(entry: StravaEntry(:final activity)) =>
        row.anchorDateLocal.add(activity.elapsedTime),
      ReplacementRow() => _replacementEndTime(row),
      SingleEntryRow() || SetupGroupRow() =>
        row.anchorDateLocal.add(kCalendarZeroDuration),
    };
  }

  /// A replacement spans its earlier half to its later one, but never shorter
  /// than [kCalendarZeroDuration]: the two halves sit within [kReplacementWindow]
  /// (minutes apart), so in timeslot views (day/3-day/week) the real span would
  /// render as a 1-2px sliver and vanish. Clamping to the point-event minimum
  /// keeps it a visible block there while month/schedule ignore duration anyway.
  DateTime _replacementEndTime(ReplacementRow row) {
    final start = row.anchorDateLocal;
    final removed = row.removed.installation.dateTimeLocal;
    final installed = row.installed.installation.dateTimeLocal;
    final later = removed.isAfter(installed) ? removed : installed;
    final minEnd = start.add(kCalendarZeroDuration);
    return later.isAfter(minEnd) ? later : minEnd;
  }

  @override
  String getSubject(int index) => switch (_item(index)) {
        final EntryRow row => calendarSubjectForRow(row),
        CalendarAddSetupSlot() => 'Add setup',
        CalendarPredictedTask(:final name) => name,
        _ => '',
      };

  @override
  Color getColor(int index) => switch (_item(index)) {
        final EntryRow row => calendarColorForRow(row, _cs),
        CalendarAddSetupSlot() => _cs.primaryContainer,
        // Faded here too: month cells fall back to indicator dots painted from
        // this colour, which never reach [_appointmentBuilder]'s outline.
        CalendarPredictedTask() => _cs.tertiary.withValues(alpha: kCalendarGhostAlpha),
        _ => Colors.transparent,
      };

  // Required for drag-and-drop with custom appointment objects. [_onDragEnd]
  // applies the new date, so return the same object to satisfy the framework's
  // non-null conversion contract.
  @override
  Object convertAppointmentToObject(
          Object customData, Appointment appointment) =>
      customData;
}

enum _CalendarView {
  schedule(CalendarView.schedule, 'Schedule', -1, Icons.view_agenda_outlined),
  month(CalendarView.month, 'Month', -1, Icons.calendar_view_month),
  week(CalendarView.week, 'Week', -1, Icons.calendar_view_week),
  threeDay(CalendarView.day, '3 Day', 3, Icons.view_column_outlined),
  day(CalendarView.day, 'Day', -1, Icons.calendar_view_day);
  final CalendarView view;
  final String label;
  final int days;
  final IconData icon;
  const _CalendarView(this.view, this.label, this.days, this.icon);
}
