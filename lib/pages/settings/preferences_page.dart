import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_weather.dart';
import '../../widgets/sheets/app_settings_radio_group.dart';
import '../../widgets/text/section_title.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

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

  static const Map<int, Text> _firstDayOfWeekOptionWidgets = {
    DateTime.monday: Text('Monday'),
    DateTime.sunday: Text('Sunday'),
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

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Appearance'),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text("App Theme Mode"),
                subtitle: _themeModeOptionWidgets[appSettings.themeMode]?.children[1] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<ThemeMode>(
                  context: context,
                  title: "App Theme Mode",
                  value: appSettings.themeMode,
                  optionWidgets: _themeModeOptionWidgets,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue == null) return;
                    appSettings.themeMode = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              const SectionTitle(title: 'Default Formats'),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text("Date Format"),
                subtitle: _dateFormatOptionWidgets[appSettings.dateFormat] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Date Format",
                  value: appSettings.dateFormat,
                  optionWidgets: _dateFormatOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.dateFormat = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("Time Format"),
                subtitle: _timeFormatOptionWidgets[appSettings.timeFormat] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Time Format",
                  value: appSettings.timeFormat,
                  optionWidgets: _timeFormatOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.timeFormat = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              if (appSettings.enableCalendar)
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text("First Day of Week"),
                  subtitle: _firstDayOfWeekOptionWidgets[appSettings.firstDayOfWeek] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => appSettingsRadioGroupSheet<int>(
                    context: context,
                    title: "First Day of Week",
                    value: appSettings.firstDayOfWeek,
                    optionWidgets: _firstDayOfWeekOptionWidgets,
                    onChanged: (int? newValue) {
                      if (newValue == null) return;
                      appSettings.firstDayOfWeek = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              const Divider(),
              const SectionTitle(title: 'Default Units'),
              ListTile(
                leading: const Icon(Icons.route),
                title: const Text("Distance Unit"),
                subtitle: _distanceUnitOptionWidgets[appSettings.distanceUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Distance Unit",
                  value: appSettings.distanceUnit,
                  optionWidgets: _distanceUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.distanceUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text("Altitude Unit"),
                subtitle: _altitudeUnitOptionWidgets[appSettings.altitudeUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Altitude Unit",
                  value: appSettings.altitudeUnit,
                  optionWidgets: _altitudeUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.altitudeUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentTemperatureIconData),
                title: const Text("Temperature Unit"),
                subtitle: _tempUnitOptionWidgets[appSettings.temperatureUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Temperature Unit",
                  value: appSettings.temperatureUnit,
                  optionWidgets: _tempUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.temperatureUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentWindSpeedIconData),
                title: const Text("Wind Speed Unit"),
                subtitle: _windSpeedUnitOptionWidgets[appSettings.windSpeedUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Wind Speed Unit",
                  value: appSettings.windSpeedUnit,
                  optionWidgets: _windSpeedUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.windSpeedUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
                title: const Text("Precipitation Unit"),
                subtitle: _precipitationUnitOptionWidgets[appSettings.precipitationUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => appSettingsRadioGroupSheet<String>(
                  context: context,
                  title: "Precipitation Unit",
                  value: appSettings.precipitationUnit,
                  optionWidgets: _precipitationUnitOptionWidgets,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.precipitationUnit = newValue;
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
