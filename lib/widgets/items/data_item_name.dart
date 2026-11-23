import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/entity_names.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/feedback/test_session.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../models/syncable.dart';
import '../../models/task/task_entry.dart';
import '../../models/task/task_rule.dart';
import '../../services/data_selection_dependencies.dart';

/// The name the data select rows show for [item] (a feedback's name is its date and time).
String dataItemName(DataKind kind, Syncable item, AppLocalizations l10n, AppSettings appSettings) => switch (kind) {
  DataKind.person => (item as Person).name,
  DataKind.bike => (item as Bike).name,
  DataKind.component => (item as Component).name,
  DataKind.setup => (item as Setup).label(l10n),
  DataKind.taskRule => (item as TaskRule).name,
  DataKind.taskEntry => (item as TaskEntry).name,
  DataKind.feedback =>
    '${DateFormat(appSettings.dateFormat, l10n.localeName).format((item as RideFeedback).dateTimeLocal)} • '
        '${DateFormat(appSettings.timeFormat, l10n.localeName).format(item.dateTimeLocal)}',
  DataKind.testSession => (item as TestSession).label(l10n),
};

/// The icon the data select rows show for [item].
IconData dataItemIcon(DataKind kind, Syncable item) => switch (kind) {
  DataKind.person => Person.iconData,
  DataKind.bike => Bike.iconData,
  DataKind.component => (item as Component).componentType.getIconData(),
  DataKind.setup => Setup.iconData,
  DataKind.taskRule => Icons.check_box_outline_blank,
  DataKind.taskEntry => Icons.check_box_outlined,
  DataKind.feedback => RideFeedback.iconData,
  DataKind.testSession => TestSession.iconData,
};
