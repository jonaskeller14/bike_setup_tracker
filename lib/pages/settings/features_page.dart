import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/filters/activity_filter.dart';
import '../../models/filters/layer_filter.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../widgets/sheets/checkbox_group.dart';
import '../../widgets/sheets/feature_setting_sheet.dart';
import '../../widgets/sheets/installation_timeline_hint_sheet.dart';
import '../../widgets/sheets/presets_setting_sheets.dart';
import '../../widgets/sheets/pressure_check_setting_sheet.dart';
import '../../widgets/sheets/subcomponents_hint_sheet.dart';
import '../../widgets/text/section_title.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static void _showLayer(BuildContext context, TimelineLayer layer) {
    final filters = context.read<AppRepository>().filters;
    filters.layers = filters.layers.copyWith(hidden: filters.layers.hidden.difference({layer}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();

    final otherTiles = [
      if (Platform.isAndroid)
        _FeatureToggleTile(
          icon: SimpleIcons.googledrive,
          title: l10n.featuresGoogleDrive,
          value: appSettings.enableGoogleDrive,
          onChanged: (v) => appSettings.enableGoogleDrive = v,
          infoText: l10n.featuresGoogleDriveInfo,
        ),
      if (appSettings.developerMode) ...[
        _FeatureToggleTile(
          icon: Icons.cloud_sync_outlined,
          title: l10n.featuresCloudSync,
          value: appSettings.enableCloudSync,
          onChanged: (v) => appSettings.enableCloudSync = v,
          infoText: l10n.featuresCloudSyncInfo,
        ),
        _FeatureToggleTile(
          icon: Icons.account_circle_outlined,
          title: l10n.featuresAccounts,
          value: appSettings.enableAccounts,
          onChanged: (v) => appSettings.enableAccounts = v,
          infoText: l10n.featuresAccountsInfo,
        ),
      ],
      if (appSettings.developerMode)
        _FeatureToggleTile(
          icon: Icons.map,
          title: l10n.featuresMapBoxTiles,
          value: appSettings.useMapBoxTiles,
          onChanged: (v) => appSettings.useMapBoxTiles = v,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featuresTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.featuresIntro),
                dense: true,
              ),
              SectionTitle(title: l10n.featuresSectionComponents),
              _FeatureToggleTile(
                icon: Icons.timeline,
                title: l10n.featuresInstallationTimeline,
                value: appSettings.enableInstallationTimeline,
                onChanged: (v) {
                  appSettings.enableInstallationTimeline = v;
                  if (!v) _showLayer(context, TimelineLayer.installations);
                },
                sheet: (context, value) => showInstallationTimelineSettingSheet(context, value: value),
              ),
              _FeatureToggleTile(
                icon: Icons.account_tree_outlined,
                title: l10n.featuresSubcomponents,
                value: appSettings.enableInstallOnComponent,
                onChanged: (v) => appSettings.enableInstallOnComponent = v,
                sheet: (context, value) => showSubcomponentsSettingSheet(context, value: value),
              ),
              _FeatureToggleTile(
                icon: Icons.auto_awesome_outlined,
                title: l10n.featuresComponentPresets,
                value: appSettings.enableComponentPresets,
                onChanged: (v) => appSettings.enableComponentPresets = v,
                sheet: (context, value) => showComponentPresetsSettingSheet(context, value: value),
              ),
              if (appSettings.developerMode)
                _FeatureToggleTile(
                  enabled: appSettings.enableComponentPresets,
                  disabledSubtitle: l10n.featuresRequiresComponentPresets,
                  icon: Icons.tips_and_updates_outlined,
                  title: l10n.featuresSetupGuides,
                  value: appSettings.enableSetupGuides,
                  onChanged: (v) => appSettings.enableSetupGuides = v,
                  sheet: (context, value) => showSetupGuidesSettingSheet(context, value: value),
                ),
              const Divider(),
              SectionTitle(title: l10n.featuresSectionAdjustments),
              _FeatureGroupTile(
                icon: CategoricalAdjustment.iconData,
                title: l10n.featuresCategoricalAdjustment,
                infoText: l10n.featuresCategoricalAdjustmentInfo,
                options: [
                  CheckboxGroupSheetOption(
                    title: l10n.featuresMultiSelect,
                    subtitle: l10n.featuresMultiSelectSubtitle,
                    value: () => appSettings.enableMultiSelect,
                    onChanged: (v) => appSettings.enableMultiSelect = v,
                  ),
                  CheckboxGroupSheetOption(
                    title: l10n.featuresCountOccurrences,
                    subtitle: l10n.featuresCountOccurrencesSubtitle,
                    value: () => appSettings.enableCountedSelect,
                    onChanged: (v) => appSettings.enableCountedSelect = v,
                  ),
                ],
              ),
              _FeatureToggleTile(
                icon: TextAdjustment.iconData,
                title: l10n.featuresTextAdjustment,
                value: appSettings.enableTextAdjustment,
                onChanged: (v) => appSettings.enableTextAdjustment = v,
                infoText: l10n.featuresTextAdjustmentInfo,
              ),
              const Divider(),
              SectionTitle(title: l10n.featuresSectionSetups),
              _FeatureGroupTile(
                icon: Icons.tag,
                title: appSettings.developerMode ? l10n.featuresSetupTagsAndBookmarks : l10n.featuresSetupTags,
                infoText: l10n.featuresSetupTagsInfo,
                options: [
                  CheckboxGroupSheetOption(
                    title: l10n.featuresSetupTagsTags,
                    subtitle: l10n.featuresSetupTagsTagsSubtitle,
                    value: () => appSettings.enableSetupTags,
                    onChanged: (v) {
                      appSettings.enableSetupTags = v;
                      if (v) return;
                      final filters = context.read<AppRepository>().filters;
                      filters.setup = filters.setup.copyWith(tags: const {});
                    },
                  ),
                  if (appSettings.developerMode)
                    CheckboxGroupSheetOption(
                      title: l10n.featuresSetupBookmarks,
                      subtitle: l10n.featuresSetupBookmarksSubtitle,
                      value: () => appSettings.enableSetupBookmark,
                      onChanged: (v) {
                        appSettings.enableSetupBookmark = v;
                        if (v) return;
                        final filters = context.read<AppRepository>().filters;
                        filters.setup = filters.setup.copyWith(bookmarkedOnly: false);
                      },
                    ),
                ],
              ),
              if (appSettings.developerMode)
                ListTile(
                  leading: const Icon(Icons.compress),
                  title: Text(l10n.featuresPressureCheck),
                  subtitle: Text(
                    appSettings.enablePressureAssistant
                        ? l10n.featuresPressureCheckOn(
                            appSettings.pressureCheckThresholdPercent,
                            pressureCheckComponentTypesSummary(appSettings.pressureCheckHiddenComponentTypes, l10n),
                          )
                        : l10n.valueOff,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => showPressureCheckSettingSheet(context),
                ),
              if (appSettings.developerMode)
                _FeatureToggleTile(
                  icon: RideFeedback.iconData,
                  title: l10n.featuresFeedback,
                  value: appSettings.enableRating,
                  onChanged: (v) {
                    appSettings.enableRating = v;
                    if (v) return;
                    _showLayer(context, TimelineLayer.feedback);
                    final filters = context.read<AppRepository>().filters;
                    filters.setup = filters.setup.copyWith(testSessionNames: const {});
                  },
                ),
              if (appSettings.developerMode && appSettings.enableRating)
                _FeatureToggleTile(
                  icon: Icons.track_changes,
                  title: l10n.featuresTestSessionGoal,
                  value: appSettings.enableTestSessionGoal,
                  onChanged: (v) => appSettings.enableTestSessionGoal = v,
                  infoText: l10n.featuresTestSessionGoalInfo,
                ),
              _FeatureToggleTile(
                icon: Icons.person,
                title: l10n.featuresRider,
                value: appSettings.enablePerson,
                onChanged: (v) => appSettings.enablePerson = v,
                infoText: l10n.featuresRiderInfo,
              ),
              if (appSettings.developerMode && appSettings.enablePerson)
                _FeatureToggleTile(
                  icon: Icons.groups_outlined,
                  title: l10n.featuresRiderAdvanced,
                  value: appSettings.enablePersonAdvanced,
                  onChanged: (v) => appSettings.enablePersonAdvanced = v,
                  infoText: l10n.featuresRiderAdvancedInfo,
                ),
              const Divider(),
              SectionTitle(title: l10n.featuresSectionSetupHistory),
              _FeatureGroupTile(
                icon: Icons.view_agenda_outlined,
                title: l10n.featuresTimelineGrouping,
                infoText: l10n.featuresTimelineGroupingInfo,
                options: [
                  CheckboxGroupSheetOption(
                    title: l10n.featuresSetupGrouping,
                    subtitle: l10n.featuresSetupGroupingSubtitle,
                    value: () => appSettings.enableTimelineSetupGrouping,
                    onChanged: (v) => appSettings.enableTimelineSetupGrouping = v,
                  ),
                  CheckboxGroupSheetOption(
                    title: l10n.featuresReplacementDetection,
                    subtitle: l10n.featuresReplacementDetectionSubtitle,
                    value: () => appSettings.enableTimelineReplacementDetection,
                    onChanged: (v) => appSettings.enableTimelineReplacementDetection = v,
                  ),
                  CheckboxGroupSheetOption(
                    title: l10n.featuresStravaContext,
                    subtitle: subscriptionService.hasStravaEntitlement
                        ? l10n.featuresStravaContextSubtitle
                        : l10n.featuresStravaContextNeedsSubscription,
                    value: () => appSettings.enableTimelineStravaContext,
                    onChanged: (v) => appSettings.enableTimelineStravaContext = v,
                    enabled: appSettings.enableStrava && subscriptionService.hasStravaEntitlement,
                  ),
                ],
              ),
              _FeatureToggleTile(
                icon: Icons.calendar_month_outlined,
                title: l10n.featuresCalendar,
                value: appSettings.enableCalendar,
                onChanged: (v) => appSettings.enableCalendar = v,
                infoText: l10n.featuresCalendarInfo,
              ),
              _FeatureToggleTile(
                icon: Icons.filter_alt_outlined,
                title: l10n.featuresAdvancedFilters,
                value: appSettings.enableAdvancedFilters,
                onChanged: (v) {
                  appSettings.enableAdvancedFilters = v;
                  if (v) return;
                  final filters = context.read<AppRepository>().filters;
                  filters.dateRange = null;
                  filters.activity = const ActivityFilter();
                },
                infoText: l10n.featuresAdvancedFiltersInfo,
              ),
              const Divider(),
              SectionTitle(title: l10n.featuresSectionTasks),
              _FeatureToggleTile(
                icon: Icons.checklist,
                title: l10n.featuresTasks,
                value: appSettings.enableTask,
                onChanged: (v) {
                  appSettings.enableTask = v;
                  if (!v) _showLayer(context, TimelineLayer.tasks);
                },
                infoText: l10n.featuresTasksInfo,
              ),
              _FeatureGroupTile(
                enabled: appSettings.enableTask,
                icon: Icons.label_outline,
                title: l10n.featuresTaskExtras,
                infoText: l10n.featuresTaskExtrasInfo,
                options: [
                  CheckboxGroupSheetOption(
                    title: l10n.featuresTaskTags,
                    subtitle: l10n.featuresTaskTagsSubtitle,
                    value: () => appSettings.enableTaskTags,
                    onChanged: (v) {
                      appSettings.enableTaskTags = v;
                      if (v) return;
                      final filters = context.read<AppRepository>().filters;
                      filters.taskRule = filters.taskRule.copyWith(tags: const {});
                    },
                  ),
                  CheckboxGroupSheetOption(
                    title: l10n.featuresTaskPriority,
                    subtitle: l10n.featuresTaskPrioritySubtitle,
                    value: () => appSettings.enableTaskPriority,
                    onChanged: (v) {
                      appSettings.enableTaskPriority = v;
                      if (v) return;
                      final filters = context.read<AppRepository>().filters;
                      filters.taskRule = filters.taskRule.copyWith(priorities: TaskPriority.values.toSet());
                    },
                  ),
                  CheckboxGroupSheetOption(
                    title: l10n.featuresTaskInterval,
                    subtitle: l10n.featuresTaskIntervalSubtitle,
                    value: () => appSettings.enableTaskInterval,
                    onChanged: (v) => appSettings.enableTaskInterval = v,
                  ),
                  CheckboxGroupSheetOption(
                    title: l10n.featuresTaskDelay,
                    subtitle: l10n.featuresTaskDelaySubtitle,
                    value: () => appSettings.enableTaskDelay,
                    onChanged: (v) => appSettings.enableTaskDelay = v,
                  ),
                ],
              ),
              _FeatureToggleTile(
                enabled: appSettings.enableTask,
                icon: Icons.insights,
                title: l10n.featuresTaskDuePrediction,
                value: appSettings.enableTaskDuePrediction,
                onChanged: (v) => appSettings.enableTaskDuePrediction = v,
                infoText: l10n.featuresTaskDuePredictionInfo,
              ),
              _FeatureToggleTile(
                enabled: appSettings.enableTask,
                icon: Icons.adjust,
                title: l10n.featuresGarageTaskIndicator,
                value: appSettings.enableGarageTaskIndicator,
                onChanged: (v) => appSettings.enableGarageTaskIndicator = v,
                infoText: l10n.featuresGarageTaskIndicatorInfo,
              ),
              _FeatureToggleTile(
                enabled: appSettings.enableTask && appSettings.enableTaskInterval,
                disabledSubtitle: appSettings.enableTask ? l10n.featuresRequiresTaskInterval : l10n.featuresRequiresTasks,
                icon: Icons.auto_awesome_outlined,
                title: l10n.featuresTaskPresets,
                value: appSettings.enableTaskPresets,
                onChanged: (v) => appSettings.enableTaskPresets = v,
                sheet: (context, value) => showTaskPresetsSettingSheet(context, value: value),
              ),
              if (otherTiles.isNotEmpty) ...[
                const Divider(),
                SectionTitle(title: l10n.featuresSectionOther),
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
  final String? disabledSubtitle;
  final Future<bool?> Function(BuildContext context, bool value)? sheet;

  const _FeatureToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.infoText,
    this.enabled = true,
    this.disabledSubtitle,
    this.sheet,
  });

  Future<void> _openSheet(BuildContext context, Future<bool?> Function(BuildContext, bool) sheet) async {
    final newValue = await sheet(context, value);
    if (newValue != null && newValue != value) onChanged(newValue);
  }

  static Map<bool, Text> _offOnOptionWidgets(AppLocalizations l10n) => {
    false: Text(l10n.valueOff),
    true: Text(l10n.valueOn),
  };

  @override
  Widget build(BuildContext context) {
    final offOnOptionWidgets = _offOnOptionWidgets(context.l10n);

    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: !enabled && disabledSubtitle != null ? Text(disabledSubtitle!) : offOnOptionWidgets[value],
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => _openSheet(
        context,
        sheet ?? (context, value) => showFeatureSettingSheet(context, title: title, value: value, infoText: infoText),
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
      subtitle: Text(enabledTitles.isEmpty ? context.l10n.valueOff : enabledTitles.join(', ')),
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
