import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../services/app_hint_service.dart';
import 'garage_list_hint.dart';
import 'getting_started_guide_hint.dart';
import 'setup_calendar_hint.dart';
import 'setup_task_hint.dart';

/// Maps hint IDs to their inline presentation, keeping eligibility out of screens.
class AppHintSlot extends StatelessWidget {
  const AppHintSlot({super.key, required this.placement});

  final AppHintPlacement placement;

  @override
  Widget build(BuildContext context) {
    final hintService = context.watch<AppHintService>();
    final hint = hintService.activeHintFor(placement);
    return switch (hint) {
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
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _enableTasks(
    BuildContext context,
    AppHintService hintService,
  ) async {
    context.read<AppSettings>().enableTask = true;
    await hintService.complete(AppHint.setupTasksV1);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        persist: false,
        showCloseIcon: true,
        content: Text('Tasks enabled — find it in the home bottom navigation bar'),
      ),
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
      const SnackBar(
        persist: false,
        showCloseIcon: true,
        content: Text(
          'Calendar enabled — find it next to the search button on the Setups tab',
        ),
      ),
    );
  }
}
