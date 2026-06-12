import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../icons/simple_icons.dart';
import '../models/app_settings.dart';
import '../models/setup.dart';
import '../models/timeline_entry.dart';
import '../repositories/app_repository.dart';
import '../services/subscription_service.dart';
import '../widgets/chips/filter_sheet_chip.dart';
import '../widgets/sheets/installation_sheet.dart';
import '../widgets/sheets/setup_details.dart';
import '../widgets/sheets/strava_activity.dart';
import '../widgets/sheets/task_rule_sheet.dart';

const Duration kCalendarZeroDuration = Duration(minutes: 30);
const Color kCalendarStravaColor = Color(0xFFFC4C02); // Strava brand orange
const Duration kCalendarScrollLeadIn = Duration(minutes: 30);
const int kCalendarFallbackHour = 6;

IconData calendarIconFor(TimelineEntry entry) => switch (entry) {
      SetupEntry() => Setup.iconData,
      StravaEntry() => SimpleIcons.strava,
      TaskTimeLineEntry() => Icons.check_box_outlined,
      InstallationEntry() => entry.componentInstallation.component.componentType.getIconData(),
    };

Color calendarColorFor(TimelineEntry entry, ColorScheme cs) => switch (entry) {
      SetupEntry() => cs.primary,
      StravaEntry() => kCalendarStravaColor,
      TaskTimeLineEntry() => cs.tertiary,
      InstallationEntry() => cs.secondary,
    };

Color calendarOnColorFor(TimelineEntry entry, ColorScheme cs) => switch (entry) {
      SetupEntry() => cs.onPrimary,
      StravaEntry() => Colors.white,
      TaskTimeLineEntry() => cs.onTertiary,
      InstallationEntry() => cs.onSecondary,
    };

