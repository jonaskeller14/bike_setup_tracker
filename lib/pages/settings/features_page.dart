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

  static const String _setupExtrasTitle = kDebugMode ? "Setup Tags, Images & Bookmarks" : "Setup Tags";

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();

    final otherTiles = [
      if (Platform.isAndroid)
        _FeatureToggleTile(
          icon: SimpleIcons.googledrive,
          title: "Google Drive Sync",
          value: appSettings.enableGoogleDrive,
          onChanged: (v) => appSettings.enableGoogleDrive = v,
          infoText:
              'Sync your data across devices and keep secure backups in your Google Drive. Your data is stored privately in your own account; we never have access to it.',
        ),
      if (kDebugMode)
        _FeatureToggleTile(
          icon: Icons.map,
          title: "MapBox Tiles",
          value: appSettings.useMapBoxTiles,
          onChanged: (v) => appSettings.useMapBoxTiles = v,
        ),
    ];

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
              const SectionTitle(title: 'Components'),
              _FeatureToggleTile(
                icon: Icons.timeline,
                title: "Installation Timeline",
                value: appSettings.enableInstallationTimeline,
                onChanged: (v) => appSettings.enableInstallationTimeline = v,
                infoText:
                    'By default, Components are linked to a Bike. '
                    'When this setting is enabled, you can track exactly when a component was installed and uninstalled. '
                    'This allows you to uninstall components and move them between different bikes without losing track of their history, usage, or setups.',
              ),
              if (kDebugMode)
                _FeatureToggleTile(
                  enabled: appSettings.enableInstallationTimeline,
                  icon: Icons.account_tree_outlined,
                  title: "Subcomponents",
                  value: appSettings.enableInstallOnComponent,
                  onChanged: (v) => appSettings.enableInstallOnComponent = v,
                  infoText:
                      'Install components on other components in the Installation Timeline, '
                      'e.g. a tire on a wheel. The subcomponent follows its parent between bikes '
                      'and is credited with the same activities. Requires the Installation Timeline.',
                ),
              if (kDebugMode)
                _FeatureToggleTile(
                  icon: Icons.auto_awesome_outlined,
                  title: "Component Presets",
                  value: appSettings.enableComponentPresets,
                  onChanged: (v) => appSettings.enableComponentPresets = v,
                  infoText:
                      'When adding a fork or shock, pick the model from a built-in '
                      'catalog to prefill its name, notes and adjustments (click ranges, '
                      'air pressure, SAG) automatically. You can still edit everything afterwards.',
                ),
              const Divider(),
              const SectionTitle(title: 'Adjustments'),
              if (kDebugMode)
                _FeatureGroupTile(
                  icon: StepAdjustment.iconData,
                  title: "Step Adjustment",
                  infoText: 'Extra options for Step Adjustments. Each can be toggled on its own.',
                  options: [
                    CheckboxGroupSheetOption(
                      title: 'Dial Color & Size',
                      subtitle:
                          'When a Step Adjustment uses a dial visualization, lets you tap the dial '
                          'preview to cycle through its color and size. When disabled, only the '
                          'visualization dropdown is shown.',
                      value: () => appSettings.enableStepDialColorSize,
                      onChanged: (v) => appSettings.enableStepDialColorSize = v,
                    ),
                  ],
                ),
              _FeatureGroupTile(
                icon: CategoricalAdjustment.iconData,
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
              _FeatureToggleTile(
                icon: TextAdjustment.iconData,
                title: "Text Adjustment",
                value: appSettings.enableTextAdjustment,
                onChanged: (v) => appSettings.enableTextAdjustment = v,
                infoText: 'Adds a Text Adjustment type that provides a free-form text field.',
              ),
              const Divider(),
              const SectionTitle(title: 'Setups'),
              _FeatureGroupTile(
                icon: Icons.tag,
                title: _setupExtrasTitle,
                infoText: 'Extra ways to organize and annotate Setups. Each can be toggled on its own.',
                options: [
                  CheckboxGroupSheetOption(
                    title: 'Tags',
                    subtitle: 'Adds the option to add tags to Setups.',
                    value: () => appSettings.enableSetupTags,
                    onChanged: (v) {
                      appSettings.enableSetupTags = v;
                      if (!v) context.read<AppRepository>().deselectAllSetupTags();
                    },
                  ),
                  if (kDebugMode)
                    CheckboxGroupSheetOption(
                      title: 'Images',
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
                      title: 'Bookmarks',
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
              if (kDebugMode)
                _FeatureToggleTile(
                  icon: Icons.compress,
                  title: "Pressure Check",
                  value: appSettings.enablePressureAssistant,
                  onChanged: (v) => appSettings.enablePressureAssistant = v,
                  infoText:
                      'When adding a setup, compares each pressure adjustment against the '
                      'temperature and altitude of the setup that last changed it. A pump '
                      'measures against the surrounding air, so colder or thinner air makes '
                      'the same sealed chamber read differently — this tells you what your '
                      'pump would read now, and whether the difference is worth correcting.',
                ),
              if (kDebugMode)
                _FeatureToggleTile(
                  icon: Icons.star,
                  title: "Rating",
                  value: appSettings.enableRating,
                  onChanged: (v) => appSettings.enableRating = v,
                ),
              if (kDebugMode)
                _FeatureToggleTile(
                  icon: Icons.person,
                  title: "Profile",
                  value: appSettings.enablePerson,
                  onChanged: (v) => appSettings.enablePerson = v,
                ),
              const Divider(),
              const SectionTitle(title: 'Setup History'),
              _FeatureGroupTile(
                icon: Icons.view_agenda_outlined,
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
              _FeatureToggleTile(
                icon: Icons.calendar_month_outlined,
                title: "Calendar",
                value: appSettings.enableCalendar,
                onChanged: (v) => appSettings.enableCalendar = v,
                infoText:
                    "Adds a calendar view, reachable from the Setup History page via the calendar button next to search and map buttons.",
              ),
              const Divider(),
              const SectionTitle(title: 'Tasks'),
              _FeatureToggleTile(
                icon: Icons.checklist,
                title: "Tasks",
                value: appSettings.enableTask,
                onChanged: (v) => appSettings.enableTask = v,
                infoText:
                    "Plan and track anything from recurring maintenance like fork services and chain cleaning to setup experiments like suspension testing or trying different handlebar widths. Keep a complete log of your goals and achievements in one place.",
              ),
              _FeatureGroupTile(
                enabled: appSettings.enableTask,
                icon: Icons.label_outline,
                title: "Task Tags, Priority, Interval & Delay",
                infoText: 'Extra fields and behaviors for Tasks. Each can be toggled on its own.',
                options: [
                  CheckboxGroupSheetOption(
                    title: 'Tags',
                    subtitle: 'Adds the option to add tags to Task Rules.',
                    value: () => appSettings.enableTaskTags,
                    onChanged: (v) {
                      appSettings.enableTaskTags = v;
                      if (!v) context.read<AppRepository>().deselectAllTaskRuleTags();
                    },
                  ),
                  CheckboxGroupSheetOption(
                    title: 'Priority',
                    subtitle: 'Shows the Priority field on tasks. Disable to simplify the task interface.',
                    value: () => appSettings.enableTaskPriority,
                    onChanged: (v) {
                      appSettings.enableTaskPriority = v;
                      if (!v) context.read<AppRepository>().selectAllTaskPriorities();
                    },
                  ),
                  CheckboxGroupSheetOption(
                    title: 'Interval',
                    subtitle:
                        "Adds an optional trigger to tasks with a progress bar based on time or, with "
                        "Strava connected, activity stats like distance, elevation and ride time.",
                    value: () => appSettings.enableTaskInterval,
                    onChanged: (v) => appSettings.enableTaskInterval = v,
                  ),
                  CheckboxGroupSheetOption(
                    title: 'Delay',
                    subtitle:
                        'Lets you postpone when a task becomes due, without changing its interval. '
                        'A delay only applies once: completing the task clears it automatically.',
                    value: () => appSettings.enableTaskDelay,
                    onChanged: (v) => appSettings.enableTaskDelay = v,
                  ),
                ],
              ),
              _FeatureToggleTile(
                enabled: appSettings.enableTask,
                icon: Icons.insights,
                title: "Task Due Prediction",
                value: appSettings.enableTaskDuePrediction,
                onChanged: (v) => appSettings.enableTaskDuePrediction = v,
                infoText:
                    'Estimates when a task will come due. For date and duration intervals, '
                    'this is calculated directly from the last completion, no Strava needed. '
                    'For other intervals (distance, elevation, ride time, ...), it extrapolates '
                    'from how much the bike has been ridden recently and needs a connected '
                    'Strava subscription. Only shows for tasks that are not due yet.',
              ),
              _FeatureToggleTile(
                enabled: appSettings.enableTask,
                icon: Icons.adjust,
                title: "Garage Task Indicator",
                value: appSettings.enableGarageTaskIndicator,
                onChanged: (v) => appSettings.enableGarageTaskIndicator = v,
                infoText: 'Shows a colored status dot on component icons in the Garage when they have open tasks.',
              ),
              if (otherTiles.isNotEmpty) ...[
                const Divider(),
                const SectionTitle(title: 'Other'),
                ...otherTiles,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? infoText;
  final bool enabled;

  const _FeatureToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.infoText,
    this.enabled = true,
  });

  static const Map<bool, Text> _offOnOptionWidgets = {
    false: Text('Off'),
    true: Text('On'),
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: _offOnOptionWidgets[value],
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => radioGroupSheet<bool>(
        context: context,
        title: title,
        value: value,
        optionWidgets: _offOnOptionWidgets,
        onChanged: (bool? newValue) {
          if (newValue == null) return;
          onChanged(newValue);
          Navigator.pop(context);
        },
        infoText: infoText,
      ),
    );
  }
}

class _FeatureGroupTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String infoText;
  final List<CheckboxGroupSheetOption> options;
  final bool enabled;

  const _FeatureGroupTile({
    required this.icon,
    required this.title,
    required this.infoText,
    required this.options,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabledTitles = options.where((o) => o.value()).map((o) => o.title);
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(enabledTitles.isEmpty ? 'Off' : enabledTitles.join(', ')),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => checkboxGroupSheet(
        context: context,
        title: title,
        infoText: infoText,
        options: options,
      ),
    );
  }
}
