import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../services/app_hint_service.dart';
import '../app_snackbar.dart';
import 'garage_list_hint.dart';
import 'getting_started_guide_hint.dart';
import 'release_44_hint.dart';
import 'setup_calendar_hint.dart';
import 'setup_comparison_hint.dart';
import 'setup_task_hint.dart';
import 'strava_gear_link_hint.dart';
import 'subcomponents_hint.dart';
import 'task_list_hint.dart';

class AppHintSlot extends StatelessWidget {
  static const _sizeAnimationDuration = Duration(milliseconds: 200);
  static const _subcomponentsEnabledMessage =
      'Subcomponents enabled — edit a part and pick its parent under "Installed on"';
  final EdgeInsetsGeometry padding;

  const AppHintSlot({super.key, required this.placement, this.padding = EdgeInsetsGeometry.zero});

  final AppHintPlacement placement;

  @override
  Widget build(BuildContext context) {
    final hintService = context.watch<AppHintService>();
    final hint = hintService.activeHintFor(placement);
    final child = switch (hint) {
      null => const SizedBox.shrink(),
      AppHint.gettingStartedV1 => GettingStartedGuideHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.gettingStartedV1)),
      ),
      AppHint.garageGesturesV1 => GarageListHint(
        onDismiss: () => unawaited(
          hintService.dismiss(AppHint.garageGesturesV1),
        ),
      ),
      AppHint.setupTasksV1 => SetupTaskHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.setupTasksV1)),
        onActivate: () => _enableTasks(context, hintService),
      ),
      AppHint.setupCalendarV1 => SetupCalendarHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.setupCalendarV1)),
        onActivate: () => _enableCalendar(context, hintService),
      ),
      AppHint.setupComparisonV1 => SetupComparisonHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.setupComparisonV1)),
      ),
      AppHint.stravaLinkGearV1 => StravaGearLinkHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.stravaLinkGearV1)),
      ),
      AppHint.installationTimelineV1 => const SizedBox.shrink(),
      AppHint.subcomponentsV1 => SubcomponentsHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.subcomponentsV1)),
        onActivate: () => _enableSubcomponents(context, hintService),
      ),
      AppHint.taskGesturesV1 => TaskListHint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.taskGesturesV1)),
      ),
      AppHint.release44 => Release44Hint(
        onDismiss: () => unawaited(hintService.dismiss(AppHint.release44)),
        onEnableSubcomponents: () async => _turnOnSubcomponents(context),
        onEnableAttachments: () => _enableAttachments(context, hintService),
      ),
    };

    return AnimatedSize(
      duration: _sizeAnimationDuration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: hint != null ? Padding(padding: padding, child: child) : child,
    );
  }

  Future<void> _enableTasks(
    BuildContext context,
    AppHintService hintService,
  ) async {
    context.read<AppSettings>().enableTask = true;
    await hintService.complete(AppHint.setupTasksV1);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.success(context, 'Tasks enabled — find it in the home bottom navigation bar'),
    );
  }

  Future<void> _enableCalendar(
    BuildContext context,
    AppHintService hintService,
  ) async {
    context.read<AppSettings>().enableCalendar = true;
    await hintService.complete(AppHint.setupCalendarV1);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.success(context, 'Calendar enabled — find it next to the search button on the Setups tab'),
    );
  }

  Future<void> _enableSubcomponents(
    BuildContext context,
    AppHintService hintService,
  ) async {
    context.read<AppSettings>().enableInstallOnComponent = true;
    await hintService.complete(AppHint.subcomponentsV1);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.success(context, _subcomponentsEnabledMessage),
    );
  }

  /// Leaves the hint pending, so a deck can move on to its next card.
  void _turnOnSubcomponents(BuildContext context) {
    context.read<AppSettings>().enableInstallOnComponent = true;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.success(context, _subcomponentsEnabledMessage),
    );
  }

  Future<void> _enableAttachments(
    BuildContext context,
    AppHintService hintService,
  ) async {
    context.read<AppSettings>().enableAttachments = true;
    await hintService.complete(AppHint.release44);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.success(context, 'Attachments enabled — add photos and files to bikes, components, setups and tasks'),
    );
  }
}
