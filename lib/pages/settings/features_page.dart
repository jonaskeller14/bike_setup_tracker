import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../widgets/sheets/checkbox_group.dart';
import '../../widgets/sheets/radio_group.dart';
import '../../widgets/text/section_title.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static const Map<bool, Text> _offOnOptionWidgets = {
    false: Text('Off'),
    true: Text('On'),
  };

  static String _timelineGroupingSummary(AppSettings settings) {
    final enabled = [
      if (settings.enableTimelineSetupGrouping) 'Setup Grouping',
      if (settings.enableTimelineReplacementDetection) 'Replacement Detection',
      if (settings.enableTimelineStravaContext) 'Strava Context',
    ];
    return enabled.isEmpty ? 'Off' : enabled.join(', ');
  }

  static String _categoricalAdjustmentSummary(AppSettings settings) {
    final enabled = [
      if (settings.enableMultiSelect) 'Multi-select',
      if (settings.enableCountedSelect) 'Count occurrences',
    ];
    return enabled.isEmpty ? 'Off' : enabled.join(', ');
  }

  static const String _setupExtrasTitle = kDebugMode ? "Setup Tags, Images & Bookmarks" : "Setup Tags";

  static String _setupExtrasSummary(AppSettings settings) {
    final enabled = [
      if (settings.enableSetupTags) 'Tags',
      if (kDebugMode && settings.enableSetupImages) 'Images',
      if (kDebugMode && settings.enableSetupBookmark) 'Bookmarks',
    ];
    return enabled.isEmpty ? 'Off' : enabled.join(', ');
  }

  static String _taskOptionsSummary(AppSettings settings) {
    final enabled = [
      if (settings.enableTaskTags) 'Tags',
      if (settings.enableTaskPriority) 'Priority',
      if (settings.enableTaskInterval) 'Interval',
      if (settings.enableTaskDelay) 'Delay',
    ];
    return enabled.isEmpty ? 'Off' : enabled.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(
                  'Enable these to add specific functionality to your workflow. Keep them disabled to maintain a simpler interface.',
                ),
                dense: true,
              ),
              const SectionTitle(title: 'Bikes & Components'),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text("Installation Timeline"),
                subtitle: _offOnOptionWidgets[appSettings.enableInstallationTimeline] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<bool>(
                  context: context,
                  title: "Installation Timeline",
                  value: appSettings.enableInstallationTimeline,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableInstallationTimeline = newValue;
                    Navigator.pop(context);
                  },
                  infoText:
                      'By default, Components are linked to a Bike. '
                      'When this setting is enabled, you can track exactly when a component was installed and uninstalled. '
                      'This allows you to uninstall components and move them between different bikes without losing track of their history, usage, or setups.',
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text("Component Presets"),
                  subtitle: _offOnOptionWidgets[appSettings.enableComponentPresets] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<bool>(
                    context: context,
                    title: "Component Presets",
                    value: appSettings.enableComponentPresets,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableComponentPresets = newValue;
                      Navigator.pop(context);
                    },
                    infoText:
                        'When adding a fork or shock, pick the model from a built-in '
                        'catalog to prefill its name, notes and adjustments (click ranges, '
                        'air pressure, SAG) automatically. You can still edit everything afterwards.',
                  ),
                ),
              const Divider(),
              const SectionTitle(title: 'Setups'),
              ListTile(
                leading: const Icon(TextAdjustment.iconData),
                title: const Text("Text Adjustment"),
                subtitle: _offOnOptionWidgets[appSettings.enableTextAdjustment] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<bool>(
                  context: context,
                  title: "Text Adjustment",
                  value: appSettings.enableTextAdjustment,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableTextAdjustment = newValue;
                    Navigator.pop(context);
                  },
                  infoText: 'Adds a Text Adjustment type that provides a free-form text field.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_rtl),
                title: const Text("Categorical Adjustment"),
                subtitle: Text(_categoricalAdjustmentSummary(appSettings)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => checkboxGroupSheet(
                  context: context,
                  title: "Categorical Adjustment",
                  infoText: 'Extra options for Categorical Adjustments. Each can be toggled on its own.',
                  options: [
                    CheckboxGroupSheetOption(
                      title: 'Multi-select',
                      subtitle: 'Allow selecting multiple categories instead of only one.',
                      value: () => appSettings.enableMultiSelect,
                      onChanged: (v) => appSettings.enableMultiSelect = v,
                    ),
                    CheckboxGroupSheetOption(
                      title: 'Count occurrences',
                      subtitle: 'Record how many times each category is selected.',
                      value: () => appSettings.enableCountedSelect,
                      onChanged: (v) => appSettings.enableCountedSelect = v,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text(_setupExtrasTitle),
                subtitle: Text(_setupExtrasSummary(appSettings)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => checkboxGroupSheet(
                  context: context,
                  title: _setupExtrasTitle,
                  infoText: 'Extra ways to organize and annotate Setups. Each can be toggled on its own.',
                  options: [
                    CheckboxGroupSheetOption(
                      title: 'Setup Tags',
                      subtitle: 'Adds the option to add tags to Setups.',
                      value: () => appSettings.enableSetupTags,
                      onChanged: (v) {
                        appSettings.enableSetupTags = v;
                        if (!v) context.read<AppRepository>().deselectAllSetupTags();
                      },
                    ),
                    if (kDebugMode)
                      CheckboxGroupSheetOption(
                        title: 'Setup Images',
                        subtitle:
                            'Attach images to setups. WARNING: images are stored only on this '
                            'device. They are NOT included in cloud/Drive backups and will be lost on '
                            'reinstall or when restoring from a backup. Use "Export Images" to move them '
                            'to a new device.',
                        value: () => appSettings.enableSetupImages,
                        onChanged: (v) => appSettings.enableSetupImages = v,
                      ),
                    if (kDebugMode)
                      CheckboxGroupSheetOption(
                        title: 'Setup Bookmarks',
                        subtitle:
                            'Mark good setups with a bookmark so they stand out among all the '
                            'setups you record. Bookmarks are stored with the setup and are '
                            'included in backups and exports.',
                        value: () => appSettings.enableSetupBookmark,
                        onChanged: (v) {
                          appSettings.enableSetupBookmark = v;
                          if (!v) context.read<AppRepository>().setShowBookmarkedSetupsOnly(false);
                        },
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.view_agenda_outlined),
                title: const Text("Timeline Grouping"),
                subtitle: Text(_timelineGroupingSummary(appSettings)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => checkboxGroupSheet(
                  context: context,
                  title: "Timeline Grouping",
                  infoText:
                      'Controls how the Setup History timeline condenses '
                      'related entries. Each pass can be toggled on its own.',
                  options: [
                    CheckboxGroupSheetOption(
                      title: 'Setup Grouping',
                      subtitle: 'Merge setups of the same bike recorded close together.',
                      value: () => appSettings.enableTimelineSetupGrouping,
                      onChanged: (v) => appSettings.enableTimelineSetupGrouping = v,
                    ),
                    CheckboxGroupSheetOption(
                      title: 'Replacement Detection',
                      subtitle: 'Show a removal and the install replacing it as one entry.',
                      value: () => appSettings.enableTimelineReplacementDetection,
                      onChanged: (v) => appSettings.enableTimelineReplacementDetection = v,
                    ),
                    CheckboxGroupSheetOption(
                      title: 'Strava Context',
                      subtitle: subscriptionService.hasStravaEntitlement
                          ? 'Mark entries recorded during a ride as part of that activity.'
                          : 'Mark entries recorded during a ride as part of that activity. Needs a connected Strava subscription.',
                      value: () => appSettings.enableTimelineStravaContext,
                      onChanged: (v) => appSettings.enableTimelineStravaContext = v,
                      enabled: appSettings.enableStrava && subscriptionService.hasStravaEntitlement,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SectionTitle(title: 'Tasks'),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text("Tasks"),
                subtitle: _offOnOptionWidgets[appSettings.enableTask] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<bool>(
                  context: context,
                  title: "Tasks",
                  infoText:
                      "Plan and track anything from recurring maintenance like fork services and chain cleaning to setup experiments like suspension testing or trying different handlebar widths. Keep a complete log of your goals and achievements in one place.",
                  value: appSettings.enableTask,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableTask = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                enabled: appSettings.enableTask,
                leading: const Icon(Icons.rule),
                title: const Text("Task Tags, Priority, Interval & Delay"),
                subtitle: Text(_taskOptionsSummary(appSettings)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => checkboxGroupSheet(
                  context: context,
                  title: "Task Tags, Priority, Interval & Delay",
                  infoText: 'Extra fields and behaviors for Tasks. Each can be toggled on its own.',
                  options: [
                    CheckboxGroupSheetOption(
                      title: 'Task Tags',
                      subtitle: 'Adds the option to add tags to Task Rules.',
                      value: () => appSettings.enableTaskTags,
                      onChanged: (v) {
                        appSettings.enableTaskTags = v;
                        if (!v) context.read<AppRepository>().deselectAllTaskRuleTags();
                      },
                    ),
                    CheckboxGroupSheetOption(
                      title: 'Task Priority',
                      subtitle: 'Shows the Priority field on tasks. Disable to simplify the task interface.',
                      value: () => appSettings.enableTaskPriority,
                      onChanged: (v) {
                        appSettings.enableTaskPriority = v;
                        if (!v) context.read<AppRepository>().selectAllTaskPriorities();
                      },
                    ),
                    CheckboxGroupSheetOption(
                      title: 'Task Interval',
                      subtitle:
                          "Adds an optional trigger to tasks with a progress bar based on time or, with "
                          "Strava connected, activity stats like distance, elevation and ride time.",
                      value: () => appSettings.enableTaskInterval,
                      onChanged: (v) => appSettings.enableTaskInterval = v,
                    ),
                    CheckboxGroupSheetOption(
                      title: 'Task Delay',
                      subtitle:
                          'Lets you postpone when a task becomes due, without changing its interval. '
                          'A delay only applies once: completing the task clears it automatically.',
                      value: () => appSettings.enableTaskDelay,
                      onChanged: (v) => appSettings.enableTaskDelay = v,
                    ),
                  ],
                ),
              ),
              if (kDebugMode)
                ListTile(
                  enabled: appSettings.enableTask,
                  leading: const Icon(Icons.insights),
                  title: const Text("Task Due Prediction"),
                  subtitle: _offOnOptionWidgets[appSettings.enableTaskDuePrediction] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<bool>(
                    context: context,
                    title: "Task Due Prediction",
                    value: appSettings.enableTaskDuePrediction,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableTaskDuePrediction = newValue;
                      Navigator.pop(context);
                    },
                    infoText:
                        'Estimates when a task will come due by extrapolating how much the bike '
                        'has been ridden recently. Needs a connected Strava subscription, and only '
                        'shows for tasks that are not due yet.',
                  ),
                ),
              ListTile(
                enabled: appSettings.enableTask,
                leading: const Icon(Icons.adjust),
                title: const Text("Garage Task Indicator"),
                subtitle: _offOnOptionWidgets[appSettings.enableGarageTaskIndicator] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<bool>(
                  context: context,
                  title: "Garage Task Indicator",
                  value: appSettings.enableGarageTaskIndicator,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableGarageTaskIndicator = newValue;
                    Navigator.pop(context);
                  },
                  infoText: 'Shows a colored status dot on component icons in the Garage when they have open tasks.',
                ),
              ),
              const Divider(),
              const SectionTitle(title: 'Other'),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(SimpleIcons.googledrive),
                  title: const Text("Google Drive Sync"),
                  subtitle: _offOnOptionWidgets[appSettings.enableGoogleDrive] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<bool>(
                    context: context,
                    title: "Google Drive Sync",
                    value: appSettings.enableGoogleDrive,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableGoogleDrive = newValue;
                      Navigator.pop(context);
                    },
                    infoText:
                        'Sync your data across devices and keep secure backups in your Google Drive. Your data is stored privately in your own account; we never have access to it.',
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text("Calendar"),
                subtitle: _offOnOptionWidgets[appSettings.enableCalendar] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<bool>(
                  context: context,
                  title: "Calendar",
                  value: appSettings.enableCalendar,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableCalendar = newValue;
                    Navigator.pop(context);
                  },
                  infoText:
                      "Adds a calendar view, reachable from the Setup History page via the calendar button next to search and map buttons.",
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  subtitle: _offOnOptionWidgets[appSettings.enablePerson] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<bool>(
                    context: context,
                    title: "Profile",
                    value: appSettings.enablePerson,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enablePerson = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text("Rating"),
                  subtitle: _offOnOptionWidgets[appSettings.enableRating] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<bool>(
                    context: context,
                    title: "Rating",
                    value: appSettings.enableRating,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableRating = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text("MapBox Tiles"),
                  subtitle: _offOnOptionWidgets[appSettings.useMapBoxTiles] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<bool>(
                    context: context,
                    title: "MapBox Tiles",
                    value: appSettings.useMapBoxTiles,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.useMapBoxTiles = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
