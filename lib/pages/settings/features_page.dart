import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../icons/simple_icons.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/sheets/app_settings_radio_group.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static const Map<bool, Text> _offOnOptionWidgets = {
    false: Text('Off'),
    true: Text('On'),
  };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Enable these to add specific functionality to your workflow. Keep them disabled to maintain a simpler interface.'),
                dense: true,
              ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(SimpleIcons.googledrive),
                  title: const Text("Google Drive Sync"),
                  subtitle: _offOnOptionWidgets[appSettings.enableGoogleDrive] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Google Drive Sync",
                    value: appSettings.enableGoogleDrive,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableGoogleDrive = newValue;
                      Navigator.pop(context);
                    },
                    infoText: 'Sync your data across devices and keep secure backups in your Google Drive. Your data is stored privately in your own account; we never have access to it.',
                  ),
                ),
              ListTile(
                leading: const Icon(Bike.iconData),
                title: const Text("Garage"),
                subtitle: _offOnOptionWidgets[appSettings.enableGarage] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Garage",
                  value: appSettings.enableGarage,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableGarage = newValue;
                    Navigator.pop(context);
                  },
                  infoText: 'Enables the Garage layout which focuses on Bikes and their installed Components. If disabled, the app uses a more traditional list-based interface.',
                ),
              ),
              ListTile(
                leading: const Icon(TextAdjustment.iconData),
                title: const Text("Text Adjustment"),
                subtitle: _offOnOptionWidgets[appSettings.enableTextAdjustment] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
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
                leading: const Icon(Icons.tag),
                title: const Text("Setup Tags"),
                subtitle: _offOnOptionWidgets[appSettings.enableSetupTags] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Setup Tags",
                  value: appSettings.enableSetupTags,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableSetupTags = newValue;
                    if (!newValue) context.read<AppRepository>().deselectAllSetupTags();
                    Navigator.pop(context);
                  },
                  infoText: 'Adds the option to add tags to Setups',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text("Installation Timeline"),
                subtitle: _offOnOptionWidgets[appSettings.enableInstallationTimeline] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Installation Timeline",
                  value: appSettings.enableInstallationTimeline,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableInstallationTimeline = newValue;
                    Navigator.pop(context);
                  },
                  infoText: 'By default, Components are linked to a Bike. '
                  'When this setting is enabled, you can track exactly when a component was installed and deinstalled. '
                  'This allows you to deinstall components and move them between different bikes without losing track of their history, usage, or setups.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text("Tasks"),
                subtitle: _offOnOptionWidgets[appSettings.enableTask] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Tasks",
                  infoText: "Plan and track anything from recurring maintenance like fork services and chain cleaning to setup experiments like suspension testing or trying different handlebar widths. Keep a complete log of your goals and achievements in one place.",
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
                leading: const Icon(Icons.tag),
                title: const Text("Task Tags"),
                subtitle: _offOnOptionWidgets[appSettings.enableTaskTags] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Task Tags",
                  value: appSettings.enableTaskTags,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableTaskTags = newValue;
                    if (!newValue) context.read<AppRepository>().deselectAllTaskRuleTags();
                    Navigator.pop(context);
                  },
                  infoText: 'Adds the option to add tags to Task Rules',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.traffic),
                title: const Text("Task Priority"),
                subtitle: _offOnOptionWidgets[appSettings.enableTaskPriority] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Task Priority",
                  value: appSettings.enableTaskPriority,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableTaskPriority = newValue;
                    if (!newValue) context.read<AppRepository>().selectAllTaskPriorities();
                    Navigator.pop(context);
                  },
                  infoText: 'Shows the Priority field on tasks. Disable to simplify the task interface.',
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text("Task Interval"),
                  subtitle: _offOnOptionWidgets[appSettings.enableTaskInterval] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Task Interval",
                    value: appSettings.enableTaskInterval,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableTaskInterval = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.more_time_rounded),
                  title: const Text("Task Delay"),
                  subtitle: _offOnOptionWidgets[appSettings.enableTaskDelay] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Task Delay",
                    value: appSettings.enableTaskDelay,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableTaskDelay = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text("Calendar"),
                subtitle: _offOnOptionWidgets[appSettings.enableCalendar] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Calendar",
                  value: appSettings.enableCalendar,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.enableCalendar = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  subtitle: _offOnOptionWidgets[appSettings.enablePerson] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
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
                  onTap: () => appSettingsRadioGroupSheet<bool>(
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
                  leading: const Icon(SimpleIcons.strava),
                  title: const Text("Strava"),
                  subtitle: _offOnOptionWidgets[appSettings.enableStrava] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Strava",
                    value: appSettings.enableStrava,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettings.enableStrava = newValue;
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
                  onTap: () => appSettingsRadioGroupSheet<bool>(
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
