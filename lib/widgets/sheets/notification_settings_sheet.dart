import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/strava_service.dart';
import 'sheet_header.dart';

/// The push notifications after a Strava ride, each with a switch and an
/// example: imported rides, and due tasks while cloud sync and tasks are on.
Future<void> showNotificationSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => const _NotificationSettingsSheet(),
  );
}

/// Task-due pushes are about the rules the cloud holds (#17 Phase 8).
bool taskNotificationsAvailable(AppSettings appSettings) => appSettings.enableCloudSync && appSettings.enableTask;

/// The notifications that are on, e.g. "Imported rides, Due tasks", or "Off".
String notificationSettingsSummary(AppSettings appSettings, AppLocalizations l10n) {
  final on = [
    if (appSettings.enableStravaNotifications) l10n.settingsStravaNotifications,
    if (taskNotificationsAvailable(appSettings) && appSettings.enableTaskNotifications) l10n.settingsTaskNotifications,
  ];
  return on.isEmpty ? l10n.valueOff : on.join(', ');
}

class _NotificationSettingsSheet extends StatelessWidget {
  const _NotificationSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.watch<AppSettings>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.settingsNotifications, leadingIcon: const Icon(Icons.notifications_active)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.settingsNotificationsIntro,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NotificationOption(
                    title: l10n.settingsStravaNotifications,
                    info: l10n.settingsStravaNotificationsInfo,
                    value: appSettings.enableStravaNotifications,
                    onChanged: (value) {
                      appSettings.enableStravaNotifications = value;
                      unawaited(context.read<StravaService>().setStravaNotificationsEnabled(value));
                    },
                    exampleTitle: l10n.settingsStravaNotificationsExampleTitle,
                    exampleBody: l10n.settingsStravaNotificationsExampleBody,
                  ),
                  if (taskNotificationsAvailable(appSettings))
                    _NotificationOption(
                      title: l10n.settingsTaskNotifications,
                      info: l10n.settingsTaskNotificationsInfo,
                      value: appSettings.enableTaskNotifications,
                      // The Strava service rewrites the device doc on the settings change.
                      onChanged: (value) => appSettings.enableTaskNotifications = value,
                      exampleTitle: l10n.settingsTaskNotificationsExampleTitle,
                      exampleBody: l10n.settingsTaskNotificationsExampleBody,
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationOption extends StatelessWidget {
  const _NotificationOption({
    required this.title,
    required this.info,
    required this.value,
    required this.onChanged,
    required this.exampleTitle,
    required this.exampleBody,
  });

  final String title;
  final String info;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String exampleTitle;
  final String exampleBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: Text(info),
          value: value,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _NotificationPreview(title: exampleTitle, body: exampleBody, enabled: value),
        ),
      ],
    );
  }
}

/// An example push as the system shows it, faded while the switch is off.
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.title, required this.body, required this.enabled});

  final String title;
  final String body;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 6,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('assets/icons/logo_256.png', width: 16, height: 16),
                ),
                Expanded(
                  child: Text(l10n.appTitle, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(l10n.settingsNotificationsExample, style: muted),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(body, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
