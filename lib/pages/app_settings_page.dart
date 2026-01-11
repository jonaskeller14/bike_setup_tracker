import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/app_settings.dart';
import '../widgets/sheets/app_settings_radio_group.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  static const Map<ThemeMode, Row> _themeModeOptionWidgets = {
    ThemeMode.system: Row(spacing: 8, children: [Icon(Icons.settings), Text("System")]),
    ThemeMode.light: Row(spacing: 8, children: [Icon(Icons.light_mode), Text("Light")]),
    ThemeMode.dark: Row(spacing: 8, children: [Icon(Icons.dark_mode), Text("Dark")]),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setThemeMode(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Default Formats',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setDateFormat(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setTimeFormat(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Default Units',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setAltitudeUnit(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.thermostat, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setTemperatureUnit(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.air, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setWindSpeedUnit(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setPrecipitationUnit(newValue);
                  Navigator.pop(context);
                }
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Experimental Features',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Experimental features are optional features which can lead to unexpected behavior. They can be enabled or disabled at any time.'),
              dense: true,
            ),
            ListTile(
              leading: Icon(SimpleIcons.googledrive, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setEnableGoogleDrive(newValue);
                  Navigator.pop(context);
                },
                infoText: 'Sync your data across devices and keep secure backups in your Google Drive. Your data is stored privately in your own account; we never have access to it.',
              ),
            ),
            ListTile(
              leading: Icon(Icons.text_snippet, color: Theme.of(context).colorScheme.primary),
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
                  appSettingsWriter.setEnableTextAdjustment(newValue);
                  Navigator.pop(context);
                },
                infoText: 'Adds a Text Adjustment type that provides a free-form text field.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
