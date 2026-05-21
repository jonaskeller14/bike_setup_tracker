import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../icons/simple_icons.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/weather.dart';
import '../repositories/app_repository.dart';
import '../services/strava_service.dart';
import '../widgets/items/strava_subscription_card.dart';
import '../widgets/sheets/app_settings_radio_group.dart';
import '../widgets/text/section_title.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  static const Map<ThemeMode, Row> _themeModeOptionWidgets = {
    ThemeMode.system: Row(
      spacing: 8,
      children: [Icon(Icons.settings), Text("System")],
    ),
    ThemeMode.light: Row(
      spacing: 8,
      children: [Icon(Icons.light_mode), Text("Light")],
    ),
    ThemeMode.dark: Row(
      spacing: 8,
      children: [Icon(Icons.dark_mode), Text("Dark")],
    ),
  };

  static const Map<String, Text> _dateFormatOptionWidgets = {
    'dd.MM.yyyy': Text('dd.MM.yyyy (09.12.2025)'),
    'dd/MM/yyyy': Text('dd/MM/yyyy (09/12/2025)'),
    'MM/dd/yyyy': Text('MM/dd/yyyy (12/09/2025)'),
    'yyyy-MM-dd': Text('yyyy-MM-dd (2025-12-09)'),
    'dd MMM yyyy': Text('dd MMM yyyy (09 Dec 2025)'),
  };

  static const Map<String, Text> _timeFormatOptionWidgets = {
    'HH:mm': Text('HH:mm (20:07)'),
    'h:mm a': Text('h:mm a (8:07 PM)'),
  };

  static const Map<String, Text> _tempUnitOptionWidgets = {
    '°C': Text('Celsius (°C)'),
    '°F': Text('Fahrenheit (°F)'),
    'K': Text('Kelvin (K)'),
  };

  static const Map<String, Text> _windSpeedUnitOptionWidgets = {
    'km/h': Text('Kilometers per hour (km/h)'),
    'mph': Text('Miles per hour (mph)'),
    'm/s': Text('Meters per second (m/s)'),
    'kt': Text('Knots (kt)'),
  };

  static const Map<String, Text> _distanceUnitOptionWidgets = {
    'km': Text('Kilometers (km)'),
    'mi': Text('Miles (mi)'),
  };

  static const Map<String, Text> _altitudeUnitOptionWidgets = {
    'm': Text('Meters (m)'),
    'ft': Text('Feet (ft)'),
  };

  static const Map<String, Text> _precipitationUnitOptionWidgets = {
    'mm': Text('Millimeters (mm)'),
    'in': Text('Inches (in)'),
  };

  static const Map<bool, Text> _offOnOptionWidgets = {
    false: Text('Off'),
    true: Text('On'),
  };

  @override
  Widget build(BuildContext context) {
    final appSettingsWriter = context.read<AppSettings>();
    final appSettingsReader = context.watch<AppSettings>();
    final strava = context.watch<StravaService>();

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Appearance'),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text("App Theme Mode"),
                subtitle: _themeModeOptionWidgets[appSettingsReader.themeMode]?.children[1] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<ThemeMode>(
                  context: context,
                  title: "App Theme Mode",
                  value: appSettingsReader.themeMode,
                  optionWidgets: _themeModeOptionWidgets,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.themeMode = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              const SectionTitle(title: 'Default Formats'),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text("Date Format"),
                subtitle: _dateFormatOptionWidgets[appSettingsReader.dateFormat] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Date Format",
                  value: appSettingsReader.dateFormat,
                  optionWidgets: _dateFormatOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.dateFormat = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("Time Format"),
                subtitle: _timeFormatOptionWidgets[appSettingsReader.timeFormat] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Time Format",
                  value: appSettingsReader.timeFormat,
                  optionWidgets: _timeFormatOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.timeFormat = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              const SectionTitle(title: 'Default Units'),
              ListTile(
                leading: const Icon(Icons.route),
                title: const Text("Distance Unit"),
                subtitle: _distanceUnitOptionWidgets[appSettingsReader.distanceUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Distance Unit",
                  value: appSettingsReader.distanceUnit,
                  optionWidgets: _distanceUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.distanceUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text("Altitude Unit"),
                subtitle: _altitudeUnitOptionWidgets[appSettingsReader.altitudeUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Altitude Unit",
                  value: appSettingsReader.altitudeUnit,
                  optionWidgets: _altitudeUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.altitudeUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Weather.currentTemperatureIconData),
                title: const Text("Temperature Unit"),
                subtitle: _tempUnitOptionWidgets[appSettingsReader.temperatureUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Temperature Unit",
                  value: appSettingsReader.temperatureUnit,
                  optionWidgets: _tempUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.temperatureUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Weather.currentWindSpeedIconData),
                title: const Text("Wind Speed Unit"),
                subtitle: _windSpeedUnitOptionWidgets[appSettingsReader.windSpeedUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Wind Speed Unit",
                  value: appSettingsReader.windSpeedUnit,
                  optionWidgets: _windSpeedUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.windSpeedUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Weather.dayAccumulatedPrecipitationIconData),
                title: const Text("Precipitation Unit"),
                subtitle: _precipitationUnitOptionWidgets[appSettingsReader.precipitationUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Precipitation Unit",
                  value: appSettingsReader.precipitationUnit,
                  optionWidgets: _precipitationUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.precipitationUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              const SectionTitle(title: 'Advanced Features'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Enable these to add specific functionality to your workflow. Keep them disabled to maintain a simpler interface.'),
                dense: true,
              ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(SimpleIcons.googledrive),
                  title: const Text("Google Drive Sync"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.enableGoogleDrive] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Google Drive Sync",
                    value: appSettingsReader.enableGoogleDrive,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.enableGoogleDrive = newValue;
                      Navigator.pop(context);
                    },
                    infoText: 'Sync your data across devices and keep secure backups in your Google Drive. Your data is stored privately in your own account; we never have access to it.',
                  ),
                ),
              ListTile(
                leading: const Icon(Bike.iconData),
                title: const Text("Garage"),
                subtitle: _offOnOptionWidgets[appSettingsReader.enableGarage] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Garage",
                  value: appSettingsReader.enableGarage,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.enableGarage = newValue;
                    Navigator.pop(context);
                  },
                  infoText: 'Enables the Garage layout which focuses on Bikes and their installed Components. If disabled, the app uses a more traditional list-based interface.',
                ),
              ),
              ListTile(
                leading: const Icon(TextAdjustment.iconData),
                title: const Text("Text Adjustment"),
                subtitle: _offOnOptionWidgets[appSettingsReader.enableTextAdjustment] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Text Adjustment",
                  value: appSettingsReader.enableTextAdjustment,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.enableTextAdjustment = newValue;
                    Navigator.pop(context);
                  },
                  infoText: 'Adds a Text Adjustment type that provides a free-form text field.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text("Setup Tags"),
                subtitle: _offOnOptionWidgets[appSettingsReader.enableSetupTags] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Setup Tags",
                  value: appSettingsReader.enableSetupTags,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.enableSetupTags = newValue;
                    if (!newValue) context.read<AppRepository>().deselectAllSetupTags();
                    Navigator.pop(context);
                  },
                  infoText: 'Adds the option to add tags to Setups',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text("Task Tags"),
                subtitle: _offOnOptionWidgets[appSettingsReader.enableTaskTags] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Task Tags",
                  value: appSettingsReader.enableTaskTags,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.enableTaskTags = newValue;
                    if (!newValue) context.read<AppRepository>().deselectAllTaskRuleTags();
                    Navigator.pop(context);
                  },
                  infoText: 'Adds the option to add tags to Task Rules',
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.enablePerson] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Profile",
                    value: appSettingsReader.enablePerson,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.enablePerson = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text("Rating"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.enableRating] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Rating",
                    value: appSettingsReader.enableRating,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.enableRating = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text("Tasks"),
                subtitle: _offOnOptionWidgets[appSettingsReader.enableTask] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<bool>(
                  context: context,
                  title: "Tasks",
                  infoText: "Plan and track anything from recurring maintenance like fork services and chain cleaning to setup experiments like suspension testing or trying different handlebar widths. Keep a complete log of your goals and achievements in one place.",
                  value: appSettingsReader.enableTask,
                  optionWidgets: _offOnOptionWidgets,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettingsWriter.enableTask = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.checklist),
                  title: const Text("Installation Timeline"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.enableInstallationTimeline] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Installation Timeline",
                    value: appSettingsReader.enableInstallationTimeline,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.enableInstallationTimeline = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text("Task Interval"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.enableTaskInterval] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Task Interval",
                    value: appSettingsReader.enableTaskInterval,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.enableTaskInterval = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.more_time_rounded),
                  title: const Text("Task Delay"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.enableTaskDelay] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "Task Delay",
                    value: appSettingsReader.enableTaskDelay,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.enableTaskDelay = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text("MapBox Tiles"),
                  subtitle: _offOnOptionWidgets[appSettingsReader.useMapBoxTiles] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<bool>(
                    context: context,
                    title: "MapBox Tiles",
                    value: appSettingsReader.useMapBoxTiles,
                    optionWidgets: _offOnOptionWidgets,
                    onChanged: (bool? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.useMapBoxTiles = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (appSettingsReader.enableStrava) ...[
                const Divider(),
                const SectionTitle(title: 'Strava Sync'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: StravaSubscriptionCard(),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: const Text("Manage Subscription"),
                  subtitle: const Text("Cancel or change your plan in the store"),
                  trailing: const Icon(Icons.open_in_new, size: 16.0),
                  onTap: () {
                    final uri = Platform.isIOS
                        ? Uri.parse('https://apps.apple.com/account/subscriptions')
                        : Uri.parse(
                            'https://play.google.com/store/account/subscriptions'
                            '?sku=strava_sync'
                            '&package=com.jonaskeller14.bike_setup_tracker',
                          );
                    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
                  },
                ),
                if (strava.isConnected)
                  ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text("Strava Notifications"),
                    subtitle: _offOnOptionWidgets[appSettingsReader.enableStravaNotifications] ?? const Text("-"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () => appSettingsRadioGroupSheet<bool>(
                      context: context,
                      title: "Strava Notifications",
                      value: appSettingsReader.enableStravaNotifications,
                      optionWidgets: _offOnOptionWidgets,
                      onChanged: (bool? newValue) {
                        if (newValue == null) return;
                        appSettingsWriter.enableStravaNotifications = newValue;
                        unawaited(context.read<StravaService>().setStravaNotificationsEnabled(newValue));
                        Navigator.pop(context);
                      },
                      infoText: 'Receive push notifications when Strava activities are imported.',
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