String calendarSubjectFor(TimelineEntry entry) => switch (entry) {
      SetupEntry() => entry.setup.name,
      StravaEntry() => entry.activity.name,
      TaskTimeLineEntry() => entry.taskEntry.name,
      InstallationEntry() => entry.componentInstallation.shortLabel,
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

  /// Dates currently visible, fed from [SfCalendar.onViewChanged]; used to tell
  /// whether "today" is already on screen (to disable the Today button).
  List<DateTime> _visibleDates = const [];

  DateTime _displayDateForDay(DateTime day, List<TimelineEntry> entries) {
    final target = DateUtils.dateOnly(day);
    DateTime? earliest;
    for (final entry in entries) {
      final local = entry.date.toLocal();
      if (!DateUtils.isSameDay(local, target)) continue;
      if (earliest == null || local.isBefore(earliest)) earliest = local;
    }
    if (earliest == null) return target.copyWith(hour: kCalendarFallbackHour);
    return earliest.subtract(kCalendarScrollLeadIn);
  }

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
    });
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Syncfusion's month-view layout crashes when the month cells get too short
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
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
    ];
  }

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
    final visibleEnd = visibleDates.last;

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
    // Tapping a day (month cell or day header) drills into the Day view.
    if (details.targetElement == CalendarElement.calendarCell ||
        details.targetElement == CalendarElement.viewHeader) {
      final date = details.date;
      if (date != null && _controller.view != CalendarView.day) {
        setState(() {
          _returnView = _selectedView;
          _selectedView = _CalendarView.day;
          _controller.view = CalendarView.day;
          _controller.displayDate = _displayDateForDay(date, entries);
        });
      }
      return;
    }

    if (details.targetElement != CalendarElement.appointment) return;
    final appointments = details.appointments;
    if (appointments == null || appointments.isEmpty) return;
    final entry = appointments.first;
    if (entry is! TimelineEntry) return;

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
    }
  }

  Future<void> _onDragEnd(AppointmentDragEndDetails details) async {
    final entry = details.appointment;
    final newLocal = details.droppingTime;
    if (entry is! TimelineEntry || newLocal == null) return;
    final newUtc = newLocal.toUtc();
    final repo = context.read<AppRepository>();

    switch (entry) {
      case SetupEntry():
        await repo.editSetup(entry.setup.copyWith(datetime: newUtc, datetimeLocal: newLocal));
      case TaskTimeLineEntry():
        await repo.editTaskEntry(
          entry.taskEntry.copyWith(dateTimeUTC: newUtc, dateTimeLocal: newLocal),
        );
      case InstallationEntry():
        final ci = entry.componentInstallation;
        final oldInstallation = ci.installation;
        final newInstallation =
            oldInstallation.copyWith(dateTimeUTC: newUtc, dateTimeLocal: newLocal);
        final updatedInstallations = ci.component.installations
            .map((i) => i == oldInstallation ? newInstallation : i)
            .toList();
        await repo.editComponent(ci.component.copyWith(installations: updatedInstallations));
      case StravaEntry():
        // Strava activities are synced and read-only — reject the move and
        // rebuild so the appointment snaps back to its original slot.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text(
            "Strava activities can't be edited",
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ));
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();
    final entries = _buildEntries(appRepository, appSettings, subscriptionService);
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
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterSheetChip(
                  enableSetupTagFilter: appSettings.enableSetupTags,
                  showTimelineVisibility: true,
                ),
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
            child: SfCalendarTheme(
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
                maxDate: DateTime.now().add(kCalendarZeroDuration),
                dataSource: _TimelineDataSource(entries, cs),
                allowDragAndDrop: true,
                dragAndDropSettings: DragAndDropSettings(
                  indicatorTimeFormat: appSettings.timeFormat,
                ),
                showDatePickerButton: true,
                backgroundColor: cs.surface,
                cellBorderColor: cs.outlineVariant,
                todayHighlightColor: cs.primary,
                headerHeight: 48,
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
                  timeIntervalHeight: 60,
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
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                  appointmentDisplayCount: 4,
                ),
              ),
            ),
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

    final entry = details.appointments.first;
    if (entry is! TimelineEntry) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = calendarColorFor(entry, cs);
    final onColor = calendarOnColorFor(entry, cs);
    final height = details.bounds.height;
    final width = details.bounds.width;
    // Decide what fits so a narrow column (many concurrent events) never
    // overflows: drop the label, then the icon, as space runs out. The label is
    // gated mainly on width, so it still shows in the short-but-wide month rows.
    final bool showIcon = width >= 16 && height >= 8;
    final bool showText = width >= 40 && height >= 9;
    final double iconSize = height < 16 ? 9 : (height < 20 ? 11 : 14);
    final double fontSize = height < 18 ? 9 : (height < 28 ? 10 : 12);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.symmetric(horizontal: showText ? 4 : 2, vertical: height < 20 ? 0 : 2),
      alignment: Alignment.centerLeft,
      child: !showIcon
          ? const SizedBox.shrink()
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(calendarIconFor(entry), size: iconSize, color: onColor),
                if (showText)
                  Flexible(
                    child: Text(
                      calendarSubjectFor(entry),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: onColor, fontSize: fontSize),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TimelineDataSource extends CalendarDataSource<TimelineEntry> {
  _TimelineDataSource(List<TimelineEntry> source, this._cs) {
    appointments = source;
  }

  final ColorScheme _cs;

  TimelineEntry _entry(int index) => appointments![index] as TimelineEntry;

  @override
  DateTime getStartTime(int index) => _entry(index).date.toLocal();

  @override
  DateTime getEndTime(int index) {
    final entry = _entry(index);
    if (entry is StravaEntry) {
      return entry.activity.startDate.toLocal().add(entry.activity.elapsedTime);
    }
    return entry.date.toLocal().add(kCalendarZeroDuration);
  }

  @override
  String getSubject(int index) => calendarSubjectFor(_entry(index));

  @override
  Color getColor(int index) => calendarColorFor(_entry(index), _cs);

  // Required for drag-and-drop with custom appointment objects. The new date is
  // applied by [_onDragEnd] via the repository, so we just hand back the same
  // entry to satisfy the framework's non-null conversion contract.
  @override
  TimelineEntry convertAppointmentToObject(
          TimelineEntry customData, Appointment appointment) =>
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
